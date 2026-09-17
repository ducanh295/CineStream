using System.ComponentModel.DataAnnotations;
using CineStream.DTOs.Categories;
using CineStream.Models.Enums;

namespace CineStream.DTOs.Movies;

// DTO hiển thị thông tin phim và luồng phát cho danh sách và quản trị
public class MovieDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? TrailerUrl { get; set; }
    public string? VideoUrl { get; set; }
    public string StreamType { get; set; } = "NONE";
    public int? Duration { get; set; }
    public int? ReleaseYear { get; set; }
    public MovieType Type { get; set; }
    public int VideoStatus { get; set; }

    // Danh sách các thể loại của phim dạng tóm tắt để ngăn vòng lặp tuần hoàn
    public List<CategoryDto> Categories { get; set; } = new();
}

// DTO chi tiết khi người dùng xem chi tiết phim (kế thừa đầy đủ thuộc tính từ MovieDto)
public class MovieDetailDto : MovieDto
{
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

// DTO khi Admin gửi form tạo phim mới
public class CreateMovieDto
{
    [Required(ErrorMessage = "Tieu de phim khong duoc de trong!")]
    [StringLength(255, MinimumLength = 1, ErrorMessage = "Tieu de phim phai tu 1 den 255 ky tu!")]
    public string Title { get; set; } = string.Empty;

    [StringLength(2000, ErrorMessage = "Mo ta phim khong duoc vuot qua 2000 ky tu!")]
    public string? Description { get; set; }

    [StringLength(500, ErrorMessage = "PosterUrl khong duoc vuot qua 500 ky tu!")]
    public string? PosterUrl { get; set; }

    [StringLength(500, ErrorMessage = "VideoUrl khong duoc vuot qua 500 ky tu!")]
    public string? VideoUrl { get; set; }

    [StringLength(500, ErrorMessage = "TrailerUrl khong duoc vuot qua 500 ky tu!")]
    public string? TrailerUrl { get; set; }

    [Range(1, 1000, ErrorMessage = "Thoi luong phim phai tu 1 den 1000 phut!")]
    public int? Duration { get; set; }

    [Range(1888, 2100, ErrorMessage = "Nam phat hanh phai tu nam 1888 den 2100!")]
    public int? ReleaseYear { get; set; }

    public MovieType Type { get; set; } = MovieType.Single;

    // Danh sách ID thể loại được chọn khi tạo phim (ví dụ: [1, 2, 4])
    public List<int> CategoryIds { get; set; } = new();
}

// DTO khi Admin cập nhật thông tin phim
public class UpdateMovieDto
{
    [Required(ErrorMessage = "Tieu de phim khong duoc de trong!")]
    [StringLength(255, MinimumLength = 1, ErrorMessage = "Tieu de phim phai tu 1 den 255 ky tu!")]
    public string Title { get; set; } = string.Empty;

    [StringLength(2000, ErrorMessage = "Mo ta phim khong duoc vuot qua 2000 ky tu!")]
    public string? Description { get; set; }

    [StringLength(500, ErrorMessage = "PosterUrl khong duoc vuot qua 500 ky tu!")]
    public string? PosterUrl { get; set; }

    [StringLength(500, ErrorMessage = "VideoUrl khong duoc vuot qua 500 ky tu!")]
    public string? VideoUrl { get; set; }

    public int VideoStatus { get; set; }

    [StringLength(500, ErrorMessage = "TrailerUrl khong duoc vuot qua 500 ky tu!")]
    public string? TrailerUrl { get; set; }

    [Range(1, 1000, ErrorMessage = "Thoi luong phim phai tu 1 den 1000 phut!")]
    public int? Duration { get; set; }

    [Range(1888, 2100, ErrorMessage = "Nam phat hanh phai tu nam 1888 den 2100!")]
    public int? ReleaseYear { get; set; }

    public MovieType Type { get; set; }

    // Cập nhật lại danh sách ID thể loại
    public List<int> CategoryIds { get; set; } = new();
}

// DTO mô tả luồng phát HLS có sẵn trong kho lưu trữ của máy chủ
public class AvailableStreamDto
{
    public string StreamKey { get; set; } = string.Empty;
    public string RelativeUrl { get; set; } = string.Empty;
    public string AbsoluteUrl { get; set; } = string.Empty;
    public string Format { get; set; } = "HLS";
    public int SegmentCount { get; set; }
    public double TotalSizeMb { get; set; }
    public bool IsAssigned { get; set; }
    public int? AssignedMovieId { get; set; }
    public string? AssignedMovieTitle { get; set; }
}

// DTO mô tả video mẫu CDN kiểm định sẵn
public class CdnPresetVideoDto
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string VideoUrl { get; set; } = string.Empty;
    public string Format { get; set; } = "MP4";
    public int Duration { get; set; }
}

// DTO phản hồi danh sách kho luồng phát HLS và video mẫu
public class AvailableStreamsResponseDto
{
    public List<AvailableStreamDto> InternalStreams { get; set; } = new();
    public List<CdnPresetVideoDto> CdnPresets { get; set; } = new();
}
