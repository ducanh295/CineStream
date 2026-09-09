using CineStream.Models;

namespace CineStream.Repositories.Interfaces;

// Interface chuyên biệt cho thể loại, kế thừa đầy đủ CRUD từ IBaseRepository
public interface ICategoryRepository : IBaseRepository<Category>
{
    // Tìm thể loại theo tên
    Task<Category?> GetByNameAsync(string name);

    // Kiểm tra trùng lặp tên thể loại (loại trừ chính nó khi cập nhật)
    Task<bool> ExistsByNameAsync(string name, int? excludeId = null);
}
