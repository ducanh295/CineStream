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

    // Lấy thông tin cấu hình Gemini API Key hiện tại của hệ thống (ưu tiên database, dự phòng appsettings)
    Task<ApiResponse<AiConfigResponseDto>> GetAiConfigAsync();

    // Cập nhật hoặc lưu mới cấu hình Gemini API Key và Model cho Chatbot vào database
    Task<ApiResponse<AiConfigResponseDto>> UpdateAiConfigAsync(UpdateAiConfigRequestDto request);

    // Xóa cấu hình API Key tùy chỉnh trong database để hoàn trả về cấu hình mặc định trong appsettings.json
    Task<ApiResponse<bool>> DeleteAiConfigAsync();
}
