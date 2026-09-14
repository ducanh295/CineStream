using System.ComponentModel.DataAnnotations;
using CineStream.Models.Enums;

namespace CineStream.DTOs.Auth;

// ================================================================
// REGISTER
// ================================================================

public class RegisterRequestDto
{
    [Required(ErrorMessage = "Tên đăng nhập không được để trống!")]
    [StringLength(
        50,
        MinimumLength = 3,
        ErrorMessage = "Tên đăng nhập phải từ 3 đến 50 ký tự!"
    )]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email không được để trống!")]
    [EmailAddress(ErrorMessage = "Định dạng email không hợp lệ!")]
    [StringLength(
        100,
        ErrorMessage = "Email không được vượt quá 100 ký tự!"
    )]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mật khẩu không được để trống!")]
    [StringLength(
        100,
        MinimumLength = 6,
        ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự!"
    )]
    public string Password { get; set; } = string.Empty;
}

// ================================================================
// LOGIN
// ================================================================

public class LoginRequestDto
{
    [Required(
        ErrorMessage =
            "Tên đăng nhập hoặc email không được để trống!"
    )]
    [StringLength(
        100,
        ErrorMessage =
            "Tên đăng nhập hoặc email không được vượt quá 100 ký tự!"
    )]
    public string UsernameOrEmail { get; set; } = string.Empty;

    [Required(
        ErrorMessage =
            "Mật khẩu không được để trống!"
    )]
    public string Password { get; set; } = string.Empty;
}

// ================================================================
// PROFILE
// ================================================================

public class ProfileDto
{
    public string? DisplayName { get; set; }

    public string? AvatarUrl { get; set; }

    public string? Bio { get; set; }
}

public class UpdateProfileDto
{
    [StringLength(
        100,
        ErrorMessage =
            "Display Name không được vượt quá 100 ký tự!"
    )]
    public string? DisplayName { get; set; }

    [StringLength(
        500,
        ErrorMessage =
            "Avatar URL không được vượt quá 500 ký tự!"
    )]
    public string? AvatarUrl { get; set; }

    [StringLength(
        500,
        ErrorMessage =
            "Bio không được vượt quá 500 ký tự!"
    )]
    public string? Bio { get; set; }
}

// ================================================================
// CHANGE PASSWORD
// ================================================================

public class ChangePasswordRequestDto
{
    [Required(
        ErrorMessage =
            "Mật khẩu hiện tại không được để trống!"
    )]
    public string CurrentPassword { get; set; }
        = string.Empty;

    [Required(
        ErrorMessage =
            "Mật khẩu mới không được để trống!"
    )]
    [StringLength(
        100,
        MinimumLength = 6,
        ErrorMessage =
            "Mật khẩu mới phải có ít nhất 6 ký tự!"
    )]
    public string NewPassword { get; set; }
        = string.Empty;

    [Required(
        ErrorMessage =
            "Xác nhận mật khẩu không được để trống!"
    )]
    [Compare(
        nameof(NewPassword),
        ErrorMessage =
            "Xác nhận mật khẩu không khớp!"
    )]
    public string ConfirmPassword { get; set; }
        = string.Empty;
}

// ================================================================
// USER RESPONSE
// ================================================================

public class UserDto
{
    public int Id { get; set; }

    public string Username { get; set; }
        = string.Empty;

    public string Email { get; set; }
        = string.Empty;

    public UserRole Role { get; set; }

    public ProfileDto? Profile { get; set; }

    // Premium
    public bool IsPremium { get; set; }

    public DateTime? PremiumExpiresAt { get; set; }
}

// ================================================================
// AUTH RESPONSE
// ================================================================

public class AuthResponseDto
{
    public string Token { get; set; }
        = string.Empty;

    public DateTime ExpiresAt { get; set; }

    public UserDto User { get; set; }
        = null!;
}

// ================================================================
// VERIFY EMAIL
// ================================================================

public class VerifyEmailRequestDto
{
    [Required(
        ErrorMessage =
            "Email không được để trống!"
    )]
    [EmailAddress(
        ErrorMessage =
            "Định dạng email không hợp lệ!"
    )]
    [StringLength(
        100,
        ErrorMessage =
            "Email không được vượt quá 100 ký tự!"
    )]
    public string Email { get; set; }
        = string.Empty;

    [Required(
        ErrorMessage =
            "Mã xác thực không được để trống!"
    )]
    [StringLength(
        10,
        MinimumLength = 4,
        ErrorMessage =
            "Mã xác thực phải từ 4 đến 10 ký tự!"
    )]
    public string Code { get; set; }
        = string.Empty;
}

// ================================================================
// RESEND VERIFICATION
// ================================================================

public class ResendVerificationEmailDto
{
    [Required(
        ErrorMessage =
            "Email không được để trống!"
    )]
    [EmailAddress(
        ErrorMessage =
            "Định dạng email không hợp lệ!"
    )]
    [StringLength(
        100,
        ErrorMessage =
            "Email không được vượt quá 100 ký tự!"
    )]
    public string Email { get; set; }
        = string.Empty;
}

// ================================================================
// FORGOT PASSWORD
// ================================================================

public class ForgotPasswordRequestDto
{
    [Required(
        ErrorMessage =
            "Email không được để trống!"
    )]
    [EmailAddress(
        ErrorMessage =
            "Định dạng email không hợp lệ!"
    )]
    [StringLength(
        100,
        ErrorMessage =
            "Email không được vượt quá 100 ký tự!"
    )]
    public string Email { get; set; }
        = string.Empty;
}

// ================================================================
// RESET PASSWORD
// ================================================================

public class ResetPasswordRequestDto
{
    [Required(
        ErrorMessage =
            "Email không được để trống!"
    )]
    [EmailAddress(
        ErrorMessage =
            "Định dạng email không hợp lệ!"
    )]
    [StringLength(
        100,
        ErrorMessage =
            "Email không được vượt quá 100 ký tự!"
    )]
    public string Email { get; set; }
        = string.Empty;

    [Required(
        ErrorMessage =
            "Mã xác thực không được để trống!"
    )]
    [StringLength(
        10,
        MinimumLength = 4,
        ErrorMessage =
            "Mã xác thực phải từ 4 đến 10 ký tự!"
    )]
    public string Code { get; set; }
        = string.Empty;

    [Required(
        ErrorMessage =
            "Mật khẩu mới không được để trống!"
    )]
    [StringLength(
        100,
        MinimumLength = 6,
        ErrorMessage =
            "Mật khẩu mới phải có ít nhất 6 ký tự!"
    )]
    public string NewPassword { get; set; }
        = string.Empty;
}

