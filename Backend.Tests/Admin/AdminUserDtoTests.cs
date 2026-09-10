using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using CineStream.DTOs.Admin;
using CineStream.Models.Enums;
using Xunit;

namespace Backend.Tests.Admin;

// Bo kiem thu don vi cho cac DTO quan tri nguoi dung va rang buoc du lieu
public class AdminUserDtoTests
{
    [Theory]
    [InlineData("", false)]
    [InlineData(null, false)]
    [InlineData("   ", false)]
    [InlineData("Vi pham chinh sach binh luan", true)]
    public void LockUserRequestDto_KiemTraLyDoKhoa_ChinhXac(string? reason, bool expectedIsValid)
    {
        // Arrange
        var dto = new LockUserRequestDto
        {
            Reason = reason!
        };

        var validationResults = new List<ValidationResult>();
        var validationContext = new ValidationContext(dto);

        // Act
        bool isValid = Validator.TryValidateObject(dto, validationContext, validationResults, true);

        // Assert
        Assert.Equal(expectedIsValid, isValid);
    }

    [Fact]
    public void LockUserRequestDto_LyDoVuotQua500KyTu_BaoLoi()
    {
        // Arrange: Tao ly do dai 501 ky tu
        var dto = new LockUserRequestDto
        {
            Reason = new string('A', 501)
        };

        var validationResults = new List<ValidationResult>();
        var validationContext = new ValidationContext(dto);

        // Act
        bool isValid = Validator.TryValidateObject(dto, validationContext, validationResults, true);

        // Assert
        Assert.False(isValid);
        Assert.Contains(validationResults, v => v.ErrorMessage!.Contains("500"));
    }

    [Fact]
    public void AdminUserDetailDto_LuuTruDayDuChiSoHoatDong()
    {
        // Arrange & Act
        var now = DateTime.UtcNow;
        var detailDto = new AdminUserDetailDto
        {
            Id = 1,
            Username = "test_user",
            Email = "test@cinestream.com",
            Role = UserRole.User,
            IsEmailConfirmed = true,
            IsLocked = false,
            LockReason = null,
            CreatedAt = now,
            FavoriteCount = 5,
            ChatLogCount = 12,
            LastFavoriteAt = now.AddHours(-1)
        };

        // Assert
        Assert.Equal(1, detailDto.Id);
        Assert.Equal("test_user", detailDto.Username);
        Assert.Equal("test@cinestream.com", detailDto.Email);
        Assert.Equal(UserRole.User, detailDto.Role);
        Assert.Equal(5, detailDto.FavoriteCount);
        Assert.Equal(12, detailDto.ChatLogCount);
        Assert.Equal(now.AddHours(-1), detailDto.LastFavoriteAt);
    }
}
