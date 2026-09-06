using Microsoft.EntityFrameworkCore;
using VietFlix.Data;
using VietFlix.Models;
using VietFlix.Repositories.Interfaces;

namespace VietFlix.Repositories.Implementations;

public class UserRepository : BaseRepository<User>, IUserRepository
{
    public UserRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _dbSet
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == email.ToLower());
    }

    public async Task<User?> GetByUsernameAsync(string username)
    {
        return await _dbSet
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Username.ToLower() == username.ToLower());
    }

    public async Task<User?> GetByEmailOrUsernameAsync(string identifier)
    {
        var lower = identifier.ToLower();
        return await _dbSet
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == lower || u.Username.ToLower() == lower);
    }

    public async Task<User?> GetWithProfileAsync(int id)
    {
        return await _dbSet
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<bool> EmailExistsAsync(string email)
    {
        return await _dbSet.AnyAsync(u => u.Email.ToLower() == email.ToLower());
    }

    public async Task<bool> UsernameExistsAsync(string username)
    {
        return await _dbSet.AnyAsync(u => u.Username.ToLower() == username.ToLower());
    }
}
