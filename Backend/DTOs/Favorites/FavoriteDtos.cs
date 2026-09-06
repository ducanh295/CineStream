namespace CineStream.DTOs.Favorites;

// 💡 DTO hiển thị danh sách phim yêu thích của user
public class FavoriteDto
{
    public int MovieId { get; set; }
    public string MovieTitle { get; set; } = string.Empty;
    public string? PosterUrl { get; set; }
    public int? Duration { get; set; }
    public int? ReleaseYear { get; set; }
    public DateTime AddedAt { get; set; }
}

// 💡 DTO nhận vào khi bấm Thích phim
public class AddFavoriteDto
{
    public int MovieId { get; set; }
}
