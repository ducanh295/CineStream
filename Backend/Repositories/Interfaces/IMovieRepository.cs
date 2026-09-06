using CineStream.Models;

namespace CineStream.Repositories.Interfaces;

public interface IMovieRepository : IBaseRepository<Movie>
{
    // 💡 Lấy chi tiết phim kèm danh sách thể loại
    Task<Movie?> GetWithCategoriesAsync(int id);

    // 💡 Lấy tất cả phim kèm thể loại (sắp xếp mới nhất trước)
    Task<IReadOnlyList<Movie>> GetAllWithCategoriesAsync();

    // 💡 Lọc danh sách phim theo thể loại cụ thể
    Task<IReadOnlyList<Movie>> GetMoviesByCategoryIdAsync(int categoryId);

    // 💡 Cập nhật các liên kết thể loại trong bảng trung gian MovieCategories
    Task UpdateMovieCategoriesAsync(int movieId, List<int> categoryIds);
}
