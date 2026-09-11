using System;
using Xunit;
using CineStream.DTOs.Payments;
using CineStream.Repositories.Interfaces;
using CineStream.Repositories.Implementations;

namespace Backend.Tests.Payments;

public class PaymentRepositoryAndDtoTests
{
    // Kiem tra khoi tao CreatePaymentRequestDto dung dinh dang
    [Fact]
    public void CreatePaymentRequestDto_ShouldHoldPlanType()
    {
        var dto = new CreatePaymentRequestDto { PlanType = "1M" };
        Assert.Equal("1M", dto.PlanType);
    }

    // Kiem tra PaymentResponseDto giu dung thong tin Napas va VietQR
    [Fact]
    public void PaymentResponseDto_ShouldContainAllFields()
    {
        var dto = new PaymentResponseDto
        {
            OrderCode = "CINE999888",
            Amount = 50000m,
            PlanDurationDays = 30,
            BankName = "MB",
            AccountNumber = "0385941522",
            AccountName = "NGUYEN KHAC DUC ANH",
            Description = "CINE999888",
            QrCodeUrl = "https://img.vietqr.io/image/MB-0385941522-compact.png?amount=50000&addInfo=CINE999888&accountName=NGUYEN%20KHAC%20DUC%20ANH",
            CreatedAt = DateTime.UtcNow
        };

        Assert.Equal("CINE999888", dto.OrderCode);
        Assert.Equal(50000m, dto.Amount);
        Assert.Equal("MB", dto.BankName);
        Assert.Equal("0385941522", dto.AccountNumber);
        Assert.Contains("img.vietqr.io", dto.QrCodeUrl);
    }

    // Kiem tra SePayWebhookDto anh xa day du cac truong JSON do SePay gui ve
    [Fact]
    public void SePayWebhookDto_ShouldMatchSePayPayload()
    {
        var dto = new SePayWebhookDto
        {
            Id = 123456,
            Gateway = "MBBank",
            TransactionDate = "2026-09-11 19:30:00",
            AccountNumber = "0385941522",
            Content = "CINE999888 chuyen tien goi VIP",
            TransferType = "in",
            TransferAmount = 50000m,
            ReferenceCode = "MB_FT12345678"
        };

        Assert.Equal(123456, dto.Id);
        Assert.Equal("MBBank", dto.Gateway);
        Assert.Equal("in", dto.TransferType);
        Assert.Equal(50000m, dto.TransferAmount);
        Assert.Equal("MB_FT12345678", dto.ReferenceCode);
    }
}
