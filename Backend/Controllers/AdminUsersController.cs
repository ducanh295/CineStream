using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CineStream.DTOs.Admin;
using CineStream.DTOs.Common;
using CineStream.Models.Enums;
using CineStream.Services.Interfaces;

namespace CineStream.Controllers;

// Controller quan tri nguoi dung danh rieng cho Quan tri vien he thong
[ApiController]
[Route("api/admin/users")]
[Authorize(Policy = "AdminOnly")]
public class AdminUsersController : ControllerBase
{
    private readonly IAdminUserService _adminUserService;

    public AdminUsersController(IAdminUserService adminUserService)
    {
        _adminUserService = adminUserService;
    }

    // GET /api/admin/users - Lay danh sach nguoi dung phan trang voi bo loc tim kiem, vai tro, trang thai khoa
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResult<AdminUserDto>>>> GetUsers(
        [FromQuery] string? search = null,
        [FromQuery] UserRole? role = null,
        [FromQuery] bool? isLocked = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var result = await _adminUserService.GetUsersAsync(search, role, isLocked, page, pageSize);
        return Ok(result);
    }

    // GET /api/admin/users/{id} - Lay chi tiet nguoi dung kem thong ke hoat dong tuong tac
    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<AdminUserDetailDto>>> GetUserDetail([FromRoute] int id)
    {
        var result = await _adminUserService.GetUserDetailAsync(id);
        if (!result.Success)
        {
            return NotFound(result);
        }
        return Ok(result);
    }

    // POST /api/admin/users/{id}/lock - Khoa tai khoan nguoi dung vi pham kem ly do
    [HttpPost("{id:int}/lock")]
    public async Task<ActionResult<ApiResponse<bool>>> LockUser(
        [FromRoute] int id,
        [FromBody] LockUserRequestDto request)
    {
        var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminIdClaim) || !int.TryParse(adminIdClaim, out int currentAdminId))
        {
            return Unauthorized(ApiResponse<bool>.Fail("Không xác định được danh tính quản trị viên!"));
        }

        var result = await _adminUserService.LockUserAsync(id, request, currentAdminId);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return Ok(result);
    }

    // POST /api/admin/users/{id}/unlock - Mo khoa tai khoan nguoi dung
    [HttpPost("{id:int}/unlock")]
    public async Task<ActionResult<ApiResponse<bool>>> UnlockUser([FromRoute] int id)
    {
        var result = await _adminUserService.UnlockUserAsync(id);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return Ok(result);
    }

    // DELETE /api/admin/users/{id} - Xoa mem tai khoan nguoi dung khoi he thong
    [HttpDelete("{id:int}")]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteUser([FromRoute] int id)
    {
        var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminIdClaim) || !int.TryParse(adminIdClaim, out int currentAdminId))
        {
            return Unauthorized(ApiResponse<bool>.Fail("Không xác định được danh tính quản trị viên!"));
        }

        var result = await _adminUserService.DeleteUserAsync(id, currentAdminId);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return Ok(result);
    }
}
