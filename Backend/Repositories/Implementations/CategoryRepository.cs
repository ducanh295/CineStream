using Microsoft.EntityFrameworkCore;
using CineStream.Data;
using CineStream.Models;
using CineStream.Repositories.Interfaces;

namespace CineStream.Repositories.Implementations;

public class CategoryRepository : BaseRepository<Category>, ICategoryRepository
{
    public CategoryRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<Category?> GetByNameAsync(string name)
    {
        // Tìm kiếm thể loại theo tên không phân biệt hoa thường
        return await _dbSet.FirstOrDefaultAsync(c => c.Name.ToLower() == name.ToLower());
    }

    public async Task<bool> ExistsByNameAsync(string name, int? excludeId = null)
    {
        // Sử dụng IgnoreQueryFilters để kiểm tra trên toàn bộ bảng, tránh lỗi vi phạm ràng buộc duy nhất (Unique Constraint) trong cơ sở dữ liệu khi đã có bản ghi bị xóa mềm
        var query = _dbSet.IgnoreQueryFilters().AsQueryable();
        if (excludeId.HasValue)
        {
            query = query.Where(c => c.Id != excludeId.Value);
        }
        return await query.AnyAsync(c => c.Name.ToLower() == name.Trim().ToLower());
    }

    public async Task<int> CountMoviesAsync(int categoryId)
    {
        // Đếm số lượng phim chưa bị xóa đang liên kết với thể loại này thông qua bảng trung gian MovieCategory
        return await _context.Set<MovieCategory>()
            .CountAsync(mc => mc.CategoryId == categoryId && !mc.Movie.IsDeleted);
    }
}
