using CineStream.DTOs.Categories;
using CineStream.DTOs.Common;
using CineStream.DTOs.Movies;
using CineStream.Models;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

public class MovieService : IMovieService
{
    private readonly IMovieRepository _movieRepo;
    private readonly ICategoryRepository _categoryRepo;

    public MovieService(IMovieRepository movieRepo, ICategoryRepository categoryRepo)
    {
        _movieRepo = movieRepo;
        _categoryRepo = categoryRepo;
    }

    public async Task<ApiResponse<IReadOnlyList<MovieDto>>> GetAllAsync(int? categoryId = null, string? search = null)
    {
        // Truy van danh sach phim, neu co categoryId thi loc theo the loai, nguoc lai lay toan bo
        IReadOnlyList<Movie> movies;
        if (categoryId.HasValue)
        {
            movies = await _movieRepo.GetMoviesByCategoryIdAsync(categoryId.Value);
        }
        else
        {
            movies = await _movieRepo.GetAllWithCategoriesAsync();
        }

        // Neu client truyen tu khoa tim kiem thi loc tiep theo tieu de phim khong phan biet hoa thuong
        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToLower();
            movies = movies.Where(m => m.Title.ToLower().Contains(keyword)).ToList();
        }

        // Anh xa danh sach thuc the sang MovieDto danh cho hien thi danh sach
        var result = movies.Select(MapToMovieDto).ToList().AsReadOnly();
        return ApiResponse<IReadOnlyList<MovieDto>>.Ok(result);
    }

    public async Task<ApiResponse<MovieDetailDto>> GetByIdAsync(int id)
    {
        // Tim phim theo ma dinh danh va nap kem danh sach the loai
        var movie = await _movieRepo.GetWithCategoriesAsync(id);
        if (movie == null)
        {
            return ApiResponse<MovieDetailDto>.Fail("Khong tim thay phim!");
        }

        // Anh xa thuc the sang MovieDetailDto gom day du duong dan video phat stream
        return ApiResponse<MovieDetailDto>.Ok(MapToMovieDetailDto(movie));
    }

    public async Task<ApiResponse<MovieDetailDto>> CreateAsync(CreateMovieDto dto)
    {
        // Kiem tra tinh hop le cua tieu de phim
        if (string.IsNullOrWhiteSpace(dto.Title))
        {
            return ApiResponse<MovieDetailDto>.Fail("Tieu de phim khong duoc de trong!");
        }

        var trimmedTitle = dto.Title.Trim();

        // Khoi tao thuc the Movie kem cac the loai lien ket trong bang trung gian
        var movie = new Movie
        {
            Title = trimmedTitle,
            Description = dto.Description?.Trim(),
            PosterUrl = dto.PosterUrl?.Trim(),
            VideoUrl = dto.VideoUrl?.Trim(),
            VideoStatus = !string.IsNullOrWhiteSpace(dto.VideoUrl) ? 1 : 0,
            TrailerUrl = dto.TrailerUrl?.Trim(),
            Duration = dto.Duration,
            ReleaseYear = dto.ReleaseYear,
            Type = dto.Type,
            MovieCategories = dto.CategoryIds?
                .Distinct()
                .Select(catId => new MovieCategory { CategoryId = catId })
                .ToList() ?? new List<MovieCategory>()
        };

        await _movieRepo.AddAsync(movie);
        await _movieRepo.SaveChangesAsync();

        // Nap lai phim kem thong tin Category day du de tra ve cho client
        var createdMovie = await _movieRepo.GetWithCategoriesAsync(movie.Id);
        return ApiResponse<MovieDetailDto>.Ok(MapToMovieDetailDto(createdMovie!), "Tao phim thanh cong!");
    }

    public async Task<ApiResponse<MovieDetailDto>> UpdateAsync(int id, UpdateMovieDto dto)
    {
        // Kiem tra tinh hop le cua tieu de phim
        if (string.IsNullOrWhiteSpace(dto.Title))
        {
            return ApiResponse<MovieDetailDto>.Fail("Tieu de phim khong duoc de trong!");
        }

        // Kiem tra bo phim can cap nhat co ton tai khong
        var movie = await _movieRepo.GetByIdAsync(id);
        if (movie == null)
        {
            return ApiResponse<MovieDetailDto>.Fail("Khong tim thay phim!");
        }

        // Cap nhat cac truong thong tin cua phim
        movie.Title = dto.Title.Trim();
        movie.Description = dto.Description?.Trim();
        movie.PosterUrl = dto.PosterUrl?.Trim();
        movie.VideoUrl = dto.VideoUrl?.Trim();
        movie.VideoStatus = dto.VideoStatus != 0 ? dto.VideoStatus : (!string.IsNullOrWhiteSpace(dto.VideoUrl) ? 1 : 0);
        movie.TrailerUrl = dto.TrailerUrl?.Trim();
        movie.Duration = dto.Duration;
        movie.ReleaseYear = dto.ReleaseYear;
        movie.Type = dto.Type;

        _movieRepo.Update(movie);

        // Dong bo lai danh sach the loai trong bang trung gian MovieCategories
        if (dto.CategoryIds != null)
        {
            await _movieRepo.UpdateMovieCategoriesAsync(id, dto.CategoryIds.Distinct().ToList());
        }

        await _movieRepo.SaveChangesAsync();

        // Nap lai thong tin phim sau khi cap nhat de tra ve ket qua day du
        var updatedMovie = await _movieRepo.GetWithCategoriesAsync(id);
        return ApiResponse<MovieDetailDto>.Ok(MapToMovieDetailDto(updatedMovie!), "Cap nhat phim thanh cong!");
    }

    public async Task<ApiResponse<bool>> DeleteAsync(int id)
    {
        // Thuc hien xoa mem bo phim theo dinh danh
        bool deleted = await _movieRepo.DeleteAsync(id);
        if (!deleted)
        {
            return ApiResponse<bool>.Fail("Khong tim thay phim!");
        }

        await _movieRepo.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Xoa phim thanh cong!");
    }

    // Lay thong tin luong phat video chuyen biet cho Player (ho tro ca HLS va CDN Direct MP4)
    public async Task<ApiResponse<MoviePlaybackDto>> GetPlaybackAsync(int id)
    {
        var movie = await _movieRepo.GetByIdAsync(id);
        if (movie == null)
        {
            return ApiResponse<MoviePlaybackDto>.Fail("Khong tim thay phim!");
        }

        var playbackDto = new MoviePlaybackDto
        {
            MovieId = movie.Id,
            Title = movie.Title,
            StreamUrl = movie.VideoUrl,
            StreamType = DetermineStreamType(movie.VideoUrl),
            VideoStatus = movie.VideoStatus,
            Duration = movie.Duration
        };

        return ApiResponse<MoviePlaybackDto>.Ok(playbackDto, "Lay thong tin luong phat thanh cong!");
    }

    // Xac dinh loai luong phat dua vao dinh dang URL video
    private static string DetermineStreamType(string? videoUrl)
    {
        if (string.IsNullOrWhiteSpace(videoUrl))
        {
            return "NONE";
        }

        if (videoUrl.Contains(".m3u8", StringComparison.OrdinalIgnoreCase))
        {
            return "HLS";
        }

        return "DIRECT_MP4";
    }

    // Anh xa thuc the Movie sang MovieDto (an VideoUrl de toi uu bang thong)
    private static MovieDto MapToMovieDto(Movie movie)
    {
        return new MovieDto
        {
            Id = movie.Id,
            Title = movie.Title,
            Description = movie.Description,
            PosterUrl = movie.PosterUrl,
            TrailerUrl = movie.TrailerUrl,
            Duration = movie.Duration,
            ReleaseYear = movie.ReleaseYear,
            Type = movie.Type,
            VideoStatus = movie.VideoStatus,
            Categories = movie.MovieCategories
                .Where(mc => mc.Category != null)
                .Select(mc => new CategoryDto
                {
                    Id = mc.Category.Id,
                    Name = mc.Category.Name,
                    Description = mc.Category.Description
                }).ToList()
        };
    }

    // Anh xa thuc the Movie sang MovieDetailDto (chua day du VideoUrl va CreatedAt)
    private static MovieDetailDto MapToMovieDetailDto(Movie movie)
    {
        return new MovieDetailDto
        {
            Id = movie.Id,
            Title = movie.Title,
            Description = movie.Description,
            PosterUrl = movie.PosterUrl,
            TrailerUrl = movie.TrailerUrl,
            Duration = movie.Duration,
            ReleaseYear = movie.ReleaseYear,
            Type = movie.Type,
            VideoStatus = movie.VideoStatus,
            VideoUrl = movie.VideoUrl,
            StreamType = DetermineStreamType(movie.VideoUrl),
            CreatedAt = movie.CreatedAt,
            Categories = movie.MovieCategories
                .Where(mc => mc.Category != null)
                .Select(mc => new CategoryDto
                {
                    Id = mc.Category.Id,
                    Name = mc.Category.Name,
                    Description = mc.Category.Description
                }).ToList()
        };
    }
}
