using CineStream.DTOs.Categories;
using CineStream.Models.Enums;

namespace CineStream.DTOs.Movies;

//DTO tóm tắt hiển thị danh sách phim ngoài trang chủ/tìm kiếm (gọn nhẹ)
public class MovieDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? TrailerUrl { get; set; }
    public int? Duration { get; set; }
    public int? ReleaseYear { get; set; }
    public MovieType Type { get; set; }
    public int VideoStatus { get; set; }

    //Danh sách các thể loại của phim (dạng tóm tắt, ngăn chặn lỗi đệ quy vòng lặp)
    public List<CategoryDto> Categories { get; set; } = new();
}

//DTO chi tiết khi người dùng click vào xem phim (có VideoUrl để phát video stream)
public class MovieDetailDto : MovieDto
{
    public string? VideoUrl { get; set; }
    public string StreamType { get; set; } = "NONE";
    public DateTime CreatedAt { get; set; }
}

//DTO chuyên biệt cung cấp thông tin luồng phát cho Player (hỗ trợ cả HLS và CDN Direct MP4)
public class MoviePlaybackDto
{
    public int MovieId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? StreamUrl { get; set; }
    public string StreamType { get; set; } = "NONE"; // "HLS" | "DIRECT_MP4" | "NONE"
    public int VideoStatus { get; set; }
    public int? Duration { get; set; }
}

//DTO khi Admin gửi form tạo phim mới
public class CreateMovieDto
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? VideoUrl { get; set; }
    public string? TrailerUrl { get; set; }
    public int? Duration { get; set; }
    public int? ReleaseYear { get; set; }
    public MovieType Type { get; set; } = MovieType.Single;

    //Danh sách ID thể loại được chọn khi tạo phim (ví dụ: [1, 2, 4])
    public List<int> CategoryIds { get; set; } = new();
}

//DTO khi Admin cập nhật thông tin phim
public class UpdateMovieDto
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? VideoUrl { get; set; }
    public int VideoStatus { get; set; }
    public string? TrailerUrl { get; set; }
    public int? Duration { get; set; }
    public int? ReleaseYear { get; set; }
    public MovieType Type { get; set; }

    //Cập nhật lại danh sách ID thể loại
    public List<int> CategoryIds { get; set; } = new();
}
