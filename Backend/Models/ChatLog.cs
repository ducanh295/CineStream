namespace VietFlix.Models;

public class ChatLog : BaseEntity
{
    public int UserId { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsFromAI { get; set; } = false;

    // 💡 Navigation Property trỏ về User gửi tin nhắn
    public virtual User User { get; set; } = null!;
}
