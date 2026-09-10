using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using CineStream.Controllers;
using CineStream.DTOs.Common;
using CineStream.DTOs.Favorites;
using CineStream.Services.Interfaces;
using Xunit;

namespace Backend.Tests.Favorites;

// Bo kiem thu don vi cho FavoritesController theo quy trinh TDD
public class FavoritesControllerTests
{
    private readonly FakeFavoriteService _fakeService;
    private readonly FavoritesController _controller;

    public FavoritesControllerTests()
    {
        _fakeService = new FakeFavoriteService();
        _controller = new FavoritesController(_fakeService);
        SetUserContext(_controller, "7");
    }

    private static void SetUserContext(ControllerBase controller, string? userId)
    {
        var claims = new List<Claim>();
        if (!string.IsNullOrEmpty(userId))
        {
            claims.Add(new Claim(ClaimTypes.NameIdentifier, userId));
        }

        var identity = new ClaimsIdentity(claims, "TestAuth");
        var principal = new ClaimsPrincipal(identity);

        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = principal }
        };
    }

    [Fact]
    public void FavoritesController_PhaiCoThuocTinhAuthorize_VaTienToRouteChuan()
    {
        // Kiem tra thuoc tinh Authorize cap Controller
        var authAttr = typeof(FavoritesController)
            .GetCustomAttributes(typeof(AuthorizeAttribute), inherit: true)
            .FirstOrDefault();

        Assert.NotNull(authAttr);

        // Kiem tra route tien to
        var routeAttr = typeof(FavoritesController)
            .GetCustomAttributes(typeof(RouteAttribute), inherit: true)
            .Cast<RouteAttribute>()
            .FirstOrDefault();

        Assert.NotNull(routeAttr);
        Assert.True(routeAttr.Template == "api/[controller]" || routeAttr.Template == "api/favorites");
    }

    [Fact]
    public async Task GetMyFavorites_NguoiDungHopLe_TraVeOkVoiDanhSach()
    {
        // Act
        var actionResult = await _controller.GetMyFavorites();

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<List<FavoriteDto>>>(okResult.Value);
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
    }

    [Fact]
    public async Task GetMyFavorites_KhongCoClaimUserId_TraVeUnauthorized()
    {
        // Arrange
        SetUserContext(_controller, null);

        // Act
        var actionResult = await _controller.GetMyFavorites();

        // Assert
        var unauthResult = Assert.IsType<UnauthorizedObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<List<FavoriteDto>>>(unauthResult.Value);
        Assert.False(response.Success);
    }

    [Fact]
    public async Task CheckFavoriteStatus_PhimHopLe_TraVeOk()
    {
        // Act
        var actionResult = await _controller.CheckFavoriteStatus(10);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<FavoriteStatusDto>>(okResult.Value);
        Assert.True(response.Success);
        Assert.Equal(10, response.Data!.MovieId);
    }

    [Fact]
    public async Task AddFavorite_ThanhCong_TraVeOk()
    {
        // Act
        var actionResult = await _controller.AddFavorite(20);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<bool>>(okResult.Value);
        Assert.True(response.Success);
    }

    [Fact]
    public async Task AddFavorite_ThatBai_TraVeBadRequest()
    {
        // Act: MovieId = 999 duoc fake service tra ve that bai
        var actionResult = await _controller.AddFavorite(999);

        // Assert
        var badResult = Assert.IsType<BadRequestObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<bool>>(badResult.Value);
        Assert.False(response.Success);
    }

    [Fact]
    public async Task RemoveFavorite_ThanhCong_TraVeOk()
    {
        // Act
        var actionResult = await _controller.RemoveFavorite(20);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<bool>>(okResult.Value);
        Assert.True(response.Success);
    }

    [Fact]
    public async Task RemoveFavorite_ThatBai_TraVeBadRequest()
    {
        // Act: MovieId = 999 duoc fake service tra ve that bai
        var actionResult = await _controller.RemoveFavorite(999);

        // Assert
        var badResult = Assert.IsType<BadRequestObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<bool>>(badResult.Value);
        Assert.False(response.Success);
    }
}

// Stub service phuc vu kiem thu FavoritesController tach biet
internal class FakeFavoriteService : IFavoriteService
{
    public Task<ApiResponse<List<FavoriteDto>>> GetMyFavoritesAsync(int userId)
    {
        var list = new List<FavoriteDto>
        {
            new FavoriteDto { MovieId = 1, Title = "Test Movie" }
        };
        return Task.FromResult(ApiResponse<List<FavoriteDto>>.Ok(list));
    }

    public Task<ApiResponse<FavoriteStatusDto>> CheckFavoriteStatusAsync(int userId, int movieId)
    {
        return Task.FromResult(ApiResponse<FavoriteStatusDto>.Ok(new FavoriteStatusDto
        {
            MovieId = movieId,
            IsFavorite = true
        }));
    }

    public Task<ApiResponse<bool>> AddFavoriteAsync(int userId, int movieId)
    {
        if (movieId == 999) return Task.FromResult(ApiResponse<bool>.Fail("Phim không tồn tại!"));
        return Task.FromResult(ApiResponse<bool>.Ok(true, "Thêm thành công"));
    }

    public Task<ApiResponse<bool>> RemoveFavoriteAsync(int userId, int movieId)
    {
        if (movieId == 999) return Task.FromResult(ApiResponse<bool>.Fail("Phim không có trong danh sách!"));
        return Task.FromResult(ApiResponse<bool>.Ok(true, "Xóa thành công"));
    }
}
