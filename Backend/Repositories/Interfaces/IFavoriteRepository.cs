using CineStream.Models;

namespace CineStream.Repositories.Interfaces;

// Interface riêng cho bảng liên kết Favorite (không kế thừa BaseEntity vì dùng Composite Key)
public interface IFavoriteRepository
{
    // Lấy danh sách phim yêu thích của 1 user (kèm thông tin Movie)
    Task<IReadOnlyList<Favorite>> GetByUserIdAsync(int userId);

    // Kiểm tra user đã thích bộ phim này chưa
    Task<bool> IsFavoriteAsync(int userId, int movieId);

    // Thêm phim vào danh sách yêu thích
    Task<bool> AddAsync(int userId, int movieId);

    // Xóa phim khỏi danh sách yêu thích
    Task<bool> RemoveAsync(int userId, int movieId);

    // Lưu thay đổi xuống DB
    Task<int> SaveChangesAsync();
}
