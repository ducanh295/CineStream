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
}
