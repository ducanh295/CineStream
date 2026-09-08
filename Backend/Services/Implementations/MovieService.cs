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

        // Neu client truyen tu khoa tim kiem thi loc tiep theo tieu de phim
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

    public Task<ApiResponse<MovieDetailDto>> CreateAsync(CreateMovieDto dto)
    {
        // Phuong thuc nay se duoc trien khai chi tiet trong Step 2.3
        throw new NotImplementedException();
    }

    public Task<ApiResponse<MovieDetailDto>> UpdateAsync(int id, UpdateMovieDto dto)
    {
        // Phuong thuc nay se duoc trien khai chi tiet trong Step 2.3
        throw new NotImplementedException();
    }

    public Task<ApiResponse<bool>> DeleteAsync(int id)
    {
        // Phuong thuc nay se duoc trien khai chi tiet trong Step 2.3
        throw new NotImplementedException();
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

    // Anh xa thuc the Movie sang MovieDetailDto (chua VideoUrl va CreatedAt)
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
