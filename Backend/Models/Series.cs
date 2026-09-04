using System.Collections.Generic;

namespace VietFlix.Models;

public class Series : BaseEntity
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? TrailerUrl { get; set; }
    public int? ReleaseYear { get; set; }

    // 💡 1 Series có nhiều Season (Mùa phim)
    public virtual ICollection<Season> Seasons { get; set; } = new List<Season>();
}