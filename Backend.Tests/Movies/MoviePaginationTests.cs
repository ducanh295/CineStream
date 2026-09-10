using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CineStream.DTOs.Common;
using CineStream.DTOs.Movies;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;
using Xunit;

namespace Backend.Tests.Movies;

// Bo kiem thu don vi cho chuc nang phan trang danh sach phim trong MovieService
public class MoviePaginationTests
{
    private readonly IMovieService _movieService;
    private readonly List<Movie> _seedMovies;

    public MoviePaginationTests()
    {
        _seedMovies = new List<Movie>
        {
            new Movie { Id = 1, Title = "Dai Thoai Tay Du", ReleaseYear = 1995, Duration = 105, Type = MovieType.Single },
            new Movie { Id = 2, Title = "Tears of Steel", ReleaseYear = 2012, Duration = 12, Type = MovieType.Single },
            new Movie { Id = 3, Title = "Big Buck Bunny", ReleaseYear = 2008, Duration = 10, Type = MovieType.Single },
            new Movie { Id = 4, Title = "Sintel", ReleaseYear = 2010, Duration = 15, Type = MovieType.Single },
            new Movie { Id = 5, Title = "Elephant Dream", ReleaseYear = 2006, Duration = 11, Type = MovieType.Single }
        };

        var fakeMovieRepo = new FakeMovieRepository(_seedMovies);
        var fakeCategoryRepo = new FakeCategoryRepository();
        _movieService = new MovieService(fakeMovieRepo, fakeCategoryRepo);
    }

    [Fact]
    public async Task GetAllAsync_PhanTrangTrangDau_TraVeDungSoLuongVaTongSo()
    {
        // Act: Lay trang 1 voi kich thuoc 2
        var response = await _movieService.GetAllAsync(categoryId: null, search: null, pageNumber: 1, pageSize: 2);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal(2, response.Data.Items.Count);
        Assert.Equal(5, response.Data.TotalCount);
        Assert.Equal(1, response.Data.PageNumber);
        Assert.Equal(2, response.Data.PageSize);
        Assert.Equal(3, response.Data.TotalPages);
        Assert.Equal("Dai Thoai Tay Du", response.Data.Items[0].Title);
        Assert.Equal("Tears of Steel", response.Data.Items[1].Title);
    }

    [Fact]
    public async Task GetAllAsync_PhanTrangTrangCuoi_TraVeSoLuongPhanTuConLai()
    {
        // Act: Lay trang 3 voi kich thuoc 2 (chi con 1 phan tu)
        var response = await _movieService.GetAllAsync(categoryId: null, search: null, pageNumber: 3, pageSize: 2);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Single(response.Data.Items);
        Assert.Equal(5, response.Data.TotalCount);
        Assert.Equal(3, response.Data.PageNumber);
        Assert.Equal("Elephant Dream", response.Data.Items[0].Title);
    }

    [Fact]
    public async Task GetAllAsync_LocTheoTuKhoaVaPhanTrang_KetQuaChinhXac()
    {
        // Act: Tim kiem tu khoa "steel"
        var response = await _movieService.GetAllAsync(categoryId: null, search: "steel", pageNumber: 1, pageSize: 10);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Single(response.Data.Items);
        Assert.Equal(1, response.Data.TotalCount);
        Assert.Equal("Tears of Steel", response.Data.Items[0].Title);
    }

    [Fact]
    public async Task GetAllAsync_ThamSoPhanTrangKhongHopLe_TuDongDieuChinhVeGiaTriAnToan()
    {
        // Act: Gui pageNumber = -1 va pageSize = 0
        var response = await _movieService.GetAllAsync(categoryId: null, search: null, pageNumber: -1, pageSize: 0);

        // Assert: He thong tu dong dieu chinh ve pageNumber = 1, pageSize = 10
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal(1, response.Data.PageNumber);
        Assert.Equal(10, response.Data.PageSize);
        Assert.Equal(5, response.Data.Items.Count);
    }
}

// Stub repository phuc vu kiem thu MovieService
internal class FakeMovieRepository : IMovieRepository
{
    private readonly List<Movie> _movies;

    public FakeMovieRepository(List<Movie> movies)
    {
        _movies = movies;
    }

    public Task<IReadOnlyList<Movie>> GetAllWithCategoriesAsync()
    {
        return Task.FromResult<IReadOnlyList<Movie>>(_movies.AsReadOnly());
    }

    public Task<IReadOnlyList<Movie>> GetMoviesByCategoryIdAsync(int categoryId)
    {
        return Task.FromResult<IReadOnlyList<Movie>>(_movies.AsReadOnly());
    }

    public Task<Movie?> GetWithCategoriesAsync(int id)
    {
        return Task.FromResult(_movies.FirstOrDefault(m => m.Id == id));
    }

    public Task UpdateMovieCategoriesAsync(int movieId, List<int> categoryIds)
    {
        return Task.CompletedTask;
    }

    public Task<Movie?> GetByIdAsync(int id) => Task.FromResult(_movies.FirstOrDefault(m => m.Id == id));
    public Task<IReadOnlyList<Movie>> GetAllAsync() => Task.FromResult<IReadOnlyList<Movie>>(_movies.AsReadOnly());
    public Task<Movie> AddAsync(Movie entity) { _movies.Add(entity); return Task.FromResult(entity); }
    public void Update(Movie entity) { }
    public Task<bool> DeleteAsync(int id) => Task.FromResult(true);
    public Task<int> SaveChangesAsync() => Task.FromResult(1);
}

// Stub repository the loai phuc vu kiem thu
internal class FakeCategoryRepository : ICategoryRepository
{
    public Task<Category?> GetByIdAsync(int id) => Task.FromResult<Category?>(null);
    public Task<Category?> GetByNameAsync(string name) => Task.FromResult<Category?>(null);
    public Task<IReadOnlyList<Category>> GetAllAsync() => Task.FromResult<IReadOnlyList<Category>>(new List<Category>());
    public Task<Category> AddAsync(Category entity) => Task.FromResult(entity);
    public void Update(Category entity) { }
    public Task<bool> DeleteAsync(int id) => Task.FromResult(true);
    public Task<int> SaveChangesAsync() => Task.FromResult(1);
    public Task<bool> ExistsByNameAsync(string name, int? excludeId = null) => Task.FromResult(false);
}
