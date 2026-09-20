using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Xunit;
using CineStream.Data;
using CineStream.DTOs.AI;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Services.Implementations;

namespace Backend.Tests.AI;

// Bo kiem thu don vi kiem tra co che khoa dac quyen Premium cho Tro ly AI CineBot
public class AiPremiumGatekeeperTests
{
    private readonly AppDbContext _context;
    private readonly IOptions<GeminiOptions> _options;

    public AiPremiumGatekeeperTests()
    {
        var dbOptions = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: $"AiGatekeeperDb_{Guid.NewGuid()}")
            .Options;

        _context = new AppDbContext(dbOptions);

        _options = Options.Create(new GeminiOptions
        {
            ApiKey = "",
            Model = "gemini-3.5-flash-lite",
            BaseUrl = "https://generativelanguage.googleapis.com/v1beta"
        });
    }

    [Fact]
    public async Task ChatAsync_FreeUser_ReturnsForbiddenErrorMessage()
    {
        // Arrange: Nguoi dung thong thuong chua dang ky Premium
        var freeUser = new User
        {
            Id = 101,
            Username = "free_user",
            Email = "free@cinestream.com",
            Role = UserRole.User,
            IsPremium = false
        };
        _context.Users.Add(freeUser);
        await _context.SaveChangesAsync();

        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);

        // Act: Goi chat khi chua co goi Premium
        var request = new ChatRequestDto { Message = "Gợi ý cho tôi phim hành động" };
        var result = await service.ChatAsync(freeUser.Id, request);

        // Assert: He thong chan va tra ve thong bao yeu cau nang cap
        Assert.NotNull(result);
        Assert.False(result.Success);
        Assert.Contains("Premium", result.Message);
    }

    [Fact]
    public async Task ChatAsync_ExpiredPremiumUser_ReturnsForbiddenErrorMessage()
    {
        // Arrange: Nguoi dung co goi Premium nhung da het han
        var expiredUser = new User
        {
            Id = 102,
            Username = "expired_user",
            Email = "expired@cinestream.com",
            Role = UserRole.User,
            IsPremium = true,
            PremiumExpiresAt = DateTime.UtcNow.AddDays(-1)
        };
        _context.Users.Add(expiredUser);
        await _context.SaveChangesAsync();

        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);

        // Act
        var request = new ChatRequestDto { Message = "Xin chào AI" };
        var result = await service.ChatAsync(expiredUser.Id, request);

        // Assert: Bi chan do goi da het han
        Assert.NotNull(result);
        Assert.False(result.Success);
        Assert.Contains("Premium", result.Message);
    }

    [Fact]
    public async Task ChatAsync_AdminUser_BypassesGatekeeperAndProceeds()
    {
        // Arrange: Tai khoan Quan tri vien (khong can phai la Premium van duoc dung)
        var adminUser = new User
        {
            Id = 103,
            Username = "admin_user",
            Email = "admin@cinestream.com",
            Role = UserRole.Admin,
            IsPremium = false
        };
        _context.Users.Add(adminUser);
        await _context.SaveChangesAsync();

        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);

        // Act
        var request = new ChatRequestDto { Message = "Phim hài" };
        var result = await service.ChatAsync(adminUser.Id, request);

        // Assert: Admin khong bi chan boi loi Premium
        Assert.NotNull(result);
        Assert.True(result.Success);
    }

    [Fact]
    public async Task ChatAsync_ActivePremiumUser_AllowedToChat()
    {
        // Arrange: Tai khoan hoi vien Premium con han su dung
        var premiumUser = new User
        {
            Id = 104,
            Username = "vip_user",
            Email = "vip@cinestream.com",
            Role = UserRole.User,
            IsPremium = true,
            PremiumExpiresAt = DateTime.UtcNow.AddMonths(1)
        };
        _context.Users.Add(premiumUser);
        await _context.SaveChangesAsync();

        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);

        // Act
        var request = new ChatRequestDto { Message = "Gợi ý phim khoa học viễn tưởng" };
        var result = await service.ChatAsync(premiumUser.Id, request);

        // Assert: Duoc phep tro chuyen va nhan phan hoi tu he thong
        Assert.NotNull(result);
        Assert.True(result.Success);
    }

    [Fact]
    public async Task GetChatHistoryAsync_FreeUser_ReturnsForbiddenErrorMessage()
    {
        // Arrange
        var freeUser = new User
        {
            Id = 105,
            Username = "free_user_history",
            Email = "free_history@cinestream.com",
            Role = UserRole.User,
            IsPremium = false
        };
        _context.Users.Add(freeUser);
        await _context.SaveChangesAsync();

        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);

        // Act
        var result = await service.GetChatHistoryAsync(freeUser.Id);

        // Assert
        Assert.NotNull(result);
        Assert.False(result.Success);
        Assert.Contains("Premium", result.Message);
    }

    [Fact]
    public async Task GetChatHistoryAsync_ActivePremiumUser_ReturnsChatLogs()
    {
        // Arrange
        var premiumUser = new User
        {
            Id = 106,
            Username = "vip_user_history",
            Email = "vip_history@cinestream.com",
            Role = UserRole.User,
            IsPremium = true,
            PremiumExpiresAt = DateTime.UtcNow.AddDays(10)
        };
        _context.Users.Add(premiumUser);
        _context.ChatLogs.Add(new ChatLog
        {
            UserId = premiumUser.Id,
            Message = "Tin nhắn lưu trữ",
            IsFromAI = false,
            CreatedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync();

        var service = new AIService(_context, new HttpClient(), _options, NullLogger<AIService>.Instance);

        // Act
        var result = await service.GetChatHistoryAsync(premiumUser.Id);

        // Assert
        Assert.NotNull(result);
        Assert.True(result.Success);
        Assert.NotEmpty(result.Data);
    }
}
