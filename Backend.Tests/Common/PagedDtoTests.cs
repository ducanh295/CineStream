using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using CineStream.DTOs.Common;
using Xunit;

namespace Backend.Tests.Common;

// Bo kiem thu don vi cho cac DTO phan trang co ban
public class PagedDtoTests
{
    [Fact]
    public void PagedResult_KhoiTaoMacDinh_DanhSachRongVaSoLuongBangKhong()
    {
        // Arrange & Act
        var result = new PagedResult<string>();

        // Assert
        Assert.NotNull(result.Items);
        Assert.Empty(result.Items);
        Assert.Equal(0, result.TotalCount);
        Assert.Equal(0, result.PageNumber);
        Assert.Equal(0, result.PageSize);
        Assert.Equal(0, result.TotalPages);
    }

    [Theory]
    [InlineData(25, 10, 3)]
    [InlineData(20, 10, 2)]
    [InlineData(1, 10, 1)]
    [InlineData(0, 10, 0)]
    [InlineData(10, 0, 0)]
    public void PagedResult_TinhTongSoTrang_ChinhXac(int totalCount, int pageSize, int expectedTotalPages)
    {
        // Arrange
        var result = new PagedResult<int>
        {
            TotalCount = totalCount,
            PageSize = pageSize
        };

        // Act & Assert
        Assert.Equal(expectedTotalPages, result.TotalPages);
    }

    [Fact]
    public void PagedRequestDto_GiaTriMacDinh_Trang1KichThuoc10()
    {
        // Arrange & Act
        var request = new PagedRequestDto();

        // Assert
        Assert.Equal(1, request.PageNumber);
        Assert.Equal(10, request.PageSize);
    }

    [Theory]
    [InlineData(1, 10, true)]
    [InlineData(5, 50, true)]
    [InlineData(10, 100, true)]
    [InlineData(0, 10, false)]
    [InlineData(-1, 10, false)]
    [InlineData(1, 0, false)]
    [InlineData(1, 101, false)]
    [InlineData(1, -5, false)]
    public void PagedRequestDto_KiemTraRangBuocDuLieu_ChinhXac(int pageNumber, int pageSize, bool expectedIsValid)
    {
        // Arrange
        var request = new PagedRequestDto
        {
            PageNumber = pageNumber,
            PageSize = pageSize
        };

        var validationResults = new List<ValidationResult>();
        var validationContext = new ValidationContext(request);

        // Act
        bool isValid = Validator.TryValidateObject(request, validationContext, validationResults, true);

        // Assert
        Assert.Equal(expectedIsValid, isValid);
    }
}
