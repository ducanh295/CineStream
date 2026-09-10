using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

// Dịch vụ gửi email định dạng giả lập in ra Console Logger
// Phục vụ môi trường phát triển (Development) và demo bảo vệ đồ án tốt nghiệp
// Bảo đảm 100% tính sẵn sàng, không phụ thuộc vào kết nối SMTP Internet bên ngoài
public class ConsoleEmailService : IEmailService
{
    private readonly ILogger<ConsoleEmailService> _logger;

    public ConsoleEmailService(ILogger<ConsoleEmailService> logger)
    {
        _logger = logger;
    }

    // Gửi email xác nhận đăng ký tài khoản kèm mã OTP kích hoạt
    public Task SendEmailConfirmationAsync(string toEmail, string code)
    {
        _logger.LogInformation("==================================================================");
        _logger.LogInformation("[EMAIL SERVICE - CONFIRMATION] Gui den: {Email}", toEmail);
        _logger.LogInformation("Tieu de: CineStream - Ma xac nhan kich hoat tai khoan");
        _logger.LogInformation("Noi dung: Ma OTP kich hoat tai khoan cua ban la: [{Code}]", code);
        _logger.LogInformation("Thoi han hieu luc: 24 gio");
        _logger.LogInformation("==================================================================");

        return Task.CompletedTask;
    }

    // Gửi email khôi phục mật khẩu kèm mã OTP đặt lại mật khẩu
    public Task SendPasswordResetAsync(string toEmail, string code)
    {
        _logger.LogInformation("==================================================================");
        _logger.LogInformation("[EMAIL SERVICE - PASSWORD RESET] Gui den: {Email}", toEmail);
        _logger.LogInformation("Tieu de: CineStream - Yeu cau dat lai mat khau");
        _logger.LogInformation("Noi dung: Ma OTP dat lai mat khau cua ban la: [{Code}]", code);
        _logger.LogInformation("Thoi han hieu luc: 15 phut");
        _logger.LogInformation("==================================================================");

        return Task.CompletedTask;
    }
}
