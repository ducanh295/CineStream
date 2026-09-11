using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;
using CineStream.Controllers;
using CineStream.DTOs.Common;
using CineStream.DTOs.Payments;
using CineStream.Services.Interfaces;

namespace Backend.Tests.Payments;

// Bo kiem thu don vi cho PaymentsController theo quy trinh TDD
public class PaymentsControllerTests
{
    private readonly FakePaymentService _fakePaymentService;
    private readonly PaymentsController _controller;

    public PaymentsControllerTests()
    {
        _fakePaymentService = new FakePaymentService();
        _controller = new PaymentsController(_fakePaymentService);

        // Gia lap HttpContext voi User Claims (UserId = 1)
        var user = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "1"),
            new Claim(ClaimTypes.Email, "test@cinestream.com"),
            new Claim(ClaimTypes.Role, "Admin")
        }, "TestAuth"));

        _controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = user }
        };
    }

    [Fact]
    public async Task CreatePayment_ValidPlan_ReturnsOkWithPaymentInfo()
    {
        var dto = new CreatePaymentRequestDto { PlanType = "1M" };
        var actionResult = await _controller.CreatePayment(dto);

        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<PaymentResponseDto>>(okResult.Value);

        Assert.True(response.Success);
        Assert.NotNull(response.Data);
        Assert.Equal("CINE_TEST_001", response.Data.OrderCode);
    }

    [Fact]
    public async Task CreatePayment_InvalidPlan_ReturnsBadRequest()
    {
        var dto = new CreatePaymentRequestDto { PlanType = "INVALID" };
        var actionResult = await _controller.CreatePayment(dto);

        var badRequest = Assert.IsType<BadRequestObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<PaymentResponseDto>>(badRequest.Value);
        Assert.False(response.Success);
    }

    [Fact]
    public async Task ProcessSePayWebhook_InvalidAuth_ReturnsUnauthorized()
    {
        var webhookDto = new SePayWebhookDto { Content = "CINE_TEST", TransferAmount = 50000m };
        var actionResult = await _controller.ProcessSePayWebhook("Apikey WRONG", webhookDto);

        Assert.IsType<UnauthorizedObjectResult>(actionResult);
    }

    [Fact]
    public async Task ProcessSePayWebhook_ValidPayload_ReturnsOk()
    {
        var webhookDto = new SePayWebhookDto { Content = "CINE_TEST_001", TransferAmount = 50000m };
        var actionResult = await _controller.ProcessSePayWebhook("Apikey 91OZTGEU9KRMCLX4GFRXARDCWHR0KNSYBIVFF3JVKWJ8IN1HYMEO4SN5DG7USZ0W", webhookDto);

        Assert.IsType<OkObjectResult>(actionResult);
    }

    [Fact]
    public async Task GetPaymentStatus_NotFound_ReturnsNotFound()
    {
        var actionResult = await _controller.GetPaymentStatus("NON_EXISTING");
        Assert.IsType<NotFoundObjectResult>(actionResult.Result);
    }

    [Fact]
    public async Task GetPaymentStatus_Found_ReturnsOk()
    {
        var actionResult = await _controller.GetPaymentStatus("CINE_TEST_001");
        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<PaymentStatusResponseDto>>(okResult.Value);
        Assert.True(response.Success);
        Assert.Equal("CINE_TEST_001", response.Data?.OrderCode);
    }

    [Fact]
    public async Task SimulatePayment_InvalidOrder_ReturnsBadRequest()
    {
        var actionResult = await _controller.SimulatePayment("NON_EXISTING");
        Assert.IsType<BadRequestObjectResult>(actionResult.Result);
    }

    [Fact]
    public async Task SimulatePayment_ValidOrder_ReturnsOk()
    {
        var actionResult = await _controller.SimulatePayment("CINE_TEST_001");
        var okResult = Assert.IsType<OkObjectResult>(actionResult.Result);
        var response = Assert.IsType<ApiResponse<bool>>(okResult.Value);
        Assert.True(response.Success);
    }
}

// Fake PaymentService phuc vu kiem thu don vi Controller doc lap
public class FakePaymentService : IPaymentService
{
    public Task<PaymentResponseDto> CreatePaymentAsync(int userId, CreatePaymentRequestDto dto)
    {
        if (dto.PlanType == "INVALID")
        {
            throw new ArgumentException("Goi khong hop le");
        }

        return Task.FromResult(new PaymentResponseDto
        {
            OrderCode = "CINE_TEST_001",
            Amount = 50000m,
            PlanDurationDays = 30,
            BankName = "MB",
            AccountNumber = "0385941522",
            AccountName = "NGUYEN KHAC DUC ANH",
            Description = "CINE_TEST_001",
            QrCodeUrl = "https://img.vietqr.io/image/MB-0385941522-compact.png"
        });
    }

    public Task<bool> ProcessSePayWebhookAsync(string? authHeader, SePayWebhookDto webhookDto)
    {
        if (authHeader != null && authHeader.Contains("91OZTGEU9KRMCLX4GFRXARDCWHR0KNSYBIVFF3JVKWJ8IN1HYMEO4SN5DG7USZ0W"))
        {
            return Task.FromResult(true);
        }
        return Task.FromResult(false);
    }

    public Task<PaymentStatusResponseDto?> GetPaymentStatusAsync(string orderCode)
    {
        if (orderCode == "CINE_TEST_001")
        {
            return Task.FromResult<PaymentStatusResponseDto?>(new PaymentStatusResponseDto
            {
                OrderCode = "CINE_TEST_001",
                Status = "Success",
                IsCompleted = true
            });
        }
        return Task.FromResult<PaymentStatusResponseDto?>(null);
    }

    public Task<bool> SimulatePaymentSuccessAsync(string orderCode)
    {
        return Task.FromResult(orderCode == "CINE_TEST_001");
    }

    public Task<IReadOnlyList<PaymentTransactionDto>> GetUserHistoryAsync(int userId)
    {
        return Task.FromResult<IReadOnlyList<PaymentTransactionDto>>(new List<PaymentTransactionDto>());
    }

    public Task<(IReadOnlyList<PaymentTransactionDto> Items, int TotalCount)> GetAdminAllTransactionsAsync(int pageNumber, int pageSize)
    {
        return Task.FromResult<(IReadOnlyList<PaymentTransactionDto>, int)>((new List<PaymentTransactionDto>(), 0));
    }
}
