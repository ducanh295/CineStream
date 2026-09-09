import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import AdminLayout from './layouts/AdminLayout';
import ProtectedRoute from './components/ProtectedRoute';
import Dashboard from './pages/Dashboard';
import Movies from './pages/Movies';
import Users from './pages/Users';
import Login from './pages/Login';

const Subscriptions = () => <div className="p-8 text-white text-2xl font-bold">Quản lý Gói dịch vụ - Coming Soon</div>;
const AiChat = () => <div className="p-8 text-white text-2xl font-bold">Hệ thống AI & Chatbot - Coming Soon</div>;
const Settings = () => <div className="p-8 text-white text-2xl font-bold">Cấu hình hệ thống - Coming Soon</div>;

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />

          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<AdminLayout />}>
              <Route index element={<Dashboard />} />
              <Route path="movies" element={<Movies />} />
              <Route path="users" element={<Users />} />
              <Route path="subscriptions" element={<Subscriptions />} />
              <Route path="ai-chat" element={<AiChat />} />
              <Route path="settings" element={<Settings />} />
            </Route>
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;