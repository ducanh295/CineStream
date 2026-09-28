# CineStream - Hệ Sinh Thái Xem Phim Trực Tuyến Đa Nền Tảng

CineStream là hệ sinh thái truyền phát phim trực tuyến hiện đại được xây dựng theo kiến trúc hướng dịch vụ (Service-Oriented Architecture - SOA). Dự án tích hợp hạ tầng truyền phát video thích ứng (Adaptive Bitrate Streaming), cổng thanh toán tự động VietQR SePay, hệ thống quản trị nội dung toàn diện và trợ lý trí tuệ nhân tạo (AI Assistant) hỗ trợ gợi ý phim thông minh theo ngữ cảnh cảm xúc của người dùng.

Hệ thống bao gồm 3 phân hệ chính:
- **Backend API**: Máy chủ dịch vụ xây dựng trên nền tảng ASP.NET Core Web API (.NET 10) và cơ sở dữ liệu PostgreSQL.
- **WebAdmin**: Bảng điều khiển quản trị viên trực quan xây dựng bằng React 18, Vite và Tailwind CSS.
- **Mobile Client**: Ứng dụng xem phim di động đa nền tảng (Android và iOS) xây dựng bằng Flutter.

---

## Mục Lục

1. [Kiến Trúc Hệ Thống](#1-kiến-trúc-hệ-thống)
2. [Các Tính Năng Trọng Tâm](#2-các-tính-năng-trọng-tâm)
3. [Công Nghệ Áp Dụng](#3-công-nghệ-áp-dụng)
4. [Cấu Trúc Thư Mục Dự Án](#4-cấu-trúc-thư-mục-dự-án)
5. [Yêu Cầu Môi Trường Cài Đặt](#5-yêu-cầu-môi-trường-cài-đặt)
6. [Hướng Dẫn Cài Đặt và Khởi Chạy Từng Bước](#6-hướng-dẫn-cài-đặt-và-khởi-chạy-từng-bước)
   - [Bước 1: Clone kho mã nguồn](#bước-1-clone-kho-mã-nguồn)
   - [Bước 2: Cài đặt và cấu hình Cơ sở dữ liệu](#bước-2-cài-đặt-và-cấu-hình-cơ-sở-dữ-liệu)
   - [Bước 3: Khởi chạy Backend API](#bước-3-khởi-chạy-backend-api)
   - [Bước 4: Khởi chạy WebAdmin](#bước-4-khởi-chạy-webadmin)
   - [Bước 5: Khởi chạy Ứng dụng Di động Flutter](#bước-5-khởi-chạy-ứng-dụng-di-động-flutter)
7. [Hướng Dẫn Sử Dụng Tool Băm Phim HLS (split_video.bat)](#7-hướng-dẫn-sử-dụng-tool-băm-phim-hls-split_videobat)
8. [Hướng Dẫn Sử Dụng Hệ Thống Cho Người Dùng và Quản Trị Viên](#8-hướng-dẫn-sử-dụng-hệ-thống-cho-người-dùng-và-quản-trị-viên)
   - [8.1. Dành cho Người dùng cuối (Mobile App Flutter)](#81-dành-cho-người-dùng-cuối-mobile-app-flutter)
   - [8.2. Dành cho Quản trị viên (WebAdmin)](#82-dành-cho-quản-trị-viên-webadmin)
9. [Tài Khoản và Dữ Liệu Khởi Tạo (Seed Data)](#9-tài-khoản-và-dữ-liệu-khởi-tạo-seed-data)
10. [Kiểm Thử Tự Động (Automated Testing)](#10-kiểm-thử-tự-động-automated-testing)
11. [Bộ Danh Mục API Cốt Lõi](#11-bộ-danh-mục-api-cốt-lõi)

---

## 1. Kiến Trúc Hệ Thống

Hệ thống vận hành theo mô hình Client-Server không trạng thái (Stateless RESTful Architecture), giao tiếp thông qua giao thức HTTP/HTTPS với định dạng dữ liệu chuẩn JSON.

```
+-------------------------------------------------------------------------+
|                              CLIENT APPS                                |
|  - WebAdmin (React 18 + Vite)           [http://localhost:5173]         |
|  - Mobile App (Flutter Android/iOS)                                     |
|  - Scalar Interactive API Reference     [http://localhost:5182/scalar]  |
+------------------------------------+------------------------------------+
                                     |
                                     | RESTful API (JWT Bearer Token)
                                     v
+------------------------------------+------------------------------------+
|                   BACKEND API (.NET 10 WEB API)                         |
|  - Routing, Rate Limiting & Global Exception Handling Middleware        |
|  - Auth & Role-Based Access Control (RBAC: Admin / User)                |
|  - Controllers: Auth, Categories, Movies, Payments, AI, AdminUsers      |
|  - Business Services: AuthService, MovieService, PaymentService, ...    |
|  - Data Access: Entity Framework Core 10, Repositories, AppDbContext    |
+-------------------+--------------------+--------------------+-----------+
                    |                    |                    |
                    v                    v                    v
          +---------+--------+  +--------+--------+  +--------+--------+
          |   PostgreSQL 16  |  | Static Media    |  | External APIs   |
          |   (CineStreamDb) |  | HLS Engine      |  | - Gemini AI     |
          |   - Relational   |  | (wwwroot/       |  | - SePay VietQR  |
          |   - Soft Delete  |  |  videos/*.m3u8) |  | - Gmail SMTP    |
          +------------------+  +-----------------+  +-----------------+
```

---

## 2. Các Tính Năng Trọng Tâm

### 2.1. Hạ Tầng Truyền Phát Video Kép (Dual-Streaming Infrastructure)
- **HLS Phân Đoạn Công Nghiệp (HTTP Live Streaming - RFC 8216)**: Video được phân đoạn thành các tệp `.ts` độ dài tối ưu kèm danh sách phát `master.m3u8`, hỗ trợ tua mượt mà và tiết kiệm băng thông mạng.
- **Direct CDN MP4**: Hỗ trợ phát luồng trực tiếp từ các máy chủ đám mây (Google Cloud Storage) đối với các nội dung lưu trữ ngoài.

### 2.2. Trợ Lý AI Điện Ảnh Thông Minh (CineBot)
- Tích hợp mô hình Google Gemini qua giao thức REST API.
- **Kỹ thuật In-Context Semantic Injection**: Trước khi gửi câu hỏi tới AI, hệ thống tự động truy vấn danh mục phim hiện có trong cơ sở dữ liệu để đưa vào ngữ cảnh hệ thống (System Prompt), giúp AI tư vấn phim chuẩn xác theo cốt truyện, thể loại và cảm xúc của người dùng.
- Tự động lưu vết lịch sử hội thoại (Chat History) theo từng tài khoản.

### 2.3. Cổng Thanh Toán Tự Động VietQR SePay với Cơ Chế Dual-Sync
- **Sinh mã VietQR Napas động**: Tự động mã hóa ngân hàng, số tài khoản, số tiền và mã đơn hàng định danh duy nhất (`CINE...`).
- **Cơ chế đồng bộ kép (Dual-Sync)**:
  - *Kênh đẩy (Push - Webhook)*: SePay gửi thông báo biến động số dư khi có giao dịch chuyển khoản thành công.
  - *Kênh kéo (Pull - Polling Fallback)*: Trong môi trường phát triển cục bộ (`localhost`) hoặc khi Webhook bị trễ mạng, luồng kiểm tra trạng thái từ Client tự động truy vấn trực tiếp SePay Open API để đối soát số tiền và nội dung, tự động kích hoạt gói VIP cho người dùng chỉ sau 2-3 giây.
- **Quản trị giá gói VIP linh hoạt**: Bảng giá các gói cước (1 Tháng, 3 Tháng, 1 Năm) được lưu trữ động trong bảng cấu hình `SystemSettings`, cho phép Quản trị viên sửa giá trực tiếp dạng Inline trên WebAdmin mà không cần can thiệp mã nguồn.

### 2.4. Bảo Mật và Toàn Vẹn Dữ Liệu Doanh Nghiệp
- **Xác thực và phân quyền (RBAC)**: Cấp phát JSON Web Token (JWT) có mã hóa Claim vai trò (`Admin`, `User`).
- **Bảo toàn dữ liệu (Data Integrity)**: Cơ chế kiểm tra ràng buộc trước khi xóa thể loại; chặn xóa thể loại nếu còn phim liên kết và phản hồi lỗi HTTP 400 chi tiết.
- **Xóa mềm (Soft Delete)**: Tự động lọc các bản ghi đã xóa bằng Global Query Filter của EF Core, bảo vệ dữ liệu khỏi các thao tác xóa nhầm.

---

## 3. Công Nghệ Áp Dụng

| Phân hệ | Công nghệ / Thư viện | Vai trò |
| :--- | :--- | :--- |
| **Backend Core** | C# 13, .NET 10 (ASP.NET Core Web API) | Xây dựng API dịch vụ, logic nghiệp vụ trung tâm |
| **Cơ sở dữ liệu** | PostgreSQL 16+ | Lưu trữ dữ liệu quan hệ, chỉ mục tìm kiếm |
| **ORM** | Entity Framework Core 10, Npgsql | Truy vấn cơ sở dữ liệu theo phương pháp Code-First |
| **Bảo mật** | JWT Bearer, BCrypt.Net-Next | Xác thực không trạng thái và mã hóa mật khẩu an toàn |
| **Trí tuệ nhân tạo** | Google Gemini REST API | Phân tích ngôn ngữ tự nhiên và tư vấn phim |
| **Cổng thanh toán** | VietQR Napas API, SePay Open API | Tạo mã QR và đối soát biến động số dư tự động |
| **Tài liệu API** | Scalar API Reference, Microsoft OpenAPI | Giao diện kiểm thử và tài liệu hóa chuẩn OpenAPI 3.0 |
| **WebAdmin** | React 18, Vite, Tailwind CSS, Lucide Icons | Giao diện quản trị phim, danh mục, người dùng và bảng giá |
| **Mobile Client** | Flutter SDK 3.x (Dart), Dio, VideoPlayer | Ứng dụng xem phim đa nền tảng cho người dùng cuối |
| **Kiểm thử** | xUnit, .NET Test SDK | Bộ kiểm thử đơn vị tự động theo phương pháp TDD |

---

## 4. Cấu Trúc Thư Mục Dự Án

```
CineStream/
|-- Backend/                            # Máy chủ ASP.NET Core Web API (.NET 10)
|   |-- Controllers/                    # Các bộ điều khiển tiếp nhận HTTP Request
|   |-- Data/                           # AppDbContext, DataSeeder khởi tạo dữ liệu
|   |-- DTOs/                           # Data Transfer Objects cho từng phân hệ
|   |-- Middlewares/                    # Exception Handling Middleware toàn cục
|   |-- Models/                         # Thực thể cơ sở dữ liệu (Movie, User, ...)
|   |-- Repositories/                   # Tầng truy xuất dữ liệu theo Repository Pattern
|   |-- Services/                       # Tầng xử lý logic nghiệp vụ trung tâm
|   |-- wwwroot/                        # Thư mục chứa video phân đoạn HLS (.m3u8, .ts)
|   |-- split_video.bat                 # Tool băm phim MP4 sang định dạng HLS tự động
|   |-- appsettings.json                # Tệp cấu hình kết nối CSDL, JWT, Gemini, SePay
|   +-- Program.cs                      # Cấu hình Dependency Injection và Middleware
|
|-- Backend.Tests/                      # Bộ kiểm thử tự động (111 unit tests)
|   |-- Admin/                          # Kiểm thử tính năng quản trị người dùng
|   |-- AI/                             # Kiểm thử phân quyền và nạp ngữ cảnh AI
|   |-- Categories/                     # Kiểm thử logic ràng buộc khi xóa thể loại
|   |-- Movies/                         # Kiểm thử lọc, tìm kiếm và phân trang phim
|   +-- Payments/                       # Kiểm thử bảng giá động và SePay Polling Fallback
|
|-- Frontend/
|   |-- WebAdmin/                       # Trang quản trị React 18 + Vite + Tailwind CSS
|   |   |-- src/api/                    # Các module gọi API Backend (axios)
|   |   |-- src/components/             # Modal, Dialog xác nhận, Protected Route
|   |   |-- src/pages/                  # Dashboard, Movies, Categories, Subscriptions, Users
|   |   +-- package.json                # Danh sách thư viện frontend
|   |
|   +-- cinestream_mobile/              # Ứng dụng di động xem phim đa nền tảng Flutter
|       |-- lib/core/                   # Cấu hình API client, theme, hằng số hệ thống
|       |-- lib/models/                 # Data model phía client
|       |-- lib/screens/                # Màn hình xem phim, thanh toán QR, chat AI
|       |-- lib/services/               # Dịch vụ gọi API Backend
|       +-- pubspec.yaml                # Cấu hình dependencies Flutter
|
+-- README.md                           # Tài liệu hướng dẫn tổng quan dự án
```

---

## 5. Yêu Cầu Môi Trường Cài Đặt

Trước khi tiến hành cài đặt, máy tính của bạn cần được cài đặt sẵn các công cụ sau:

1. **.NET SDK 10.0**: Kiểm tra bằng lệnh `dotnet --version`.
2. **Node.js 18+ và npm**: Kiểm tra bằng lệnh `node -v` và `npm -v`.
3. **Flutter SDK 3.x**: Kiểm tra bằng lệnh `flutter --version` và `flutter doctor`.
4. **PostgreSQL 16+**: Hệ quản trị cơ sở dữ liệu đang hoạt động trên cổng mặc định `5432`.
5. **FFmpeg**: Phục vụ công cụ băm phim HLS. Kiểm tra bằng lệnh `ffmpeg -version`.
6. **Git**: Công cụ quản lý mã nguồn.

---

## 6. Hướng Dẫn Cài Đặt và Khởi Chạy Từng Bước

### Bước 1: Clone kho mã nguồn

Mở terminal hoặc Git Bash trên máy tính và chạy lệnh:

```bash
git clone https://github.com/ducanh295/CineStream.git
cd CineStream
```

---

### Bước 2: Cài đặt và cấu hình Cơ sở dữ liệu

1. **Tạo cơ sở dữ liệu PostgreSQL**:
   Mở công cụ pgAdmin hoặc terminal `psql` và tạo một cơ sở dữ liệu mới có tên `CineStreamDb`:
   ```sql
   CREATE DATABASE "CineStreamDb";
   ```

2. **Cập nhật chuỗi kết nối trong Backend**:
   Mở tệp `Backend/appsettings.json` và cập nhật thông tin tài khoản PostgreSQL của bạn tại mục `ConnectionStrings`:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Host=localhost;Port=5432;Database=CineStreamDb;Username=postgres;Password=mat_khau_cua_ban"
     },
     "JWT": {
       "Key": "your-super-secret-key-at-least-32-characters-long",
       "Issuer": "CineStream",
       "Audience": "CineStreamApp",
       "ExpireMinutes": 60
     },
     "Gemini": {
       "ApiKey": "YOUR_GEMINI_API_KEY",
       "Model": "gemini-3.5-flash-lite",
       "BaseUrl": "https://generativelanguage.googleapis.com/v1beta"
     },
     "SePay": {
       "BankName": "MB",
       "AccountNumber": "0385941522",
       "AccountName": "NGUYEN KHAC DUC ANH",
       "ApiKey": "YOUR_SEPAY_API_KEY"
     }
   }
   ```

> Lưu ý: Hệ thống đã tích hợp cơ chế tự động khởi tạo bảng (`Database.EnsureCreated()`) và nạp dữ liệu mẫu (`DataSeeder`) ngay khi khởi động, bạn không cần phải chạy lệnh Migration thủ công.

---

### Bước 3: Khởi chạy Backend API

Di chuyển vào thư mục `Backend` và tiến hành biên dịch, khởi chạy:

```bash
cd Backend

# Khôi phục các gói thư viện
dotnet restore

# Biên dịch kiểm tra lỗi
dotnet build

# Khởi chạy dịch vụ API
dotnet run
```

Sau khi khởi chạy thành công, máy chủ lắng nghe tại:
- **Địa chỉ API chính**: `http://localhost:5182`
- **Tài liệu kiểm thử Scalar API Reference**: `http://localhost:5182/scalar/v1`
- **Đặc tả OpenAPI JSON**: `http://localhost:5182/openapi/v1.json`

---

### Bước 4: Khởi chạy WebAdmin

Mở một cửa sổ Terminal mới và di chuyển vào thư mục `Frontend/WebAdmin`:

```bash
cd Frontend/WebAdmin

# Cài đặt các thư viện phụ thuộc
npm install

# Khởi chạy máy chủ phát triển
npm run dev
```

Sau khi khởi chạy, mở trình duyệt truy cập:
- **Địa chỉ giao diện**: `http://localhost:5173`

---

### Bước 5: Khởi chạy Ứng dụng Di động Flutter

Mở một cửa sổ Terminal mới và di chuyển vào thư mục `Frontend/cinestream_mobile`:

```bash
cd Frontend/cinestream_mobile

# Tải các gói thư viện Flutter
flutter pub get

# Kiểm tra danh sách thiết bị/máy ảo đang kết nối
flutter devices

# Khởi chạy ứng dụng trên máy ảo hoặc thiết bị thật
flutter run
```

> **Lưu ý cấu hình địa chỉ IP cho Mobile**:
> - Nếu chạy trên **Android Emulator**: Địa chỉ trỏ về máy chủ Backend cục bộ là `http://10.0.2.2:5182/api`.
> - Nếu chạy trên **iOS Simulator**: Sử dụng `http://localhost:5182/api`.
> - Nếu chạy trên **Thiết bị thật (Android/iOS vật lý)**: Thay thế bằng địa chỉ IPv4 nội bộ mạng WiFi của máy tính (ví dụ: `http://192.168.1.15:5182/api`).
> Cấu hình này nằm tại tệp `Frontend/cinestream_mobile/lib/core/constants/api_constants.dart`.

---

## 7. Hướng Dẫn Sử Dụng Tool Băm Phim HLS (`split_video.bat`)

Công cụ `Backend/split_video.bat` được xây dựng nhằm tự động hóa quy trình phân đoạn video MP4 thành định dạng chuẩn công nghiệp HTTP Live Streaming (HLS RFC 8216) phục vụ hệ thống streaming nội bộ của CineStream.

### 7.1. Lợi ích của việc băm phim sang HLS
- **Tối ưu băng thông**: Trình phát chỉ tải từng đoạn nhỏ 6 giây (`.ts`) thay vì tải cả tệp MP4 hàng gigabyte.
- **Tua phim tức thì**: Người dùng có thể nhảy tới bất kỳ mốc thời gian nào mà không phải chờ tải trước toàn bộ video.
- **Bảo mật nội dung**: Chống lộ trực tiếp đường dẫn tệp MP4 gốc trên máy chủ.
- **Hỗ trợ đa định dạng video**: Tự động chuyển đổi các codec video phức tạp (như VP9, AV1 từ YouTube) về chuẩn H.264 tương thích 100% với cả Web lẫn ứng dụng di động.

### 7.2. Yêu cầu tiên quyết
- Máy tính đã cài đặt **FFmpeg** và thêm vào biến môi trường `PATH`. Kiểm tra bằng lệnh:
  ```bash
  ffmpeg -version
  ```
- *Tăng tốc phần cứng (Tùy chọn)*: Hỗ trợ card đồ họa NVIDIA (NVENC) để mã hóa siêu tốc. Nếu máy tính không có card NVIDIA, script sẽ tự động nhận diện và chuyển sang mã hóa bằng CPU (`libx264`).

### 7.3. Cách sử dụng công cụ băm phim

Bạn có thể thực hiện theo 1 trong 2 cách sau:

**Cách 1: Kéo thả trực quan (Khuyên dùng)**
1. Mở thư mục `Backend/` trong Windows Explorer.
2. Kéo trực tiếp tệp phim định dạng `.mp4` của bạn và thả vào tệp `split_video.bat`.
3. Cửa sổ Command Prompt xuất hiện, hiển thị tên video đầu vào.
4. Nhập tên thư mục muốn lưu trữ (hoặc nhấn `ENTER` để lấy theo tên tệp mặc định).
5. Quá trình băm phim tự động diễn ra. Khi hoàn tất, tệp danh sách phát `master.m3u8` và các mảnh video `.ts` sẽ được sinh ra tại thư mục:
   ```
   Backend/wwwroot/videos/<ten_thu_muc>/
   ```

**Cách 2: Chạy từ dòng lệnh Terminal**
```cmd
cd Backend
split_video.bat "D:\Videos\my_movie.mp4"
```

### 7.4. Hướng dẫn gán luồng HLS vào phim trên WebAdmin
1. Đăng nhập trang quản trị WebAdmin (`http://localhost:5173`).
2. Vào mục **Quản lý phim** -> Bấm **Thêm phim mới** (hoặc Sửa phim có sẵn).
3. Tại ô nhập **Video URL**, bấm nút **"Kho HLS nội bộ"**:
   - Hệ thống hiển thị danh sách các thư mục phim đã được băm sẵn trong thư mục `wwwroot/videos/`.
   - Nhấp chuột chọn thư mục phim bạn vừa băm (ví dụ: `my_movie`).
   - Đường dẫn `/videos/my_movie/master.m3u8` sẽ được tự động điền vào ô Video URL chỉ bằng 1 cú nhấp chuột.
4. Điền các thông tin khác (Tên phim, mô tả, ảnh poster, thể loại) và bấm **Lưu thay đổi**.

### 7.5. Kiểm tra phát thử luồng HLS trực tiếp
Sau khi băm phim xong, bạn có thể kiểm tra trực tiếp khả năng phát luồng HLS trên trình duyệt bằng cách truy cập:
```
http://localhost:5182/player.html
```
Dán đường dẫn HLS (ví dụ: `/videos/my_movie/master.m3u8`) và bấm phát để kiểm tra chất lượng video, phụ đề và khả năng tua thời gian.

---

## 8. Hướng Dẫn Sử Dụng Hệ Thống Cho Người Dùng và Quản Trị Viên

### 8.1. Dành cho Người dùng cuối (Mobile App Flutter)

1. **Đăng ký và Đăng nhập**:
   - Mở ứng dụng CineStream trên điện thoại hoặc máy ảo.
   - Bấm "Đăng ký" nếu chưa có tài khoản, hoặc nhập tài khoản người dùng thử nghiệm: `user@cinestream.com` / `User@123`.
2. **Khám phá và Xem phim**:
   - Màn hình chính hiển thị Banner phim mới nhất, các hàng danh mục phim theo thể loại (Hành Động, Viễn Tưởng, Hoạt Hình, ...).
   - Nhấn vào bộ phim bất kỳ để xem chi tiết: diễn viên, đạo diễn, điểm đánh giá, tóm tắt cốt truyện.
   - Bấm **"Xem phim ngay"**: Trình phát Video Player tích hợp sẽ tự động nhận diện luồng phát (HLS hoặc MP4), hỗ trợ phóng to toàn màn hình, tua tiến/lùi 10 giây, điều chỉnh âm lượng và độ sáng.
3. **Nâng cấp gói tài khoản VIP (VietQR SePay)**:
   - Vào mục **Tài khoản** -> Chọn **Nâng cấp VIP**.
   - Chọn gói dịch vụ mong muốn (Gói 1 Tháng, 3 Tháng hoặc 1 Năm).
   - Màn hình hiển thị mã QR VietQR Napas chuẩn ngân hàng kèm thông tin chuyển khoản (Số tiền, số tài khoản MBBank, nội dung chuyển khoản `CINE...`).
   - Mở ứng dụng ngân hàng hoặc MoMo trên điện thoại và quét mã QR để chuyển khoản.
   - Nhờ cơ chế **Dual-Sync Polling Fallback**, chỉ sau 2-3 giây kể từ khi ngân hàng báo chuyển tiền thành công, ứng dụng CineStream sẽ tự động phát hiện, chúc mừng và nâng cấp tài khoản của bạn lên VIP với đầy đủ quyền lợi.
4. **Trò chuyện cùng Trợ lý AI CineBot**:
   - Nhấn vào biểu tượng Chat AI trên thanh điều hướng.
   - Nhập cảm xúc hoặc mong muốn (ví dụ: *"Tôi đang buồn, hãy gợi ý cho tôi một bộ phim hài nhẹ nhàng của Châu Tinh Trì"*).
   - Trợ lý AI CineBot sẽ phân tích ngữ cảnh, đối soát với kho phim thực tế của CineStream và đưa ra lời khuyên phù hợp kèm nút chuyển nhanh đến bộ phim được gợi ý.

---

### 8.2. Dành cho Quản trị viên (WebAdmin)

1. **Đăng nhập Quản trị viên**:
   - Truy cập `http://localhost:5173/login`.
   - Đăng nhập bằng tài khoản: `admin@cinestream.com` / `Admin@123`.
2. **Bảng điều khiển (Dashboard)**:
   - Theo dõi tổng số phim, tổng số thể loại, tổng số người dùng và tổng doanh thu nạp VIP theo thời gian thực.
3. **Quản lý Thể loại (Categories)**:
   - Thêm thể loại mới, chỉnh sửa mô tả.
   - Bảng hiển thị cột **Số lượng phim** đang liên kết với từng thể loại.
   - **Cơ chế bảo vệ dữ liệu**: Nếu một thể loại đang có phim liên kết, hệ thống sẽ cảnh báo và chặn thao tác xóa nhằm bảo đảm toàn vẹn dữ liệu hệ thống.
4. **Quản lý Phim (Movies)**:
   - Thêm phim mới, chỉnh sửa thông tin, đổi ảnh bìa, phân loại nhiều danh mục cho phim.
   - Chọn nguồn video: Nhập link CDN MP4 hoặc bấm nút "Kho HLS nội bộ" để chọn thư mục phim đã băm bằng `split_video.bat`.
5. **Quản trị Bảng giá gói VIP (Subscriptions)**:
   - Trang hiển thị bảng giá niêm yết các gói VIP (1 Tháng, 3 Tháng, 1 Năm).
   - **Tính năng sửa giá nhanh Inline**: Bấm nút **"Sửa giá"** ngay trên thẻ gói VIP, nhập số tiền mới (tối thiểu từ 1.000 VNĐ), nhấn `Enter` để lưu hoặc `Esc` để hủy. Giá mới sẽ ngay lập tức được áp dụng cho mọi đơn hàng tạo mới trên cả WebAdmin lẫn Mobile App.
   - **Lịch sử giao dịch**: Xem danh sách toàn bộ các giao dịch nạp tiền, lọc theo trạng thái (Chờ thanh toán, Thành công, Thất bại), kiểm tra mã giao dịch ngân hàng.
   - **Mô phỏng thanh toán (Demo)**: Cho phép Quản trị viên bấm nút "Mô phỏng thanh toán thành công" đối với bất kỳ đơn hàng nào đang ở trạng thái Pending để phục vụ việc bảo vệ đồ án hoặc kiểm thử mà không cần thực sự chuyển tiền ngân hàng.
6. **Quản lý Người dùng (Users)**:
   - Xem danh sách thành viên hệ thống, ngày tham gia, vai trò và trạng thái VIP.
   - Khóa tài khoản vi phạm kèm lý do, mở khóa tài khoản.
   - Điều chỉnh hoặc cấp thời hạn VIP thủ công cho từng người dùng.

---

## 9. Tài Khoản và Dữ Liệu Khởi Tạo (Seed Data)

Khi khởi động lần đầu, hệ thống tự động nạp sẵn các tài khoản và nội dung phim phục vụ kiểm thử và thuyết trình:

### 9.1. Tài khoản mặc định

| Vai trò | Email đăng nhập | Mật khẩu | Đặc quyền |
| :--- | :--- | :--- | :--- |
| **Quản trị viên (Admin)** | `admin@cinestream.com` | `Admin@123` | Toàn quyền quản trị phim, thể loại, người dùng, xem toàn bộ giao dịch, sửa giá gói VIP |
| **Người dùng thường (User)** | `user@cinestream.com` | `User@123` | Xem phim thường, trò chuyện với trợ lý AI, nạp tiền mua gói VIP |

### 9.2. Dữ liệu phim và luồng phát mẫu

Hệ thống có sẵn các bộ phim mẫu để trải nghiệm đầy đủ 2 cơ chế streaming:
1. **Đại Thoại Tây Du**: Định dạng HLS nội bộ phục vụ từ máy chủ Backend (`/videos/1/master.m3u8`), gồm trọn vẹn các phân đoạn `.ts`.
2. **Tears of Steel**: Định dạng HLS nội bộ (`/videos/2/master.m3u8`).
3. **Big Buck Bunny**: Phát luồng trực tiếp CDN Direct MP4.
4. **Sintel**: Phát luồng trực tiếp CDN Direct MP4.
5. **Elephant's Dream**: Phát luồng trực tiếp CDN Direct MP4.

---

## 10. Kiểm Thử Tự Động (Automated Testing)

Dự án áp dụng quy trình kiểm thử nghiêm ngặt theo phương pháp Phát triển Hướng Kiểm thử (Test-Driven Development - TDD).

Để chạy toàn bộ bộ kiểm thử đơn vị của Backend, chạy lệnh sau tại thư mục gốc:

```bash
dotnet test Backend.Tests
```

**Báo cáo phạm vi kiểm thử hiện tại:**
- **Tổng số bài kiểm thử**: 111 bài kiểm thử tự động.
- **Tỷ lệ vượt qua**: 100% (Passed: 111, Failed: 0, Skipped: 0).
- **Các nhóm nghiệp vụ kiểm thử chính**:
  - `AdminUsersControllerTests`: Kiểm tra phân quyền, khóa/mở khóa tài khoản, chặn Admin tự xóa chính mình.
  - `CategoryServiceTests`: Kiểm tra nghiệp vụ chặn xóa thể loại khi còn phim liên kết.
  - `PaymentPlanTests`: Kiểm tra tính hợp lệ của bảng giá VIP động và tính năng sửa giá.
  - `SePayPollingFallbackTests`: Kiểm tra cơ chế tự động đối soát giao dịch SePay API khi không có Webhook.
  - `AiPremiumGatekeeperTests`: Kiểm tra bảo vệ quyền truy cập trợ lý AI và nạp ngữ cảnh danh mục phim.

---

## 11. Bộ Danh Mục API Cốt Lõi

### 11.1. Xác thực & Tài khoản (`/api/auth`)
- `POST /api/auth/register`: Đăng ký tài khoản người dùng mới.
- `POST /api/auth/login`: Xác thực đăng nhập và nhận JWT Token.
- `GET /api/auth/me`: Lấy thông tin tài khoản người dùng hiện tại (Yêu cầu JWT Token).
- `GET /api/auth/admin-check`: Kiểm tra quyền quản trị viên.

### 11.2. Thể loại phim (`/api/categories`)
- `GET /api/categories`: Lấy danh sách thể loại phim (Công khai).
- `GET /api/categories/{id}`: Xem chi tiết thể loại kèm số lượng phim liên kết (Công khai).
- `POST /api/categories`: Thêm thể loại mới (Yêu cầu quyền Admin).
- `PUT /api/categories/{id}`: Cập nhật thể loại (Yêu cầu quyền Admin).
- `DELETE /api/categories/{id}`: Xóa thể loại (Chặn xóa nếu còn phim liên kết, yêu cầu quyền Admin).

### 11.3. Quản lý phim & Truyền phát (`/api/movies`)
- `GET /api/movies`: Danh sách phim có hỗ trợ tìm kiếm, lọc theo thể loại và phân trang (Công khai).
- `GET /api/movies/{id}`: Xem thông tin chi tiết một bộ phim (Công khai).
- `GET /api/movies/{id}/playback`: Lấy thông tin luồng phát (Tự động nhận diện HLS m3u8 hoặc CDN MP4).
- `POST /api/movies`: Thêm phim mới kèm liên kết danh mục thể loại (Yêu cầu quyền Admin).
- `PUT /api/movies/{id}`: Chỉnh sửa thông tin phim (Yêu cầu quyền Admin).
- `DELETE /api/movies/{id}`: Xóa mềm phim khỏi hệ thống (Yêu cầu quyền Admin).

### 11.4. Thanh toán & Gói dịch vụ VIP (`/api/payments`)
- `GET /api/payments/plans`: Xem bảng giá niêm yết các gói VIP (Công khai).
- `PUT /api/payments/plans/{planType}`: Quản trị viên cập nhật giá gói VIP động (Yêu cầu quyền Admin).
- `POST /api/payments/create`: Tạo đơn thanh toán và sinh ảnh VietQR Napas tự động (Yêu cầu đăng nhập).
- `GET /api/payments/status/{orderCode}`: Kiểm tra trạng thái đơn hàng (Tự động kích hoạt cơ chế Polling Fallback đối soát SePay).
- `POST /api/payments/sepay-webhook`: Điểm tiếp nhận Webhook biến động số dư từ cổng SePay.
- `POST /api/payments/simulate/{orderCode}`: Kích hoạt mô phỏng thanh toán phục vụ kiểm thử và demo (Yêu cầu quyền Admin).
- `GET /api/payments/admin/all`: Xem toàn bộ lịch sử giao dịch phân trang (Yêu cầu quyền Admin).

### 11.5. Trợ lý AI Điện ảnh (`/api/ai`)
- `POST /api/ai/chat`: Gửi câu hỏi tư vấn phim và nhận phản hồi thông minh kèm mã phim gợi ý (Yêu cầu đăng nhập).
- `GET /api/ai/history`: Lấy lịch sử các phiên trò chuyện của người dùng (Yêu cầu đăng nhập).
- `DELETE /api/ai/history`: Xóa lịch sử trò chuyện của người dùng (Yêu cầu đăng nhập).

### 11.6. Quản trị người dùng (`/api/admin/users`)
- `GET /api/admin/users`: Danh sách người dùng hệ thống có phân trang và bộ lọc (Yêu cầu quyền Admin).
- `GET /api/admin/users/{id}`: Xem chi tiết thông tin và thống kê tương tác của người dùng (Yêu cầu quyền Admin).
- `POST /api/admin/users/{id}/lock`: Khóa tài khoản kèm lý do vi phạm (Yêu cầu quyền Admin).
- `POST /api/admin/users/{id}/unlock`: Mở khóa tài khoản (Yêu cầu quyền Admin).
- `DELETE /api/admin/users/{id}`: Xóa mềm tài khoản người dùng (Chặn tự xóa chính mình, yêu cầu quyền Admin).
- `PUT /api/admin/users/{id}/premium`: Cấp hoặc điều chỉnh thời hạn VIP thủ công (Yêu cầu quyền Admin).

---

## Bản Quyền và Tác Giả

Dự án được phát triển phục vụ mục đích học tập, nghiên cứu và bảo vệ đồ án chuyên ngành Công nghệ Thông tin. Mọi đóng góp và phản hồi xin vui lòng tạo Issue hoặc Pull Request trên kho lưu trữ mã nguồn.
