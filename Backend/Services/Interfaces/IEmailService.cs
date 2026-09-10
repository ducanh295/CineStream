using System.Threading.Tasks;

namespace CineStream.Services.Interfaces;

// Giao diện trừu tượng hóa dịch vụ gửi email trong toàn hệ sinh thái CineStream
public interface IEmailService
{
    // Gửi email xác nhận đăng ký tài khoản kèm mã OTP kích hoạt
    Task SendEmailConfirmationAsync(string toEmail, string code);

    // Gửi email khôi phục mật khẩu kèm mã OTP đặt lại mật khẩu
    Task SendPasswordResetAsync(string toEmail, string code);
}
