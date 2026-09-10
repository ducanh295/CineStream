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

    public AuthService(IUserRepository userRepo, IJwtService jwtService, IEmailService emailService)
    {
        _userRepo = userRepo;
        _jwtService = jwtService;
        _emailService = emailService;
    }

    public async Task<ApiResponse<AuthResponseDto>> RegisterAsync(RegisterRequestDto request)
    {
        var email = request.Email.Trim();
        var username = request.Username.Trim();

        // Kiểm tra tính duy nhất của Email trong hệ thống (bao gồm tài khoản đã xóa mềm)
        bool emailExists = await _userRepo.EmailExistsAsync(email);
        if (emailExists)
        {
            return ApiResponse<AuthResponseDto>.Fail("Email đã được sử dụng");
        }

        // Kiểm tra tính duy nhất của Username để tránh xung đột dữ liệu (bao gồm tài khoản đã xóa mềm)
        bool usernameExists = await _userRepo.UsernameExistsAsync(username);
        if (usernameExists)
        {
            return ApiResponse<AuthResponseDto>.Fail("Tên đăng nhập đã được sử dụng");
        }

        // Mã hóa mật khẩu một chiều sử dụng thuật toán BCrypt
        string hashedPassword = BCrypt.Net.BCrypt.HashPassword(request.Password);

        // Tạo mã OTP xác nhận kích hoạt gồm 6 chữ số ngẫu nhiên
        string otpCode = Random.Shared.Next(100000, 999999).ToString();

        // Khởi tạo thực thể User kèm mã xác nhận email có thời hạn 24 giờ
        var user = new User
        {
            Username = username,
            Email = email,
            PasswordHash = hashedPassword,
            Role = UserRole.User,
            IsEmailConfirmed = false,
            EmailConfirmationToken = otpCode,
            EmailConfirmationTokenExpiresAt = DateTime.UtcNow.AddHours(24),
            Profile = new Profile { DisplayName = username }
        };
        await _userRepo.AddAsync(user);
        await _userRepo.SaveChangesAsync();

        // Gửi email xác thực kèm mã OTP kích hoạt đến hòm thư người dùng
        await _emailService.SendEmailConfirmationAsync(user.Email, otpCode);

        // Đóng gói dữ liệu phản hồi (tài khoản chưa kích hoạt nên chưa cấp Access Token hoạt động)
        var response = new AuthResponseDto
        {
            Token = string.Empty,
            ExpiresAt = DateTime.MinValue,
            User = MapToUserDto(user)
        };

        return ApiResponse<AuthResponseDto>.Ok(response, "Đăng ký tài khoản thành công! Vui lòng kiểm tra email để kích hoạt tài khoản.");
    }

    public async Task<ApiResponse<AuthResponseDto>> LoginAsync(LoginRequestDto request)
    {
        var identifier = request.UsernameOrEmail.Trim();

        // Tìm kiếm tài khoản người dùng theo Email hoặc Username
        var user = await _userRepo.GetByEmailOrUsernameAsync(identifier);
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

        // Kiểm tra trạng thái xác thực email của tài khoản trước khi cấp quyền truy cập
        if (!user.IsEmailConfirmed)
        {
            return ApiResponse<AuthResponseDto>.Fail("Tài khoản chưa được kích hoạt email! Vui lòng kiểm tra hộp thư để xác thực tài khoản.");
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

    public async Task<ApiResponse> VerifyEmailAsync(VerifyEmailRequestDto request)
    {
        // Tìm kiếm thông tin người dùng theo Email
        var user = await _userRepo.GetByEmailAsync(request.Email.Trim());
        if (user == null)
        {
            return ApiResponse.Fail("Tài khoản không tồn tại trong hệ thống!");
        }

        // Nếu tài khoản đã kích hoạt trước đó thì trả về thông báo thành công
        if (user.IsEmailConfirmed)
        {
            return ApiResponse.Ok("Tài khoản đã được xác thực trước đó!");
        }

        // Kiểm tra tính chính xác của mã OTP
        if (string.IsNullOrWhiteSpace(user.EmailConfirmationToken) || user.EmailConfirmationToken != request.Code.Trim())
        {
            return ApiResponse.Fail("Mã xác thực không chính xác!");
        }

        // Kiểm tra thời hạn hiệu lực của mã OTP
        if (!user.EmailConfirmationTokenExpiresAt.HasValue || user.EmailConfirmationTokenExpiresAt.Value < DateTime.UtcNow)
        {
            return ApiResponse.Fail("Mã xác thực đã hết hạn! Vui lòng yêu cầu gửi lại mã mới.");
        }

        // Kích hoạt tài khoản thành công và hủy mã OTP
        user.IsEmailConfirmed = true;
        user.EmailConfirmationToken = null;
        user.EmailConfirmationTokenExpiresAt = null;
        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync();

        return ApiResponse.Ok("Xác thực email thành công! Bạn có thể đăng nhập ngay bây giờ.");
    }

    public async Task<ApiResponse> ResendVerificationEmailAsync(ResendVerificationEmailDto request)
    {
        // Tìm kiếm thông tin người dùng theo Email
        var user = await _userRepo.GetByEmailAsync(request.Email.Trim());
        if (user == null)
        {
            return ApiResponse.Fail("Không tìm thấy tài khoản với email này!");
        }

        // Kiểm tra nếu tài khoản đã xác thực thì không cần gửi lại
        if (user.IsEmailConfirmed)
        {
            return ApiResponse.Fail("Tài khoản này đã được xác thực rồi!");
        }

        // Tạo mã OTP 6 số mới và làm mới thời hạn hiệu lực 24 giờ
        string newOtpCode = Random.Shared.Next(100000, 999999).ToString();
        user.EmailConfirmationToken = newOtpCode;
        user.EmailConfirmationTokenExpiresAt = DateTime.UtcNow.AddHours(24);
        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync();

        // Gửi email chứa mã OTP kích hoạt mới
        await _emailService.SendEmailConfirmationAsync(user.Email, newOtpCode);

        return ApiResponse.Ok("Mã xác thực mới đã được gửi đến email của bạn.");
    }

    public Task<ApiResponse> LogoutAsync()
    {
        // Trong kiến trúc JWT Stateless, máy chủ ghi nhận kết thúc phiên làm việc
        // Phía Client có trách nhiệm hủy bỏ Token khỏi bộ nhớ cục bộ (Storage)
        return Task.FromResult(ApiResponse.Ok("Đăng xuất thành công!"));
    }

    public async Task<ApiResponse> ForgotPasswordAsync(ForgotPasswordRequestDto request)
    {
        // Tìm kiếm tài khoản người dùng theo Email
        var user = await _userRepo.GetByEmailAsync(request.Email.Trim());
        if (user == null)
        {
            return ApiResponse.Fail("Không tìm thấy tài khoản với email này!");
        }

        // Tạo mã OTP đặt lại mật khẩu gồm 6 chữ số ngẫu nhiên
        string resetOtp = Random.Shared.Next(100000, 999999).ToString();
        user.PasswordResetToken = resetOtp;
        user.PasswordResetTokenExpiresAt = DateTime.UtcNow.AddMinutes(15);
        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync();

        // Gửi email chứa mã OTP đặt lại mật khẩu
        await _emailService.SendPasswordResetAsync(user.Email, resetOtp);

        return ApiResponse.Ok("Mã khôi phục mật khẩu đã được gửi đến email của bạn.");
    }

    public async Task<ApiResponse> ResetPasswordAsync(ResetPasswordRequestDto request)
    {
        // Tìm kiếm tài khoản người dùng theo Email
        var user = await _userRepo.GetByEmailAsync(request.Email.Trim());
        if (user == null)
        {
            return ApiResponse.Fail("Không tìm thấy tài khoản với email này!");
        }

        // Kiểm tra tính chính xác của mã OTP
        if (string.IsNullOrWhiteSpace(user.PasswordResetToken) || user.PasswordResetToken != request.Code.Trim())
        {
            return ApiResponse.Fail("Mã xác thực không chính xác!");
        }

        // Kiểm tra thời hạn hiệu lực của mã OTP (15 phút)
        if (!user.PasswordResetTokenExpiresAt.HasValue || user.PasswordResetTokenExpiresAt.Value < DateTime.UtcNow)
        {
            return ApiResponse.Fail("Mã xác thực đã hết hạn! Vui lòng yêu cầu cấp mã mới.");
        }

        // Mã hóa mật khẩu mới bằng thuật toán BCrypt
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);

        // Hủy bỏ mã OTP sau khi sử dụng thành công để ngăn chặn tấn công phát lại
        user.PasswordResetToken = null;
        user.PasswordResetTokenExpiresAt = null;
        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync();

        return ApiResponse.Ok("Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.");
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
