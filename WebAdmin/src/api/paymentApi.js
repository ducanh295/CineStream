import axiosInstance from './axios';

const paymentApi = {
  getSubscriptionPlans: () => axiosInstance.get('/subscriptions/plans'),
  updatePlan: (id, data) => axiosInstance.put(`/subscriptions/plans/${id}`, data),
  getTransactionHistory: (params) => axiosInstance.get('/payments/history', { params }),
  getRevenueStats: () => axiosInstance.get('/payments/revenue-report'),
};

export default paymentApi;