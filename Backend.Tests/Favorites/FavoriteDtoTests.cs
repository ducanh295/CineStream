using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using CineStream.DTOs.Favorites;
using Xunit;

namespace Backend.Tests.Favorites;

// Bo kiem thu don vi cho cac DTOs phan he Phim Yeu Thich (Favorites)
public class FavoriteDtoTests
{
    [Fact]
    public void FavoriteDto_KhoiTaoMacDinh_DanhSachTheLoaiKhongNull()
    {
        // Arrange & Act
        var dto = new FavoriteDto();

        // Assert
        Assert.NotNull(dto.Categories);
        Assert.Empty(dto.Categories);
        Assert.Equal(string.Empty, dto.Title);
    }

    [Fact]
    public void FavoriteDto_GanGiaTriHopLe_LuuTruChinhXac()
    {
        // Arrange
        var now = DateTime.UtcNow;
        var dto = new FavoriteDto
        {
            MovieId = 10,
            Title = "Đại Thoại Tây Du",
            Description = "Phim kinh điển Châu Tinh Trì",
            PosterUrl = "https://example.com/poster.jpg",
            TrailerUrl = "https://example.com/trailer.mp4",
            Duration = 105,
            ReleaseYear = 1995,
            Categories = new List<string> { "Hành Động", "Hài Hước" },
            AddedAt = now
        };

        // Assert
        Assert.Equal(10, dto.MovieId);
        Assert.Equal("Đại Thoại Tây Du", dto.Title);
        Assert.Equal(2, dto.Categories.Count);
        Assert.Equal(now, dto.AddedAt);
    }

    [Fact]
    public void FavoriteStatusDto_LuuTruDungTrangThaiYeuThich()
    {
        // Arrange & Act
        var dto = new FavoriteStatusDto
        {
            MovieId = 5,
            IsFavorite = true
        };

        // Assert
        Assert.Equal(5, dto.MovieId);
        Assert.True(dto.IsFavorite);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(-100)]
    public void AddFavoriteDto_MovieIdKhongHopLe_BaoLoiValidation(int invalidMovieId)
    {
        // Arrange
        var dto = new AddFavoriteDto { MovieId = invalidMovieId };
        var validationResults = ValidateModel(dto);

        // Assert
        Assert.NotEmpty(validationResults);
        Assert.Contains(validationResults, v => v.ErrorMessage!.Contains("Mã phim không hợp lệ"));
    }

    [Fact]
    public void AddFavoriteDto_MovieIdHopLe_ValidationThanhCong()
    {
        // Arrange
        var dto = new AddFavoriteDto { MovieId = 1 };
        var validationResults = ValidateModel(dto);

        // Assert
        Assert.Empty(validationResults);
    }

    private static List<ValidationResult> ValidateModel(object model)
    {
        var context = new ValidationContext(model, null, null);
        var results = new List<ValidationResult>();
        Validator.TryValidateObject(model, context, results, true);
        return results;
    }
}
