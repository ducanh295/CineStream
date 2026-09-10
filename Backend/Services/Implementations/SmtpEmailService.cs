using System;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

// Dịch vụ gửi email qua giao thức SMTP (hỗ trợ Google Gmail SMTP)
// Kết hợp cơ chế ghi log dự phòng (Fallback Logger) đảm bảo an toàn tối đa khi chạy ngoại tuyến hoặc bảo vệ đồ án
public class SmtpEmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(IConfiguration configuration, ILogger<SmtpEmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    // Gửi email xác nhận đăng ký tài khoản kèm mã OTP kích hoạt
    public async Task SendEmailConfirmationAsync(string toEmail, string code)
    {
        // Ghi log ra màn hình console phục vụ theo dõi và đối soát khi demo
        _logger.LogInformation("==================================================================");
        _logger.LogInformation("[EMAIL SERVICE - CONFIRMATION] Gui den: {Email}", toEmail);
        _logger.LogInformation("Tieu de: CineStream - Ma xac nhan kich hoat tai khoan");
        _logger.LogInformation("Noi dung: Ma OTP kich hoat tai khoan cua ban la: [{Code}]", code);
        _logger.LogInformation("Thoi han hieu luc: 24 gio");
        _logger.LogInformation("==================================================================");

        string subject = "CineStream - Ma xac nhan kich hoat tai khoan";
        string htmlBody = $@"
            <div style=""font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;"">
                <h2 style=""color: #e50914; text-align: center;"">CineStream</h2>
                <h3 style=""color: #333;"">Xác nhận đăng ký tài khoản</h3>
                <p>Cảm ơn bạn đã đăng ký tài khoản tại <strong>CineStream</strong>. Vui lòng sử dụng mã OTP dưới đây để hoàn tất kích hoạt tài khoản:</p>
                <div style=""text-align: center; margin: 30px 0;"">
                    <span style=""display: inline-block; font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #e50914; background: #f7f7f7; padding: 12px 28px; border-radius: 6px; border: 1px dashed #e50914;"">{code}</span>
                </div>
                <p style=""color: #666; font-size: 14px;"">Mã xác thực có hiệu lực trong <strong>24 giờ</strong>. Vì lý do bảo mật, tuyệt đối không chia sẻ mã này cho bất kỳ ai.</p>
                <hr style=""border: none; border-top: 1px solid #eee; margin: 20px 0;"" />
                <p style=""color: #999; font-size: 12px; text-align: center;"">Đây là email tự động từ hệ thống CineStream, vui lòng không phản hồi email này.</p>
            </div>";

        await SendEmailInternalAsync(toEmail, subject, htmlBody);
    }

    // Gửi email khôi phục mật khẩu kèm mã OTP đặt lại mật khẩu
    public async Task SendPasswordResetAsync(string toEmail, string code)
    {
        _logger.LogInformation("==================================================================");
        _logger.LogInformation("[EMAIL SERVICE - PASSWORD RESET] Gui den: {Email}", toEmail);
        _logger.LogInformation("Tieu de: CineStream - Yeu cau dat lai mat khau");
        _logger.LogInformation("Noi dung: Ma OTP dat lai mat khau cua ban la: [{Code}]", code);
        _logger.LogInformation("Thoi han hieu luc: 15 phut");
        _logger.LogInformation("==================================================================");

        string subject = "CineStream - Yeu cau dat lai mat khau";
        string htmlBody = $@"
            <div style=""font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;"">
                <h2 style=""color: #e50914; text-align: center;"">CineStream</h2>
                <h3 style=""color: #333;"">Đặt lại mật khẩu</h3>
                <p>Hệ thống nhận được yêu cầu đặt lại mật khẩu cho tài khoản liên kết với email này. Vui lòng dùng mã OTP bên dưới:</p>
                <div style=""text-align: center; margin: 30px 0;"">
                    <span style=""display: inline-block; font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #e50914; background: #f7f7f7; padding: 12px 28px; border-radius: 6px; border: 1px dashed #e50914;"">{code}</span>
                </div>
                <p style=""color: #666; font-size: 14px;"">Mã xác thực có hiệu lực trong <strong>15 phút</strong>. Nếu bạn không gửi yêu cầu này, vui lòng bỏ qua email hoặc liên hệ quản trị viên.</p>
                <hr style=""border: none; border-top: 1px solid #eee; margin: 20px 0;"" />
                <p style=""color: #999; font-size: 12px; text-align: center;"">Đây là email tự động từ hệ thống CineStream, vui lòng không phản hồi email này.</p>
            </div>";

        await SendEmailInternalAsync(toEmail, subject, htmlBody);
    }

    // Logic gửi email qua giao thức SMTP kèm cơ chế bắt lỗi an toàn không làm crash luồng chính
    private async Task SendEmailInternalAsync(string toEmail, string subject, string htmlBody)
    {
        var smtpSection = _configuration.GetSection("Smtp");
        string host = smtpSection["Host"] ?? "smtp.gmail.com";
        int port = int.TryParse(smtpSection["Port"], out int p) ? p : 587;
        string senderEmail = smtpSection["SenderEmail"] ?? "nkda941@gmail.com";
        string senderName = smtpSection["SenderName"] ?? "CineStream Security";
        string username = smtpSection["Username"] ?? senderEmail;
        string password = smtpSection["Password"] ?? string.Empty;
        bool enableSsl = bool.TryParse(smtpSection["EnableSsl"], out bool ssl) ? ssl : true;

        if (string.IsNullOrWhiteSpace(password))
        {
            _logger.LogWarning("Chua cau hinh mat khau SMTP! Ma OTP van duoc ghi nhan day du tren Logger console.");
            return;
        }

        try
        {
            using var client = new SmtpClient(host, port)
            {
                EnableSsl = enableSsl,
                UseDefaultCredentials = false,
                Credentials = new NetworkCredential(username, password)
            };

            using var message = new MailMessage
            {
                From = new MailAddress(senderEmail, senderName),
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true
            };
            message.To.Add(toEmail);

            await client.SendMailAsync(message);
            _logger.LogInformation("Gui email thanh cong qua Gmail SMTP den dia chi: {Email}", toEmail);
        }
        catch (Exception ex)
        {
            // Bắt lỗi kết nối mạng hoặc timeout, giữ an toàn tuyệt đối cho luồng ứng dụng
            _logger.LogWarning(ex, "Gui email qua Gmail SMTP that bai (khong co mang hoac loi SMTP). Ma OTP da duoc luu an toan tai Logger console.");
        }
    }
}
