using System.Collections.Generic;
using System.Threading.Tasks;
using CineStream.Models;

namespace CineStream.Repositories.Interfaces;

// Giao dien thao tac du lieu cho bang PaymentTransactions
public interface IPaymentTransactionRepository : IBaseRepository<PaymentTransaction>
{
    // Tim giao dich theo ma don hang duy nhat
    Task<PaymentTransaction?> GetByOrderCodeAsync(string orderCode);

    // Tim giao dich theo ma giao dich do cong thanh toan tra ve (chong xu ly trung)
    Task<PaymentTransaction?> GetByGatewayTransactionIdAsync(string gatewayTransactionId);

    // Lay toan bo lich su giao dich cua mot nguoi dung
    Task<IReadOnlyList<PaymentTransaction>> GetByUserIdAsync(int userId);

    // Lay danh sach giao dich phan trang kem tong so luong cho quan tri vien
    Task<(IReadOnlyList<PaymentTransaction> Items, int TotalCount)> GetPagedAsync(int pageNumber, int pageSize);
}
