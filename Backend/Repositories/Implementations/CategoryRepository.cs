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
        // Tim kiem the loai theo ten khong phan biet hoa thuong
        return await _dbSet.FirstOrDefaultAsync(c => c.Name.ToLower() == name.ToLower());
    }

    public async Task<bool> ExistsByNameAsync(string name, int? excludeId = null)
    {
        // Su dung IgnoreQueryFilters de kiem tra tren toan bo bang, tranh loi vi pham unique constraint database khi da co ban ghi bi xoa mem
        var query = _dbSet.IgnoreQueryFilters().AsQueryable();
        if (excludeId.HasValue)
        {
            query = query.Where(c => c.Id != excludeId.Value);
        }
        return await query.AnyAsync(c => c.Name.ToLower() == name.Trim().ToLower());
    }
}
