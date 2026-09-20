using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Xunit;
using CineStream.DTOs.Payments;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;

namespace Backend.Tests.Payments;

// Bo kiem thu don vi cho PaymentService theo quy trinh TDD
public class PaymentServiceTests
{
    private readonly FakePaymentTransactionRepository _fakePaymentRepo;
    private readonly FakeUserRepositoryForPayment _fakeUserRepo;
    private readonly IConfiguration _configuration;
    private readonly IPaymentService _paymentService;

    public PaymentServiceTests()
    {
        _fakePaymentRepo = new FakePaymentTransactionRepository();
        _fakeUserRepo = new FakeUserRepositoryForPayment();

        // Cau hinh gia lap SePay trong appsettings
        var inMemorySettings = new Dictionary<string, string?>
        {
            { "SePay:BankName", "MB" },
            { "SePay:AccountNumber", "0385941522" },
            { "SePay:AccountName", "NGUYEN KHAC DUC ANH" },
            { "SePay:ApiKey", "91OZTGEU9KRMCLX4GFRXARDCWHR0KNSYBIVFF3JVKWJ8IN1HYMEO4SN5DG7USZ0W" }
        };
        _configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();

        _paymentService = new PaymentService(_fakePaymentRepo, _fakeUserRepo, _configuration);
    }

    [Fact]
    public async Task CreatePaymentAsync_ValidPlan1M_CreatesPendingTransactionAndReturnsVietQR()
    {
        // Act
        var result = await _paymentService.CreatePaymentAsync(1, new CreatePaymentRequestDto { PlanType = "1M" });

        // Assert
        Assert.NotNull(result);
        Assert.StartsWith("CINE", result.OrderCode);
        Assert.Equal(2000m, result.Amount);
        Assert.Equal(30, result.PlanDurationDays);
        Assert.Equal("MB", result.BankName);
        Assert.Equal("0385941522", result.AccountNumber);
        Assert.Contains(result.OrderCode, result.QrCodeUrl);
        Assert.Contains("img.vietqr.io", result.QrCodeUrl);

        var saved = await _fakePaymentRepo.GetByOrderCodeAsync(result.OrderCode);
        Assert.NotNull(saved);
        Assert.Equal(PaymentStatus.Pending, saved.Status);
    }

    [Fact]
    public async Task CreatePaymentAsync_ValidPlan3M_AppliesCorrectPricing()
    {
        var result = await _paymentService.CreatePaymentAsync(1, new CreatePaymentRequestDto { PlanType = "3M" });
        Assert.Equal(5000m, result.Amount);
        Assert.Equal(90, result.PlanDurationDays);
    }

    [Fact]
    public async Task CreatePaymentAsync_ValidPlan1Y_AppliesCorrectPricing()
    {
        var result = await _paymentService.CreatePaymentAsync(1, new CreatePaymentRequestDto { PlanType = "1Y" });
        Assert.Equal(10000m, result.Amount);
        Assert.Equal(365, result.PlanDurationDays);
    }

    [Fact]
    public async Task CreatePaymentAsync_InvalidPlan_ThrowsArgumentException()
    {
        await Assert.ThrowsAsync<ArgumentException>(() =>
            _paymentService.CreatePaymentAsync(1, new CreatePaymentRequestDto { PlanType = "INVALID" }));
    }

    [Fact]
    public async Task ProcessSePayWebhookAsync_InvalidApiKey_ReturnsFalse()
    {
        var webhook = new SePayWebhookDto { Content = "CINE123", TransferAmount = 50000m, TransferType = "in" };
        var result = await _paymentService.ProcessSePayWebhookAsync("Apikey SAI_KEY", webhook);
        Assert.False(result);
    }

    [Fact]
    public async Task ProcessSePayWebhookAsync_ValidPayment_ActivatesUserPremiumAndSetsSuccess()
    {
        // Arrange: Tao user chua co VIP
        var user = new User { Id = 10, Email = "user@test.com", Username = "usertest", IsPremium = false, PremiumExpiresAt = null };
        _fakeUserRepo.Seed(user);

        // Tao don hang pending
        var transaction = new PaymentTransaction
        {
            Id = 1,
            UserId = 10,
            OrderCode = "CINE260911001",
            Amount = 50000m,
            PlanDurationDays = 30,
            Status = PaymentStatus.Pending
        };
        await _fakePaymentRepo.AddAsync(transaction);

        var webhook = new SePayWebhookDto
        {
            Id = 9999,
            Content = "CHUYEN TIEN CINE260911001 VIP",
            TransferAmount = 50000m,
            TransferType = "in",
            ReferenceCode = "FT_MB_9999"
        };

        // Act
        var result = await _paymentService.ProcessSePayWebhookAsync(
            "Apikey 91OZTGEU9KRMCLX4GFRXARDCWHR0KNSYBIVFF3JVKWJ8IN1HYMEO4SN5DG7USZ0W", webhook);

        // Assert
        Assert.True(result);
        Assert.Equal(PaymentStatus.Success, transaction.Status);
        Assert.Equal("FT_MB_9999", transaction.GatewayTransactionId);
        Assert.NotNull(transaction.CompletedAt);

        Assert.True(user.IsPremium);
        Assert.NotNull(user.PremiumExpiresAt);
        Assert.True(user.PremiumExpiresAt > DateTime.UtcNow.AddDays(29));
    }

    [Fact]
    public async Task ProcessSePayWebhookAsync_UserHasActivePremium_ExtendsExistingExpirationDate()
    {
        // Arrange: User dang co VIP con han 15 ngay
        var existingExpiry = DateTime.UtcNow.AddDays(15);
        var user = new User { Id = 20, Email = "vip@test.com", Username = "viptest", IsPremium = true, PremiumExpiresAt = existingExpiry };
        _fakeUserRepo.Seed(user);

        var transaction = new PaymentTransaction
        {
            Id = 2,
            UserId = 20,
            OrderCode = "CINE260911002",
            Amount = 50000m,
            PlanDurationDays = 30,
            Status = PaymentStatus.Pending
        };
        await _fakePaymentRepo.AddAsync(transaction);

        var webhook = new SePayWebhookDto
        {
            Id = 8888,
            Content = "THANH TOAN CINE260911002",
            TransferAmount = 50000m,
            TransferType = "in",
            ReferenceCode = "FT_MB_8888"
        };

        // Act
        var result = await _paymentService.ProcessSePayWebhookAsync(
            "Bearer 91OZTGEU9KRMCLX4GFRXARDCWHR0KNSYBIVFF3JVKWJ8IN1HYMEO4SN5DG7USZ0W", webhook);

        // Assert: Thoi han moi phai la 15 + 30 = 45 ngay
        Assert.True(result);
        Assert.True(user.PremiumExpiresAt > DateTime.UtcNow.AddDays(44));
    }

    [Fact]
    public async Task ProcessSePayWebhookAsync_Idempotency_AlreadySuccess_DoesNotExtendTwice()
    {
        // Arrange: Giao dich da hoan tat truoc do
        var fixedExpiry = DateTime.UtcNow.AddDays(30);
        var user = new User { Id = 30, Email = "idempotent@test.com", Username = "idempotent", IsPremium = true, PremiumExpiresAt = fixedExpiry };
        _fakeUserRepo.Seed(user);

        var transaction = new PaymentTransaction
        {
            Id = 3,
            UserId = 30,
            OrderCode = "CINE260911003",
            Amount = 50000m,
            PlanDurationDays = 30,
            Status = PaymentStatus.Success,
            GatewayTransactionId = "ALREADY_PROCESSED"
        };
        await _fakePaymentRepo.AddAsync(transaction);

        var webhook = new SePayWebhookDto
        {
            Id = 7777,
            Content = "CINE260911003",
            TransferAmount = 50000m,
            TransferType = "in",
            ReferenceCode = "ALREADY_PROCESSED"
        };

        // Act
        var result = await _paymentService.ProcessSePayWebhookAsync(
            "Apikey 91OZTGEU9KRMCLX4GFRXARDCWHR0KNSYBIVFF3JVKWJ8IN1HYMEO4SN5DG7USZ0W", webhook);

        // Assert: Van tra ve true nhung han su dung khong bi cong them
        Assert.True(result);
        Assert.Equal(fixedExpiry, user.PremiumExpiresAt);
    }

    [Fact]
    public async Task SimulatePaymentSuccessAsync_ValidPendingOrder_UpgradesUserToPremium()
    {
        var user = new User { Id = 40, Email = "sim@test.com", Username = "simuser", IsPremium = false };
        _fakeUserRepo.Seed(user);

        var transaction = new PaymentTransaction
        {
            Id = 4,
            UserId = 40,
            OrderCode = "CINE_SIM_001",
            Amount = 135000m,
            PlanDurationDays = 90,
            Status = PaymentStatus.Pending
        };
        await _fakePaymentRepo.AddAsync(transaction);

        var result = await _paymentService.SimulatePaymentSuccessAsync("CINE_SIM_001");

        Assert.True(result);
        Assert.Equal(PaymentStatus.Success, transaction.Status);
        Assert.StartsWith("SIMULATED_", transaction.GatewayTransactionId);
        Assert.True(user.IsPremium);
        Assert.True(user.PremiumExpiresAt > DateTime.UtcNow.AddDays(89));
    }
}

// Fake repositories phuc vu kiem thu don vi doc lap
public class FakePaymentTransactionRepository : IPaymentTransactionRepository
{
    private readonly List<PaymentTransaction> _transactions = new();

    public Task<PaymentTransaction?> GetByIdAsync(int id) =>
        Task.FromResult(_transactions.FirstOrDefault(t => t.Id == id && !t.IsDeleted));

    public Task<IReadOnlyList<PaymentTransaction>> GetAllAsync() =>
        Task.FromResult<IReadOnlyList<PaymentTransaction>>(_transactions.Where(t => !t.IsDeleted).ToList());

    public Task<PaymentTransaction> AddAsync(PaymentTransaction entity)
    {
        if (entity.Id == 0) entity.Id = _transactions.Count + 1;
        _transactions.Add(entity);
        return Task.FromResult(entity);
    }

    public void Update(PaymentTransaction entity)
    {
        var existing = _transactions.FirstOrDefault(t => t.Id == entity.Id);
        if (existing != null)
        {
            existing.Status = entity.Status;
            existing.GatewayTransactionId = entity.GatewayTransactionId;
            existing.CompletedAt = entity.CompletedAt;
            existing.UpdatedAt = DateTime.UtcNow;
        }
    }

    public Task<bool> DeleteAsync(int id)
    {
        var existing = _transactions.FirstOrDefault(t => t.Id == id);
        if (existing == null) return Task.FromResult(false);
        existing.IsDeleted = true;
        return Task.FromResult(true);
    }

    public Task<int> SaveChangesAsync() => Task.FromResult(1);

    public Task<PaymentTransaction?> GetByOrderCodeAsync(string orderCode) =>
        Task.FromResult(_transactions.FirstOrDefault(t => t.OrderCode == orderCode && !t.IsDeleted));

    public Task<PaymentTransaction?> GetByGatewayTransactionIdAsync(string gatewayTransactionId) =>
        Task.FromResult(_transactions.FirstOrDefault(t => t.GatewayTransactionId == gatewayTransactionId && !t.IsDeleted));

    public Task<IReadOnlyList<PaymentTransaction>> GetByUserIdAsync(int userId) =>
        Task.FromResult<IReadOnlyList<PaymentTransaction>>(_transactions.Where(t => t.UserId == userId && !t.IsDeleted).ToList());

    public Task<(IReadOnlyList<PaymentTransaction> Items, int TotalCount)> GetPagedAsync(int pageNumber, int pageSize)
    {
        var active = _transactions.Where(t => !t.IsDeleted).OrderByDescending(t => t.CreatedAt).ToList();
        var paged = active.Skip((pageNumber - 1) * pageSize).Take(pageSize).ToList();
        return Task.FromResult<(IReadOnlyList<PaymentTransaction>, int)>((paged, active.Count));
    }
}

public class FakeUserRepositoryForPayment : IUserRepository
{
    private readonly List<User> _users = new();

    public void Seed(User user) => _users.Add(user);

    public Task<User?> GetByIdAsync(int id) =>
        Task.FromResult(_users.FirstOrDefault(u => u.Id == id && !u.IsDeleted));

    public Task<IReadOnlyList<User>> GetAllAsync() =>
        Task.FromResult<IReadOnlyList<User>>(_users.Where(u => !u.IsDeleted).ToList());

    public Task<User> AddAsync(User entity)
    {
        if (entity.Id == 0) entity.Id = _users.Count + 1;
        _users.Add(entity);
        return Task.FromResult(entity);
    }

    public void Update(User entity)
    {
        var existing = _users.FirstOrDefault(u => u.Id == entity.Id);
        if (existing != null)
        {
            existing.IsPremium = entity.IsPremium;
            existing.PremiumExpiresAt = entity.PremiumExpiresAt;
            existing.UpdatedAt = DateTime.UtcNow;
        }
    }

    public Task<bool> DeleteAsync(int id) => Task.FromResult(true);
    public Task<int> SaveChangesAsync() => Task.FromResult(1);

    public Task<User?> GetByEmailAsync(string email) => Task.FromResult(_users.FirstOrDefault(u => u.Email == email));
    public Task<User?> GetByUsernameAsync(string username) => Task.FromResult(_users.FirstOrDefault(u => u.Username == username));
    public Task<User?> GetByEmailOrUsernameAsync(string identifier) => Task.FromResult(_users.FirstOrDefault(u => u.Email == identifier || u.Username == identifier));
    public Task<User?> GetWithProfileAsync(int id) => Task.FromResult(_users.FirstOrDefault(u => u.Id == id));
    public Task<bool> EmailExistsAsync(string email) => Task.FromResult(_users.Any(u => u.Email == email));
    public Task<bool> UsernameExistsAsync(string username) => Task.FromResult(_users.Any(u => u.Username == username));
    public Task<User?> GetDetailWithStatsAsync(int id) => Task.FromResult(_users.FirstOrDefault(u => u.Id == id));
    public Task<IReadOnlyList<User>> GetPagedAsync(string? search, UserRole? role, bool? isLocked, int page, int pageSize) =>
        Task.FromResult<IReadOnlyList<User>>(_users.Skip((page - 1) * pageSize).Take(pageSize).ToList());
    public Task<int> CountAsync(string? search, UserRole? role, bool? isLocked) => Task.FromResult(_users.Count);
    public Task<bool> ConfirmedEmailExistsAsync(string email) => Task.FromResult(false);
    public Task<bool> ConfirmedUsernameExistsAsync(string username) => Task.FromResult(false);
    public Task<List<User>> GetUnconfirmedUsersByEmailOrUsernameAsync(string email, string username) => Task.FromResult(new List<User>());
    public Task HardDeleteAsync(User user) => Task.CompletedTask;
}
