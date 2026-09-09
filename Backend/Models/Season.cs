using System.Collections.Generic;

namespace CineStream.Models;

public class Season : BaseEntity
{
    public int SeriesId { get; set; }
    public int SeasonNumber { get; set; }
    public string? Title { get; set; }

    // Khóa ngoại trỏ ngược về Series cha
    public virtual Series Series { get; set; } = null!;

    // 1 Season có nhiều Episode (Tập phim)
    public virtual ICollection<Episode> Episodes { get; set; } = new List<Episode>();
}
