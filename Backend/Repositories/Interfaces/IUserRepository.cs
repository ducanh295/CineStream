using System.Collections.Generic;
using System.Threading.Tasks;
using CineStream.Models;
using CineStream.Models.Enums;

namespace CineStream.Repositories.Interfaces;

public interface IUserRepository : IBaseRepository<User>
{
    // Tìm user theo Email
    Task<User?> GetByEmailAsync(string email);

    // Tìm user theo Username
    Task<User?> GetByUsernameAsync(string username);

    // Tìm user bằng Email hoặc Username (hữu ích cho Form đăng nhập)
    Task<User?> GetByEmailOrUsernameAsync(string identifier);

    // Lấy thông tin user kèm Profile
    Task<User?> GetWithProfileAsync(int id);

    // Kiểm tra email đã tồn tại hay chưa
    Task<bool> EmailExistsAsync(string email);

    // Kiểm tra username đã tồn tại hay chưa
    Task<bool> UsernameExistsAsync(string username);

    // Truy vấn chi tiết người dùng kèm thông tin Profile, danh sách Favorites và ChatLogs phục vụ thống kê
    Task<User?> GetDetailWithStatsAsync(int id);

    // Lấy danh sách người dùng phân trang kết hợp tìm kiếm từ khóa, lọc theo vai trò và trạng thái khóa
    Task<IReadOnlyList<User>> GetPagedAsync(string? search, UserRole? role, bool? isLocked, int page, int pageSize);

    // Đếm tổng số người dùng thỏa mãn điều kiện lọc phục vụ tính toán số trang
    Task<int> CountAsync(string? search, UserRole? role, bool? isLocked);
}
