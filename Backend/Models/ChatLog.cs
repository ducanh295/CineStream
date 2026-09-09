namespace CineStream.Models;

public class ChatLog : BaseEntity
{
    public int UserId { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsFromAI { get; set; } = false;

    // Quan hệ điều hướng (Navigation Property) tới người dùng sở hữu đoạn chat
    public virtual User User { get; set; } = null!;
}
