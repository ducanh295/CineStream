namespace CineStream.Models;

public class Profile : BaseEntity
{
    public int UserId { get; set; }
    public string? DisplayName { get; set; }
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }

    // 💡 Navigation Property ngược về User: Profile này thuộc về ai
    public virtual User User { get; set; } = null!;
}