using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using CineStream.DTOs.Payments;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

// Trien khai nghiep vu thanh toan goi Premium va xu ly Webhook SePay
public class PaymentService : IPaymentService
{
    private readonly IPaymentTransactionRepository _paymentRepo;
    private readonly IUserRepository _userRepo;
    private readonly IConfiguration _configuration;

    public PaymentService(
        IPaymentTransactionRepository paymentRepo,
        IUserRepository userRepo,
        IConfiguration configuration)
    {
        _paymentRepo = paymentRepo;
        _userRepo = userRepo;
        _configuration = configuration;
    }

    // Tao yeu cau thanh toan don hang moi va tra ve thong tin VietQR Napas
    public async Task<PaymentResponseDto> CreatePaymentAsync(int userId, CreatePaymentRequestDto dto)
    {
        decimal amount;
        int planDurationDays;

        switch (dto.PlanType?.Trim().ToUpperInvariant())
        {
            case "1M":
                amount = 2000m;
                planDurationDays = 30;
                break;
            case "3M":
                amount = 5000m;
                planDurationDays = 90;
                break;
            case "1Y":
                amount = 10000m;
                planDurationDays = 365;
                break;
            default:
                throw new ArgumentException("Goi dang ky khong hop le. Chi chap nhan '1M', '3M', hoac '1Y'.");
        }

        // Sinh ma don hang duy nhat bat dau bang CINE kem timestamp va so ngau nhien
        var orderCode = $"CINE{DateTime.UtcNow:yyMMddHHmmss}{Random.Shared.Next(10, 99)}";

        // Lay thong tin cau hinh tai khoan SePay tu appsettings.json
        var bankName = _configuration["SePay:BankName"] ?? "MB";
        var accountNumber = _configuration["SePay:AccountNumber"] ?? "0385941522";
        var accountName = _configuration["SePay:AccountName"] ?? "NGUYEN KHAC DUC ANH";

        // Tao duong dan anh VietQR dong theo chuan Napas
        var encodedAccountName = Uri.EscapeDataString(accountName);
        var qrCodeUrl = $"https://img.vietqr.io/image/{bankName}-{accountNumber}-compact.png?amount={amount}&addInfo={orderCode}&accountName={encodedAccountName}";

        var transaction = new PaymentTransaction
        {
            UserId = userId,
            OrderCode = orderCode,
            Amount = amount,
            PlanDurationDays = planDurationDays,
            Status = PaymentStatus.Pending,
            PaymentGateway = $"SePay_{bankName}"
        };

        await _paymentRepo.AddAsync(transaction);
        await _paymentRepo.SaveChangesAsync();

        return new PaymentResponseDto
        {
            OrderCode = orderCode,
            Amount = amount,
            PlanDurationDays = planDurationDays,
            BankName = bankName,
            AccountNumber = accountNumber,
            AccountName = accountName,
            Description = orderCode,
            QrCodeUrl = qrCodeUrl,
            CreatedAt = transaction.CreatedAt
        };
    }

    // Xu ly Webhook nhan tien tu SePay voi co che Idempotency va xac thuc ApiKey
    public async Task<bool> ProcessSePayWebhookAsync(string? authHeader, SePayWebhookDto webhookDto)
    {
        // 1. Xac thuc ma API Key SePay gui sang
        var expectedApiKey = _configuration["SePay:ApiKey"];
        if (string.IsNullOrWhiteSpace(expectedApiKey) || string.IsNullOrWhiteSpace(authHeader))
        {
            return false;
        }

        var token = authHeader.Replace("Apikey ", "", StringComparison.OrdinalIgnoreCase)
                              .Replace("Bearer ", "", StringComparison.OrdinalIgnoreCase)
                              .Trim();

        if (!string.Equals(token, expectedApiKey, StringComparison.Ordinal))
        {
            return false;
        }

        // 2. Chi xu ly giao dich tien vao (transferType = "in")
        if (!string.Equals(webhookDto.TransferType, "in", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        // 3. Trich xuat ma don hang CINE tu noi dung chuyen khoan
        var content = webhookDto.Content ?? string.Empty;
        var match = Regex.Match(content, @"CINE\w+", RegexOptions.IgnoreCase);
        if (!match.Success)
        {
            return true;
        }

        var orderCode = match.Value.ToUpperInvariant();
        var transaction = await _paymentRepo.GetByOrderCodeAsync(orderCode);
        if (transaction == null)
        {
            return true;
        }

        // 4. Co che Idempotency: Neu don hang da thanh cong truoc do thi bo qua khong cong them
        if (transaction.Status == PaymentStatus.Success)
        {
            return true;
        }

        // 5. Kiem tra so tien chuyen khoan co du voi so tien don hang hay khong
        if (webhookDto.TransferAmount < transaction.Amount)
        {
            transaction.Status = PaymentStatus.Failed;
            _paymentRepo.Update(transaction);
            await _paymentRepo.SaveChangesAsync();
            return false;
        }

        // 6. Cap nhat trang thai don hang thanh cong
        transaction.Status = PaymentStatus.Success;
        transaction.GatewayTransactionId = webhookDto.ReferenceCode ?? webhookDto.Id.ToString();
        transaction.CompletedAt = DateTime.UtcNow;
        _paymentRepo.Update(transaction);

        // 7. Kich hoat hoac gia han goi Premium cho nguoi dung
        var user = await _userRepo.GetByIdAsync(transaction.UserId);
        if (user != null)
        {
            if (user.IsPremium && user.PremiumExpiresAt.HasValue && user.PremiumExpiresAt.Value > DateTime.UtcNow)
            {
                // Nguoi dung dang co VIP con han: Cong don them so ngay tu moc het han cu
                user.PremiumExpiresAt = user.PremiumExpiresAt.Value.AddDays(transaction.PlanDurationDays);
            }
            else
            {
                // Nguoi dung moi mua hoac goi cu da het han: Cong tu ngay hien tai
                user.IsPremium = true;
                user.PremiumExpiresAt = DateTime.UtcNow.AddDays(transaction.PlanDurationDays);
            }

            _userRepo.Update(user);
            await _userRepo.SaveChangesAsync();
        }

        await _paymentRepo.SaveChangesAsync();
        return true;
    }

    // Tra cuu trang thai don hang cho Client polling
    public async Task<PaymentStatusResponseDto?> GetPaymentStatusAsync(string orderCode)
    {
        var transaction = await _paymentRepo.GetByOrderCodeAsync(orderCode);
        if (transaction == null) return null;

        return new PaymentStatusResponseDto
        {
            OrderCode = transaction.OrderCode,
            Status = transaction.Status.ToString(),
            IsCompleted = transaction.Status == PaymentStatus.Success,
            CompletedAt = transaction.CompletedAt
        };
    }

    // Gia lap thanh toan thanh cong danh rieng cho kiem thu va bao ve do an
    public async Task<bool> SimulatePaymentSuccessAsync(string orderCode)
    {
        var transaction = await _paymentRepo.GetByOrderCodeAsync(orderCode);
        if (transaction == null) return false;

        if (transaction.Status == PaymentStatus.Success) return true;

        transaction.Status = PaymentStatus.Success;
        transaction.GatewayTransactionId = $"SIMULATED_{Guid.NewGuid():N}"[..18];
        transaction.CompletedAt = DateTime.UtcNow;
        _paymentRepo.Update(transaction);

        var user = await _userRepo.GetByIdAsync(transaction.UserId);
        if (user != null)
        {
            if (user.IsPremium && user.PremiumExpiresAt.HasValue && user.PremiumExpiresAt.Value > DateTime.UtcNow)
            {
                user.PremiumExpiresAt = user.PremiumExpiresAt.Value.AddDays(transaction.PlanDurationDays);
            }
            else
            {
                user.IsPremium = true;
                user.PremiumExpiresAt = DateTime.UtcNow.AddDays(transaction.PlanDurationDays);
            }

            _userRepo.Update(user);
            await _userRepo.SaveChangesAsync();
        }

        await _paymentRepo.SaveChangesAsync();
        return true;
    }

    // Lay lich su giao dich cua nguoi dung
    public async Task<IReadOnlyList<PaymentTransactionDto>> GetUserHistoryAsync(int userId)
    {
        var items = await _paymentRepo.GetByUserIdAsync(userId);
        return items.Select(MapToDto).ToList();
    }

    // Lay danh sach giao dich phan trang cho quan tri vien
    public async Task<(IReadOnlyList<PaymentTransactionDto> Items, int TotalCount)> GetAdminAllTransactionsAsync(int pageNumber, int pageSize)
    {
        var (items, totalCount) = await _paymentRepo.GetPagedAsync(pageNumber, pageSize);
        return (items.Select(MapToDto).ToList(), totalCount);
    }

    private static PaymentTransactionDto MapToDto(PaymentTransaction pt)
    {
        return new PaymentTransactionDto
        {
            Id = pt.Id,
            UserId = pt.UserId,
            UserEmail = pt.User?.Email,
            OrderCode = pt.OrderCode,
            Amount = pt.Amount,
            PlanDurationDays = pt.PlanDurationDays,
            Status = pt.Status.ToString(),
            PaymentGateway = pt.PaymentGateway,
            GatewayTransactionId = pt.GatewayTransactionId,
            CreatedAt = pt.CreatedAt,
            CompletedAt = pt.CompletedAt
        };
    }
}
