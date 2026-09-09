using System;

namespace CineStream.Models;

// Bảng trung gian M:N giữa User và Movie (phim yêu thích), có thêm cột ngày thêm CreatedAt
public class Favorite
{
    public int UserId { get; set; }
    public int MovieId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Property trỏ về User và Movie
    public virtual User User { get; set; } = null!;
    public virtual Movie Movie { get; set; } = null!;
}
