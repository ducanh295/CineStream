using Microsoft.EntityFrameworkCore;
using VietFlix.Data;
using VietFlix.Models;
using VietFlix.Repositories.Interfaces;

namespace VietFlix.Repositories.Implementations;

// 💡 Implementation dùng chung mọi câu lệnh CRUD cơ bản của EF Core
public class BaseRepository<T> : IBaseRepository<T> where T : BaseEntity
{
    // 💡 DbContext và DbSet được chia sẻ cho các class con kế thừa sử dụng
    protected readonly AppDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public BaseRepository(AppDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public virtual async Task<T?> GetByIdAsync(int id)
    {
        // 💡 Tìm theo khóa chính Id
        return await _dbSet.FindAsync(id);
    }

    public virtual async Task<IReadOnlyList<T>> GetAllAsync()
    {
        // 💡 AsNoTracking() giúp đọc dữ liệu nhanh hơn vì EF Core không cần theo dõi trạng thái thay đổi
        return await _dbSet.AsNoTracking().ToListAsync();
    }

    public virtual async Task<T> AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
        return entity;
    }

    public virtual void Update(T entity)
    {
        // 💡 Tự động cập nhật thời gian sửa đổi gần nhất
        entity.UpdatedAt = DateTime.UtcNow;
        _dbSet.Update(entity);
    }

    public virtual async Task<bool> DeleteAsync(int id)
    {
        var entity = await _dbSet.FindAsync(id);
        if (entity == null) return false;

        // 💡 Xóa mềm (Soft Delete) để bảo toàn dữ liệu và lịch sử hệ thống
        entity.IsDeleted = true;
        entity.DeletedAt = DateTime.UtcNow;
        _dbSet.Update(entity);
        return true;
    }

    public virtual async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }
}
