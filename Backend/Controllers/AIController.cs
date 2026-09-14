    using System.Security.Claims;
    using Microsoft.AspNetCore.Authorization;
    using Microsoft.AspNetCore.Mvc;
    using CineStream.DTOs.AI;
    using CineStream.DTOs.Common;
    using CineStream.Services.Interfaces;

    namespace CineStream.Controllers;

    // Bộ điều khiển API Trợ lý Điện ảnh AI CineBot
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AIController : ControllerBase
    {
        private readonly IAIService _aiService;

        public AIController(IAIService aiService)
        {
            _aiService = aiService;
        }

        // POST /api/ai/chat - Gửi tin nhắn tới trợ lý AI CineBot để nhận tư vấn và gợi ý phim
        [HttpPost("chat")]
        public async Task<ActionResult<ApiResponse<ChatResponseDto>>> Chat([FromBody] ChatRequestDto request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized(ApiResponse<ChatResponseDto>.Fail("Không xác định được danh tính người dùng!"));
            }

            var result = await _aiService.ChatAsync(userId, request);
            if (!result.Success)
            {
                return BadRequest(result);
            }

            return Ok(result);
        }

        // GET /api/ai/history - Lấy danh sách lịch sử hội thoại gần nhất của người dùng
        [HttpGet("history")]
        public async Task<ActionResult<ApiResponse<List<ChatLogDto>>>> GetHistory([FromQuery] int limit = 30)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized(ApiResponse<List<ChatLogDto>>.Fail("Không xác định được danh tính người dùng!"));
            }

            var result = await _aiService.GetChatHistoryAsync(userId, limit);
            return Ok(result);
        }

        // DELETE /api/ai/history - Xóa toàn bộ lịch sử trò chuyện của người dùng hiện tại
        [HttpDelete("history")]
        public async Task<ActionResult<ApiResponse<bool>>> ClearHistory()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized(ApiResponse<bool>.Fail("Không xác định được danh tính người dùng!"));
            }

            var result = await _aiService.ClearChatHistoryAsync(userId);
            return Ok(result);
        }
    }
