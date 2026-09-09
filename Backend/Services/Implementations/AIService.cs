using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using CineStream.Data;
using CineStream.DTOs.AI;
using CineStream.DTOs.Categories;
using CineStream.DTOs.Common;
using CineStream.DTOs.Movies;
using CineStream.Models;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

// Triển khai dịch vụ trợ lý AI Điện ảnh CineBot kết nối Gemini API và tích hợp RAG nội bộ
public class AIService : IAIService
{
    private readonly AppDbContext _context;
    private readonly HttpClient _httpClient;
    private readonly GeminiOptions _geminiOptions;
    private readonly ILogger<AIService> _logger;

    public AIService(
        AppDbContext context,
        HttpClient httpClient,
        IOptions<GeminiOptions> geminiOptions,
        ILogger<AIService> logger)
    {
        _context = context;
        _httpClient = httpClient;
        _geminiOptions = geminiOptions.Value;
        _logger = logger;
    }

    // Xử lý tin nhắn của người dùng, truy vấn kho phim nội bộ và tạo phản hồi từ AI
    public async Task<ApiResponse<ChatResponseDto>> ChatAsync(int userId, ChatRequestDto request)
    {
        var userMessage = request.Message.Trim();

        // 1. Truy vấn danh sách phim đang hoạt động để làm ngữ cảnh RAG
        var availableMovies = await _context.Movies
            .Include(m => m.MovieCategories)
                .ThenInclude(mc => mc.Category)
            .OrderByDescending(m => m.CreatedAt)
            .Take(30)
            .ToListAsync();

        // 2. Lấy 4 tin nhắn gần nhất để làm ngữ cảnh hội thoại ngắn hạn (Rolling Window)
        var recentLogs = await _context.ChatLogs
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedAt)
            .Take(4)
            .OrderBy(c => c.CreatedAt)
            .ToListAsync();

        string aiReplyText;
        var recommendedMovieIds = new List<int>();

        // 3. Kiểm tra và gọi Gemini API nếu có cấu hình ApiKey hợp lệ
        if (!string.IsNullOrWhiteSpace(_geminiOptions.ApiKey))
        {
            try
            {
                var systemPrompt = BuildSystemPrompt(availableMovies, recentLogs, userMessage);
                var geminiResponse = await CallGeminiApiAsync(systemPrompt);

                if (!string.IsNullOrWhiteSpace(geminiResponse))
                {
                    aiReplyText = ParseReplyAndExtractMovies(geminiResponse, out recommendedMovieIds);
                }
                else
                {
                    aiReplyText = GenerateFallbackResponse(userMessage, availableMovies, out recommendedMovieIds);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Lỗi khi gọi Gemini API. Hệ thống chuyển sang cơ chế phản hồi dự phòng cục bộ.");
                aiReplyText = GenerateFallbackResponse(userMessage, availableMovies, out recommendedMovieIds);
            }
        }
        else
        {
            // Trường hợp chưa có ApiKey hoặc chạy ngoại tuyến, sử dụng cơ chế Fallback thông minh
            aiReplyText = GenerateFallbackResponse(userMessage, availableMovies, out recommendedMovieIds);
        }

        // 4. Lưu nhật ký hội thoại vào cơ sở dữ liệu (Cả câu hỏi và phản hồi)
        var userLog = new ChatLog
        {
            UserId = userId,
            Message = userMessage,
            IsFromAI = false,
            CreatedAt = DateTime.UtcNow
        };

        var aiLog = new ChatLog
        {
            UserId = userId,
            Message = aiReplyText,
            IsFromAI = true,
            CreatedAt = DateTime.UtcNow
        };

        await _context.ChatLogs.AddRangeAsync(userLog, aiLog);
        await _context.SaveChangesAsync();

        // 5. Lấy danh sách thực thể phim được gợi ý để trả về DTO đầy đủ
        var recommendedMovies = availableMovies
            .Where(m => recommendedMovieIds.Contains(m.Id))
            .Select(m => new MovieDto
            {
                Id = m.Id,
                Title = m.Title,
                Description = m.Description,
                PosterUrl = m.PosterUrl,
                TrailerUrl = m.TrailerUrl,
                Duration = m.Duration,
                ReleaseYear = m.ReleaseYear,
                Type = m.Type,
                VideoStatus = m.VideoStatus,
                Categories = m.MovieCategories
                    .Where(mc => mc.Category != null)
                    .Select(mc => new CategoryDto
                    {
                        Id = mc.Category.Id,
                        Name = mc.Category.Name,
                        Description = mc.Category.Description
                    }).ToList()
            }).ToList();

        var responseDto = new ChatResponseDto
        {
            Reply = aiReplyText,
            RecommendedMovies = recommendedMovies,
            CreatedAt = DateTime.UtcNow
        };

        return ApiResponse<ChatResponseDto>.Ok(responseDto, "Trợ lý AI phản hồi thành công!");
    }

    // Lấy lịch sử trò chuyện gần nhất theo cơ chế cửa sổ trượt (Rolling Window)
    public async Task<ApiResponse<List<ChatLogDto>>> GetChatHistoryAsync(int userId, int limit = 30)
    {
        // Ràng buộc giới hạn an toàn để tránh tải quá tải bộ nhớ hệ thống
        if (limit <= 0) limit = 30;
        if (limit > 100) limit = 100;

        var logs = await _context.ChatLogs
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedAt)
            .Take(limit)
            .OrderBy(c => c.CreatedAt)
            .Select(c => new ChatLogDto
            {
                Id = c.Id,
                UserId = c.UserId,
                Message = c.Message,
                IsFromAI = c.IsFromAI,
                CreatedAt = c.CreatedAt
            })
            .ToListAsync();

        return ApiResponse<List<ChatLogDto>>.Ok(logs, "Lấy lịch sử trò chuyện thành công!");
    }

    // Xóa toàn bộ lịch sử trò chuyện của người dùng (Xóa mềm Soft-Delete)
    public async Task<ApiResponse<bool>> ClearChatHistoryAsync(int userId)
    {
        var logs = await _context.ChatLogs
            .Where(c => c.UserId == userId)
            .ToListAsync();

        if (logs.Any())
        {
            foreach (var log in logs)
            {
                log.IsDeleted = true;
                log.UpdatedAt = DateTime.UtcNow;
            }
            await _context.SaveChangesAsync();
        }

        return ApiResponse<bool>.Ok(true, "Đã xóa toàn bộ lịch sử trò chuyện!");
    }

    // Xây dựng System Prompt chứa ngữ cảnh kho phim nội bộ và quy tắc ứng xử
    private static string BuildSystemPrompt(List<Movie> movies, List<ChatLog> history, string currentQuestion)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Bạn là CineBot - trợ lý điện ảnh thông minh và độc quyền của hệ thống CineStream.");
        sb.AppendLine("Quy tắc nghiệp vụ bắt buộc:");
        sb.AppendLine("1. Nhiệm vụ duy nhất của bạn là tư vấn phim, giới thiệu phim và giải đáp thắc mắc điện ảnh.");
        sb.AppendLine("2. Nếu người dùng hỏi về các chủ đề ngoài phim ảnh (thời tiết, toán học, lập trình, nấu ăn, chính trị...), hãy từ chối lịch sự, thân thiện và mời người dùng quay lại chủ đề xem phim.");
        sb.AppendLine("3. Bạn CHỈ ĐƯỢC PHÉP gợi ý các bộ phim có trong danh sách kho phim CineStream bên dưới. Tuyệt đối không bịa đặt phim ngoài hệ thống.");
        sb.AppendLine("4. Định dạng phản hồi: Nếu có gợi ý phim, đặt danh sách ID phim ở dòng cuối cùng theo đúng mẫu: [RECOMMENDED_MOVIES: id1, id2].");
        sb.AppendLine();

        sb.AppendLine("DANH SÁCH KHO PHIM CINESTREAM HIỆN CÓ:");
        foreach (var m in movies)
        {
            var categories = string.Join(", ", m.MovieCategories.Select(mc => mc.Category?.Name).Where(n => !string.IsNullOrEmpty(n)));
            sb.AppendLine($"- [ID: {m.Id}] Phim: {m.Title} | Thể loại: {categories} | Thời lượng: {m.Duration} phút | Năm: {m.ReleaseYear} | Mô tả: {m.Description}");
        }
        sb.AppendLine();

        if (history.Any())
        {
            sb.AppendLine("LỊCH SỬ HỘI THOẠI GẦN ĐÂY:");
            foreach (var h in history)
            {
                sb.AppendLine(h.IsFromAI ? $"CineBot: {h.Message}" : $"User: {h.Message}");
            }
            sb.AppendLine();
        }

        sb.AppendLine($"CÂU HỎI HIỆN TẠI CỦA NGƯỜI DÙNG: {currentQuestion}");
        return sb.ToString();
    }

    // Gọi REST API của Google Gemini
    private async Task<string?> CallGeminiApiAsync(string prompt)
    {
        var model = string.IsNullOrWhiteSpace(_geminiOptions.Model) ? "gemini-1.5-flash" : _geminiOptions.Model;
        var baseUrl = string.IsNullOrWhiteSpace(_geminiOptions.BaseUrl) 
            ? "https://generativelanguage.googleapis.com/v1beta" 
            : _geminiOptions.BaseUrl.TrimEnd('/');

        var endpoint = $"{baseUrl}/models/{model}:generateContent?key={_geminiOptions.ApiKey}";

        var requestBody = new
        {
            contents = new[]
            {
                new
                {
                    role = "user",
                    parts = new[] { new { text = prompt } }
                }
            },
            generationConfig = new
            {
                temperature = 0.7,
                maxOutputTokens = 1000
            }
        };

        var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
        var response = await _httpClient.PostAsync(endpoint, content);

        if (!response.IsSuccessStatusCode)
        {
            var errorDetails = await response.Content.ReadAsStringAsync();
            _logger.LogWarning("Gemini API trả về mã lỗi HTTP {StatusCode}: {ErrorDetails}", response.StatusCode, errorDetails);
            return null;
        }

        var jsonString = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(jsonString);

        if (document.RootElement.TryGetProperty("candidates", out var candidates) &&
            candidates.GetArrayLength() > 0 &&
            candidates[0].TryGetProperty("content", out var contentElem) &&
            contentElem.TryGetProperty("parts", out var parts) &&
            parts.GetArrayLength() > 0 &&
            parts[0].TryGetProperty("text", out var textElem))
        {
            return textElem.GetString();
        }

        return null;
    }

    // Tách nội dung trả lời và trích xuất danh sách ID phim được gợi ý
    private static string ParseReplyAndExtractMovies(string fullResponse, out List<int> movieIds)
    {
        movieIds = new List<int>();
        var pattern = @"\[RECOMMENDED_MOVIES:\s*([\d\s,]+)\]";
        var match = Regex.Match(fullResponse, pattern);

        if (match.Success)
        {
            var idsString = match.Groups[1].Value;
            var parts = idsString.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            foreach (var part in parts)
            {
                if (int.TryParse(part, out var id))
                {
                    movieIds.Add(id);
                }
            }

            // Xóa thẻ tag để phản hồi hiển thị cho người dùng được tự nhiên, sạch sẽ
            return fullResponse.Replace(match.Value, string.Empty).Trim();
        }

        return fullResponse.Trim();
    }

    // Cơ chế phản hồi dự phòng cục bộ (Fallback Mechanism) đảm bảo 100% không bao giờ bị sập hệ thống
    private static string GenerateFallbackResponse(string userMessage, List<Movie> availableMovies, out List<int> recommendedIds)
    {
        recommendedIds = new List<int>();
        var lowerMsg = userMessage.ToLower();

        // Kiểm tra các từ khóa chủ đề ngoài phim ảnh để từ chối lịch sự
        var nonMovieKeywords = new[] { "thời tiết", "thoi tiet", "nấu ăn", "nau an", "toán", "toan hoc", "code", "lập trình", "lap trinh", "1+1", "ai la tong thong" };
        if (nonMovieKeywords.Any(k => lowerMsg.Contains(k)))
        {
            return "Chào bạn! Tôi là CineBot - trợ lý điện ảnh độc quyền của CineStream. Tôi chỉ có thể hỗ trợ bạn tìm kiếm và gợi ý các bộ phim tuyệt vời trong hệ thống. Bạn có muốn khám phá một tựa phim hấp dẫn cho hôm nay không?";
        }

        // Lọc phim dựa trên từ khóa thể loại trong câu hỏi
        var matched = availableMovies.Where(m =>
            lowerMsg.Contains(m.Title.ToLower()) ||
            m.MovieCategories.Any(mc => mc.Category != null && lowerMsg.Contains(mc.Category.Name.ToLower())) ||
            (lowerMsg.Contains("hài") && m.MovieCategories.Any(mc => mc.Category != null && mc.Category.Name.Contains("Hài"))) ||
            (lowerMsg.Contains("hành động") && m.MovieCategories.Any(mc => mc.Category != null && mc.Category.Name.Contains("Hành động"))) ||
            (lowerMsg.Contains("hoạt hình") && m.MovieCategories.Any(mc => mc.Category != null && mc.Category.Name.Contains("Hoạt hình"))) ||
            (lowerMsg.Contains("châu tinh trì") && m.Title.ToLower().Contains("đại thoại tây du"))
        ).Take(3).ToList();

        if (matched.Any())
        {
            recommendedIds = matched.Select(m => m.Id).ToList();
            var titles = string.Join(", ", matched.Select(m => m.Title));
            return $"CineBot rất vui được hỗ trợ bạn! Dựa trên sở thích bạn vừa chia sẻ, CineStream gợi ý bạn nên thưởng thức các tác phẩm: {titles}. Bạn có thể xem ngay danh sách bên dưới!";
        }

        // Nếu không khớp từ khóa cụ thể, gợi ý các phim nổi bật nhất trong hệ thống
        var topMovies = availableMovies.Take(2).ToList();
        recommendedIds = topMovies.Select(m => m.Id).ToList();
        return "Chào bạn! CineBot đã ghi nhận yêu cầu của bạn. Dưới đây là những bộ phim đặc sắc và đang được yêu thích nhất trên CineStream mà bạn không nên bỏ lỡ:";
    }
}
