using System.ComponentModel.DataAnnotations;
using CineStream.DTOs.Movies;

namespace CineStream.DTOs.AI;

// DTO tiếp nhận tin nhắn hội thoại từ người dùng gửi tới trợ lý AI
public class ChatRequestDto
{
    [Required(ErrorMessage = "Nội dung tin nhắn không được để trống!")]
    [StringLength(2000, MinimumLength = 1, ErrorMessage = "Nội dung tin nhắn phải từ 1 đến 2000 ký tự!")]
    public string Message { get; set; } = string.Empty;
}

// DTO phản hồi từ trợ lý AI CineBot bao gồm câu trả lời và danh sách phim gợi ý
public class ChatResponseDto
{
    // Câu trả lời hoặc lời tư vấn từ AI
    public string Reply { get; set; } = string.Empty;

    // Danh sách các bộ phim hệ thống gợi ý phù hợp với yêu cầu của người dùng
    public List<MovieDto> RecommendedMovies { get; set; } = new();

    // Thời điểm phản hồi của trợ lý AI
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// DTO biểu diễn một bản ghi nhật ký hội thoại trong lịch sử trò chuyện
public class ChatLogDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsFromAI { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Tùy chọn cấu hình kết nối Google Gemini API
public class GeminiOptions
{
    public string ApiKey { get; set; } = string.Empty;
    public string Model { get; set; } = "gemini-3.5-flash-lite";
    public string BaseUrl { get; set; } = "https://generativelanguage.googleapis.com/v1beta";
}
