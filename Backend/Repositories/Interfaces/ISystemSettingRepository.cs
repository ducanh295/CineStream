using System.Threading.Tasks;
using CineStream.Models;

namespace CineStream.Repositories.Interfaces;

// Giao dien luu tru va truy van cac tham so cau hinh dong trong he thong
public interface ISystemSettingRepository : IBaseRepository<SystemSetting>
{
    Task<string?> GetValueAsync(string key);
    Task SetValueAsync(string key, string value, string? description = null);
}
