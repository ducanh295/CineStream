using System.Collections.Generic;

namespace CineStream.Models;

public class Category : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }

    // 💡 1 thể loại chứa nhiều phim qua bảng trung gian MovieCategory
    public virtual ICollection<MovieCategory> MovieCategories { get; set; } = new List<MovieCategory>();
}
