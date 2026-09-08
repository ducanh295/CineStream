using System.ComponentModel.DataAnnotations;
using CineStream.Models.Enums;

namespace CineStream.DTOs.Auth;

// DTO nhận dữ liệu đăng ký tài khoản
public class RegisterRequestDto
{
    [Required(ErrorMessage = "Ten dang nhap khong duoc de trong!")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Ten dang nhap phai tu 3 den 50 ky tu!")]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email khong duoc de trong!")]
    [EmailAddress(ErrorMessage = "Dinh dang email khong hop le!")]
    [StringLength(100, ErrorMessage = "Email khong duoc vuot qua 100 ky tu!")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mat khau khong duoc de trong!")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Mat khau phai co it nhat 6 ky tu!")]
    public string Password { get; set; } = string.Empty;
}

// DTO nhận dữ liệu đăng nhập
public class LoginRequestDto
{
    // Cho phép người dùng đăng nhập linh hoạt bằng Email hoặc Username
    [Required(ErrorMessage = "Ten dang nhap hoac email khong duoc de trong!")]
    [StringLength(100, ErrorMessage = "Ten dang nhap hoac email khong duoc vuot qua 100 ky tu!")]
    public string UsernameOrEmail { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mat khau khong duoc de trong!")]
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
