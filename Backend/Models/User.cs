using System;
using System.Collections.Generic;
using CineStream.Models.Enums;

namespace CineStream.Models;

public class User : BaseEntity
{
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public UserRole Role { get; set; } = UserRole.User;

    // Trạng thái xác thực hòm thư và mã OTP kích hoạt tài khoản
    public bool IsEmailConfirmed { get; set; } = false;
    public string? EmailConfirmationToken { get; set; }
    public DateTime? EmailConfirmationTokenExpiresAt { get; set; }

    // Mã OTP và thời hạn hiệu lực phục vụ khôi phục mật khẩu
    public string? PasswordResetToken { get; set; }
    public DateTime? PasswordResetTokenExpiresAt { get; set; }

    // Trạng thái khóa tài khoản do Quản trị viên thiết lập và lý do khóa
    public bool IsLocked { get; set; } = false;
    public string? LockReason { get; set; }

    // Trạng thái hội viên cao cấp và thời hạn hiệu lực của gói
    public bool IsPremium { get; set; } = false;
    public DateTime? PremiumExpiresAt { get; set; }

    // 1 User có 1 Profile (1:1), Profile có thể null khi tài khoản vừa tạo
    public virtual Profile? Profile { get; set; }

    // 1 User có nhiều phim yêu thích (1:N qua bảng trung gian Favorite)
    public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();

    // 1 User có nhiều tin nhắn lịch sử AI Chat (1:N)
    public virtual ICollection<ChatLog> ChatLogs { get; set; } = new List<ChatLog>();
}