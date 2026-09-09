using System.Collections.Generic;
using CineStream.Models.Enums;

namespace CineStream.Models;

public class Movie : BaseEntity
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }

    // Đường dẫn file master.m3u8 phục vụ streaming HLS
    public string? VideoUrl { get; set; }

    // Trạng thái video: 0 = Chưa có, 1 = Đã upload & sẵn sàng phát
    public int VideoStatus { get; set; } = 0;

    public string? TrailerUrl { get; set; }
    public int? Duration { get; set; }
    public int? ReleaseYear { get; set; }
    public MovieType Type { get; set; } = MovieType.Single;

    // 1 Movie thuộc nhiều thể loại (M:N thông qua bảng MovieCategory)
    public virtual ICollection<MovieCategory> MovieCategories { get; set; } = new List<MovieCategory>();

    // 1 Movie có thể được nhiều User thêm vào danh sách yêu thích
    public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
}
