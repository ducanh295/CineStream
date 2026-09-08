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
        // Kiểm tra email đã có người dùng chưa
        //kiểm tra xem eamil có trùng ko
        bool emailExists = await _userRepo.EmailExistsAsync(request.Email);
        //nếu có thì từ chối đăng ký
        if (emailExists)
        {
            return ApiResponse<AuthResponseDto>.Fail("Email đã được sử dụng");
        }

        //Kiểm tra username đã có người dùng chưa
        //kiểm tra xem eamil có trùng ko
        bool usernameExists = await _userRepo.UsernameExistsAsync(request.Username);
        //nếu có thì từ chối đăng ký
        if (usernameExists)
        {
            return ApiResponse<AuthResponseDto>.Fail("Name đã được sử dụng");
        }

        //Băm mật khẩu bằng BCrypt
        string hashedPassword = BCrypt.Net.BCrypt.HashPassword(request.Password);

        //Khởi tạo đối tượng User mới

        var user = new User
        {
            Username = request.Username,
            Email = request.Email,
            PasswordHash = hashedPassword,
            Role = UserRole.User,
            Profile = new Profile { DisplayName = request.Username }
        };
        await _userRepo.AddAsync(user);


        // Sinh JWT Token và đóng gói dữ liệu trả về
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

        //Tìm user trong DB theo Email hoặc Username

        var user = await _userRepo.GetByEmailOrUsernameAsync(request.UsernameOrEmail);
        if (user == null)
        {
            return ApiResponse<AuthResponseDto>.Fail("tài khoản hoặc mật khẩu không chính xác !");
        }

        // So sánh mật khẩu người dùng nhập vào với PasswordHash trong DB
        bool isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        if (!isPasswordValid)
        {
            return ApiResponse<AuthResponseDto>.Fail("Tài khoản hoặc mật khẩu không chính xác");
        }

        // Tạo JWT Token và trả về thành công
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
        //Lấy thông tin user kèm profile qua ID
        var user = await _userRepo.GetWithProfileAsync(userId);
        if (user == null)
        {
            return ApiResponse<UserDto>.Fail("Không tìm thấy người dùng!");
        }

        return ApiResponse<UserDto>.Ok(MapToUserDto(user));
    }

    //  Hàm tiện ích dùng chung: Chuyển đổi từ Model User sang UserDto (không làm lộ PasswordHash)
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
