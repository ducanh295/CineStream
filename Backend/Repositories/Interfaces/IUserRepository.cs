using CineStream.Models;

namespace CineStream.Repositories.Interfaces;

public interface IUserRepository : IBaseRepository<User>
{
    // 💡 Tìm user theo Email
    Task<User?> GetByEmailAsync(string email);

    // 💡 Tìm user theo Username
    Task<User?> GetByUsernameAsync(string username);

    // 💡 Tìm user bằng Email hoặc Username (hữu ích cho Form đăng nhập)
    Task<User?> GetByEmailOrUsernameAsync(string identifier);

    // 💡 Lấy thông tin user kèm Profile
    Task<User?> GetWithProfileAsync(int id);

    // 💡 Kiểm tra email đã tồn tại hay chưa
    Task<bool> EmailExistsAsync(string email);

    // 💡 Kiểm tra username đã tồn tại hay chưa
    Task<bool> UsernameExistsAsync(string username);
}
