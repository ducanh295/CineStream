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
    private readonly IEmailService _emailService;

    public AuthService(
        IUserRepository userRepo,
        IJwtService jwtService,
        IEmailService emailService)
    {
        _userRepo = userRepo;
        _jwtService = jwtService;
        _emailService = emailService;
    }

    // ============================================================
    // REGISTER
    // ============================================================

    public async Task<ApiResponse<AuthResponseDto>> RegisterAsync(
        RegisterRequestDto request)
    {
        var email = request.Email.Trim();
        var username = request.Username.Trim();

        // Kiểm tra Email đã tồn tại
        bool emailExists =
            await _userRepo.EmailExistsAsync(email);

        if (emailExists)
        {
            return ApiResponse<AuthResponseDto>.Fail(
                "Email đã được sử dụng"
            );
        }

        // Kiểm tra Username đã tồn tại
        bool usernameExists =
            await _userRepo.UsernameExistsAsync(username);

        if (usernameExists)
        {
            return ApiResponse<AuthResponseDto>.Fail(
                "Tên đăng nhập đã được sử dụng"
            );
        }

        // Mã hóa mật khẩu bằng BCrypt
        string hashedPassword =
            BCrypt.Net.BCrypt.HashPassword(
                request.Password
            );

        // Tạo OTP xác thực email
        string otpCode =
            Random.Shared.Next(
                100000,
                999999
            ).ToString();

        // Tạo User
        var user = new User
        {
            Username = username,
            Email = email,
            PasswordHash = hashedPassword,
            Role = UserRole.User,

            IsEmailConfirmed = false,

            EmailConfirmationToken =
                otpCode,

            EmailConfirmationTokenExpiresAt =
                DateTime.UtcNow.AddHours(24),

            Profile = new Profile
            {
                DisplayName = username
            },

            // Premium mặc định
            IsPremium = false,
            PremiumExpiresAt = null
        };

        await _userRepo.AddAsync(user);
        await _userRepo.SaveChangesAsync();

        // Gửi OTP xác thực email
        await _emailService.SendEmailConfirmationAsync(
            user.Email,
            otpCode
        );

        var response =
            new AuthResponseDto
            {
                Token = string.Empty,
                ExpiresAt = DateTime.MinValue,
                User = MapToUserDto(user)
            };

        return ApiResponse<AuthResponseDto>.Ok(
            response,
            "Đăng ký tài khoản thành công! Vui lòng kiểm tra email để kích hoạt tài khoản."
        );
    }

    // ============================================================
    // LOGIN
    // ============================================================

    public async Task<ApiResponse<AuthResponseDto>> LoginAsync(
        LoginRequestDto request)
    {
        var identifier =
            request.UsernameOrEmail.Trim();

        // Tìm theo Username hoặc Email
        var user =
            await _userRepo.GetByEmailOrUsernameAsync(
                identifier
            );

        if (user == null)
        {
            return ApiResponse<AuthResponseDto>.Fail(
                "Tài khoản hoặc mật khẩu không chính xác!"
            );
        }

        // Kiểm tra mật khẩu
        bool isPasswordValid =
            BCrypt.Net.BCrypt.Verify(
                request.Password,
                user.PasswordHash
            );

        if (!isPasswordValid)
        {
            return ApiResponse<AuthResponseDto>.Fail(
                "Tài khoản hoặc mật khẩu không chính xác!"
            );
        }

        // Kiểm tra tài khoản bị khóa
        if (user.IsLocked)
        {
            var reasonSuffix =
                !string.IsNullOrWhiteSpace(
                    user.LockReason
                )
                    ? $" Lý do: {user.LockReason}"
                    : string.Empty;

            return ApiResponse<AuthResponseDto>.Fail(
                $"Tài khoản của bạn đã bị khóa bởi Quản trị viên.{reasonSuffix}"
            );
        }

        // Kiểm tra Email đã xác thực
        if (!user.IsEmailConfirmed)
        {
            return ApiResponse<AuthResponseDto>.Fail(
                "Tài khoản chưa được kích hoạt email! Vui lòng kiểm tra hộp thư để xác thực tài khoản."
            );
        }

        // Tạo JWT
        string token =
            _jwtService.GenerateToken(user);

        var response =
            new AuthResponseDto
            {
                Token = token,
                ExpiresAt =
                    DateTime.UtcNow.AddHours(1),
                User = MapToUserDto(user)
            };

        return ApiResponse<AuthResponseDto>.Ok(
            response,
            "Đăng nhập thành công!"
        );
    }

    // ============================================================
    // GET CURRENT USER
    // ============================================================

    public async Task<ApiResponse<UserDto>> GetCurrentUserAsync(
        int userId)
    {
        // Lấy User kèm Profile
        var user =
            await _userRepo.GetWithProfileAsync(
                userId
            );

        if (user == null)
        {
            return ApiResponse<UserDto>.Fail(
                "Không tìm thấy người dùng!"
            );
        }

        return ApiResponse<UserDto>.Ok(
            MapToUserDto(user)
        );
    }

    // ============================================================
    // UPDATE PROFILE
    // ============================================================

    public async Task<ApiResponse<UserDto>> UpdateProfileAsync(
        int userId,
        UpdateProfileDto request)
    {
        // Lấy User kèm Profile
        var user =
            await _userRepo.GetWithProfileAsync(
                userId
            );

        if (user == null)
        {
            return ApiResponse<UserDto>.Fail(
                "Không tìm thấy người dùng!"
            );
        }

        // Nếu User chưa có Profile thì tạo mới
        if (user.Profile == null)
        {
            user.Profile = new Profile();
        }

        // ========================================================
        // DISPLAY NAME
        // ========================================================

        if (request.DisplayName != null)
        {
            user.Profile.DisplayName =
                request.DisplayName.Trim();
        }

        // ========================================================
        // AVATAR URL
        // ========================================================

        if (request.AvatarUrl != null)
        {
            user.Profile.AvatarUrl =
                request.AvatarUrl.Trim();
        }

        // ========================================================
        // BIO
        // ========================================================

        if (request.Bio != null)
        {
            user.Profile.Bio =
                request.Bio.Trim();
        }

        // Đánh dấu User đã thay đổi
        _userRepo.Update(user);

        await _userRepo.SaveChangesAsync();

        // ========================================================
        // REFRESH DỮ LIỆU SAU KHI UPDATE
        // ========================================================

        var updatedUser =
            await _userRepo.GetWithProfileAsync(
                userId
            );

        if (updatedUser == null)
        {
            return ApiResponse<UserDto>.Fail(
                "Cập nhật thành công nhưng không thể tải lại thông tin người dùng!"
            );
        }

        return ApiResponse<UserDto>.Ok(
            MapToUserDto(updatedUser),
            "Cập nhật hồ sơ thành công!"
        );
    }

    // ============================================================
    // CHANGE PASSWORD
    // ============================================================

    public async Task<ApiResponse> ChangePasswordAsync(
        int userId,
        ChangePasswordRequestDto request)
    {
        // Lấy User hiện tại
        var user =
            await _userRepo.GetWithProfileAsync(
                userId
            );

        if (user == null)
        {
            return ApiResponse.Fail(
                "Không tìm thấy người dùng!"
            );
        }

        // ========================================================
        // KIỂM TRA MẬT KHẨU HIỆN TẠI
        // ========================================================

        bool currentPasswordValid =
            BCrypt.Net.BCrypt.Verify(
                request.CurrentPassword,
                user.PasswordHash
            );

        if (!currentPasswordValid)
        {
            return ApiResponse.Fail(
                "Mật khẩu hiện tại không chính xác!"
            );
        }

        // ========================================================
        // KIỂM TRA MẬT KHẨU MỚI KHÁC MẬT KHẨU CŨ
        // ========================================================

        bool samePassword =
            BCrypt.Net.BCrypt.Verify(
                request.NewPassword,
                user.PasswordHash
            );

        if (samePassword)
        {
            return ApiResponse.Fail(
                "Mật khẩu mới phải khác mật khẩu hiện tại!"
            );
        }

        // ========================================================
        // CẬP NHẬT MẬT KHẨU
        // ========================================================

        user.PasswordHash =
            BCrypt.Net.BCrypt.HashPassword(
                request.NewPassword
            );

        _userRepo.Update(user);

        await _userRepo.SaveChangesAsync();

        return ApiResponse.Ok(
            "Đổi mật khẩu thành công!"
        );
    }

    // ============================================================
    // VERIFY EMAIL
    // ============================================================

    public async Task<ApiResponse> VerifyEmailAsync(
        VerifyEmailRequestDto request)
    {
        var user =
            await _userRepo.GetByEmailAsync(
                request.Email.Trim()
            );

        if (user == null)
        {
            return ApiResponse.Fail(
                "Tài khoản không tồn tại trong hệ thống!"
            );
        }

        // Đã xác thực trước đó
        if (user.IsEmailConfirmed)
        {
            return ApiResponse.Ok(
                "Tài khoản đã được xác thực trước đó!"
            );
        }

        // Kiểm tra OTP
        if (
            string.IsNullOrWhiteSpace(
                user.EmailConfirmationToken
            ) ||
            user.EmailConfirmationToken !=
                request.Code.Trim()
        )
        {
            return ApiResponse.Fail(
                "Mã xác thực không chính xác!"
            );
        }

        // Kiểm tra thời hạn OTP
        if (
            !user.EmailConfirmationTokenExpiresAt.HasValue ||
            user.EmailConfirmationTokenExpiresAt.Value <
                DateTime.UtcNow
        )
        {
            return ApiResponse.Fail(
                "Mã xác thực đã hết hạn! Vui lòng yêu cầu gửi lại mã mới."
            );
        }

        // Kích hoạt tài khoản
        user.IsEmailConfirmed = true;

        user.EmailConfirmationToken =
            null;

        user.EmailConfirmationTokenExpiresAt =
            null;

        _userRepo.Update(user);

        await _userRepo.SaveChangesAsync();

        return ApiResponse.Ok(
            "Xác thực email thành công! Bạn có thể đăng nhập ngay bây giờ."
        );
    }

    // ============================================================
    // RESEND VERIFICATION EMAIL
    // ============================================================

    public async Task<ApiResponse> ResendVerificationEmailAsync(
        ResendVerificationEmailDto request)
    {
        var user =
            await _userRepo.GetByEmailAsync(
                request.Email.Trim()
            );

        if (user == null)
        {
            return ApiResponse.Fail(
                "Không tìm thấy tài khoản với email này!"
            );
        }

        // Đã xác thực
        if (user.IsEmailConfirmed)
        {
            return ApiResponse.Fail(
                "Tài khoản này đã được xác thực rồi!"
            );
        }

        // Tạo OTP mới
        string newOtpCode =
            Random.Shared.Next(
                100000,
                999999
            ).ToString();

        user.EmailConfirmationToken =
            newOtpCode;

        user.EmailConfirmationTokenExpiresAt =
            DateTime.UtcNow.AddHours(24);

        _userRepo.Update(user);

        await _userRepo.SaveChangesAsync();

        // Gửi email
        await _emailService.SendEmailConfirmationAsync(
            user.Email,
            newOtpCode
        );

        return ApiResponse.Ok(
            "Mã xác thực mới đã được gửi đến email của bạn."
        );
    }

    // ============================================================
    // LOGOUT
    // ============================================================

    public Task<ApiResponse> LogoutAsync()
    {
        // JWT Stateless:
        // Client chịu trách nhiệm xóa Access Token.
        return Task.FromResult(
            ApiResponse.Ok(
                "Đăng xuất thành công!"
            )
        );
    }

    // ============================================================
    // FORGOT PASSWORD
    // ============================================================

    public async Task<ApiResponse> ForgotPasswordAsync(
        ForgotPasswordRequestDto request)
    {
        var user =
            await _userRepo.GetByEmailAsync(
                request.Email.Trim()
            );

        if (user == null)
        {
            return ApiResponse.Fail(
                "Không tìm thấy tài khoản với email này!"
            );
        }

        // Tạo OTP 6 số
        string resetOtp =
            Random.Shared.Next(
                100000,
                999999
            ).ToString();

        user.PasswordResetToken =
            resetOtp;

        user.PasswordResetTokenExpiresAt =
            DateTime.UtcNow.AddMinutes(15);

        _userRepo.Update(user);

        await _userRepo.SaveChangesAsync();

        // Gửi OTP qua email
        await _emailService.SendPasswordResetAsync(
            user.Email,
            resetOtp
        );

        return ApiResponse.Ok(
            "Mã khôi phục mật khẩu đã được gửi đến email của bạn."
        );
    }

    // ============================================================
    // RESET PASSWORD
    // ============================================================

    public async Task<ApiResponse> ResetPasswordAsync(
        ResetPasswordRequestDto request)
    {
        var user =
            await _userRepo.GetByEmailAsync(
                request.Email.Trim()
            );

        if (user == null)
        {
            return ApiResponse.Fail(
                "Không tìm thấy tài khoản với email này!"
            );
        }

        // Kiểm tra OTP
        if (
            string.IsNullOrWhiteSpace(
                user.PasswordResetToken
            ) ||
            user.PasswordResetToken !=
                request.Code.Trim()
        )
        {
            return ApiResponse.Fail(
                "Mã xác thực không chính xác!"
            );
        }

        // Kiểm tra hết hạn
        if (
            !user.PasswordResetTokenExpiresAt.HasValue ||
            user.PasswordResetTokenExpiresAt.Value <
                DateTime.UtcNow
        )
        {
            return ApiResponse.Fail(
                "Mã xác thực đã hết hạn! Vui lòng yêu cầu cấp mã mới."
            );
        }

        // Hash mật khẩu mới
        user.PasswordHash =
            BCrypt.Net.BCrypt.HashPassword(
                request.NewPassword
            );

        // Hủy OTP
        user.PasswordResetToken =
            null;

        user.PasswordResetTokenExpiresAt =
            null;

        _userRepo.Update(user);

        await _userRepo.SaveChangesAsync();

        return ApiResponse.Ok(
            "Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới."
        );
    }

    // ============================================================
    // MAP USER -> USER DTO
    // ============================================================

    private static UserDto MapToUserDto(
        User user)
    {
        return new UserDto
        {
            Id =
                user.Id,

            Username =
                user.Username,

            Email =
                user.Email,

            Role =
                user.Role,

            Profile =
                user.Profile != null
                    ? new ProfileDto
                    {
                        DisplayName =
                            user.Profile.DisplayName,

                        AvatarUrl =
                            user.Profile.AvatarUrl,

                        Bio =
                            user.Profile.Bio
                    }
                    : null,

            // ====================================================
            // PREMIUM
            // ====================================================

            IsPremium =
                user.IsPremium,

            PremiumExpiresAt =
                user.PremiumExpiresAt
        };
    }
}

