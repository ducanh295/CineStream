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

    // POST /api/auth/register: Tiếp nhận thông tin đăng ký tài khoản mới và gửi mã OTP kích hoạt
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

    // POST /api/auth/login: Đăng nhập hệ thống bằng Tên đăng nhập hoặc Email kèm kiểm tra kích hoạt
    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Login([FromBody] LoginRequestDto request)
    {
        var result = await _authService.LoginAsync(request);
        if (!result.Success)
        {
            // Trả về BadRequest HTTP 400 nếu tài khoản chưa kích hoạt email hoặc bị khóa bởi Quản trị viên
            if (result.Message != null && (result.Message.Contains("chưa được kích hoạt") || result.Message.Contains("khóa") || result.Message.Contains("khoá")))
            {
                return BadRequest(result);
            }
            return Unauthorized(result);
        }
        return Ok(result);
    }

    // POST /api/auth/verify-email: Xác thực kích hoạt tài khoản người dùng qua mã số OTP
    [HttpPost("verify-email")]
    public async Task<ActionResult<ApiResponse>> VerifyEmail([FromBody] VerifyEmailRequestDto request)
    {
        var result = await _authService.VerifyEmailAsync(request);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return Ok(result);
    }

    // POST /api/auth/resend-verification: Cấp lại mã OTP kích hoạt mới cho tài khoản chưa xác minh
    [HttpPost("resend-verification")]
    public async Task<ActionResult<ApiResponse>> ResendVerification([FromBody] ResendVerificationEmailDto request)
    {
        var result = await _authService.ResendVerificationEmailAsync(request);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return Ok(result);
    }

    // POST /api/auth/logout: Đăng xuất người dùng và kết thúc phiên làm việc
    [HttpPost("logout")]
    public async Task<ActionResult<ApiResponse>> Logout()
    {
        var result = await _authService.LogoutAsync();
        return Ok(result);
    }

    // POST /api/auth/forgot-password: Yêu cầu cấp mã OTP 6 số khôi phục mật khẩu qua email
    [HttpPost("forgot-password")]
    public async Task<ActionResult<ApiResponse>> ForgotPassword([FromBody] ForgotPasswordRequestDto request)
    {
        var result = await _authService.ForgotPasswordAsync(request);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return Ok(result);
    }

    // POST /api/auth/reset-password: Xác thực mã OTP và tiến hành cập nhật mật khẩu mới
    [HttpPost("reset-password")]
    public async Task<ActionResult<ApiResponse>> ResetPassword([FromBody] ResetPasswordRequestDto request)
    {
        var result = await _authService.ResetPasswordAsync(request);
        if (!result.Success)
        {
            return BadRequest(result);
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

    // Yêu cầu quyền Quản trị viên theo Authorization Policy AdminOnly
    [Authorize(Policy = "AdminOnly")]
    [HttpGet("admin-check")]
    public ActionResult<ApiResponse<string>> AdminCheck()
    {
        return Ok(ApiResponse<string>.Ok("Xác thực quyền Quản trị viên thành công!"));
    }
}
