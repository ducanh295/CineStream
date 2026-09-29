 
import { useState, useEffect, useCallback } from 'react';
 
import { motion } from 'framer-motion';
 
import { Users, DollarSign, Tag, Film, Loader2, Receipt } from 'lucide-react';
 
import { Link } from 'react-router-dom';
 
import movieApi from '../api/movieApi';
 
import categoryApi from '../api/categoryApi';
 
import userApi from '../api/userApi';
 
import paymentApi from '../api/paymentApi';

 
const isSuccessfulTransaction = (transaction) => transaction.status === 1 || transaction.status === 'Success';

 
const formatCurrency = (amount) => new Intl.NumberFormat('vi-VN', {
  style: 'currency',
  currency: 'VND',
}).format(Number(amount) || 0);

// logic lấy ngày tháng năm từ đối tượng Date và trả về chuỗi định dạng YYYY-MM-DD
const getLocalDateKey = (date) => {
  // date.getFullYear() là phương thức lấy năm từ đối tượng Date, trả về giá trị số nguyên đại diện cho năm.
  const year = date.getFullYear();
  // dòng này sử dụng phương thức getMonth() của đối tượng Date để lấy tháng (0-11), sau đó cộng thêm 1 để có giá trị từ 1-12, và sử dụng padStart(2, '0') để đảm bảo rằng tháng luôn có hai chữ số (ví dụ: "01", "02", ..., "12").
  const month = String(date.getMonth() + 1).padStart(2, '0');
  // dòng này sử dụng phương thức getDate() của đối tượng Date để lấy ngày trong tháng (1-31), và sử dụng padStart(2, '0') để đảm bảo rằng ngày luôn có hai chữ số (ví dụ: "01", "02", ..., "31").
  const day = String(date.getDate()).padStart(2, '0');
  // trả về một chuỗi định dạng "YYYY-MM-DD" bằng cách kết hợp các giá trị năm, tháng và ngày đã được xử lý ở trên.
  return `${year}-${month}-${day}`;
};

// logic lấy thống kê giao dịch trong 7 ngày gần nhất từ danh sách giao dịch
const getRecentTransactionStats = (transactions) => {
  // tạo mới một đối tượng Date đại diện cho ngày hiện tại.
  const today = new Date();
  // Trả về một mảng gồm 7 phần tử, mỗi phần tử đại diện cho một ngày trong 7 ngày gần nhất, bắt đầu từ hôm nay và lùi về trước.
  return Array.from({ length: 7 }, (_, index) => {
    // Tạo một đối tượng Date mới dựa trên ngày hiện tại (today) để tránh thay đổi ngày gốc.
    const date = new Date(today);
     // Đặt giờ, phút, giây và mili giây của đối tượng Date thành 0 để chỉ giữ lại ngày.
    date.setHours(0, 0, 0, 0);
     // Trừ đi số ngày tương ứng với chỉ số index để lấy ngày trong 7 ngày gần nhất (index từ 0 đến 6).
    date.setDate(today.getDate() - (6 - index));
    // Lấy khóa ngày định dạng "YYYY-MM-DD" từ đối tượng Date hiện tại.
    const dateKey = getLocalDateKey(date);
    // Lọc danh sách giao dịch để chỉ giữ lại những giao dịch thành công và có ngày hoàn thành hoặc ngày tạo trùng với ngày hiện tại (dateKey).
    const dailyTransactions = transactions.filter((transaction) => {
      // kiểm tra xem giao dịch có phải là giao dịch thành công hay không, nếu không thì bỏ qua.
      if (!isSuccessfulTransaction(transaction)) return false;
      // Lấy ngày hoàn thành của giao dịch (completedAt) hoặc ngày tạo (createdAt) nếu completedAt không tồn tại.
      const completedDate = transaction.completedAt || transaction.createdAt;
      // trả về true nếu ngày hoàn thành trùng với ngày hiện tại (dateKey), ngược lại trả về false.
      return completedDate && getLocalDateKey(new Date(completedDate)) === dateKey;
    });

    // Trả về một đối tượng chứa thông tin thống kê cho ngày hiện tại, bao gồm nhãn ngày (label), số lượng giao dịch (count) và tổng doanh thu (revenue).
    return {
      label: date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
      count: dailyTransactions.length,
      revenue: dailyTransactions.reduce((total, transaction) => total + (Number(transaction.amount) || 0), 0),
    };
  });
};

// logic lấy tất cả giao dịch từ API, bao gồm việc phân trang và kết hợp dữ liệu từ các trang khác nhau.
const fetchAllTransactions = async () => {
  // 1000 là số lượng giao dịch tối đa mà API sẽ trả về trong một lần gọi, được sử dụng để phân trang dữ liệu.
  const pageSize = 1000;
  // Gọi API để lấy danh sách giao dịch từ trang đầu tiên với kích thước trang là pageSize.
  const firstResponse = await paymentApi.getAdminAllTransactions({ page: 1, pageSize });
  // Kiểm tra xem dữ liệu trả về từ API có phải là một mảng hay không, nếu có thì lấy dữ liệu đó, nếu không thì lấy giá trị mặc định là một mảng rỗng.
  const firstItems = Array.isArray(firstResponse?.data) ? firstResponse.data : [];
  // Lấy tổng số lượng giao dịch từ phản hồi đầu tiên, nếu không có giá trị thì sử dụng độ dài của mảng firstItems làm tổng.
  const total = Number(firstResponse?.total) || firstItems.length;
  // Tính toán tổng số trang cần lấy dựa trên tổng số lượng giao dịch và kích thước trang (pageSize), sử dụng Math.ceil để làm tròn lên.
  const totalPages = Math.ceil(total / pageSize);

  // Nếu tổng số trang nhỏ hơn hoặc bằng 1, tức là chỉ có một trang dữ liệu, thì trả về danh sách giao dịch từ trang đầu tiên (firstItems) mà không cần gọi thêm API cho các trang khác.
  if (totalPages <= 1) return firstItems;

  // Nếu có nhiều trang dữ liệu, sử dụng Promise.all để gọi API cho tất cả các trang còn lại (từ trang 2 đến trang totalPages) và chờ đợi tất cả các phản hồi hoàn thành.
  const remainingResponses = await Promise.all(
    Array.from({ length: totalPages - 1 }, (_, index) => (
      // Gọi API để lấy danh sách giao dịch từ các trang còn lại, với page được tính là index + 2 (vì index bắt đầu từ 0) và pageSize là kích thước trang đã định nghĩa trước đó.
      paymentApi.getAdminAllTransactions({ page: index + 2, pageSize })
    )),
  );

   
  return firstItems.concat(
    // Duyệt qua tất cả các phản hồi từ các trang còn lại và kết hợp dữ liệu giao dịch từ mỗi phản hồi vào mảng kết quả cuối cùng.
    ...remainingResponses.map((response) => (Array.isArray(response?.data) ? response.data : [])),
  );
};

// logic hiển thị thẻ thống kê với các thông tin như biểu tượng, nhãn, giá trị, màu sắc, độ trễ và ghi chú.
const StatCard = ({ icon: Icon, label, value, color, delay, note }) => (
  <motion.div
    initial={{ opacity: 0, scale: 0.9 }}
    animate={{ opacity: 1, scale: 1 }}
    transition={{ delay }}
    className="bg-slate-900 border border-slate-800 p-6 rounded-2xl relative overflow-hidden group"
  >
    {/* hiệu ứng*/}
    <div className={`absolute top-0 right-0 w-24 h-24 blur-3xl opacity-10 rounded-full -mr-8 -mt-8 ${color}`}></div>
    {/* Icon + thông tin */}
    <div className="flex items-center gap-4 relative z-10">
      {/* khung chứa icon */}
      <div className={`p-4 rounded-xl ${color.replace('bg-', 'bg-opacity-20 ')}`}>
        {/* icon */}
        <Icon className={color.replace('bg-', 'text-')} size={28} />
      </div>
       
      <div>
        {/* hiển thị tên */}
        <p className="text-slate-400 text-sm font-medium">{label}</p>
        {/* giá trị  */}
        <h3 className="text-2xl font-bold text-white mt-1">{value}</h3>
      </div>
    </div>
    {/* ghi chú */}
    <div className="mt-4 flex items-center gap-2 text-slate-500 text-xs">
      {/* Hiển thị phần tử giao diện span và nội dung con của nó. */}
      <span>{note}</span>
    </div>
  </motion.div>
);

// logic hiển thị trang tổng quan với các thông tin thống kê về phim, thể loại, doanh thu và thành viên.
const Dashboard = () => {
  // đây là các state để lưu trữ dữ liệu và trạng thái của trang tổng quan, bao gồm danh sách phim, tổng số phim, tổng số người dùng, danh sách thể loại, danh sách giao dịch, trạng thái tải dữ liệu và thông báo lỗi
  const [movies, setMovies] = useState([]);
  const [totalMovieCount, setTotalMovieCount] = useState(0);
  const [totalUserCount, setTotalUserCount] = useState(0);
  const [categories, setCategories] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');

  // logic lấy dữ liệu tổng quan từ API, bao gồm danh sách phim, thể loại, người dùng và giao dịch, và cập nhật các state tương ứng.
  const fetchDashboardData = useCallback(async () => {
    // Đặt trạng thái loading thành true để hiển thị giao diện tải dữ liệu.
    setLoading(true);
    // Đặt thông báo lỗi thành rỗng để xóa thông báo lỗi trước đó (nếu có).
    setErrorMsg('');
    // Bao bọc thao tác có thể lỗi để xử lý an toàn.
    try {
      // logic gọi API đồng thời để lấy dữ liệu tổng quan từ các nguồn khác nhau, bao gồm danh sách phim, thể loại, người dùng và giao dịch.
      const [movieRes, categoryRes, userRes, transactionRes] = await Promise.all([
        movieApi.getAll({ page: 1, pageSize: 100 }),
        categoryApi.getAll(),
        userApi.getAllUsers({ page: 1, pageSize: 1 }),
        // fetchAllTransactions là một hàm bất đồng bộ được định nghĩa trước đó để lấy tất cả các giao dịch từ API, bao gồm việc phân trang và kết hợp dữ liệu từ các trang khác nhau
        fetchAllTransactions(),
      ]);
      
      const movieData = movieRes?.data;
      // Cập nhật state movies với dữ liệu phim từ API, nếu dữ liệu không phải là mảng thì sử dụng giá trị mặc định là một mảng rỗng.
      setMovies(Array.isArray(movieData) ? movieData : movieData?.items || []);
      // Cập nhật state totalMovieCount với tổng số lượng phim từ API, nếu dữ liệu không phải là mảng thì sử dụng giá trị mặc định là 0. 
      setTotalMovieCount(Array.isArray(movieData) ? movieData.length : movieData?.totalCount || 0);
      // Cập nhật state categories với dữ liệu thể loại từ API, nếu dữ liệu không phải là mảng thì sử dụng giá trị mặc định là một mảng rỗng. 
      setCategories(Array.isArray(categoryRes?.data) ? categoryRes.data : []);
      
      const userData = userRes?.data;
      // Cập nhật state totalUserCount với tổng số lượng người dùng từ API, nếu dữ liệu không phải là mảng thì sử dụng giá trị mặc định là 0. 
      setTotalUserCount(Array.isArray(userData) ? userData.length : userData?.totalCount || 0);
      // Cập nhật state transactions với dữ liệu giao dịch từ API, nếu dữ liệu không phải là mảng thì sử dụng giá trị mặc định là một mảng rỗng. 
      setTransactions(Array.isArray(transactionRes) ? transactionRes : []);
    } catch (err) {
      // Nếu có lỗi xảy ra trong quá trình gọi API, đặt thông báo lỗi với thông tin lỗi hoặc một thông báo mặc định.
      setErrorMsg(err.message || 'Không thể tải dữ liệu tổng quan. Vui lòng thử lại!');
    } finally {
      // Đặt trạng thái loading thành false để kết thúc giao diện tải dữ liệu. 
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
   
  const successfulTransactions = transactions.filter(isSuccessfulTransaction);
   
  const totalRevenue = successfulTransactions.reduce((total, transaction) => total + (Number(transaction.amount) || 0), 0);
   
  const recentTransactionStats = getRecentTransactionStats(transactions);
   
  const recentRevenue = recentTransactionStats.reduce((total, item) => total + item.revenue, 0);


   
  return (
    <div className="space-y-8">
       
      <div>
         
        <h1 className="text-3xl font-bold text-white">Tổng quan hệ thống</h1>
         
        <p className="text-slate-400 mt-1">Chào mừng bạn trở lại, đây là dữ liệu mới nhất hôm nay.</p>
      </div>

      {errorMsg && (
        <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm p-3 rounded-xl">
          {errorMsg}
        </div>
      )}

       
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

       
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
         
        <div className="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-2xl p-6">
           
          <h2 className="text-xl font-bold text-white mb-6">Phim mới cập nhật</h2>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-10 text-slate-500">
               
              <Loader2 className="animate-spin mb-3" size={28} />
               
              <p>Đang tải danh sách phim...</p>
            </div>
          ) : recentMovies.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-10 text-slate-500">
              {/* Hiển thị phần tử giao diện Film và nội dung con của nó. */}
              <Film size={32} className="mb-3 opacity-50" />
               
              <p>Chưa có phim nào trong hệ thống.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {recentMovies.map((movie) => (
                <Link to={`/movies/${movie.id}`} key={movie.id} className="flex items-center justify-between p-4 bg-slate-800/50 rounded-xl border border-slate-700/50 hover:border-blue-500/50 transition-all cursor-pointer">
                   
                  <div className="flex items-center gap-4">
                     
                    <div className="w-12 h-16 bg-slate-700 rounded-lg overflow-hidden shrink-0">
                      {movie.posterUrl ? (
                        <img src={movie.posterUrl} alt={movie.title} className="w-full h-full object-cover" />
                      ) : null}
                    </div>
                     
                    <div>
                      {/* Hiển thị phần tử giao diện h4 và nội dung con của nó. */}
                      <h4 className="text-white font-semibold">{movie.title}</h4>
                       
                      <p className="text-slate-400 text-sm">
                        {(movie.categories || []).map((c) => c.name).join(', ') || 'Chưa gán thể loại'}
                        {movie.duration ? ` • ${movie.duration} phút` : ''}
                      </p>
                    </div>
                  </div>
                   
                  <div className="text-right">
                     
                    <p className="text-blue-400 font-bold">{movie.releaseYear || '—'}</p>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>

         
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
           
          <h2 className="text-xl font-bold text-white mb-6">Thể loại hiện có</h2>
          {loading ? (
            <div className="flex justify-center py-10 text-slate-500">
               
              <Loader2 className="animate-spin" size={28} />
            </div>
          ) : categories.length === 0 ? (
            <p className="text-slate-500 text-sm">Chưa có thể loại nào.</p>
          ) : (
            <div className="space-y-3">
              {categories.map((cat) => {
                 
                const movieCount = movies.filter((m) =>
                  (m.categories || []).some((c) => c.id === cat.id)
                ).length;
                 
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

       
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
         
        <div className="flex items-center justify-between gap-4 mb-6">
           
          <div>
             
            <h2 className="text-xl font-bold text-white">Doanh thu 7 ngày gần nhất</h2>
             
            <p className="text-sm text-slate-500 mt-1">Tổng doanh thu: {formatCurrency(recentRevenue)}</p>
          </div>
          {/* Hiển thị phần tử giao diện Receipt và nội dung con của nó. */}
          <Receipt className="text-emerald-400" size={24} />
        </div>

        {loading ? (
          <div className="flex justify-center py-10 text-slate-500">
             
            <Loader2 className="animate-spin" size={28} />
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-3">
              {recentTransactionStats.map((item) => (
                <div key={item.label} className="rounded-lg bg-slate-800/50 px-3 py-2 text-center">
                   
                  <p className="text-xs text-slate-500">{item.label}</p>
                   
                  <p className="text-sm font-semibold text-emerald-300 mt-1">{formatCurrency(item.revenue)}</p>
                   
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