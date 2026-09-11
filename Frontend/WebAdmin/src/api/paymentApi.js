import axiosInstance from './axios';

// API module cho chuc nang thanh toan VietQR SePay va quan ly goi VIP
const paymentApi = {
  // Khoi tao don thanh toan VietQR (PlanType: "1M", "3M", "1Y")
  createPayment: (data) => axiosInstance.post('/payments/create', data),

  // Lay trang thai don hang theo ma don (phuc vu polling kiem tra ket qua)
  getPaymentStatus: (orderCode) => axiosInstance.get(`/payments/status/${orderCode}`),

  // Quan tri vien gia lap thanh toan thanh cong phuc vu demo do an tot nghiep
  simulatePayment: (orderCode) => axiosInstance.post(`/payments/simulate/${orderCode}`),

  // Lay lich su giao dich nap tien cua tai khoan hien tai
  getMyHistory: () => axiosInstance.get('/payments/history'),

  // Quan tri vien lay toan bo giao dich he thong phan trang
  getAdminAllTransactions: (params) => axiosInstance.get('/payments/admin/all', { params }),
};

export default paymentApi;