using CineStream.Models;

namespace CineStream.Repositories.Interfaces;

public interface ISeriesRepository : IBaseRepository<Series>
{
    // Lấy chi tiết Series kèm danh sách Seasons và các Episodes bên trong
    Task<Series?> GetWithDetailsAsync(int id);

    // Lấy tất cả Series kèm thông tin mùa
    Task<IReadOnlyList<Series>> GetAllWithSeasonsAsync();
}
