// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { useState, useEffect, useCallback } from 'react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { motion } from 'framer-motion';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Users, DollarSign, Tag, Film, Loader2, Receipt } from 'lucide-react';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import { Link } from 'react-router-dom';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import movieApi from '../api/movieApi';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import categoryApi from '../api/categoryApi';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import userApi from '../api/userApi';
// Nạp mô-đun phụ thuộc cần dùng trong tệp này.
import paymentApi from '../api/paymentApi';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const isSuccessfulTransaction = (transaction) => transaction.status === 1 || transaction.status === 'Success';

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const formatCurrency = (amount) => new Intl.NumberFormat('vi-VN', {
  style: 'currency',
  currency: 'VND',
}).format(Number(amount) || 0);

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const getLocalDateKey = (date) => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const year = date.getFullYear();
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const month = String(date.getMonth() + 1).padStart(2, '0');
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const day = String(date.getDate()).padStart(2, '0');
  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return `${year}-${month}-${day}`;
};

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const getRecentTransactionStats = (transactions) => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const today = new Date();
  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return Array.from({ length: 7 }, (_, index) => {
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const date = new Date(today);
     
    date.setHours(0, 0, 0, 0);
     
    date.setDate(today.getDate() - (6 - index));
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const dateKey = getLocalDateKey(date);
    // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
    const dailyTransactions = transactions.filter((transaction) => {
      // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
      if (!isSuccessfulTransaction(transaction)) return false;
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const completedDate = transaction.completedAt || transaction.createdAt;
      // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
      return completedDate && getLocalDateKey(new Date(completedDate)) === dateKey;
    });

    // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
    return {
      label: date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
      count: dailyTransactions.length,
      revenue: dailyTransactions.reduce((total, transaction) => total + (Number(transaction.amount) || 0), 0),
    };
  });
};

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const fetchAllTransactions = async () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const pageSize = 1000;
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const firstResponse = await paymentApi.getAdminAllTransactions({ page: 1, pageSize });
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const firstItems = Array.isArray(firstResponse?.data) ? firstResponse.data : [];
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const total = Number(firstResponse?.total) || firstItems.length;
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const totalPages = Math.ceil(total / pageSize);

  // Kiểm tra điều kiện để chọn nhánh xử lý phù hợp.
  if (totalPages <= 1) return firstItems;

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const remainingResponses = await Promise.all(
    Array.from({ length: totalPages - 1 }, (_, index) => (
      paymentApi.getAdminAllTransactions({ page: index + 2, pageSize })
    )),
  );

  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return firstItems.concat(
    ...remainingResponses.map((response) => (Array.isArray(response?.data) ? response.data : [])),
  );
};

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const StatCard = ({ icon: Icon, label, value, color, delay, note }) => (
  <motion.div
    initial={{ opacity: 0, scale: 0.9 }}
    animate={{ opacity: 1, scale: 1 }}
    transition={{ delay }}
    className="bg-slate-900 border border-slate-800 p-6 rounded-2xl relative overflow-hidden group"
  >
    {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
    <div className={`absolute top-0 right-0 w-24 h-24 blur-3xl opacity-10 rounded-full -mr-8 -mt-8 ${color}`}></div>
    {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
    <div className="flex items-center gap-4 relative z-10">
      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className={`p-4 rounded-xl ${color.replace('bg-', 'bg-opacity-20 ')}`}>
        {/* Hiển thị phần tử giao diện Icon và nội dung con của nó. */}
        <Icon className={color.replace('bg-', 'text-')} size={28} />
      </div>
      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div>
        {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
        <p className="text-slate-400 text-sm font-medium">{label}</p>
        {/* Hiển thị phần tử giao diện h3 và nội dung con của nó. */}
        <h3 className="text-2xl font-bold text-white mt-1">{value}</h3>
      </div>
    </div>
    {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
    <div className="mt-4 flex items-center gap-2 text-slate-500 text-xs">
      {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
      <span>{note}</span>
    </div>
  </motion.div>
);

// Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
const Dashboard = () => {
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [movies, setMovies] = useState([]);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [totalMovieCount, setTotalMovieCount] = useState(0);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [totalUserCount, setTotalUserCount] = useState(0);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [categories, setCategories] = useState([]);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [transactions, setTransactions] = useState([]);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [loading, setLoading] = useState(true);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const [errorMsg, setErrorMsg] = useState('');

  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const fetchDashboardData = useCallback(async () => {
     
    setLoading(true);
     
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const [movieRes, categoryRes, userRes, transactionRes] = await Promise.all([
        movieApi.getAll({ page: 1, pageSize: 100 }),
        categoryApi.getAll(),
        userApi.getAllUsers({ page: 1, pageSize: 1 }),
        fetchAllTransactions(),
      ]);
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const movieData = movieRes?.data;
       
      setMovies(Array.isArray(movieData) ? movieData : movieData?.items || []);
       
      setTotalMovieCount(Array.isArray(movieData) ? movieData.length : movieData?.totalCount || 0);
       
      setCategories(Array.isArray(categoryRes?.data) ? categoryRes.data : []);
      // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
      const userData = userRes?.data;
       
      setTotalUserCount(Array.isArray(userData) ? userData.length : userData?.totalCount || 0);
       
      setTransactions(Array.isArray(transactionRes) ? transactionRes : []);
    } catch (err) {
       
      setErrorMsg(err.message || 'Không thể tải dữ liệu tổng quan. Vui lòng thử lại!');
    } finally {
       
      setLoading(false);
    }
  }, []);

   
  useEffect(() => {
     
    Promise.resolve().then(() => {
       
      fetchDashboardData();
    });
  }, [fetchDashboardData]);

  // Lấy 5 phim mới nhất theo thứ tự API trả về (giả định API trả theo id tăng dần / mới nhất trước)
  const recentMovies = [...movies].slice(0, 5);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const successfulTransactions = transactions.filter(isSuccessfulTransaction);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const totalRevenue = successfulTransactions.reduce((total, transaction) => total + (Number(transaction.amount) || 0), 0);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const recentTransactionStats = getRecentTransactionStats(transactions);
  // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
  const recentRevenue = recentTransactionStats.reduce((total, item) => total + item.revenue, 0);


  // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
  return (
    <div className="space-y-8">
      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div>
        {/* Hiển thị phần tử giao diện h1 và nội dung con của nó. */}
        <h1 className="text-3xl font-bold text-white">Tổng quan hệ thống</h1>
        {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
        <p className="text-slate-400 mt-1">Chào mừng bạn trở lại, đây là dữ liệu mới nhất hôm nay.</p>
      </div>

      {errorMsg && (
        <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">
          {errorMsg}
        </div>
      )}

      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Hiển thị phần tử giao diện StatCard và nội dung con của nó. */}
        <StatCard
          icon={Film}
          label="Tổng số phim"
          value={loading ? '...' : totalMovieCount}
          color="bg-blue-500"
          delay={0.1}
          // note="Dữ liệu thật từ hệ thống"
        />
        {/* Hiển thị phần tử giao diện StatCard và nội dung con của nó. */}
        <StatCard
          icon={Tag}
          label="Tổng thể loại"
          value={loading ? '...' : categories.length}
          color="bg-purple-500"
          delay={0.2}
          // note="Dữ liệu thật từ hệ thống"
        />
        {/* Hiển thị phần tử giao diện StatCard và nội dung con của nó. */}
        <StatCard
          icon={DollarSign}
          label="Doanh thu"
          value={loading ? '...' : formatCurrency(totalRevenue)}
          color="bg-green-500"
          delay={0.3}
          note={`${successfulTransactions.length} giao dịch thành công`}
        />
        {/* Hiển thị phần tử giao diện StatCard và nội dung con của nó. */}
        <StatCard
          icon={Users}
          label="Tổng thành viên"
          value={loading ? '...' : totalUserCount}
          color="bg-orange-500"
          delay={0.4}
          // note="Dữ liệu thật từ hệ thống"
        />
      </div>

      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
        <div className="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-2xl p-6">
          {/* Hiển thị phần tử giao diện h2 và nội dung con của nó. */}
          <h2 className="text-xl font-bold text-white mb-6">Phim mới cập nhật</h2>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-10 text-slate-500">
              {/* Hiển thị phần tử giao diện Loader2 và nội dung con của nó. */}
              <Loader2 className="animate-spin mb-3" size={28} />
              {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
              <p>Đang tải danh sách phim...</p>
            </div>
          ) : recentMovies.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-10 text-slate-500">
              {/* Hiển thị phần tử giao diện Film và nội dung con của nó. */}
              <Film size={32} className="mb-3 opacity-50" />
              {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
              <p>Chưa có phim nào trong hệ thống.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {recentMovies.map((movie) => (
                <Link to={`/movies/${movie.id}`} key={movie.id} className="flex items-center justify-between p-4 bg-slate-800/50 rounded-xl border border-slate-700/50 hover:border-blue-500/50 transition-all cursor-pointer">
                  {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                  <div className="flex items-center gap-4">
                    {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                    <div className="w-12 h-16 bg-slate-700 rounded-lg overflow-hidden shrink-0">
                      {movie.posterUrl ? (
                        <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" />
                      ) : null}
                    </div>
                    {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                    <div>
                      {/* Hiển thị phần tử giao diện h4 và nội dung con của nó. */}
                      <h4 className="text-white font-semibold">{movie.title}</h4>
                      {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
                      <p className="text-slate-400 text-sm">
                        {(movie.categories || []).map((c) => c.name).join(', ') || 'Chưa gán thể loại'}
                        {movie.duration ? ` • ${movie.duration} phút` : ''}
                      </p>
                    </div>
                  </div>
                  {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
                  <div className="text-right">
                    {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
                    <p className="text-blue-400 font-bold">{movie.releaseYear || '—'}</p>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          {/* Hiển thị phần tử giao diện h2 và nội dung con của nó. */}
          <h2 className="text-xl font-bold text-white mb-6">Thể loại hiện có</h2>
          {loading ? (
            <div className="flex justify-center py-10 text-slate-500">
              {/* Hiển thị phần tử giao diện Loader2 và nội dung con của nó. */}
              <Loader2 className="animate-spin" size={28} />
            </div>
          ) : categories.length === 0 ? (
            <p className="text-slate-500 text-sm">Chưa có thể loại nào.</p>
          ) : (
            <div className="space-y-3">
              {categories.map((cat) => {
                // Khai báo dữ liệu hoặc giá trị phục vụ luồng xử lý bên dưới.
                const movieCount = movies.filter((m) =>
                  (m.categories || []).some((c) => c.id === cat.id)
                ).length;
                // Trả về kết quả hoặc giao diện từ nhánh xử lý hiện tại.
                return (
                  <div key={cat.id} className="flex items-center justify-between">
                    {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                    <span className="text-slate-300 text-sm">{cat.name}</span>
                    {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
                    <span className="text-slate-500 text-xs bg-slate-800 px-2 py-1 rounded-full">
                      {movieCount} phim
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
        {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
        <div className="flex items-center justify-between gap-4 mb-6">
          {/* Hiển thị phần tử giao diện div và nội dung con của nó. */}
          <div>
            {/* Hiển thị phần tử giao diện h2 và nội dung con của nó. */}
            <h2 className="text-xl font-bold text-white">Doanh thu 7 ngày gần nhất</h2>
            {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
            <p className="text-sm text-slate-500 mt-1">Tổng doanh thu: {formatCurrency(recentRevenue)}</p>
          </div>
          {/* Hiển thị phần tử giao diện Receipt và nội dung con của nó. */}
          <Receipt className="text-emerald-400" size={24} />
        </div>

        {loading ? (
          <div className="flex justify-center py-10 text-slate-500">
            {/* Hiển thị phần tử giao diện Loader2 và nội dung con của nó. */}
            <Loader2 className="animate-spin" size={28} />
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-3">
              {recentTransactionStats.map((item) => (
                <div key={item.label} className="rounded-lg bg-slate-800/50 px-3 py-2 text-center">
                  {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
                  <p className="text-xs text-slate-500">{item.label}</p>
                  {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
                  <p className="text-sm font-semibold text-emerald-300 mt-1">{formatCurrency(item.revenue)}</p>
                  {/* Hiển thị phần tử giao diện p và nội dung con của nó. */}
                  <p className="text-xs text-slate-500 mt-1">{item.count} giao dịch</p>
                </div>
              ))}
          </div>
        )}
      </div>
    </div>
  );
};

// Xuất thành phần chính để các tệp khác có thể sử dụng.
export default Dashboard;