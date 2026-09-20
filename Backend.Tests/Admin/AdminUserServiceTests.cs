using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CineStream.DTOs.Admin;
using CineStream.DTOs.Auth;
using CineStream.DTOs.Common;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;
using Xunit;

namespace Backend.Tests.Admin;

// Bo kiem thu don vi cho AdminUserService theo quy trinh TDD
public class AdminUserServiceTests
{
    private readonly FakeAdminUserRepository _fakeUserRepo;
    private readonly IAdminUserService _adminUserService;

    public AdminUserServiceTests()
    {
        _fakeUserRepo = new FakeAdminUserRepository();
        _adminUserService = new AdminUserService(_fakeUserRepo);
    }

    [Fact]
    public async Task GetUsersAsync_PhanTrangVaLoc_TraVeDanhSachChinhXac()
    {
        // Arrange
        _fakeUserRepo.Seed(new User { Id = 1, Username = "admin1", Email = "admin1@cinestream.com", Role = UserRole.Admin });
        _fakeUserRepo.Seed(new User { Id = 2, Username = "user1", Email = "user1@cinestream.com", Role = UserRole.User });
        _fakeUserRepo.Seed(new User { Id = 3, Username = "user2", Email = "user2@cinestream.com", Role = UserRole.User });

        // Act: Lay trang 1 voi kich thuoc 2
        var response = await _adminUserService.GetUsersAsync(search: null, role: null, isLocked: null, page: 1, pageSize: 2);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal(2, response.Data.Items.Count);
        Assert.Equal(3, response.Data.TotalCount);
        Assert.Equal(2, response.Data.TotalPages);
    }

    [Fact]
    public async Task GetUserDetailAsync_NguoiDungTonTai_TraVeThongKeHoatDong()
    {
        // Arrange
        var user = new User
        {
            Id = 5,
            Username = "movie_fan",
            Email = "fan@cinestream.com",
            Role = UserRole.User,
            Favorites = new List<Favorite>
            {
                new Favorite { UserId = 5, MovieId = 1, CreatedAt = DateTime.UtcNow.AddDays(-2) },
                new Favorite { UserId = 5, MovieId = 2, CreatedAt = DateTime.UtcNow.AddDays(-1) }
            },
            ChatLogs = new List<ChatLog>
            {
                new ChatLog { UserId = 5, Message = "Goi y phim", IsFromAI = false }
            }
        };
        _fakeUserRepo.Seed(user);

        // Act
        var response = await _adminUserService.GetUserDetailAsync(5);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal(2, response.Data.FavoriteCount);
        Assert.Equal(1, response.Data.ChatLogCount);
        Assert.NotNull(response.Data.LastFavoriteAt);
    }

    [Fact]
    public async Task LockUserAsync_AdminTuKhoaChinhMinh_BaoLoiPhongVe()
    {
        // Arrange
        var request = new LockUserRequestDto { Reason = "Thu tu khoa" };

        // Act: Admin Id = 1 co tinh tu khoa chinh minh (targetUserId = 1)
        var response = await _adminUserService.LockUserAsync(targetUserId: 1, request, currentAdminId: 1);

        // Assert
        Assert.False(response.Success);
        Assert.Contains("không thể tự khóa", response.Message);
    }

    [Fact]
    public async Task LockUserAsync_KhoaUserKhac_CapNhatTrangThaiVaLyDo()
    {
        // Arrange
        var user = new User { Id = 8, Username = "spammer", Email = "spammer@cinestream.com", IsLocked = false };
        _fakeUserRepo.Seed(user);
        var request = new LockUserRequestDto { Reason = "Spam tin nhan trong he thong" };

        // Act
        var response = await _adminUserService.LockUserAsync(targetUserId: 8, request, currentAdminId: 1);

        // Assert
        Assert.True(response.Success);
        var updated = await _fakeUserRepo.GetByIdAsync(8);
        Assert.NotNull(updated);
        Assert.True(updated.IsLocked);
        Assert.Equal("Spam tin nhan trong he thong", updated.LockReason);
    }

    [Fact]
    public async Task UnlockUserAsync_TaiKhoanDangBiKhoa_MoKhoaThanhCong()
    {
        // Arrange
        var user = new User { Id = 9, Username = "banned_user", Email = "banned@cinestream.com", IsLocked = true, LockReason = "Tam khoa" };
        _fakeUserRepo.Seed(user);

        // Act
        var response = await _adminUserService.UnlockUserAsync(targetUserId: 9);

        // Assert
        Assert.True(response.Success);
        var updated = await _fakeUserRepo.GetByIdAsync(9);
        Assert.NotNull(updated);
        Assert.False(updated.IsLocked);
        Assert.Null(updated.LockReason);
    }

    [Fact]
    public async Task DeleteUserAsync_AdminTuXoaChinhMinh_BaoLoiPhongVe()
    {
        // Act: Admin Id = 1 co tinh tu xoa chinh minh
        var response = await _adminUserService.DeleteUserAsync(targetUserId: 1, currentAdminId: 1);

        // Assert
        Assert.False(response.Success);
        Assert.Contains("không thể tự xóa", response.Message);
    }

    [Fact]
    public async Task DeleteUserAsync_XoaUserHopLe_ThanhCong()
    {
        // Arrange
        var user = new User { Id = 15, Username = "to_delete", Email = "delete@cinestream.com" };
        _fakeUserRepo.Seed(user);

        // Act
        var response = await _adminUserService.DeleteUserAsync(targetUserId: 15, currentAdminId: 1);

        // Assert
        Assert.True(response.Success);
        Assert.Null(await _fakeUserRepo.GetByIdAsync(15));
    }
}

// Stub repository ho tro day du cac phuong thuc quan tri phuc vu kiem thu
internal class FakeAdminUserRepository : IUserRepository
{
    private readonly List<User> _users = new();

    public void Seed(User user) => _users.Add(user);

    public Task<User?> GetByIdAsync(int id) => Task.FromResult(_users.FirstOrDefault(u => u.Id == id && !u.IsDeleted));
    public Task<IReadOnlyList<User>> GetAllAsync() => Task.FromResult<IReadOnlyList<User>>(_users.Where(u => !u.IsDeleted).ToList());
    public Task<User> AddAsync(User entity) { _users.Add(entity); return Task.FromResult(entity); }
    public void Update(User entity) { }
    public Task<bool> DeleteAsync(int id)
    {
        var item = _users.FirstOrDefault(u => u.Id == id);
        if (item == null) return Task.FromResult(false);
        item.IsDeleted = true;
        _users.Remove(item);
        return Task.FromResult(true);
    }
    public Task<int> SaveChangesAsync() => Task.FromResult(1);

    public Task<User?> GetDetailWithStatsAsync(int id) => Task.FromResult(_users.FirstOrDefault(u => u.Id == id));

    public Task<IReadOnlyList<User>> GetPagedAsync(string? search, UserRole? role, bool? isLocked, int page, int pageSize)
    {
        var query = _users.Where(u => !u.IsDeleted);
        if (!string.IsNullOrWhiteSpace(search))
        {
            var clean = search.Trim().ToLower();
            query = query.Where(u => u.Username.ToLower().Contains(clean) || u.Email.ToLower().Contains(clean));
        }
        if (role.HasValue) query = query.Where(u => u.Role == role.Value);
        if (isLocked.HasValue) query = query.Where(u => u.IsLocked == isLocked.Value);
        return Task.FromResult<IReadOnlyList<User>>(query.Skip((page - 1) * pageSize).Take(pageSize).ToList());
    }

    public Task<int> CountAsync(string? search, UserRole? role, bool? isLocked)
    {
        var query = _users.Where(u => !u.IsDeleted);
        if (!string.IsNullOrWhiteSpace(search))
        {
            var clean = search.Trim().ToLower();
            query = query.Where(u => u.Username.ToLower().Contains(clean) || u.Email.ToLower().Contains(clean));
        }
        if (role.HasValue) query = query.Where(u => u.Role == role.Value);
        if (isLocked.HasValue) query = query.Where(u => u.IsLocked == isLocked.Value);
        return Task.FromResult(query.Count());
    }

    public Task<User?> GetByEmailAsync(string email) => Task.FromResult(_users.FirstOrDefault(u => u.Email.Equals(email, StringComparison.OrdinalIgnoreCase)));
    public Task<User?> GetByUsernameAsync(string username) => Task.FromResult(_users.FirstOrDefault(u => u.Username.Equals(username, StringComparison.OrdinalIgnoreCase)));
    public Task<User?> GetByEmailOrUsernameAsync(string identifier) => Task.FromResult(_users.FirstOrDefault(u => u.Email.Equals(identifier, StringComparison.OrdinalIgnoreCase) || u.Username.Equals(identifier, StringComparison.OrdinalIgnoreCase)));
    public Task<User?> GetWithProfileAsync(int id) => Task.FromResult(_users.FirstOrDefault(u => u.Id == id));
    public Task<bool> EmailExistsAsync(string email) => Task.FromResult(_users.Any(u => u.Email.Equals(email, StringComparison.OrdinalIgnoreCase)));
    public Task<bool> UsernameExistsAsync(string username) => Task.FromResult(_users.Any(u => u.Username.Equals(username, StringComparison.OrdinalIgnoreCase)));
    public Task<bool> ConfirmedEmailExistsAsync(string email) => Task.FromResult(false);
    public Task<bool> ConfirmedUsernameExistsAsync(string username) => Task.FromResult(false);
    public Task<List<User>> GetUnconfirmedUsersByEmailOrUsernameAsync(string email, string username) => Task.FromResult(new List<User>());
    public Task HardDeleteAsync(User user) => Task.CompletedTask;
}
