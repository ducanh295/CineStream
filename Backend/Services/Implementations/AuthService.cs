using BCrypt.Net;
using CineStream.DTOs.Auth;
using CineStream.DTOs.Common;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepo;
    private readonly IJwtService _jwtService;

    public AuthService(IUserRepository userRepo, IJwtService jwtService)
    {
        _userRepo = userRepo;
        _jwtService = jwtService;
    }

    public async Task<ApiResponse<AuthResponseDto>> RegisterAsync(RegisterRequestDto request)
    {
        // Kiểm tra tính duy nhất của Email trong hệ thống
        bool emailExists = await _userRepo.EmailExistsAsync(request.Email);
        if (emailExists)
        {
            return ApiResponse<AuthResponseDto>.Fail("Email đã được sử dụng");
        }

        // Kiểm tra tính duy nhất của Username để tránh xung đột dữ liệu
        bool usernameExists = await _userRepo.UsernameExistsAsync(request.Username);
        if (usernameExists)
        {
            return ApiResponse<AuthResponseDto>.Fail("Tên đăng nhập đã được sử dụng");
        }

        // Mã hóa mật khẩu một chiều sử dụng thuật toán BCrypt
        string hashedPassword = BCrypt.Net.BCrypt.HashPassword(request.Password);

        // Khởi tạo thực thể User kèm Profile mặc định và lưu vào cơ sở dữ liệu
        var user = new User
        {
            Username = request.Username,
            Email = request.Email,
            PasswordHash = hashedPassword,
            Role = UserRole.User,
            Profile = new Profile { DisplayName = request.Username }
        };
        await _userRepo.AddAsync(user);
        await _userRepo.SaveChangesAsync();

        // Tạo JWT Token xác thực và đóng gói dữ liệu phản hồi
        string token = _jwtService.GenerateToken(user);
        var response = new AuthResponseDto
        {
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            User = MapToUserDto(user)
        };

        return ApiResponse<AuthResponseDto>.Ok(response, "Đăng ký tài khoản thành công!");
    }

    public async Task<ApiResponse<AuthResponseDto>> LoginAsync(LoginRequestDto request)
    {
        // Tìm kiếm tài khoản người dùng theo Email hoặc Username
        var user = await _userRepo.GetByEmailOrUsernameAsync(request.UsernameOrEmail);
        if (user == null)
        {
            return ApiResponse<AuthResponseDto>.Fail("Tài khoản hoặc mật khẩu không chính xác!");
        }

        // Xác thực mật khẩu người dùng nhập vào với chuỗi băm lưu trong cơ sở dữ liệu
        bool isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        if (!isPasswordValid)
        {
            return ApiResponse<AuthResponseDto>.Fail("Tài khoản hoặc mật khẩu không chính xác!");
        }

        // Khởi tạo JWT Token có thời hạn và đóng gói thông tin đăng nhập thành công
        string token = _jwtService.GenerateToken(user);
        var response = new AuthResponseDto
        {
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            User = MapToUserDto(user)
        };

        return ApiResponse<AuthResponseDto>.Ok(response, "Đăng nhập thành công!");
    }

    public async Task<ApiResponse<UserDto>> GetCurrentUserAsync(int userId)
    {
        // Truy vấn thông tin người dùng kèm hồ sơ cá nhân theo định danh
        var user = await _userRepo.GetWithProfileAsync(userId);
        if (user == null)
        {
            return ApiResponse<UserDto>.Fail("Không tìm thấy người dùng!");
        }

        return ApiResponse<UserDto>.Ok(MapToUserDto(user));
    }

    // Ánh xạ thực thể User sang UserDto nhằm bảo mật, loại trừ trường thông tin nhạy cảm PasswordHash
    private static UserDto MapToUserDto(User user)
    {
        return new UserDto
        {
            Id = user.Id,
            Username = user.Username,
            Email = user.Email,
            Role = user.Role,
            Profile = user.Profile != null ? new ProfileDto
            {
                DisplayName = user.Profile.DisplayName,
                AvatarUrl = user.Profile.AvatarUrl,
                Bio = user.Profile.Bio
            } : null
        };
    }
}
