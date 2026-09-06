using Microsoft.EntityFrameworkCore;
using VietFlix.Data;
using VietFlix.Models;
using VietFlix.Repositories.Interfaces;

namespace VietFlix.Repositories.Implementations;

public class CategoryRepository : BaseRepository<Category>, ICategoryRepository
{
    public CategoryRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<Category?> GetByNameAsync(string name)
    {
        // 💡 So sánh không phân biệt hoa thường
        return await _dbSet.FirstOrDefaultAsync(c => c.Name.ToLower() == name.ToLower());
    }

    public async Task<bool> ExistsByNameAsync(string name, int? excludeId = null)
    {
        var query = _dbSet.AsQueryable();
        if (excludeId.HasValue)
        {
            query = query.Where(c => c.Id != excludeId.Value);
        }
        return await query.AnyAsync(c => c.Name.ToLower() == name.ToLower());
    }
}
