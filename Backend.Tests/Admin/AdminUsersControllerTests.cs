using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using CineStream.Controllers;
using CineStream.DTOs.Admin;
using CineStream.DTOs.Common;
using CineStream.Models.Enums;
using CineStream.Services.Interfaces;
using Xunit;

namespace Backend.Tests.Admin;

// Bo kiem thu don vi cho AdminUsersController
public class AdminUsersControllerTests
{
    private readonly FakeAdminUserService _fakeService;
    private readonly AdminUsersController _controller;

    public AdminUsersControllerTests()
    {
        _fakeService = new FakeAdminUserService();
        _controller = new AdminUsersController(_fakeService);
        SetUserContext(_controller, "1", "Admin");
    }

    private static void SetUserContext(ControllerBase controller, string? userId, string? role)
    {
        var claims = new List<Claim>();
        if (!string.IsNullOrEmpty(userId)) claims.Add(new Claim(ClaimTypes.NameIdentifier, userId));
        if (!string.IsNullOrEmpty(role)) claims.Add(new Claim(ClaimTypes.Role, role));

        var identity = new ClaimsIdentity(claims, "TestAuth");
        var principal = new ClaimsPrincipal(identity);

        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = principal }
        };
    }

    [Fact]
    public void AdminUsersController_PhaiCoPolicyAdminOnly_VaTienToRouteChuan()
    {
        // Kiem tra thuoc tinh Authorize cap Controller
        var authAttr = typeof(AdminUsersController)
            .GetCustomAttributes(typeof(AuthorizeAttribute), inherit: true)
            .Cast<AuthorizeAttribute>()
            .FirstOrDefault();

        Assert.NotNull(authAttr);
        Assert.Equal("AdminOnly", authAttr.Policy);

        // Kiem tra route tien to
        var routeAttr = typeof(AdminUsersController)
            .GetCustomAttributes(typeof(RouteAttribute), inherit: true)
            .Cast<RouteAttribute>()
            .FirstOrDefault();

        Assert.NotNull(routeAttr);
        Assert.Equal("api/admin/users", routeAttr.Template);
    }

    [Fact]
    public async Task GetUsers_GoiService_TraVeOkVoiDanhSachPhanTrang()
    {
        // Act
        var result = await _controller.GetUsers(search: "cinestream", role: UserRole.User, isLocked: false, page: 1, pageSize: 10);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<PagedResult<AdminUserDto>>>(okResult.Value);
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
    }

    [Fact]
    public async Task GetUserDetail_NguoiDungTonTai_TraVeOk()
    {
        // Act
        var result = await _controller.GetUserDetail(10);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<AdminUserDetailDto>>(okResult.Value);
        Assert.True(response.Success);
        Assert.Equal(10, response.Data!.Id);
    }

    [Fact]
    public async Task GetUserDetail_KhongTonTai_TraVeNotFound()
    {
        // Act
        var result = await _controller.GetUserDetail(999);

        // Assert
        var notFoundResult = Assert.IsType<NotFoundObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<AdminUserDetailDto>>(notFoundResult.Value);
        Assert.False(response.Success);
    }

    [Fact]
    public async Task LockUser_ThanhCong_TraVeOk()
    {
        // Arrange
        var request = new LockUserRequestDto { Reason = "Vi pham quy che he thong" };

        // Act
        var result = await _controller.LockUser(5, request);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<bool>>(okResult.Value);
        Assert.True(response.Success);
    }

    [Fact]
    public async Task LockUser_TuKhoaChinhMinh_TraVeBadRequest()
    {
        // Arrange
        var request = new LockUserRequestDto { Reason = "Tu khoa" };

        // Act: targetUserId = 1 trung voi currentAdminId = 1
        var result = await _controller.LockUser(1, request);

        // Assert
        var badResult = Assert.IsType<BadRequestObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<bool>>(badResult.Value);
        Assert.False(response.Success);
    }

    [Fact]
    public async Task UnlockUser_ThanhCong_TraVeOk()
    {
        // Act
        var result = await _controller.UnlockUser(5);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<bool>>(okResult.Value);
        Assert.True(response.Success);
    }

    [Fact]
    public async Task DeleteUser_ThanhCong_TraVeOk()
    {
        // Act: Xoa user Id = 2
        var result = await _controller.DeleteUser(2);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<bool>>(okResult.Value);
        Assert.True(response.Success);
    }

    [Fact]
    public async Task DeleteUser_TuXoaChinhMinh_TraVeBadRequest()
    {
        // Act: targetUserId = 1 trung voi currentAdminId = 1
        var result = await _controller.DeleteUser(1);

        // Assert
        var badResult = Assert.IsType<BadRequestObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<bool>>(badResult.Value);
        Assert.False(response.Success);
    }

    [Fact]
    public async Task LockUser_KhongCoClaimAdminId_TraVeUnauthorized()
    {
        // Arrange: Controller khong co claim
        SetUserContext(_controller, null, null);
        var request = new LockUserRequestDto { Reason = "Test unauthorized" };

        // Act
        var result = await _controller.LockUser(5, request);

        // Assert
        var unauthResult = Assert.IsType<UnauthorizedObjectResult>(result.Result);
        var response = Assert.IsType<ApiResponse<bool>>(unauthResult.Value);
        Assert.False(response.Success);
    }
}

// Fake service ho tro kiem thu Controller tach biet voi Database
internal class FakeAdminUserService : IAdminUserService
{
    public Task<ApiResponse<PagedResult<AdminUserDto>>> GetUsersAsync(string? search, UserRole? role, bool? isLocked, int page = 1, int pageSize = 10)
    {
        var result = new PagedResult<AdminUserDto>
        {
            Items = new List<AdminUserDto>(),
            TotalCount = 0,
            PageNumber = page,
            PageSize = pageSize
        };
        return Task.FromResult(ApiResponse<PagedResult<AdminUserDto>>.Ok(result));
    }

    public Task<ApiResponse<AdminUserDetailDto>> GetUserDetailAsync(int id)
    {
        if (id == 999) return Task.FromResult(ApiResponse<AdminUserDetailDto>.Fail("Không tìm thấy"));
        return Task.FromResult(ApiResponse<AdminUserDetailDto>.Ok(new AdminUserDetailDto { Id = id, Username = "test" }));
    }

    public Task<ApiResponse<bool>> LockUserAsync(int targetUserId, LockUserRequestDto request, int currentAdminId)
    {
        if (targetUserId == currentAdminId) return Task.FromResult(ApiResponse<bool>.Fail("Quản trị viên không thể tự khóa chính mình!"));
        return Task.FromResult(ApiResponse<bool>.Ok(true, "Khóa thành công"));
    }

    public Task<ApiResponse<bool>> UnlockUserAsync(int targetUserId)
    {
        return Task.FromResult(ApiResponse<bool>.Ok(true, "Mở khóa thành công"));
    }

    public Task<ApiResponse<bool>> DeleteUserAsync(int targetUserId, int currentAdminId)
    {
        if (targetUserId == currentAdminId) return Task.FromResult(ApiResponse<bool>.Fail("Quản trị viên không thể tự xóa chính mình!"));
        return Task.FromResult(ApiResponse<bool>.Ok(true, "Xóa thành công"));
    }
}
