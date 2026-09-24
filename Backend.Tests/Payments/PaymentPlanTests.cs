using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Xunit;
using CineStream.DTOs.Payments;
using CineStream.Models;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;

namespace Backend.Tests.Payments;

// Bo kiem thu cho chuc nang bang gia goi VIP va tinh nang sua gia admin theo TDD
public class PaymentPlanTests
{
    private readonly FakePaymentTransactionRepository _fakePaymentRepo;
    private readonly FakeUserRepositoryForPayment _fakeUserRepo;
    private readonly FakeSystemSettingRepository _fakeSystemSettingRepo;
    private readonly IConfiguration _configuration;
    private readonly IPaymentService _paymentService;

    public PaymentPlanTests()
    {
        _fakePaymentRepo = new FakePaymentTransactionRepository();
        _fakeUserRepo = new FakeUserRepositoryForPayment();
        _fakeSystemSettingRepo = new FakeSystemSettingRepository();

        var inMemorySettings = new Dictionary<string, string?>
        {
            { "SePay:BankName", "MB" },
            { "SePay:AccountNumber", "0385941522" },
            { "SePay:AccountName", "NGUYEN KHAC DUC ANH" },
            { "SePay:ApiKey", "TEST_API_KEY" }
        };
        _configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();

        _paymentService = new PaymentService(
            _fakePaymentRepo,
            _fakeUserRepo,
            _configuration,
            _fakeSystemSettingRepo);
    }

    [Fact]
    public async Task GetSubscriptionPlansAsync_TraVe3GoiMacDinhKhiChuaSuaGia()
    {
        // Act
        var plans = await _paymentService.GetSubscriptionPlansAsync();

        // Assert
        Assert.NotNull(plans);
        Assert.Equal(3, plans.Count);

        var plan1M = plans.FirstOrDefault(p => p.Id == "1M");
        Assert.NotNull(plan1M);
        Assert.Equal(2000m, plan1M.Price);
        Assert.Equal(30, plan1M.Days);

        var plan3M = plans.FirstOrDefault(p => p.Id == "3M");
        Assert.NotNull(plan3M);
        Assert.Equal(5000m, plan3M.Price);
        Assert.True(plan3M.Highlight);

        var plan1Y = plans.FirstOrDefault(p => p.Id == "1Y");
        Assert.NotNull(plan1Y);
        Assert.Equal(10000m, plan1Y.Price);
        Assert.Equal(365, plan1Y.Days);
    }

    [Fact]
    public async Task UpdatePlanPriceAsync_CapNhatGiaGoi1M_ThanhCongVaAnhHuongToiCreatePayment()
    {
        // Act: Quan tri vien sua gia goi 1M thanh 3500 VND
        var updated = await _paymentService.UpdatePlanPriceAsync("1M", 3500m);

        // Assert 1: Thong tin goi duoc cap nhat ngay
        Assert.NotNull(updated);
        Assert.Equal("1M", updated.Id);
        Assert.Equal(3500m, updated.Price);

        // Assert 2: Danh sach goi moi cung phan anh gia 3500 VND
        var plans = await _paymentService.GetSubscriptionPlansAsync();
        var plan1M = plans.First(p => p.Id == "1M");
        Assert.Equal(3500m, plan1M.Price);

        // Assert 3: Tao don hang VietQR moi voi goi 1M phai co gia moi 3500 VND
        var payment = await _paymentService.CreatePaymentAsync(1, new CreatePaymentRequestDto { PlanType = "1M" });
        Assert.Equal(3500m, payment.Amount);
        Assert.Contains("amount=3500", payment.QrCodeUrl);
    }

    [Fact]
    public async Task UpdatePlanPriceAsync_GiaNhoHon1000_NemNgoaiLeArgumentException()
    {
        // Act & Assert: Khong chap nhan gia < 1000 VND
        await Assert.ThrowsAsync<ArgumentException>(() =>
            _paymentService.UpdatePlanPriceAsync("1M", 500m));
    }

    [Fact]
    public async Task UpdatePlanPriceAsync_GoiKhongTonTai_NemNgoaiLeArgumentException()
    {
        // Act & Assert: Khong chap nhan ma goi khong hop le
        await Assert.ThrowsAsync<ArgumentException>(() =>
            _paymentService.UpdatePlanPriceAsync("INVALID_PLAN", 5000m));
    }
}

// Fake repository cho SystemSetting
internal class FakeSystemSettingRepository : ISystemSettingRepository
{
    private readonly Dictionary<string, string> _settings = new();

    public Task<string?> GetValueAsync(string key)
    {
        _settings.TryGetValue(key, out var val);
        return Task.FromResult<string?>(val);
    }

    public Task SetValueAsync(string key, string value, string? description = null)
    {
        _settings[key] = value;
        return Task.CompletedTask;
    }

    public Task<SystemSetting?> GetByIdAsync(int id) => Task.FromResult<SystemSetting?>(null);
    public Task<IReadOnlyList<SystemSetting>> GetAllAsync() => Task.FromResult<IReadOnlyList<SystemSetting>>(new List<SystemSetting>());
    public Task<SystemSetting> AddAsync(SystemSetting entity) => Task.FromResult(entity);
    public void Update(SystemSetting entity) { }
    public Task<bool> DeleteAsync(int id) => Task.FromResult(true);
    public Task<int> SaveChangesAsync() => Task.FromResult(1);
}
