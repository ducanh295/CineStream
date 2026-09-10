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

    public async Task<ApiResponse<PagedResult<MovieDto>>> GetAllAsync(int? categoryId = null, string? search = null, int pageNumber = 1, int pageSize = 10)
    {
        // Dam bao pageNumber va pageSize luon hop le phong ngua tham so sai lech
        if (pageNumber < 1) pageNumber = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        // Truy vấn danh sách phim, nếu có categoryId thì lọc theo thể loại, ngược lại lấy toàn bộ
        IReadOnlyList<Movie> movies;
        if (categoryId.HasValue)
        {
            movies = await _movieRepo.GetMoviesByCategoryIdAsync(categoryId.Value);
        }
        else
        {
            movies = await _movieRepo.GetAllWithCategoriesAsync();
        }

        // Nếu client truyền từ khóa tìm kiếm thì lọc tiếp theo tiêu đề phim không phân biệt hoa thường
        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToLower();
            movies = movies.Where(m => m.Title.ToLower().Contains(keyword)).ToList();
        }

        var totalCount = movies.Count;

        // Ap dung cat phan trang theo vi tri trang va kich thuoc trang yeu cau
        var pagedMovies = movies
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(MapToMovieDto)
            .ToList();

        var result = new PagedResult<MovieDto>
        {
            Items = pagedMovies,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize
        };

        return ApiResponse<PagedResult<MovieDto>>.Ok(result);
    }

    public async Task<ApiResponse<MovieDetailDto>> GetByIdAsync(int id)
    {
        // Tìm phim theo mã định danh và nạp kèm danh sách thể loại
        var movie = await _movieRepo.GetWithCategoriesAsync(id);
        if (movie == null)
        {
            return ApiResponse<MovieDetailDto>.Fail("Khong tim thay phim!");
        }

        // Ánh xạ thực thể sang MovieDetailDto gồm đầy đủ đường dẫn video phát stream
        return ApiResponse<MovieDetailDto>.Ok(MapToMovieDetailDto(movie));
    }

    public async Task<ApiResponse<MovieDetailDto>> CreateAsync(CreateMovieDto dto)
    {
        // Kiểm tra tính hợp lệ của tiêu đề phim
        if (string.IsNullOrWhiteSpace(dto.Title))
        {
            return ApiResponse<MovieDetailDto>.Fail("Tieu de phim khong duoc de trong!");
        }

        var trimmedTitle = dto.Title.Trim();

        // Khởi tạo thực thể Movie kèm các thể loại liên kết trong bảng trung gian
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

        // Nạp lại phim kèm thông tin Category đầy đủ để trả về cho client
        var createdMovie = await _movieRepo.GetWithCategoriesAsync(movie.Id);
        return ApiResponse<MovieDetailDto>.Ok(MapToMovieDetailDto(createdMovie!), "Tao phim thanh cong!");
    }

    public async Task<ApiResponse<MovieDetailDto>> UpdateAsync(int id, UpdateMovieDto dto)
    {
        // Kiểm tra tính hợp lệ của tiêu đề phim
        if (string.IsNullOrWhiteSpace(dto.Title))
        {
            return ApiResponse<MovieDetailDto>.Fail("Tieu de phim khong duoc de trong!");
        }

        // Kiểm tra bộ phim cần cập nhật có tồn tại không
        var movie = await _movieRepo.GetByIdAsync(id);
        if (movie == null)
        {
            return ApiResponse<MovieDetailDto>.Fail("Khong tim thay phim!");
        }

        // Cập nhật các trường thông tin của phim
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

        // Đồng bộ lại danh sách thể loại trong bảng trung gian MovieCategories
        if (dto.CategoryIds != null)
        {
            await _movieRepo.UpdateMovieCategoriesAsync(id, dto.CategoryIds.Distinct().ToList());
        }

        await _movieRepo.SaveChangesAsync();

        // Nạp lại thông tin phim sau khi cập nhật để trả về kết quả đầy đủ
        var updatedMovie = await _movieRepo.GetWithCategoriesAsync(id);
        return ApiResponse<MovieDetailDto>.Ok(MapToMovieDetailDto(updatedMovie!), "Cap nhat phim thanh cong!");
    }

    public async Task<ApiResponse<bool>> DeleteAsync(int id)
    {
        // Thực hiện xóa mềm bộ phim theo định danh
        bool deleted = await _movieRepo.DeleteAsync(id);
        if (!deleted)
        {
            return ApiResponse<bool>.Fail("Khong tim thay phim!");
        }

        await _movieRepo.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Xoa phim thanh cong!");
    }

    // Lấy thông tin luồng phát video chuyên biệt cho Player (hỗ trợ cả HLS và CDN Direct MP4)
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

    // Xác định loại luồng phát dựa vào định dạng URL video
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

    // Ánh xạ thực thể Movie sang MovieDto (ẩn VideoUrl để tối ưu băng thông)
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

    // Ánh xạ thực thể Movie sang MovieDetailDto (chứa đầy đủ VideoUrl và CreatedAt)
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
