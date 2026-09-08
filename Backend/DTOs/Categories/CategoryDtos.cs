using System.ComponentModel.DataAnnotations;

namespace CineStream.DTOs.Categories;

// DTO trả về thông tin thể loại cho client
public class CategoryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
}

// DTO nhận từ client khi tạo thể loại mới
public class CreateCategoryDto
{
    [Required(ErrorMessage = "Ten the loai khong duoc de trong!")]
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Ten the loai phai tu 1 den 100 ky tu!")]
    public string Name { get; set; } = string.Empty;

    [StringLength(500, ErrorMessage = "Mo ta the loai khong duoc vuot qua 500 ky tu!")]
    public string? Description { get; set; }
}

// DTO nhận từ client khi cập nhật thể loại
public class UpdateCategoryDto
{
    [Required(ErrorMessage = "Ten the loai khong duoc de trong!")]
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Ten the loai phai tu 1 den 100 ky tu!")]
    public string Name { get; set; } = string.Empty;

    [StringLength(500, ErrorMessage = "Mo ta the loai khong duoc vuot qua 500 ky tu!")]
    public string? Description { get; set; }
}
