using VietFlix.Models;

namespace VietFlix.Repositories.Interfaces;

// 💡 Interface generic dùng chung cho mọi Entity kế thừa từ BaseEntity
public interface IBaseRepository<T> where T : BaseEntity
{
    // 💡 Lấy một bản ghi theo Id (chỉ lấy bản ghi chưa xóa mềm)
    Task<T?> GetByIdAsync(int id);

    // 💡 Lấy toàn bộ danh sách bản ghi
    Task<IReadOnlyList<T>> GetAllAsync();

    // 💡 Thêm mới một bản ghi
    Task<T> AddAsync(T entity);

    // 💡 Đánh dấu cập nhật bản ghi
    void Update(T entity);

    // 💡 Xóa mềm (Soft Delete) theo Id
    Task<bool> DeleteAsync(int id);

    // 💡 Lưu các thay đổi xuống Database
    Task<int> SaveChangesAsync();
}
