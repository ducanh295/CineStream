using System.Collections.Generic;
using VietFlix.Models.Enums;

namespace VietFlix.Models;

public class User : BaseEntity
{
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public UserRole Role { get; set; } = UserRole.User;

    // 💡 1 User có 1 Profile (1:1), Profile có thể null khi tài khoản vừa tạo
    public virtual Profile? Profile { get; set; }

    // 💡 1 User có nhiều phim yêu thích (1:N qua bảng trung gian Favorite)
    public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();

    // 💡 1 User có nhiều tin nhắn lịch sử AI Chat (1:N)
    public virtual ICollection<ChatLog> ChatLogs { get; set; } = new List<ChatLog>();
}