import { motion } from 'framer-motion';
import { Users, Play, TrendingUp, DollarSign } from 'lucide-react';

const StatCard = ({ icon: Icon, label, value, color, delay }) => (
  <motion.div
    initial={{ opacity: 0, scale: 0.9 }}
    animate={{ opacity: 1, scale: 1 }}
    transition={{ delay }}
    className="bg-slate-900 border border-slate-800 p-6 rounded-2xl relative overflow-hidden group"
  >
    <div className={`absolute top-0 right-0 w-24 h-24 blur-3xl opacity-10 rounded-full -mr-8 -mt-8 ${color}`}></div>
    <div className="flex items-center gap-4 relative z-10">
      <div className={`p-4 rounded-xl ${color.replace('bg-', 'bg-opacity-20 ')}`}>
        <Icon className={color.replace('bg-', 'text-')} size={28} />
      </div>
      <div>
        <p className="text-slate-400 text-sm font-medium">{label}</p>
        <h3 className="text-2xl font-bold text-white mt-1">{value}</h3>
      </div>
    </div>
    <div className="mt-4 flex items-center gap-2 text-green-400 text-sm">
      <TrendingUp size={16} />
      <span>+12.5% so với tháng trước</span>
    </div>
  </motion.div>
);

const Dashboard = () => {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white">Tổng quan hệ thống</h1>
        <p className="text-slate-400 mt-1">Chào mừng bạn trở lại, đây là dữ liệu mới nhất hôm nay.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard icon={Users} label="Tổng thành viên" value="45,280" color="bg-blue-500" delay={0.1} />
        <StatCard icon={Play} label="Lượt xem phim" value="1.2M" color="bg-purple-500" delay={0.2} />
        <StatCard icon={DollarSign} label="Doanh thu" value="$84,200" color="bg-green-500" delay={0.3} />
        <StatCard icon={TrendingUp} label="Gói đăng ký" value="12,500" color="bg-orange-500" delay={0.4} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h2 className="text-xl font-bold text-white mb-6">Phim thịnh hành gần đây</h2>
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex items-center justify-between p-4 bg-slate-800/50 rounded-xl border border-slate-700/50 hover:border-blue-500/50 transition-all cursor-pointer">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-16 bg-slate-700 rounded-lg animate-pulse"></div>
                  <div>
                    <h4 className="text-white font-semibold italic text-slate-500">Đang tải tên phim từ Backend...</h4>
                    <p className="text-slate-400 text-sm">Hành động • 2h 15p</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-blue-400 font-bold">8.5 IMDB</p>
                  <p className="text-slate-500 text-xs">24k lượt xem</p>
                </div>
              </div>
            ))}
          </div>
        </div>
        
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h2 className="text-xl font-bold text-white mb-6">Hoạt động mới nhất</h2>
          <div className="relative border-l border-slate-800 pl-6 space-y-6">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="relative">
                <div className="absolute -left-[31px] top-0 w-2.5 h-2.5 rounded-full bg-blue-600 shadow-[0_0_10px_rgba(37,99,235,0.8)]"></div>
                <p className="text-white text-sm font-medium italic text-slate-500">Admin vừa cập nhật phim mới</p>
                <p className="text-slate-500 text-xs mt-1">10 phút trước</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;