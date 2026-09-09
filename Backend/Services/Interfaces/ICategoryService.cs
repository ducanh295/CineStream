using CineStream.DTOs.Categories;
using CineStream.DTOs.Common;

namespace CineStream.Services.Interfaces;

// Giao diện dịch vụ quản lý thể loại phim, định nghĩa các thao tác nghiệp vụ CRUD
public interface ICategoryService
{
    // Lấy toàn bộ danh sách thể loại hiện có trong hệ thống
    Task<ApiResponse<IReadOnlyList<CategoryDto>>> GetAllAsync();

    // Lấy chi tiết một thể loại theo định danh
    Task<ApiResponse<CategoryDto>> GetByIdAsync(int id);

    // Tạo mới một thể loại từ dữ liệu đầu vào của client
    Task<ApiResponse<CategoryDto>> CreateAsync(CreateCategoryDto dto);

    // Cập nhật thông tin thể loại theo định danh và dữ liệu mới
    Task<ApiResponse<CategoryDto>> UpdateAsync(int id, UpdateCategoryDto dto);

    // Xóa mềm thể loại theo định danh
    Task<ApiResponse<bool>> DeleteAsync(int id);
}
