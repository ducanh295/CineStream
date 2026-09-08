using Microsoft.EntityFrameworkCore;
using CineStream.Data;
using CineStream.Models;
using CineStream.Repositories.Interfaces;

namespace CineStream.Repositories.Implementations;

public class MovieRepository : BaseRepository<Movie>, IMovieRepository
{
    public MovieRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<Movie?> GetWithCategoriesAsync(int id)
    {
        //  Include bảng liên kết MovieCategory và bảng Category để nạp thông tin thể loại
        return await _dbSet
            .Include(m => m.MovieCategories)
                .ThenInclude(mc => mc.Category)
            .FirstOrDefaultAsync(m => m.Id == id);
    }

    public async Task<IReadOnlyList<Movie>> GetAllWithCategoriesAsync()
    {
        return await _dbSet
            .AsNoTracking()
            .Include(m => m.MovieCategories)
                .ThenInclude(mc => mc.Category)
            .OrderByDescending(m => m.CreatedAt)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<Movie>> GetMoviesByCategoryIdAsync(int categoryId)
    {
        return await _dbSet
            .AsNoTracking()
            .Where(m => m.MovieCategories.Any(mc => mc.CategoryId == categoryId))
            .Include(m => m.MovieCategories)
                .ThenInclude(mc => mc.Category)
            .OrderByDescending(m => m.CreatedAt)
            .ToListAsync();
    }

    public async Task UpdateMovieCategoriesAsync(int movieId, List<int> categoryIds)
    {
        //  1. Lấy toàn bộ quan hệ thể loại cũ của phim này
        var currentCategories = await _context.MovieCategories
            .Where(mc => mc.MovieId == movieId)
            .ToListAsync();

        //  2. Xóa các quan hệ cũ khỏi bảng trung gian
        _context.MovieCategories.RemoveRange(currentCategories);

        //  3. Thêm các quan hệ thể loại mới
        var newCategories = categoryIds.Select(catId => new MovieCategory
        {
            MovieId = movieId,
            CategoryId = catId
        });

        await _context.MovieCategories.AddRangeAsync(newCategories);
    }
}
