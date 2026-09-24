using System;
using System.ComponentModel.DataAnnotations;

namespace CineStream.DTOs.Payments;

// Yeu cau khoi tao don hang thanh toan goi Premium
public class CreatePaymentRequestDto
{
    // Loai goi dang ky: "1M" (1 Thang), "3M" (3 Thang), "1Y" (1 Nam)
    [Required]
    public string PlanType { get; set; } = "1M";
}

// Ket qua tao don thanh toan tra ve cho nguoi dung quet ma VietQR
public class PaymentResponseDto
{
    public string OrderCode { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public int PlanDurationDays { get; set; }
    public string BankName { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;
    public string AccountName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string QrCodeUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

// Du lieu Webhook do SePay ban sang khi co bien dong chuyen khoan
public class SePayWebhookDto
{
    public long Id { get; set; }
    public string? Gateway { get; set; }
    public string? TransactionDate { get; set; }
    public string? AccountNumber { get; set; }
    public string? SubAccount { get; set; }
    public string? Code { get; set; }
    public string? Content { get; set; }
    public string? TransferType { get; set; }
    public string? Description { get; set; }
    public decimal TransferAmount { get; set; }
    public string? ReferenceCode { get; set; }
    public decimal Accumulated { get; set; }
}

// DTO the hien thong tin giao dich cho nguoi dung va quan tri vien
public class PaymentTransactionDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string? UserEmail { get; set; }
    public string OrderCode { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public int PlanDurationDays { get; set; }
    public string Status { get; set; } = string.Empty;
    public string PaymentGateway { get; set; } = string.Empty;
    public string? GatewayTransactionId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

// Ket qua phan hoi trang thai don hang cho Client polling
public class PaymentStatusResponseDto
{
    public string OrderCode { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
}

// Thong tin goi cuoc VIP CineStream
public class SubscriptionPlanDto
{
    public string Id { get; set; } = string.Empty; // "1M", "3M", "1Y"
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Days { get; set; }
    public string? Description { get; set; }
    public string? Discount { get; set; }
    public bool Highlight { get; set; }
}

// Yeu cau cap nhat gia goi cuoc tu quan tri vien
public class UpdatePlanPriceDto
{
    [Range(1000, 100000000, ErrorMessage = "Gia goi phai tu 1.000d den 100.000.000d!")]
    public decimal Price { get; set; }
}
