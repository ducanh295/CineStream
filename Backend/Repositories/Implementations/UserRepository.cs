using Microsoft.EntityFrameworkCore;
using CineStream.Data;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Repositories.Interfaces;

namespace CineStream.Repositories.Implementations;

public class UserRepository : BaseRepository<User>, IUserRepository
{
    public UserRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        var cleanEmail = email.Trim().ToLower();
        return await _dbSet
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == cleanEmail);
    }

    public async Task<User?> GetByUsernameAsync(string username)
    {
        var cleanUsername = username.Trim().ToLower();
        return await _dbSet
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Username.ToLower() == cleanUsername);
    }

    public async Task<User?> GetByEmailOrUsernameAsync(string identifier)
    {
        var cleanIdentifier = identifier.Trim().ToLower();
        return await _dbSet
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == cleanIdentifier || u.Username.ToLower() == cleanIdentifier);
    }

    public async Task<User?> GetWithProfileAsync(int id)
    {
        return await _dbSet
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<bool> EmailExistsAsync(string email)
    {
        // Su dung IgnoreQueryFilters de kiem tra tren toan bo co so du lieu bao gom ban ghi da xoa mem
        // Tranh xung dot Unique Constraint IX_Users_Email trong PostgreSQL
        var cleanEmail = email.Trim().ToLower();
        return await _dbSet.IgnoreQueryFilters().AnyAsync(u => u.Email.ToLower() == cleanEmail);
    }

    public async Task<bool> UsernameExistsAsync(string username)
    {
        // Su dung IgnoreQueryFilters de kiem tra tren toan bo co so du lieu bao gom ban ghi da xoa mem
        // Tranh xung dot Unique Constraint IX_Users_Username trong PostgreSQL
        var cleanUsername = username.Trim().ToLower();
        return await _dbSet.IgnoreQueryFilters().AnyAsync(u => u.Username.ToLower() == cleanUsername);
    }

    public async Task<User?> GetDetailWithStatsAsync(int id)
    {
        // Nap kem Profile, Favorites va ChatLogs de dem tong so luong hoat dong thuc te
        return await _dbSet
            .Include(u => u.Profile)
            .Include(u => u.Favorites)
            .Include(u => u.ChatLogs)
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<IReadOnlyList<User>> GetPagedAsync(string? search, UserRole? role, bool? isLocked, int page, int pageSize)
    {
        var query = _dbSet.Include(u => u.Profile).AsQueryable();

        // Loc theo tu khoa tim kiem tren Username hoac Email
        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToLower();
            query = query.Where(u => u.Username.ToLower().Contains(keyword) || u.Email.ToLower().Contains(keyword));
        }

        // Loc theo vai tro nguoi dung (Admin hoac User)
        if (role.HasValue)
        {
            query = query.Where(u => u.Role == role.Value);
        }

        // Loc theo trang thai khoa tai khoan
        if (isLocked.HasValue)
        {
            query = query.Where(u => u.IsLocked == isLocked.Value);
        }

        // Sap xep nguoi dung moi nhat len dau va cat phan trang theo yeu cau
        return await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<int> CountAsync(string? search, UserRole? role, bool? isLocked)
    {
        var query = _dbSet.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToLower();
            query = query.Where(u => u.Username.ToLower().Contains(keyword) || u.Email.ToLower().Contains(keyword));
        }

        if (role.HasValue)
        {
            query = query.Where(u => u.Role == role.Value);
        }

        if (isLocked.HasValue)
        {
            query = query.Where(u => u.IsLocked == isLocked.Value);
        }

        return await query.CountAsync();
    }
}
