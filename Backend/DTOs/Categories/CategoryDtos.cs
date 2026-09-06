namespace CineStream.DTOs.Categories;

// 💡 DTO trả về thông tin thể loại cho client
public class CategoryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
}

// 💡 DTO nhận từ client khi tạo thể loại mới (chỉ nhận trường cần thiết)
public class CreateCategoryDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
}

// 💡 DTO nhận từ client khi cập nhật thể loại
public class UpdateCategoryDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
}
