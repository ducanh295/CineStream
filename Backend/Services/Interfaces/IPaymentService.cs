using System.Collections.Generic;
using System.Threading.Tasks;
using CineStream.DTOs.Payments;

namespace CineStream.Services.Interfaces;

// Giao dien nghiep vu xu ly thanh toan goi VIP va Webhook SePay
public interface IPaymentService
{
    // Nguoi dung tao yeu cau thanh toan de lay ma don hang va QR VietQR
    Task<PaymentResponseDto> CreatePaymentAsync(int userId, CreatePaymentRequestDto dto);

    // Xu ly Webhook bien dong so du do SePay ban sang khi co tien vao tai khoan
    Task<bool> ProcessSePayWebhookAsync(string? authHeader, SePayWebhookDto webhookDto);

    // Kiem tra trang thai don hang cho Client polling
    Task<PaymentStatusResponseDto?> GetPaymentStatusAsync(string orderCode);

    // Gia lap thanh toan thanh cong phuc vu test va bao ve do an an toan
    Task<bool> SimulatePaymentSuccessAsync(string orderCode);

    // Lay lich su giao dich cua nguoi dung
    Task<IReadOnlyList<PaymentTransactionDto>> GetUserHistoryAsync(int userId);

    // Lay toan bo lich su giao dich phan trang cho quan tri vien
    Task<(IReadOnlyList<PaymentTransactionDto> Items, int TotalCount)> GetAdminAllTransactionsAsync(int pageNumber, int pageSize);

    // Lay danh sach bang gia cac goi VIP (gia dong hoac mac dinh)
    Task<IReadOnlyList<SubscriptionPlanDto>> GetSubscriptionPlansAsync();

    // Quan tri vien cap nhat gia cho mot goi VIP
    Task<SubscriptionPlanDto> UpdatePlanPriceAsync(string planType, decimal newPrice);
}
