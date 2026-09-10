using CineStream.DTOs.Auth;
using CineStream.DTOs.Common;

namespace CineStream.Services.Interfaces;

public interface IAuthService
{
    // Đăng ký tài khoản mới
    Task<ApiResponse<AuthResponseDto>> RegisterAsync(RegisterRequestDto request);

    // Đăng nhập tài khoản
    Task<ApiResponse<AuthResponseDto>> LoginAsync(LoginRequestDto request);

    // Lấy thông tin user hiện tại qua ID (sau khi đã giải mã JWT)
    Task<ApiResponse<UserDto>> GetCurrentUserAsync(int userId);

    // Xác thực email người dùng thông qua mã OTP
    Task<ApiResponse> VerifyEmailAsync(VerifyEmailRequestDto request);

    // Gửi lại mã OTP xác minh email cho tài khoản chưa kích hoạt
    Task<ApiResponse> ResendVerificationEmailAsync(ResendVerificationEmailDto request);

    // Đăng xuất và kết thúc phiên làm việc
    Task<ApiResponse> LogoutAsync();

    // Yêu cầu cấp mã OTP khôi phục mật khẩu khi quên
    Task<ApiResponse> ForgotPasswordAsync(ForgotPasswordRequestDto request);

    // Xác thực mã OTP và đặt lại mật khẩu mới
    Task<ApiResponse> ResetPasswordAsync(ResetPasswordRequestDto request);
}
