using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
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
    private readonly ISystemSettingRepository? _systemSettingRepo;
    private readonly IHttpClientFactory? _httpClientFactory;

    // Danh sach cac goi VIP CineStream mac dinh cua he thong
    private static readonly IReadOnlyList<SubscriptionPlanDto> BasePlans = new List<SubscriptionPlanDto>
    {
        new SubscriptionPlanDto
        {
            Id = "1M",
            Name = "Gói VIP 1 Tháng",
            Price = 2000m,
            Days = 30,
            Discount = null,
            Highlight = false,
            Description = "Trải nghiệm không giới hạn phim chất lượng Full HD, không quảng cáo trong 30 ngày."
        },
        new SubscriptionPlanDto
        {
            Id = "3M",
            Name = "Gói VIP 3 Tháng",
            Price = 5000m,
            Days = 90,
            Discount = "Tiết kiệm",
            Highlight = true,
            Description = "Lựa chọn phổ biến nhất. Xem phim mượt mà chuẩn 4K, hỗ trợ đa thiết bị trong 90 ngày."
        },
        new SubscriptionPlanDto
        {
            Id = "1Y",
            Name = "Gói VIP 1 Năm",
            Price = 10000m,
            Days = 365,
            Discount = "Tiết kiệm 20%",
            Highlight = false,
            Description = "Gói ưu đãi cao nhất cho tín đồ điện ảnh CineStream. Tiết kiệm tối đa chi phí hàng tháng."
        }
    };

    public PaymentService(
        IPaymentTransactionRepository paymentRepo,
        IUserRepository userRepo,
        IConfiguration configuration)
        : this(paymentRepo, userRepo, configuration, null, null)
    {
    }

    public PaymentService(
        IPaymentTransactionRepository paymentRepo,
        IUserRepository userRepo,
        IConfiguration configuration,
        ISystemSettingRepository? systemSettingRepo)
        : this(paymentRepo, userRepo, configuration, systemSettingRepo, null)
    {
    }

    public PaymentService(
        IPaymentTransactionRepository paymentRepo,
        IUserRepository userRepo,
        IConfiguration configuration,
        ISystemSettingRepository? systemSettingRepo,
        IHttpClientFactory? httpClientFactory)
    {
        _paymentRepo = paymentRepo;
        _userRepo = userRepo;
        _configuration = configuration;
        _systemSettingRepo = systemSettingRepo;
        _httpClientFactory = httpClientFactory;
    }

    // Lay danh sach bang gia cac goi VIP (gia dong tu CSDL hoac mac dinh)
    public async Task<IReadOnlyList<SubscriptionPlanDto>> GetSubscriptionPlansAsync()
    {
        var result = new List<SubscriptionPlanDto>();
        foreach (var basePlan in BasePlans)
        {
            var plan = new SubscriptionPlanDto
            {
                Id = basePlan.Id,
                Name = basePlan.Name,
                Price = await GetPlanPriceAsync(basePlan.Id, basePlan.Price),
                Days = basePlan.Days,
                Discount = basePlan.Discount,
                Highlight = basePlan.Highlight,
                Description = basePlan.Description
            };
            result.Add(plan);
        }
        return result.AsReadOnly();
    }

    // Quan tri vien cap nhat gia cho mot goi VIP
    public async Task<SubscriptionPlanDto> UpdatePlanPriceAsync(string planType, decimal newPrice)
    {
        var normalizedType = planType?.Trim().ToUpperInvariant() ?? string.Empty;
        var basePlan = BasePlans.FirstOrDefault(p => p.Id == normalizedType);
        if (basePlan == null)
        {
            throw new ArgumentException($"Goi dang ky '{planType}' khong hop le. Chi chap nhan '1M', '3M', hoac '1Y'.");
        }

        if (newPrice < 1000m)
        {
            throw new ArgumentException("Gia goi cuoc toi thieu phai tu 1.000d tro len.");
        }

        if (_systemSettingRepo != null)
        {
            var key = $"PlanPrice_{normalizedType}";
            await _systemSettingRepo.SetValueAsync(key, newPrice.ToString("0.##"), $"Gia niem yet cho {basePlan.Name}");
        }

        return new SubscriptionPlanDto
        {
            Id = basePlan.Id,
            Name = basePlan.Name,
            Price = newPrice,
            Days = basePlan.Days,
            Discount = basePlan.Discount,
            Highlight = basePlan.Highlight,
            Description = basePlan.Description
        };
    }

    private async Task<decimal> GetPlanPriceAsync(string planType, decimal defaultPrice)
    {
        if (_systemSettingRepo == null) return defaultPrice;
        var key = $"PlanPrice_{planType}";
        var val = await _systemSettingRepo.GetValueAsync(key);
        if (decimal.TryParse(val, out var parsed) && parsed >= 1000m)
        {
            return parsed;
        }
        return defaultPrice;
    }

    // Tao yeu cau thanh toan don hang moi va tra ve thong tin VietQR Napas
    public async Task<PaymentResponseDto> CreatePaymentAsync(int userId, CreatePaymentRequestDto dto)
    {
        var normalizedType = dto.PlanType?.Trim().ToUpperInvariant() ?? string.Empty;
        var basePlan = BasePlans.FirstOrDefault(p => p.Id == normalizedType);
        if (basePlan == null)
        {
            throw new ArgumentException("Goi dang ky khong hop le. Chi chap nhan '1M', '3M', hoac '1Y'.");
        }

        decimal amount = await GetPlanPriceAsync(basePlan.Id, basePlan.Price);
        int planDurationDays = basePlan.Days;

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

        // 6. Cap nhat trang thai va kich hoat VIP cho nguoi dung
        var gatewayId = webhookDto.ReferenceCode ?? webhookDto.Id.ToString();
        return await FulfillPaymentSuccessAsync(transaction, gatewayId);
    }

    // Tra cuu trang thai don hang cho Client polling va tu dong dong bo SePay neu don hang con Pending
    public async Task<PaymentStatusResponseDto?> GetPaymentStatusAsync(string orderCode)
    {
        var transaction = await _paymentRepo.GetByOrderCodeAsync(orderCode);
        if (transaction == null) return null;

        // Neu don hang da hoan tat thanh cong, tra ve ket qua ngay
        if (transaction.Status == PaymentStatus.Success)
        {
            return new PaymentStatusResponseDto
            {
                OrderCode = transaction.OrderCode,
                Status = transaction.Status.ToString(),
                IsCompleted = true,
                CompletedAt = transaction.CompletedAt
            };
        }

        // Neu don hang dang Pending, thuc hien co che Polling Fallback goi SePay Open API de dong bo
        if (transaction.Status == PaymentStatus.Pending)
        {
            var isSynced = await SyncWithSePayApiAsync(transaction);
            if (isSynced)
            {
                return new PaymentStatusResponseDto
                {
                    OrderCode = transaction.OrderCode,
                    Status = PaymentStatus.Success.ToString(),
                    IsCompleted = true,
                    CompletedAt = transaction.CompletedAt
                };
            }
        }

        return new PaymentStatusResponseDto
        {
            OrderCode = transaction.OrderCode,
            Status = transaction.Status.ToString(),
            IsCompleted = false,
            CompletedAt = transaction.CompletedAt
        };
    }

    // Co che Polling Fallback: Truy van danh sach giao dich tu SePay Open API khi Webhook chua toi
    private async Task<bool> SyncWithSePayApiAsync(PaymentTransaction transaction)
    {
        var apiKey = _configuration["SePay:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey)) return false;

        try
        {
            var client = _httpClientFactory != null
                ? _httpClientFactory.CreateClient("SePayClient")
                : new HttpClient();

            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            var request = new HttpRequestMessage(HttpMethod.Get, "https://my.sepay.vn/userapi/transactions/list?limit=20");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var response = await client.SendAsync(request, cts.Token);
            if (!response.IsSuccessStatusCode)
            {
                return false;
            }

            var json = await response.Content.ReadAsStringAsync(cts.Token);
            using var doc = JsonDocument.Parse(json);

            if (!doc.RootElement.TryGetProperty("transactions", out var txArray) || txArray.ValueKind != JsonValueKind.Array)
            {
                return false;
            }

            foreach (var item in txArray.EnumerateArray())
            {
                var content = item.TryGetProperty("transaction_content", out var cProp) ? cProp.GetString() : null;
                if (string.IsNullOrEmpty(content) || !content.Contains(transaction.OrderCode, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                decimal amountIn = 0;
                if (item.TryGetProperty("amount_in", out var aProp))
                {
                    if (aProp.ValueKind == JsonValueKind.Number)
                    {
                        amountIn = aProp.GetDecimal();
                    }
                    else if (aProp.ValueKind == JsonValueKind.String)
                    {
                        decimal.TryParse(aProp.GetString(), NumberStyles.Any, CultureInfo.InvariantCulture, out amountIn);
                    }
                }

                if (amountIn >= transaction.Amount)
                {
                    var refNumber = item.TryGetProperty("reference_number", out var rProp) ? rProp.GetString() : null;
                    var txId = item.TryGetProperty("id", out var idProp) ? idProp.ToString() : null;
                    var gatewayId = !string.IsNullOrWhiteSpace(refNumber) ? refNumber : (txId ?? "SEPAY_SYNC");

                    return await FulfillPaymentSuccessAsync(transaction, gatewayId);
                }
            }
        }
        catch
        {
            // Xu ly an toan khi mang bi ngat hoac SePay khong phan hoi kip
            return false;
        }

        return false;
    }

    // Kich hoat VIP va danh dau don hang thanh cong dung chung cho Webhook, Mo phong va Polling Sync
    private async Task<bool> FulfillPaymentSuccessAsync(PaymentTransaction transaction, string gatewayTransactionId)
    {
        if (transaction.Status == PaymentStatus.Success) return true;

        transaction.Status = PaymentStatus.Success;
        transaction.GatewayTransactionId = gatewayTransactionId;
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

    // Gia lap thanh toan thanh cong danh rieng cho kiem thu va bao ve do an
    public async Task<bool> SimulatePaymentSuccessAsync(string orderCode)
    {
        var transaction = await _paymentRepo.GetByOrderCodeAsync(orderCode);
        if (transaction == null) return false;

        var gatewayId = $"SIMULATED_{Guid.NewGuid():N}"[..18];
        return await FulfillPaymentSuccessAsync(transaction, gatewayId);
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
