using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CineStream.DTOs.Auth;
using CineStream.DTOs.Common;
using CineStream.Services.Interfaces;

namespace CineStream.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    ///api/auth/register
    [HttpPost("register")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Register([FromBody] RegisterRequestDto request)
    {
        var result = await _authService.RegisterAsync(request);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return Ok(result);
    }

    // /api/auth/login
    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Login([FromBody] LoginRequestDto request)
    {
        var result = await _authService.LoginAsync(request);
        if (!result.Success)
        {
            return Unauthorized(result);
        }
        return Ok(result);
    }

    // Yêu cầu phải có Header Authorization: Bearer <token>
    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<ApiResponse<UserDto>>> GetMe()
    {
        // Trích xuất UserId từ thông tin Claims được gắn trong JWT Token
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
        {
            return Unauthorized(ApiResponse<UserDto>.Fail("Không xác định được danh tính người dùng!"));
        }

        var result = await _authService.GetCurrentUserAsync(userId);
        if (!result.Success)
        {
            return NotFound(result);
        }
        return Ok(result);
    }
}
