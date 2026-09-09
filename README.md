
## 1. TỔNG QUAN ĐỀ TÀI

CineStream là hệ sinh thái xem phim trực tuyến hiện đại được thiết kế theo kiến trúc hướng dịch vụ (Service-Oriented Architecture), tích hợp hạ tầng truyền phát video thích ứng (Adaptive Streaming) và trợ lý trí tuệ nhân tạo (AI Assistant) hỗ trợ người dùng khám phá điện ảnh theo ngữ cảnh cảm xúc.

### Các phân hệ trọng tâm
- **Hạ tầng Dual-Streaming**: Hỗ trợ đồng thời chuẩn truyền phát phân đoạn công nghiệp HLS (HTTP Live Streaming - RFC 8216) tối ưu băng thông và luồng trực tiếp CDN Direct MP4.
- **Trợ lý AI Điện ảnh Thông minh (CineBot)**: Tích hợp Google Gemini 2.5 Flash với kỹ thuật nạp ngữ cảnh dữ liệu động (In-Context Semantic Movie Injection) giúp gợi ý phim chuẩn xác theo tâm trạng và cốt truyện.
- **Bảo mật và Phân quyền Quản trị (RBAC)**: Kiến trúc phòng thủ nhiều tầng kết hợp JSON Web Token (JWT Claims), Authorization Policies (`AdminOnly`), Data Annotations Validation và chuẩn hóa cấu trúc dữ liệu lỗi `ApiResponse<T>`.
- **Tài liệu hóa API Trực quan**: Tích hợp chuẩn OpenAPI 3.0 và giao diện tài liệu động Scalar API Reference (`ScalarTheme.Moon`).

---

## 2. KIẾN TRÚC HỆ THỐNG (SYSTEM ARCHITECTURE)

```
[ Mobile App / Web Client / Scalar UI ]
                   |
                   | HTTP/HTTPS (RESTful API + JWT Bearer)
                   v
+-------------------------------------------------------------+
|               ASP.NET Core Web API (.NET 10)                |
|                                                             |
|  [ Controllers Layer ]                                      |
|    - AuthController                                         |
|    - CategoriesController                                   |
|    - MoviesController (CRUD + Dual-Streaming Playback)       |
|    - AIController (Chatbot + Semantic Context + History)    |
|                                                             |
|  [ Defense & Security Layer ]                               |
|    - JWT Authentication Middleware                          |
|    - Authorization Policy ("AdminOnly")                     |
|    - Data Annotations Model Validation Filter               |
|    - Global Exception & ApiResponse Normalization           |
|                                                             |
|  [ Services Layer ]                                         |
|    - AuthService, CategoryService, MovieService             |
|    - AIService (Gemini Client + Semantic Prompt Builder)    |
|    - JwtService, PasswordHasher                             |
|                                                             |
|  [ Repositories & Data Layer ]                              |
|    - Entity Framework Core 10 (Code-First)                  |
|    - AppDbContext (Global Query Filters: Soft Delete)       |
|    - Generic Repository Pattern                             |
|    - DataSeeder (.IgnoreQueryFilters Safe Seeding)          |
+--------------+------------------------------+---------------+
               |                              |
               v                              v
    +--------------------+       +----------------------------+
    | PostgreSQL 16+ DB  |       | HLS Static Media Engine    |
    | (Relational Data,  |       | (wwwroot/videos/)          |
    |  ChatLogs, Movies, |       | - master.m3u8 Playlists    |
    |  Categories, Users)|       | - 6-second .ts Segments    |
    +--------------------+       +----------------------------+
               |
               v External API
    +-----------------------------+
    | Google Gemini 2.5 Flash API |
    | (AI Movie Recommendation)   |
    +-----------------------------+
```

---

## 3. CÔNG NGHỆ ÁP DỤNG

| Thành phần | Công nghệ / Thư viện | Vai trò |
| :--- | :--- | :--- |
| **Nền tảng Backend** | C# 13 / .NET 10 (ASP.NET Core Web API) | Xử lý logic nghiệp vụ và cung cấp RESTful API |
| **Cơ sở dữ liệu** | PostgreSQL 16+ / Npgsql.EntityFrameworkCore | Lưu trữ dữ liệu quan hệ, chỉ mục tìm kiếm |
| **ORM** | Entity Framework Core 10 | Quản trị truy vấn dữ liệu Code-First |
| **Bảo mật** | Microsoft.AspNetCore.Authentication.JwtBearer | Xác thực không trạng thái (Stateless Authentication) |
| **Mã hóa mật khẩu** | BCrypt.Net-Next | Băm mật khẩu một chiều an toàn với Salt ngẫu nhiên |
| **AI Engine** | Google Gemini 2.5 Flash REST API | Xử lý ngôn ngữ tự nhiên và gợi ý phim thông minh |
| **Streaming Engine** | FFmpeg NVENC (GPU RTX 3050) / HLS RFC 8216 | Phân đoạn video MPEG-TS và sinh Master Playlist |
| **Tài liệu API** | Scalar.AspNetCore 2.0 / Microsoft.AspNetCore.OpenApi | Giao diện tài liệu tương tác kiểm thử trực quan |

---

## 4. HƯỚNG DẪN CÀI ĐẶT VÀ KHỞI CHẠY

### 4.1. Yêu cầu môi trường
- .NET SDK 10.0 trở lên.
- PostgreSQL 16 trở lên (đang chạy trên cổng 5432).
- Python 3.10+ (phục vụ chạy kịch bản kiểm thử TDD tự động).

### 4.2. Cấu hình chuỗi kết nối và API Key
Kiểm tra và cập nhật file `Backend/appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=cinestream_db;Username=postgres;Password=your_password"
  },
  "JwtSettings": {
    "SecretKey": "ChuoiKhoaBiMatJWTChoHeThongCineStream2026DuAnTotNghiep",
    "Issuer": "CineStreamAuthServer",
    "Audience": "CineStreamClients",
    "ExpiryInHours": 24
  },
  "Gemini": {
    "ApiKey": "YOUR_GEMINI_API_KEY",
    "Model": "gemini-2.5-flash",
    "ApiUrl": "https://generativelanguage.googleapis.com/v1beta/models"
  }
}
```

### 4.3. Chạy ứng dụng
Mở terminal tại thư mục gốc của dự án:
```bash
# Di chuyển vào thư mục Backend
cd Backend

# Biên dịch kiểm tra mã nguồn
dotnet build

# Khởi chạy máy chủ Backend
dotnet run
```
Sau khi khởi chạy thành công, máy chủ lắng nghe tại:
- Cổng HTTP: `http://localhost:5182`
- Giao diện tài liệu Scalar API Reference: `http://localhost:5182/scalar/v1`
- OpenAPI Specification: `http://localhost:5182/openapi/v1.json`

---

## 5. TÀI KHOẢN VÀ DỮ LIỆU MẪU (SEED DATA SẴN SÀNG DEMO)

Hệ thống được tích hợp bộ nạp dữ liệu tự động `DataSeeder` ngay khi khởi động, sẵn sàng phục vụ Hội đồng chấm thi mà không cần cấu hình thủ công:

### 5.1. Tài khoản mặc định
| Tài khoản | Email / Username | Mật khẩu | Quyền hạn (Role) | Chức năng kiểm thử |
| :--- | :--- | :--- | :--- | :--- |
| **Quản trị viên** | `admin@cinestream.com` / `admin` | `Admin@123` | `Admin` (1) | Toàn quyền CRUD thể loại, phim, quản trị |
| **Người dùng** | `user@cinestream.com` / `user` | `User@123` | `User` (0) | Xem phim, lọc phim, chat AI, bị chặn CRUD |

### 5.2. Danh mục 7 thể loại phim chuẩn
Hành Động, Hài Hước, Viễn Tưởng, Tình Cảm, Hoạt Hình, Võ Thuật, Phiêu Lưu.

### 5.3. Kho 5 phim mẫu phục vụ Demo luồng Streaming
1. **Đại Thoại Tây Du (Châu Tinh Trì)**:
   - Thể loại: Hài Hước, Hành Động, Võ Thuật.
   - Luồng phát: HLS nội bộ `/videos/1/master.m3u8` (Trọn vẹn 105 phút, 611 phân đoạn `.ts`).
2. **Tears of Steel (Chiến Binh Thép)**:
   - Thể loại: Viễn Tưởng, Hành Động.
   - Luồng phát: HLS nội bộ `/videos/2/master.m3u8`.
3. **Big Buck Bunny (Chú Thỏ Nổi Giận)**:
   - Thể loại: Hoạt Hình, Hài Hước.
   - Luồng phát: CDN Direct MP4 Google Storage.
4. **Sintel (Hành Trình Tìm Rồng)**:
   - Thể loại: Hoạt Hình, Phiêu Lưu.
   - Luồng phát: CDN Direct MP4 Google Storage.
5. **Elephant's Dream (Giấc Mơ Cơ Khí)**:
   - Thể loại: Viễn Tưởng, Hành Động.
   - Luồng phát: CDN Direct MP4 Google Storage.

---

## 6. DANH SÁCH BỘ ENDPOINTS CỐT LÕI

### 6.1. Xác thực & Hồ sơ (Authentication)
- `POST /api/auth/register`: Đăng ký tài khoản người dùng mới.
- `POST /api/auth/login`: Đăng nhập cấp phát JWT Token.
- `GET /api/auth/me`: Lấy thông tin cá nhân và quyền hạn hiện tại (Yêu cầu Token).
- `GET /api/auth/admin-check`: Kiểm tra quyền quản trị tập trung (Chỉ Admin).

### 6.2. Quản lý Thể loại (Categories)
- `GET /api/categories`: Lấy danh sách thể loại hoạt động (Public).
- `GET /api/categories/{id}`: Xem chi tiết thể loại (Public).
- `POST /api/categories`: Tạo thể loại mới (Admin Only).
- `PUT /api/categories/{id}`: Cập nhật thông tin thể loại (Admin Only).
- `DELETE /api/categories/{id}`: Xóa mềm thể loại (Admin Only).

### 6.3. Quản lý Phim & Phát luồng (Movies & Streaming Playback)
- `GET /api/movies?genre={id}&search={keyword}`: Danh sách phim có lọc thể loại và tìm kiếm (Public).
- `GET /api/movies/{id}`: Xem chi tiết thông tin phim (Public).
- `GET /api/movies/{id}/playback`: API phát luồng video thông minh (Tự động nhận diện HLS / CDN MP4) (Public).
- `POST /api/movies`: Thêm phim mới kèm danh sách thể loại liên kết (Admin Only).
- `PUT /api/movies/{id}`: Sửa thông tin phim và thể loại liên kết (Admin Only).
- `DELETE /api/movies/{id}`: Xóa mềm phim (Admin Only).

### 6.4. Trợ lý AI Điện ảnh (AI Assistant - CineBot)
- `POST /api/ai/chat`: Gửi câu hỏi tư vấn phim và nhận phản hồi thông minh kèm ID phim đề xuất (Yêu cầu Token).
- `GET /api/ai/history`: Lấy lịch sử các đoạn trò chuyện gần nhất của người dùng (Yêu cầu Token).
- `DELETE /api/ai/history`: Xóa mềm lịch sử trò chuyện của người dùng hiện tại (Yêu cầu Token).

---

## 7. TÀI LIỆU HỖ TRỢ BẢO VỆ ĐỒ ÁN
Vui lòng tham khảo tệp chi tiết [DEFENSE_GUIDE.md](DEFENSE_GUIDE.md) để xem:
- Kịch bản thuyết trình và Demo mẫu 5 phút ghi điểm trước Hội đồng.
- Cẩm nang trả lời 10 câu hỏi vấn đáp chuyên sâu về kiến trúc, an ninh và thuật toán.
