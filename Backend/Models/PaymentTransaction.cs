using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using CineStream.Models.Enums;

namespace CineStream.Models;

// Thuc the luu tru lich su giao dich thanh toan qua cong SePay
public class PaymentTransaction : BaseEntity
{
    // ID nguoi dung thuc hien giao dich
    public int UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    // Ma don hang duy nhat cua CineStream de doi soat (vi du: CINE123456)
    [Required]
    [MaxLength(50)]
    public string OrderCode { get; set; } = string.Empty;

    // So tien thanh toan
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    // So ngay cong them cho goi VIP (30, 90, 365)
    public int PlanDurationDays { get; set; }

    // Trang thai giao dich
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;

    // Ten cong thanh toan
    [MaxLength(50)]
    public string PaymentGateway { get; set; } = "SePay_MBBank";

    // Ma giao dich ngan hang hoac SePay tra ve sau khi chuyen khoan thanh cong
    [MaxLength(100)]
    public string? GatewayTransactionId { get; set; }

    // Thoi gian hoan tat giao dich
    public DateTime? CompletedAt { get; set; }
}
