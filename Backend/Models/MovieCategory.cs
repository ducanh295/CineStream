namespace CineStream.Models;

// 💡 Bảng trung gian M:N giữa Movie và Category (Composite Key: MovieId + CategoryId)
public class MovieCategory
{
    public int MovieId { get; set; }
    public int CategoryId { get; set; }

    // 💡 Navigation Property trỏ về 2 thực thể cha
    // null! báo cho C# biết EF Core sẽ tự load dữ liệu này, tránh warning CS8625 / CS8618
    public virtual Movie Movie { get; set; } = null!;
    public virtual Category Category { get; set; } = null!;
}