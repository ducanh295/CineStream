using CineStream.DTOs.AI;
using CineStream.DTOs.Common;

namespace CineStream.Services.Interfaces;

// Giao diện dịch vụ trợ lý AI Điện ảnh CineBot
public interface IAIService
{
    // Gửi tin nhắn hội thoại tới trợ lý AI để nhận tư vấn và danh sách phim gợi ý
    Task<ApiResponse<ChatResponseDto>> ChatAsync(int userId, ChatRequestDto request);

    // Lấy danh sách lịch sử hội thoại gần nhất của người dùng theo cơ chế cửa sổ trượt (Rolling Window)
    Task<ApiResponse<List<ChatLogDto>>> GetChatHistoryAsync(int userId, int limit = 30);

    // Xóa toàn bộ lịch sử trò chuyện để bắt đầu phiên hội thoại mới
    Task<ApiResponse<bool>> ClearChatHistoryAsync(int userId);
}
