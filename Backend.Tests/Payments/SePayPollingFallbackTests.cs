using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Xunit;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Services.Implementations;
using CineStream.Services.Interfaces;

namespace Backend.Tests.Payments;

// Bo kiem thu don vi cho co che SePay Polling Fallback theo quy trinh TDD
public class SePayPollingFallbackTests
{
    private readonly FakePaymentTransactionRepository _fakePaymentRepo;
    private readonly FakeUserRepositoryForPayment _fakeUserRepo;
    private readonly IConfiguration _configuration;

    public SePayPollingFallbackTests()
    {
        _fakePaymentRepo = new FakePaymentTransactionRepository();
        _fakeUserRepo = new FakeUserRepositoryForPayment();

        var inMemorySettings = new Dictionary<string, string?>
        {
            { "SePay:BankName", "MB" },
            { "SePay:AccountNumber", "0385941522" },
            { "SePay:AccountName", "NGUYEN KHAC DUC ANH" },
            { "SePay:ApiKey", "TEST_SEPAY_API_KEY" }
        };
        _configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();
    }

    [Fact]
    public async Task GetPaymentStatusAsync_DonHangDaThanhCong_TraVeCompletedVaKhongGoiSePayApi()
    {
        // Arrange
        bool httpCalled = false;
        var clientFactory = CreateMockHttpClientFactory(_ =>
        {
            httpCalled = true;
            return new HttpResponseMessage(HttpStatusCode.OK);
        });

        var paymentService = new PaymentService(
            _fakePaymentRepo,
            _fakeUserRepo,
            _configuration,
            null,
            clientFactory);

        var tx = new PaymentTransaction
        {
            Id = 1,
            UserId = 1,
            OrderCode = "CINE_SUCCESS_001",
            Amount = 2000m,
            PlanDurationDays = 30,
            Status = PaymentStatus.Success
        };
        await _fakePaymentRepo.AddAsync(tx);

        // Act
        var result = await paymentService.GetPaymentStatusAsync("CINE_SUCCESS_001");

        // Assert
        Assert.NotNull(result);
        Assert.True(result.IsCompleted);
        Assert.Equal("Success", result.Status);
        Assert.False(httpCalled);
    }

    [Fact]
    public async Task GetPaymentStatusAsync_DonHangPending_SePayCoGiaoDichKhop_TuDongDongBoVaKichHoatVip()
    {
        // Arrange
        var user = new User { Id = 101, Email = "user101@test.com", Username = "user101", IsPremium = false };
        _fakeUserRepo.Seed(user);

        var tx = new PaymentTransaction
        {
            Id = 10,
            UserId = 101,
            OrderCode = "CINE26092310043912",
            Amount = 2000m,
            PlanDurationDays = 30,
            Status = PaymentStatus.Pending
        };
        await _fakePaymentRepo.AddAsync(tx);

        var sepayJsonResponse = @"{
            ""status"": 200,
            ""transactions"": [
                {
                    ""id"": ""84019455"",
                    ""bank_brand_name"": ""MBBank"",
                    ""account_number"": ""0385941522"",
                    ""amount_in"": ""2000.00"",
                    ""transaction_content"": ""148227318669-CINE26092310043912-CHUYEN TIEN-MOMO"",
                    ""reference_number"": ""FT26266565971678""
                }
            ]
        }";

        var clientFactory = CreateMockHttpClientFactory(req =>
        {
            Assert.Equal("Bearer", req.Headers.Authorization?.Scheme);
            Assert.Equal("TEST_SEPAY_API_KEY", req.Headers.Authorization?.Parameter);

            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(sepayJsonResponse, Encoding.UTF8, "application/json")
            };
        });

        var paymentService = new PaymentService(
            _fakePaymentRepo,
            _fakeUserRepo,
            _configuration,
            null,
            clientFactory);

        // Act
        var result = await paymentService.GetPaymentStatusAsync("CINE26092310043912");

        // Assert
        Assert.NotNull(result);
        Assert.True(result.IsCompleted);
        Assert.Equal("Success", result.Status);

        // Kiem tra du lieu trong Database
        var savedTx = await _fakePaymentRepo.GetByOrderCodeAsync("CINE26092310043912");
        Assert.NotNull(savedTx);
        Assert.Equal(PaymentStatus.Success, savedTx.Status);
        Assert.Equal("FT26266565971678", savedTx.GatewayTransactionId);
        Assert.NotNull(savedTx.CompletedAt);

        // Kiem tra User duoc kich hoat VIP
        Assert.True(user.IsPremium);
        Assert.NotNull(user.PremiumExpiresAt);
        Assert.True(user.PremiumExpiresAt > DateTime.UtcNow.AddDays(29));
    }

    [Fact]
    public async Task GetPaymentStatusAsync_DonHangPending_SePayChuaCoGiaoDichKhop_GiuNguyenPending()
    {
        // Arrange
        var user = new User { Id = 102, Email = "user102@test.com", Username = "user102", IsPremium = false };
        _fakeUserRepo.Seed(user);

        var tx = new PaymentTransaction
        {
            Id = 11,
            UserId = 102,
            OrderCode = "CINE_NOT_FOUND_YET",
            Amount = 2000m,
            PlanDurationDays = 30,
            Status = PaymentStatus.Pending
        };
        await _fakePaymentRepo.AddAsync(tx);

        var sepayJsonResponse = @"{
            ""status"": 200,
            ""transactions"": [
                {
                    ""id"": ""84019000"",
                    ""amount_in"": ""50000.00"",
                    ""transaction_content"": ""OTHER TRANSACTION WITHOUT MATCHING CODE"",
                    ""reference_number"": ""FT_OTHER""
                }
            ]
        }";

        var clientFactory = CreateMockHttpClientFactory(_ => new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(sepayJsonResponse, Encoding.UTF8, "application/json")
        });

        var paymentService = new PaymentService(
            _fakePaymentRepo,
            _fakeUserRepo,
            _configuration,
            null,
            clientFactory);

        // Act
        var result = await paymentService.GetPaymentStatusAsync("CINE_NOT_FOUND_YET");

        // Assert
        Assert.NotNull(result);
        Assert.False(result.IsCompleted);
        Assert.Equal("Pending", result.Status);
        Assert.False(user.IsPremium);
    }

    [Fact]
    public async Task GetPaymentStatusAsync_DonHangPending_SePayChuyenKhongDuTien_KhongKichHoatVip()
    {
        // Arrange: Don hang 5000 VND nhung khach chi chuyen 2000 VND
        var user = new User { Id = 103, Email = "user103@test.com", Username = "user103", IsPremium = false };
        _fakeUserRepo.Seed(user);

        var tx = new PaymentTransaction
        {
            Id = 12,
            UserId = 103,
            OrderCode = "CINE_UNDERPAID",
            Amount = 5000m,
            PlanDurationDays = 90,
            Status = PaymentStatus.Pending
        };
        await _fakePaymentRepo.AddAsync(tx);

        var sepayJsonResponse = @"{
            ""status"": 200,
            ""transactions"": [
                {
                    ""id"": ""84019111"",
                    ""amount_in"": ""2000.00"",
                    ""transaction_content"": ""CHUYEN TIEN CINE_UNDERPAID"",
                    ""reference_number"": ""FT_UNDERPAID""
                }
            ]
        }";

        var clientFactory = CreateMockHttpClientFactory(_ => new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(sepayJsonResponse, Encoding.UTF8, "application/json")
        });

        var paymentService = new PaymentService(
            _fakePaymentRepo,
            _fakeUserRepo,
            _configuration,
            null,
            clientFactory);

        // Act
        var result = await paymentService.GetPaymentStatusAsync("CINE_UNDERPAID");

        // Assert
        Assert.NotNull(result);
        Assert.False(result.IsCompleted);
        Assert.Equal("Pending", result.Status);
        Assert.False(user.IsPremium);
    }

    [Fact]
    public async Task GetPaymentStatusAsync_KhiSePayBiLoiMang_XuLyAnToanVaKhongNemNgoaiLe()
    {
        // Arrange: Mock HttpClient tra ve HTTP 500
        var tx = new PaymentTransaction
        {
            Id = 13,
            UserId = 104,
            OrderCode = "CINE_ERROR_HANDLE",
            Amount = 2000m,
            PlanDurationDays = 30,
            Status = PaymentStatus.Pending
        };
        await _fakePaymentRepo.AddAsync(tx);

        var clientFactory = CreateMockHttpClientFactory(_ => new HttpResponseMessage(HttpStatusCode.InternalServerError));

        var paymentService = new PaymentService(
            _fakePaymentRepo,
            _fakeUserRepo,
            _configuration,
            null,
            clientFactory);

        // Act & Assert: Khong duoc quang Exception ma phai tra ve Pending an toan
        var result = await paymentService.GetPaymentStatusAsync("CINE_ERROR_HANDLE");
        Assert.NotNull(result);
        Assert.False(result.IsCompleted);
        Assert.Equal("Pending", result.Status);
    }

    private static IHttpClientFactory CreateMockHttpClientFactory(Func<HttpRequestMessage, HttpResponseMessage> handlerFunc)
    {
        var handler = new TestHttpMessageHandler(handlerFunc);
        var client = new HttpClient(handler);
        return new TestHttpClientFactory(client);
    }
}

// HttpMessageHandler gia lap de kiem thu Http request/response
internal class TestHttpMessageHandler : HttpMessageHandler
{
    private readonly Func<HttpRequestMessage, HttpResponseMessage> _handlerFunc;

    public TestHttpMessageHandler(Func<HttpRequestMessage, HttpResponseMessage> handlerFunc)
    {
        _handlerFunc = handlerFunc;
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        return Task.FromResult(_handlerFunc(request));
    }
}

// IHttpClientFactory gia lap cho moi truong kiem thu
internal class TestHttpClientFactory : IHttpClientFactory
{
    private readonly HttpClient _client;

    public TestHttpClientFactory(HttpClient client)
    {
        _client = client;
    }

    public HttpClient CreateClient(string name) => _client;
}
