using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CineStream.DTOs.Auth;
using CineStream.DTOs.Common;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;
using Xunit;

namespace Backend.Tests.Auth;

// Bo kiem thu don vi cho chuc nang khoa tai khoan nguoi dung va chan dang nhap trong AuthService
public class UserLockTests
{
    private readonly FakeUserRepository _fakeUserRepo;
    private readonly AuthService _authService;

    public UserLockTests()
    {
        _fakeUserRepo = new FakeUserRepository();
        var fakeJwtService = new FakeJwtService();
        var fakeEmailService = new FakeEmailService();
        _authService = new AuthService(_fakeUserRepo, fakeJwtService, fakeEmailService);
    }

    [Fact]
    public void UserModel_GiaTriKhoiTao_ChuaBiKhoaVaKhongCoLyDo()
    {
        // Arrange & Act
        var user = new User();

        // Assert
        Assert.False(user.IsLocked);
        Assert.Null(user.LockReason);
    }

    [Fact]
    public async Task LoginAsync_TaiKhoanBiKhoa_TraVeLoiVaLyDoKhoa()
    {
        // Arrange: Tao tai khoan da kich hoat email nhung bi Quan tri vien khoa
        var passwordHash = BCrypt.Net.BCrypt.HashPassword("Password123");
        var lockedUser = new User
        {
            Id = 10,
            Username = "locked_user",
            Email = "locked@cinestream.com",
            PasswordHash = passwordHash,
            Role = UserRole.User,
            IsEmailConfirmed = true,
            IsLocked = true,
            LockReason = "Vi pham chinh sach cong dong"
        };
        _fakeUserRepo.SeedUser(lockedUser);

        var loginRequest = new LoginRequestDto
        {
            UsernameOrEmail = "locked_user",
            Password = "Password123"
        };

        // Act
        var response = await _authService.LoginAsync(loginRequest);

        // Assert
        Assert.False(response.Success);
        Assert.Contains("khóa", response.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("Vi pham chinh sach cong dong", response.Message);
        Assert.Null(response.Data);
    }

    [Fact]
    public async Task LoginAsync_TaiKhoanKhongBiKhoa_DangNhapThanhCong()
    {
        // Arrange: Tao tai khoan binh thuong
        var passwordHash = BCrypt.Net.BCrypt.HashPassword("Password123");
        var normalUser = new User
        {
            Id = 11,
            Username = "normal_user",
            Email = "normal@cinestream.com",
            PasswordHash = passwordHash,
            Role = UserRole.User,
            IsEmailConfirmed = true,
            IsLocked = false
        };
        _fakeUserRepo.SeedUser(normalUser);

        var loginRequest = new LoginRequestDto
        {
            UsernameOrEmail = "normal_user",
            Password = "Password123"
        };

        // Act
        var response = await _authService.LoginAsync(loginRequest);

        // Assert
        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal("fake_token_jwt", response.Data.Token);
    }
}

// Stub UserRepository phuc vu kiem thu
internal class FakeUserRepository : IUserRepository
{
    private readonly List<User> _users = new();

    public void SeedUser(User user) => _users.Add(user);

    public Task<User?> GetByEmailOrUsernameAsync(string identifier)
    {
        var clean = identifier.Trim().ToLower();
        var user = _users.Find(u => u.Email.ToLower() == clean || u.Username.ToLower() == clean);
        return Task.FromResult(user);
    }

    public Task<User?> GetByEmailAsync(string email) => Task.FromResult(_users.Find(u => u.Email.Equals(email, StringComparison.OrdinalIgnoreCase)));
    public Task<User?> GetByUsernameAsync(string username) => Task.FromResult(_users.Find(u => u.Username.Equals(username, StringComparison.OrdinalIgnoreCase)));
    public Task<User?> GetWithProfileAsync(int id) => Task.FromResult(_users.Find(u => u.Id == id));
    public Task<bool> EmailExistsAsync(string email) => Task.FromResult(_users.Exists(u => u.Email.Equals(email, StringComparison.OrdinalIgnoreCase)));
    public Task<bool> UsernameExistsAsync(string username) => Task.FromResult(_users.Exists(u => u.Username.Equals(username, StringComparison.OrdinalIgnoreCase)));

    public Task<User?> GetByIdAsync(int id) => Task.FromResult(_users.Find(u => u.Id == id));
    public Task<IReadOnlyList<User>> GetAllAsync() => Task.FromResult<IReadOnlyList<User>>(_users.AsReadOnly());
    public Task<User> AddAsync(User entity) { _users.Add(entity); return Task.FromResult(entity); }
    public void Update(User entity) { }
    public Task<bool> DeleteAsync(int id) => Task.FromResult(true);
    public Task<int> SaveChangesAsync() => Task.FromResult(1);

    public Task<User?> GetDetailWithStatsAsync(int id) => Task.FromResult(_users.Find(u => u.Id == id));
    public Task<IReadOnlyList<User>> GetPagedAsync(string? search, UserRole? role, bool? isLocked, int page, int pageSize)
    {
        var query = _users.AsEnumerable();
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
        var query = _users.AsEnumerable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var clean = search.Trim().ToLower();
            query = query.Where(u => u.Username.ToLower().Contains(clean) || u.Email.ToLower().Contains(clean));
        }
        if (role.HasValue) query = query.Where(u => u.Role == role.Value);
        if (isLocked.HasValue) query = query.Where(u => u.IsLocked == isLocked.Value);
        return Task.FromResult(query.Count());
    }

    public Task<bool> ConfirmedEmailExistsAsync(string email) => Task.FromResult(false);
    public Task<bool> ConfirmedUsernameExistsAsync(string username) => Task.FromResult(false);
    public Task<List<User>> GetUnconfirmedUsersByEmailOrUsernameAsync(string email, string username) => Task.FromResult(new List<User>());
    public Task HardDeleteAsync(User user) => Task.CompletedTask;
}

// Stub JwtService phuc vu kiem thu
internal class FakeJwtService : IJwtService
{
    public string GenerateToken(User user) => "fake_token_jwt";
}

// Stub EmailService phuc vu kiem thu
internal class FakeEmailService : IEmailService
{
    public Task SendEmailConfirmationAsync(string toEmail, string otpCode) => Task.CompletedTask;
    public Task SendPasswordResetAsync(string toEmail, string otpCode) => Task.CompletedTask;
}
