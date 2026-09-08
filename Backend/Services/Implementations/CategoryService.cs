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
        // Truy van toan bo the loai tu tang du lieu va anh xa sang DTO
        var categories = await _categoryRepo.GetAllAsync();
        var result = categories.Select(MapToDto).ToList().AsReadOnly();
        return ApiResponse<IReadOnlyList<CategoryDto>>.Ok(result);
    }

    public async Task<ApiResponse<CategoryDto>> GetByIdAsync(int id)
    {
        // Tim the loai theo dinh danh, tra ve loi 404 neu khong ton tai
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null)
        {
            return ApiResponse<CategoryDto>.Fail("Khong tim thay the loai!");
        }

        return ApiResponse<CategoryDto>.Ok(MapToDto(category));
    }

    public async Task<ApiResponse<CategoryDto>> CreateAsync(CreateCategoryDto dto)
    {
        // Kiem tra du lieu dau vao khong duoc rong
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            return ApiResponse<CategoryDto>.Fail("Ten the loai khong duoc de trong!");
        }

        var trimmedName = dto.Name.Trim();

        // Kiem tra trung lap ten the loai truoc khi tao moi
        bool nameExists = await _categoryRepo.ExistsByNameAsync(trimmedName);
        if (nameExists)
        {
            return ApiResponse<CategoryDto>.Fail("Ten the loai da ton tai!");
        }

        // Khoi tao thuc the Category tu du lieu dau vao va luu vao co so du lieu
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
        // Kiem tra du lieu dau vao khong duoc rong
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            return ApiResponse<CategoryDto>.Fail("Ten the loai khong duoc de trong!");
        }

        // Kiem tra the loai can cap nhat co ton tai trong he thong khong
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null)
        {
            return ApiResponse<CategoryDto>.Fail("Khong tim thay the loai!");
        }

        var trimmedName = dto.Name.Trim();

        // Kiem tra trung lap ten voi the loai khac (loai tru chinh no)
        bool nameExists = await _categoryRepo.ExistsByNameAsync(trimmedName, id);
        if (nameExists)
        {
            return ApiResponse<CategoryDto>.Fail("Ten the loai da ton tai!");
        }

        // Cap nhat cac truong du lieu va ghi xuong co so du lieu
        category.Name = trimmedName;
        category.Description = dto.Description?.Trim();

        _categoryRepo.Update(category);
        await _categoryRepo.SaveChangesAsync();

        return ApiResponse<CategoryDto>.Ok(MapToDto(category), "Cap nhat the loai thanh cong!");
    }

    public async Task<ApiResponse<bool>> DeleteAsync(int id)
    {
        // Thuc hien xoa mem the loai theo dinh danh
        bool deleted = await _categoryRepo.DeleteAsync(id);
        if (!deleted)
        {
            return ApiResponse<bool>.Fail("Khong tim thay the loai!");
        }

        await _categoryRepo.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Xoa the loai thanh cong!");
    }

    // Anh xa thuc the Category sang CategoryDto de tra ve cho client
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
