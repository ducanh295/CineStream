using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using CineStream.Data;
using CineStream.Models;
using CineStream.Repositories.Interfaces;

namespace CineStream.Repositories.Implementations;

// Trien khai cac phuong thuc truy van du lieu cho bang PaymentTransactions
public class PaymentTransactionRepository : BaseRepository<PaymentTransaction>, IPaymentTransactionRepository
{
    public PaymentTransactionRepository(AppDbContext context) : base(context)
    {
    }

    // Tra cuu giao dich theo ma don hang kem thong tin User
    public async Task<PaymentTransaction?> GetByOrderCodeAsync(string orderCode)
    {
        return await _dbSet
            .Include(pt => pt.User)
            .FirstOrDefaultAsync(pt => pt.OrderCode == orderCode);
    }

    // Tra cuu giao dich theo ma doi soat ngan hang cua SePay
    public async Task<PaymentTransaction?> GetByGatewayTransactionIdAsync(string gatewayTransactionId)
    {
        return await _dbSet
            .FirstOrDefaultAsync(pt => pt.GatewayTransactionId == gatewayTransactionId);
    }

    // Lay toan bo giao dich cua nguoi dung sap xep theo thoi gian moi nhat
    public async Task<IReadOnlyList<PaymentTransaction>> GetByUserIdAsync(int userId)
    {
        return await _dbSet
            .AsNoTracking()
            .Where(pt => pt.UserId == userId)
            .OrderByDescending(pt => pt.CreatedAt)
            .ToListAsync();
    }

    // Phan trang danh sach giao dich cho quan tri vien
    public async Task<(IReadOnlyList<PaymentTransaction> Items, int TotalCount)> GetPagedAsync(int pageNumber, int pageSize)
    {
        var query = _dbSet
            .AsNoTracking()
            .Include(pt => pt.User)
            .OrderByDescending(pt => pt.CreatedAt);

        var totalCount = await query.CountAsync();
        var items = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, totalCount);
    }
}
