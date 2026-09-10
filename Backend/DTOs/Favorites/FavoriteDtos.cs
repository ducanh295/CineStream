using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace CineStream.DTOs.Favorites;

// DTO thong tin mot bo phim trong danh sach yeu thich cua nguoi dung
public class FavoriteDto
{
    public int MovieId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? TrailerUrl { get; set; }
    public int? Duration { get; set; }
    public int? ReleaseYear { get; set; }
    public List<string> Categories { get; set; } = new();
    public DateTime AddedAt { get; set; }
}

// DTO kiem tra trang thai mot bo phim da duoc them vao danh sach yeu thich hay chua
public class FavoriteStatusDto
{
    public int MovieId { get; set; }
    public bool IsFavorite { get; set; }
}

// DTO tiep nhan yeu cau them phim vao danh sach yeu thich kem rang buoc du lieu
public class AddFavoriteDto
{
    [Required(ErrorMessage = "Mã phim không được để trống!")]
    [Range(1, int.MaxValue, ErrorMessage = "Mã phim không hợp lệ!")]
    public int MovieId { get; set; }
}
