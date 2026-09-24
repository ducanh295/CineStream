using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CineStream.Models;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;
using Xunit;

namespace Backend.Tests.Categories;

// Bo kiem thu don vi cho CategoryService theo quy trinh TDD
public class CategoryServiceTests
{
    private readonly FakeCategoryRepository _fakeCategoryRepo;
    private readonly ICategoryService _categoryService;

    public CategoryServiceTests()
    {
        _fakeCategoryRepo = new FakeCategoryRepository();
        _categoryService = new CategoryService(_fakeCategoryRepo);
    }

    [Fact]
    public async Task DeleteAsync_KhiTheLoaiKhongTonTai_TraVeFailNotFound()
    {
        // Act: Xoa the loai co ID khong ton tai
        var result = await _categoryService.DeleteAsync(9999);

        // Assert: He thong phai bao loi khong tim thay
        Assert.False(result.Success);
        Assert.Equal("Khong tim thay the loai!", result.Message);
    }

    [Fact]
    public async Task DeleteAsync_KhiTheLoaiDangCoPhimLienKet_TraVeFailVaChanXoa()
    {
        // Arrange: Tao the loai co ID = 1 va gan 3 bo phim lien ket
        var category = new Category { Id = 1, Name = "Hành Động", Description = "Phim hanh dong gay can" };
        _fakeCategoryRepo.Seed(category);
        _fakeCategoryRepo.SetMovieCount(1, 3);

        // Act: Yeu cau xoa the loai
        var result = await _categoryService.DeleteAsync(1);

        // Assert: Nghiep vu phai chan khong cho xoa va tra ve thong diep canh bao ro rang
        Assert.False(result.Success);
        Assert.Contains("Khong the xoa the loai dang co 3 bo phim lien ket", result.Message);

        // Kiem tra the loai van con nguyen ven, chua bi danh dau IsDeleted
        var existingCategory = await _fakeCategoryRepo.GetByIdAsync(1);
        Assert.NotNull(existingCategory);
        Assert.False(existingCategory.IsDeleted);
    }

    [Fact]
    public async Task DeleteAsync_KhiTheLoaiKhongCoPhimLienKet_XoaThanhCong()
    {
        // Arrange: Tao the loai khong co phim nao lien ket
        var category = new Category { Id = 2, Name = "Kinh Dị", Description = "The loai moi chua co phim" };
        _fakeCategoryRepo.Seed(category);
        _fakeCategoryRepo.SetMovieCount(2, 0);

        // Act: Xoa the loai trong
        var result = await _categoryService.DeleteAsync(2);

        // Assert: Xoa thanh cong va the loai duoc danh dau xoa mem
        Assert.True(result.Success);
        Assert.Equal("Xoa the loai thanh cong!", result.Message);

        var existingCategory = await _fakeCategoryRepo.GetByIdAsync(2);
        Assert.True(existingCategory == null || existingCategory.IsDeleted);
    }
}

// Fake repository gia lap thao tac CSDL InMemory phuc vu kiem thu doc lap
internal class FakeCategoryRepository : ICategoryRepository
{
    private readonly List<Category> _categories = new();
    private readonly Dictionary<int, int> _movieCounts = new();

    public void Seed(Category category)
    {
        _categories.Add(category);
    }

    public void SetMovieCount(int categoryId, int count)
    {
        _movieCounts[categoryId] = count;
    }

    public Task<Category?> GetByIdAsync(int id)
    {
        var cat = _categories.FirstOrDefault(c => c.Id == id && !c.IsDeleted);
        return Task.FromResult(cat);
    }

    public Task<IReadOnlyList<Category>> GetAllAsync()
    {
        IReadOnlyList<Category> list = _categories.Where(c => !c.IsDeleted).ToList().AsReadOnly();
        return Task.FromResult(list);
    }

    public Task<Category> AddAsync(Category entity)
    {
        entity.Id = _categories.Count > 0 ? _categories.Max(c => c.Id) + 1 : 1;
        _categories.Add(entity);
        return Task.FromResult(entity);
    }

    public void Update(Category entity)
    {
        var existing = _categories.FirstOrDefault(c => c.Id == entity.Id);
        if (existing != null)
        {
            existing.Name = entity.Name;
            existing.Description = entity.Description;
            existing.IsDeleted = entity.IsDeleted;
            existing.DeletedAt = entity.DeletedAt;
            existing.UpdatedAt = entity.UpdatedAt;
        }
    }

    public Task<bool> DeleteAsync(int id)
    {
        var entity = _categories.FirstOrDefault(c => c.Id == id && !c.IsDeleted);
        if (entity == null) return Task.FromResult(false);

        entity.IsDeleted = true;
        entity.DeletedAt = System.DateTime.UtcNow;
        return Task.FromResult(true);
    }

    public Task<int> SaveChangesAsync()
    {
        return Task.FromResult(1);
    }

    public Task<Category?> GetByNameAsync(string name)
    {
        var cat = _categories.FirstOrDefault(c => !c.IsDeleted && string.Equals(c.Name, name, System.StringComparison.OrdinalIgnoreCase));
        return Task.FromResult(cat);
    }

    public Task<bool> ExistsByNameAsync(string name, int? excludeId = null)
    {
        var exists = _categories.Any(c =>
            (!excludeId.HasValue || c.Id != excludeId.Value) &&
            string.Equals(c.Name, name, System.StringComparison.OrdinalIgnoreCase));
        return Task.FromResult(exists);
    }

    public Task<int> CountMoviesAsync(int categoryId)
    {
        _movieCounts.TryGetValue(categoryId, out int count);
        return Task.FromResult(count);
    }
}
