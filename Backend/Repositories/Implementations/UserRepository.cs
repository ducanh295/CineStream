using Microsoft.EntityFrameworkCore;
using CineStream.Data;
using CineStream.Models;
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
}
