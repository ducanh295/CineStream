using Microsoft.EntityFrameworkCore;
using VietFlix.Data;
using VietFlix.Models;
using VietFlix.Repositories.Interfaces;

namespace VietFlix.Repositories.Implementations;

public class SeriesRepository : BaseRepository<Series>, ISeriesRepository
{
    public SeriesRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<Series?> GetWithDetailsAsync(int id)
    {
        // 💡 Load cấu trúc lồng nhau: Series -> Seasons -> Episodes có sắp xếp theo thứ tự
        return await _dbSet
            .Include(s => s.Seasons.OrderBy(sn => sn.SeasonNumber))
                .ThenInclude(sn => sn.Episodes.OrderBy(e => e.EpisodeNumber))
            .FirstOrDefaultAsync(s => s.Id == id);
    }

    public async Task<IReadOnlyList<Series>> GetAllWithSeasonsAsync()
    {
        return await _dbSet
            .AsNoTracking()
            .Include(s => s.Seasons)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();
    }
}
