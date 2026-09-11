using System;
using Xunit;
using CineStream.Models;
using CineStream.Models.Enums;

namespace Backend.Tests.Payments;

public class PaymentModelTests
{
    // Kiểm tra định nghĩa các giá trị Enum PaymentStatus đúng với quy chuẩn
    [Fact]
    public void PaymentStatus_ShouldContainExpectedEnumValues()
    {
        Assert.Equal(0, (int)PaymentStatus.Pending);
        Assert.Equal(1, (int)PaymentStatus.Success);
        Assert.Equal(2, (int)PaymentStatus.Failed);
        Assert.Equal(3, (int)PaymentStatus.Cancelled);
    }

    // Kiểm tra khởi tạo thực thể PaymentTransaction với các giá trị mặc định hợp lệ
    [Fact]
    public void PaymentTransaction_ShouldInitializeWithDefaultValues()
    {
        var before = DateTime.UtcNow;
        var transaction = new PaymentTransaction
        {
            UserId = 1,
            OrderCode = "CINE123456",
            Amount = 50000m,
            PlanDurationDays = 30,
            PaymentGateway = "SePay_MBBank"
        };
        var after = DateTime.UtcNow;

        Assert.Equal(1, transaction.UserId);
        Assert.Equal("CINE123456", transaction.OrderCode);
        Assert.Equal(50000m, transaction.Amount);
        Assert.Equal(30, transaction.PlanDurationDays);
        Assert.Equal("SePay_MBBank", transaction.PaymentGateway);
        Assert.Equal(PaymentStatus.Pending, transaction.Status);
        Assert.False(transaction.IsDeleted);
        Assert.Null(transaction.CompletedAt);
        Assert.True(transaction.CreatedAt >= before && transaction.CreatedAt <= after);
    }
}
