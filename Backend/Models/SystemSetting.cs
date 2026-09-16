namespace CineStream.Models;

// Thực thể lưu trữ các tham số cấu hình động của hệ thống
public class SystemSetting : BaseEntity
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string? Description { get; set; }
}
