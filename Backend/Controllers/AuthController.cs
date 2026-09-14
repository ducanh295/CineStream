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

    public AuthController(
        IAuthService authService)
    {
        _authService = authService;
    }

    // ============================================================
    // REGISTER
    // POST /api/auth/register
    // ============================================================

    [HttpPost("register")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Register(
        [FromBody] RegisterRequestDto request)
    {
        var result =
            await _authService.RegisterAsync(request);

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // ============================================================
    // LOGIN
    // POST /api/auth/login
    // ============================================================

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<AuthResponseDto>>> Login(
        [FromBody] LoginRequestDto request)
    {
        var result =
            await _authService.LoginAsync(request);

        if (!result.Success)
        {
            // Tài khoản chưa xác thực email
            // hoặc bị khóa bởi Admin.
            if (
                result.Message != null &&
                (
                    result.Message.Contains(
                        "chưa được kích hoạt"
                    ) ||
                    result.Message.Contains(
                        "khóa"
                    ) ||
                    result.Message.Contains(
                        "khoá"
                    )
                )
            )
            {
                return BadRequest(result);
            }

            return Unauthorized(result);
        }

        return Ok(result);
    }

    // ============================================================
    // VERIFY EMAIL
    // POST /api/auth/verify-email
    // ============================================================

    [HttpPost("verify-email")]
    public async Task<ActionResult<ApiResponse>> VerifyEmail(
        [FromBody] VerifyEmailRequestDto request)
    {
        var result =
            await _authService.VerifyEmailAsync(
                request
            );

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // ============================================================
    // RESEND VERIFICATION
    // POST /api/auth/resend-verification
    // ============================================================

    [HttpPost("resend-verification")]
    public async Task<ActionResult<ApiResponse>> ResendVerification(
        [FromBody] ResendVerificationEmailDto request)
    {
        var result =
            await _authService.ResendVerificationEmailAsync(
                request
            );

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // ============================================================
    // LOGOUT
    // POST /api/auth/logout
    // ============================================================

    [HttpPost("logout")]
    public async Task<ActionResult<ApiResponse>> Logout()
    {
        var result =
            await _authService.LogoutAsync();

        return Ok(result);
    }

    // ============================================================
    // FORGOT PASSWORD
    // POST /api/auth/forgot-password
    // ============================================================

    [HttpPost("forgot-password")]
    public async Task<ActionResult<ApiResponse>> ForgotPassword(
        [FromBody] ForgotPasswordRequestDto request)
    {
        var result =
            await _authService.ForgotPasswordAsync(
                request
            );

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // ============================================================
    // RESET PASSWORD
    // POST /api/auth/reset-password
    // ============================================================

    [HttpPost("reset-password")]
    public async Task<ActionResult<ApiResponse>> ResetPassword(
        [FromBody] ResetPasswordRequestDto request)
    {
        var result =
            await _authService.ResetPasswordAsync(
                request
            );

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // ============================================================
    // GET CURRENT USER
    // GET /api/auth/me
    // ============================================================

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<ApiResponse<UserDto>>> GetMe()
    {
        var userId =
            GetCurrentUserId();

        if (userId == null)
        {
            return Unauthorized(
                ApiResponse<UserDto>.Fail(
                    "Không xác định được danh tính người dùng!"
                )
            );
        }

        var result =
            await _authService.GetCurrentUserAsync(
                userId.Value
            );

        if (!result.Success)
        {
            return NotFound(result);
        }

        return Ok(result);
    }

    // ============================================================
    // UPDATE PROFILE
    // PUT /api/auth/profile
    // ============================================================

    [Authorize]
    [HttpPut("profile")]
    public async Task<ActionResult<ApiResponse<UserDto>>> UpdateProfile(
        [FromBody] UpdateProfileDto request)
    {
        var userId =
            GetCurrentUserId();

        if (userId == null)
        {
            return Unauthorized(
                ApiResponse<UserDto>.Fail(
                    "Không xác định được danh tính người dùng!"
                )
            );
        }

        var result =
            await _authService.UpdateProfileAsync(
                userId.Value,
                request
            );

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // ============================================================
    // CHANGE PASSWORD
    // POST /api/auth/change-password
    // ============================================================

    [Authorize]
    [HttpPost("change-password")]
    public async Task<ActionResult<ApiResponse>> ChangePassword(
        [FromBody] ChangePasswordRequestDto request)
    {
        var userId =
            GetCurrentUserId();

        if (userId == null)
        {
            return Unauthorized(
                ApiResponse.Fail(
                    "Không xác định được danh tính người dùng!"
                )
            );
        }

        var result =
            await _authService.ChangePasswordAsync(
                userId.Value,
                request
            );

        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // ============================================================
    // ADMIN CHECK
    // GET /api/auth/admin-check
    // ============================================================

    [Authorize(Policy = "AdminOnly")]
    [HttpGet("admin-check")]
    public ActionResult<ApiResponse<string>> AdminCheck()
    {
        return Ok(
            ApiResponse<string>.Ok(
                "Xác thực quyền Quản trị viên thành công!"
            )
        );
    }

    // ============================================================
    // GET CURRENT USER ID FROM JWT
    // ============================================================

    private int? GetCurrentUserId()
    {
        var userIdClaim =
            User.FindFirst(
                ClaimTypes.NameIdentifier
            )?.Value;

        if (
            string.IsNullOrWhiteSpace(
                userIdClaim
            )
        )
        {
            return null;
        }

        if (
            !int.TryParse(
                userIdClaim,
                out int userId
            )
        )
        {
            return null;
        }

        return userId;
    }
}

