using CineStream.Models.Enums;

namespace CineStream.DTOs.Auth;

//  DTO nhận dữ liệu đăng ký tài khoản
public class RegisterRequestDto
{
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

//  DTO nhận dữ liệu đăng nhập
public class LoginRequestDto
{
    //  Cho phép người dùng đăng nhập linh hoạt bằng Email hoặc Username
    public string UsernameOrEmail { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

//  DTO thông tin hồ sơ người dùng (Profile)
public class ProfileDto
{
    public string? DisplayName { get; set; }
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
}

public class UpdateProfileDto
{
    public string? DisplayName { get; set; }
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
}

//  DTO tóm tắt thông tin User trả về client (TUYỆT ĐỐI KHÔNG chứa PasswordHash)
public class UserDto
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public UserRole Role { get; set; }
    public ProfileDto? Profile { get; set; }
}

//  DTO trả về sau khi đăng nhập / đăng ký thành công
public class AuthResponseDto
{
    //  JWT Token để client gắn vào header Authorization: Bearer <token>
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public UserDto User { get; set; } = null!;
}
