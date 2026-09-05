using System.Net;
using System.Text.Json;
using VietFlix.DTOs.Common;

namespace VietFlix.Middleware;

// 💡 Middleware bắt lỗi tập trung (Global Exception Handler) cho toàn bộ HTTP pipeline
public class ExceptionHandlingMiddleware
{
    // 💡 RequestDelegate đại diện cho middleware tiếp theo cần được gọi trong pipeline
    private readonly RequestDelegate _next;

    // 💡 Logger ghi log ra terminal/console để dev kiểm tra nguyên nhân lỗi
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            // 💡 Cho phép request tiếp tục đi sâu vào các Controller/Service bên trong
            await _next(context);
        }
        catch (Exception ex)
        {
            // 💡 Bắt mọi unhandled exception nổ ra từ bất kỳ đâu trong ứng dụng
            _logger.LogError(ex, "Unhandled Exception: {Message}", ex.Message);

            // 💡 Đóng gói lỗi và trả về JSON tiêu chuẩn cho client
            await HandleExceptionAsync(context);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context)
    {
        // 💡 Thiết lập Content-Type là JSON và Status Code là 500 (Internal Server Error)
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

        // 💡 Dùng ApiResponse bọc thông báo lỗi thân thiện, không lộ stack trace nhạy cảm
        var response = ApiResponse.Fail("Đã có lỗi xảy ra từ máy chủ. Vui lòng thử lại sau!");

        // 💡 Chuẩn hóa key JSON thành camelCase (success, message thay vì Success, Message)
        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        var json = JsonSerializer.Serialize(response, jsonOptions);
        await context.Response.WriteAsync(json);
    }
}
