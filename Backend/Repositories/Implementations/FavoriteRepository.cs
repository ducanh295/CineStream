using Microsoft.EntityFrameworkCore;
using VietFlix.Data;
using VietFlix.Models;
using VietFlix.Repositories.Interfaces;

namespace VietFlix.Repositories.Implementations;

public class FavoriteRepository : IFavoriteRepository
{
    private readonly AppDbContext _context;

    public FavoriteRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyList<Favorite>> GetByUserIdAsync(int userId)
    {
        // 💡 Load danh sách phim yêu thích kèm thông tin Movie, sắp xếp theo thời gian thêm mới nhất
        return await _context.Favorites
            .AsNoTracking()
            .Include(f => f.Movie)
            .Where(f => f.UserId == userId)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();
    }

    public async Task<bool> IsFavoriteAsync(int userId, int movieId)
    {
        return await _context.Favorites
            .AnyAsync(f => f.UserId == userId && f.MovieId == movieId);
    }

    public async Task<bool> AddAsync(int userId, int movieId)
    {
        var exists = await IsFavoriteAsync(userId, movieId);
        if (exists) return false;

        var favorite = new Favorite
        {
            UserId = userId,
            MovieId = movieId,
            CreatedAt = DateTime.UtcNow
        };

        await _context.Favorites.AddAsync(favorite);
        return true;
    }

    public async Task<bool> RemoveAsync(int userId, int movieId)
    {
        var favorite = await _context.Favorites
            .FirstOrDefaultAsync(f => f.UserId == userId && f.MovieId == movieId);

        if (favorite == null) return false;

        _context.Favorites.Remove(favorite);
        return true;
    }

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }
}
