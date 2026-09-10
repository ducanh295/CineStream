using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CineStream.DTOs.Favorites;
using CineStream.Models;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;
using Xunit;

namespace Backend.Tests.Favorites;

// Bo kiem thu don vi cho FavoriteService theo quy trinh TDD
public class FavoriteServiceTests
{
    private readonly FakeFavoriteRepository _fakeFavoriteRepo;
    private readonly FakeMovieRepositoryForFavorite _fakeMovieRepo;
    private readonly IFavoriteService _favoriteService;

    public FavoriteServiceTests()
    {
        _fakeFavoriteRepo = new FakeFavoriteRepository();
        _fakeMovieRepo = new FakeMovieRepositoryForFavorite();
        _favoriteService = new FavoriteService(_fakeFavoriteRepo, _fakeMovieRepo);
    }

    [Fact]
    public async Task GetMyFavoritesAsync_TraVeDanhSachKemTheLoaiVaSapXepThoiGian()
    {
        // Arrange
        var movie1 = new Movie
        {
            Id = 1,
            Title = "Phim Hành Động 1",
            MovieCategories = new List<MovieCategory>
            {
                new MovieCategory { MovieId = 1, Category = new Category { Id = 1, Name = "Hành Động" } }
            }
        };
        var movie2 = new Movie
        {
            Id = 2,
            Title = "Phim Hài 2",
            MovieCategories = new List<MovieCategory>
            {
                new MovieCategory { MovieId = 2, Category = new Category { Id = 2, Name = "Hài Hước" } }
            }
        };

        _fakeMovieRepo.Seed(movie1);
        _fakeMovieRepo.Seed(movie2);

        _fakeFavoriteRepo.Seed(new Favorite { UserId = 10, MovieId = 1, Movie = movie1, CreatedAt = DateTime.UtcNow.AddMinutes(-10) });
        _fakeFavoriteRepo.Seed(new Favorite { UserId = 10, MovieId = 2, Movie = movie2, CreatedAt = DateTime.UtcNow });

        // Act
        var response = await _favoriteService.GetMyFavoritesAsync(10);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal(2, response.Data.Count);

        // Phim moi them gan nhat phai dung dau tien
        Assert.Equal(2, response.Data[0].MovieId);
        Assert.Contains("Hài Hước", response.Data[0].Categories);
    }

    [Fact]
    public async Task CheckFavoriteStatusAsync_PhimDaThich_TraVeTrue()
    {
        // Arrange
        _fakeFavoriteRepo.Seed(new Favorite { UserId = 5, MovieId = 100 });

        // Act
        var response = await _favoriteService.CheckFavoriteStatusAsync(userId: 5, movieId: 100);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.True(response.Data.IsFavorite);
    }

    [Fact]
    public async Task CheckFavoriteStatusAsync_PhimChuaThich_TraVeFalse()
    {
        // Act
        var response = await _favoriteService.CheckFavoriteStatusAsync(userId: 5, movieId: 999);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.False(response.Data.IsFavorite);
    }

    [Fact]
    public async Task AddFavoriteAsync_PhimKhongTonTai_BaoLoi()
    {
        // Act: MovieId = 999 khong ton tai trong MovieRepository
        var response = await _favoriteService.AddFavoriteAsync(userId: 1, movieId: 999);

        // Assert
        Assert.False(response.Success);
        Assert.Contains("Không tìm thấy", response.Message);
    }

    [Fact]
    public async Task AddFavoriteAsync_PhimTonTaiVaChuaThich_ThemThanhCong()
    {
        // Arrange
        var movie = new Movie { Id = 20, Title = "Phim Moi" };
        _fakeMovieRepo.Seed(movie);

        // Act
        var response = await _favoriteService.AddFavoriteAsync(userId: 1, movieId: 20);

        // Assert
        Assert.True(response.Success);
        Assert.True(await _fakeFavoriteRepo.IsFavoriteAsync(1, 20));
    }

    [Fact]
    public async Task AddFavoriteAsync_PhimDaCoSanTrongYeuThich_KhongBaoLoiHeThong()
    {
        // Arrange: Phim da duoc them vao danh sach truoc do
        var movie = new Movie { Id = 30, Title = "Phim Co San" };
        _fakeMovieRepo.Seed(movie);
        _fakeFavoriteRepo.Seed(new Favorite { UserId = 1, MovieId = 30, Movie = movie });

        // Act: Nguoi dung an them lai (tinh chat luy dang Idempotent)
        var response = await _favoriteService.AddFavoriteAsync(userId: 1, movieId: 30);

        // Assert
        Assert.True(response.Success);
        Assert.Contains("đã có sẵn", response.Message);
    }

    [Fact]
    public async Task RemoveFavoriteAsync_PhimKhongCoTrongYeuThich_BaoLoi()
    {
        // Act: Xoa phim chua tung duoc them vao yeu thich
        var response = await _favoriteService.RemoveFavoriteAsync(userId: 1, movieId: 50);

        // Assert
        Assert.False(response.Success);
        Assert.Contains("không có trong danh sách", response.Message);
    }

    [Fact]
    public async Task RemoveFavoriteAsync_PhimDangCoTrongYeuThich_XoaThanhCong()
    {
        // Arrange
        _fakeFavoriteRepo.Seed(new Favorite { UserId = 1, MovieId = 60 });

        // Act
        var response = await _favoriteService.RemoveFavoriteAsync(userId: 1, movieId: 60);

        // Assert
        Assert.True(response.Success);
        Assert.False(await _fakeFavoriteRepo.IsFavoriteAsync(1, 60));
    }
}

// Stub repository yeu thich phuc vu kiem thu
internal class FakeFavoriteRepository : IFavoriteRepository
{
    private readonly List<Favorite> _favorites = new();

    public void Seed(Favorite favorite) => _favorites.Add(favorite);

    public Task<IReadOnlyList<Favorite>> GetByUserIdAsync(int userId)
    {
        var list = _favorites.Where(f => f.UserId == userId)
                             .OrderByDescending(f => f.CreatedAt)
                             .ToList();
        return Task.FromResult<IReadOnlyList<Favorite>>(list);
    }

    public Task<bool> IsFavoriteAsync(int userId, int movieId)
    {
        return Task.FromResult(_favorites.Any(f => f.UserId == userId && f.MovieId == movieId));
    }

    public Task<bool> AddAsync(int userId, int movieId)
    {
        if (_favorites.Any(f => f.UserId == userId && f.MovieId == movieId)) return Task.FromResult(false);
        _favorites.Add(new Favorite { UserId = userId, MovieId = movieId, CreatedAt = DateTime.UtcNow });
        return Task.FromResult(true);
    }

    public Task<bool> RemoveAsync(int userId, int movieId)
    {
        var item = _favorites.FirstOrDefault(f => f.UserId == userId && f.MovieId == movieId);
        if (item == null) return Task.FromResult(false);
        _favorites.Remove(item);
        return Task.FromResult(true);
    }

    public Task<int> SaveChangesAsync() => Task.FromResult(1);
}

// Stub repository phim phuc vu kiem thu
internal class FakeMovieRepositoryForFavorite : IMovieRepository
{
    private readonly List<Movie> _movies = new();

    public void Seed(Movie movie) => _movies.Add(movie);

    public Task<Movie?> GetByIdAsync(int id) => Task.FromResult(_movies.FirstOrDefault(m => m.Id == id && !m.IsDeleted));
    public Task<IReadOnlyList<Movie>> GetAllAsync() => Task.FromResult<IReadOnlyList<Movie>>(_movies.Where(m => !m.IsDeleted).ToList());
    public Task<Movie> AddAsync(Movie entity) { _movies.Add(entity); return Task.FromResult(entity); }
    public void Update(Movie entity) { }
    public Task<bool> DeleteAsync(int id) => Task.FromResult(true);
    public Task<int> SaveChangesAsync() => Task.FromResult(1);

    public Task<Movie?> GetWithCategoriesAsync(int id) => Task.FromResult(_movies.FirstOrDefault(m => m.Id == id));
    public Task<IReadOnlyList<Movie>> GetAllWithCategoriesAsync() => Task.FromResult<IReadOnlyList<Movie>>(_movies);
    public Task<IReadOnlyList<Movie>> GetMoviesByCategoryIdAsync(int categoryId) => Task.FromResult<IReadOnlyList<Movie>>(_movies);
    public Task UpdateMovieCategoriesAsync(int movieId, List<int> categoryIds) => Task.CompletedTask;
}
