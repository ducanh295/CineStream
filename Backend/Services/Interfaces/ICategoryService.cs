using CineStream.DTOs.Categories;
using CineStream.DTOs.Common;

namespace CineStream.Services.Interfaces;

// Giao dien dich vu quan ly the loai phim, dinh nghia cac thao tac nghiep vu CRUD
public interface ICategoryService
{
    // Lay toan bo danh sach the loai hien co trong he thong
    Task<ApiResponse<IReadOnlyList<CategoryDto>>> GetAllAsync();

    // Lay chi tiet mot the loai theo dinh danh
    Task<ApiResponse<CategoryDto>> GetByIdAsync(int id);

    // Tao moi mot the loai tu du lieu dau vao cua client
    Task<ApiResponse<CategoryDto>> CreateAsync(CreateCategoryDto dto);

    // Cap nhat thong tin the loai theo dinh danh va du lieu moi
    Task<ApiResponse<CategoryDto>> UpdateAsync(int id, UpdateCategoryDto dto);

    // Xoa mem the loai theo dinh danh
    Task<ApiResponse<bool>> DeleteAsync(int id);
}
