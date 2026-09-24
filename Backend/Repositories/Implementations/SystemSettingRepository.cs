using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using CineStream.Data;
using CineStream.Models;
using CineStream.Repositories.Interfaces;

namespace CineStream.Repositories.Implementations;

// Trien khai repository quan ly bang SystemSettings
public class SystemSettingRepository : BaseRepository<SystemSetting>, ISystemSettingRepository
{
    public SystemSettingRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<string?> GetValueAsync(string key)
    {
        var setting = await _dbSet.FirstOrDefaultAsync(s => s.Key == key);
        return setting?.Value;
    }

    public async Task SetValueAsync(string key, string value, string? description = null)
    {
        var setting = await _dbSet.FirstOrDefaultAsync(s => s.Key == key);
        if (setting == null)
        {
            setting = new SystemSetting
            {
                Key = key,
                Value = value,
                Description = description
            };
            await _dbSet.AddAsync(setting);
        }
        else
        {
            setting.Value = value;
            if (!string.IsNullOrWhiteSpace(description))
            {
                setting.Description = description;
            }
            setting.UpdatedAt = DateTime.UtcNow;
            _dbSet.Update(setting);
        }

        await _context.SaveChangesAsync();
    }
}
