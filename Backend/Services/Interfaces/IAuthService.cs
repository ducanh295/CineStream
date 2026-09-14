using CineStream.DTOs.Auth;
using CineStream.DTOs.Common;

namespace CineStream.Services.Interfaces;

public interface IAuthService
{
    // ============================================================
    // ĐĂNG KÝ / ĐĂNG NHẬP
    // ============================================================

    // Đăng ký tài khoản mới
    Task<ApiResponse<AuthResponseDto>> RegisterAsync(
        RegisterRequestDto request
    );

    // Đăng nhập tài khoản
    Task<ApiResponse<AuthResponseDto>> LoginAsync(
        LoginRequestDto request
    );

    // ============================================================
    // THÔNG TIN TÀI KHOẢN
    // ============================================================

    // Lấy thông tin user hiện tại qua ID từ JWT
    Task<ApiResponse<UserDto>> GetCurrentUserAsync(
        int userId
    );

    // Cập nhật thông tin Profile
    Task<ApiResponse<UserDto>> UpdateProfileAsync(
        int userId,
        UpdateProfileDto request
    );

    // Đổi mật khẩu khi người dùng đã đăng nhập
    Task<ApiResponse> ChangePasswordAsync(
        int userId,
        ChangePasswordRequestDto request
    );

    // ============================================================
    // XÁC THỰC EMAIL
    // ============================================================

    // Xác thực email bằng mã OTP
    Task<ApiResponse> VerifyEmailAsync(
        VerifyEmailRequestDto request
    );

    // Gửi lại mã OTP xác minh email
    Task<ApiResponse> ResendVerificationEmailAsync(
        ResendVerificationEmailDto request
    );

    // ============================================================
    // ĐĂNG XUẤT
    // ============================================================

    // Đăng xuất tài khoản
    Task<ApiResponse> LogoutAsync();

    // ============================================================
    // KHÔI PHỤC MẬT KHẨU
    // ============================================================

    // Yêu cầu mã OTP khôi phục mật khẩu
    Task<ApiResponse> ForgotPasswordAsync(
        ForgotPasswordRequestDto request
    );

    // Xác thực OTP và đặt lại mật khẩu mới
    Task<ApiResponse> ResetPasswordAsync(
        ResetPasswordRequestDto request
    );
}

