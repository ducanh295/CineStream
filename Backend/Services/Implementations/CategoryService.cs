using CineStream.DTOs.Categories;
using CineStream.DTOs.Common;
using CineStream.Models;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

public class CategoryService : ICategoryService
{
    private readonly ICategoryRepository _categoryRepo;

    public CategoryService(ICategoryRepository categoryRepo)
    {
        _categoryRepo = categoryRepo;
    }

    public async Task<ApiResponse<IReadOnlyList<CategoryDto>>> GetAllAsync()
    {
        // Truy vấn toàn bộ thể loại từ tầng dữ liệu và ánh xạ sang DTO kèm số lượng phim liên kết
        var categories = await _categoryRepo.GetAllAsync();
        var dtoList = new List<CategoryDto>();
        foreach (var c in categories)
        {
            var dto = MapToDto(c);
            dto.MovieCount = await _categoryRepo.CountMoviesAsync(c.Id);
            dtoList.Add(dto);
        }
        return ApiResponse<IReadOnlyList<CategoryDto>>.Ok(dtoList.AsReadOnly());
    }

    public async Task<ApiResponse<CategoryDto>> GetByIdAsync(int id)
    {
        // Tìm thể loại theo định danh, trả về lỗi 404 nếu không tồn tại
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null)
        {
            return ApiResponse<CategoryDto>.Fail("Khong tim thay the loai!");
        }

        var dto = MapToDto(category);
        dto.MovieCount = await _categoryRepo.CountMoviesAsync(id);
        return ApiResponse<CategoryDto>.Ok(dto);
    }

    public async Task<ApiResponse<CategoryDto>> CreateAsync(CreateCategoryDto dto)
    {
        // Kiểm tra dữ liệu đầu vào không được để trống
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            return ApiResponse<CategoryDto>.Fail("Ten the loai khong duoc de trong!");
        }

        var trimmedName = dto.Name.Trim();

        // Kiểm tra trùng lặp tên thể loại trước khi tạo mới
        bool nameExists = await _categoryRepo.ExistsByNameAsync(trimmedName);
        if (nameExists)
        {
            return ApiResponse<CategoryDto>.Fail("Ten the loai da ton tai!");
        }

        // Khởi tạo thực thể Category từ dữ liệu đầu vào và lưu vào cơ sở dữ liệu
        var category = new Category
        {
            Name = trimmedName,
            Description = dto.Description?.Trim()
        };

        await _categoryRepo.AddAsync(category);
        await _categoryRepo.SaveChangesAsync();

        return ApiResponse<CategoryDto>.Ok(MapToDto(category), "Tao the loai thanh cong!");
    }

    public async Task<ApiResponse<CategoryDto>> UpdateAsync(int id, UpdateCategoryDto dto)
    {
        // Kiểm tra dữ liệu đầu vào không được để trống
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            return ApiResponse<CategoryDto>.Fail("Ten the loai khong duoc de trong!");
        }

        // Kiểm tra thể loại cần cập nhật có tồn tại trong hệ thống không
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null)
        {
            return ApiResponse<CategoryDto>.Fail("Khong tim thay the loai!");
        }

        var trimmedName = dto.Name.Trim();

        // Kiểm tra trùng lặp tên với thể loại khác (loại trừ chính nó)
        bool nameExists = await _categoryRepo.ExistsByNameAsync(trimmedName, id);
        if (nameExists)
        {
            return ApiResponse<CategoryDto>.Fail("Ten the loai da ton tai!");
        }

        // Cập nhật các trường dữ liệu và ghi xuống cơ sở dữ liệu
        category.Name = trimmedName;
        category.Description = dto.Description?.Trim();

        _categoryRepo.Update(category);
        await _categoryRepo.SaveChangesAsync();

        return ApiResponse<CategoryDto>.Ok(MapToDto(category), "Cap nhat the loai thanh cong!");
    }

    public async Task<ApiResponse<bool>> DeleteAsync(int id)
    {
        // 1. Kiem tra the loai co ton tai trong he thong hay khong
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null)
        {
            return ApiResponse<bool>.Fail("Khong tim thay the loai!");
        }

        // 2. Chuan nghiep vu doanh nghiep: Kiem tra rang buoc toan ven du lieu voi phim
        int movieCount = await _categoryRepo.CountMoviesAsync(id);
        if (movieCount > 0)
        {
            return ApiResponse<bool>.Fail($"Khong the xoa the loai dang co {movieCount} bo phim lien ket! Vui long go the loai khoi cac phim lien quan truoc.");
        }

        // 3. Thuc hien xoa mem the loai theo dinh danh
        bool deleted = await _categoryRepo.DeleteAsync(id);
        if (!deleted)
        {
            return ApiResponse<bool>.Fail("Khong tim thay the loai!");
        }

        await _categoryRepo.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Xoa the loai thanh cong!");
    }

    // Ánh xạ thực thể Category sang CategoryDto để trả về cho client
    private static CategoryDto MapToDto(Category category)
    {
        return new CategoryDto
        {
            Id = category.Id,
            Name = category.Name,
            Description = category.Description
        };
    }
}
