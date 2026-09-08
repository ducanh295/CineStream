# 🎬 CineStream — Danh Sách Tính Năng Sản Phẩm (Feature Spec)

> **Tài liệu dành cho**: Đội ngũ Frontend, Marketing và Product để viết bài giới thiệu, preview tính năng cho người dùng và đối chiếu giao diện người dùng (UI/UX).  
> **Nền tảng hỗ trợ**: Ứng dụng di động (Mobile App - Flutter) & Cổng quản trị Web (Admin Portal - React).

---

## I. TỔNG QUAN VỀ CINESTREAM

**CineStream** là nền tảng xem phim trực tuyến thế hệ mới, mang đến trải nghiệm điện ảnh mượt mà, nội dung phong phú từ phim lẻ điện ảnh (Movies) đến các series dài tập (TV Series). Hệ thống được thiết kế hướng tới trải nghiệm cá nhân hóa cao cấp và tích hợp trợ lý phim thông minh.

---

## II. TÍNH NĂNG DÀNH CHO NGƯỜI DÙNG (USER EXPERIENCE)

### 1. Khám Phá & Trải Nghiệm Nội Dung (Discovery & Streaming)
* **Trang chủ sống động (Home Banner & Featured)**: 
  * Hiển thị danh sách phim nổi bật (Hero Banner/Carousel).
  * Các danh mục thịnh hành: *Phim mới cập nhật, Phim lẻ đặc sắc, Series truyền hình hot*.
* **Bộ lọc thể loại linh hoạt (Genres & Categories)**: 
  * Phân loại đa dạng: Hành động, Viễn tưởng, Kinh dị, Tình cảm, Hoạt hình, Tâm lý...
  * Lọc phim theo thể loại chỉ với một chạm.
* **Tìm kiếm thông minh (Search)**:
  * Tìm kiếm tức thì theo từ khóa, tên phim tiếng Việt và tên gốc tiếng Anh.
* **Trang chi tiết phim toàn diện (Movie Detail)**:
  * Đầy đủ thông tin: Poster chất lượng cao, tóm tắt nội dung (synopsis), thời lượng, năm phát hành, danh sách thể loại.
  * Xem trước đoạn giới thiệu (Trailer Preview).
* **Trình phát video chuyên nghiệp (Video Streaming Player)**:
  * Trình phát video thích ứng (HLS / MP4 streaming), tối ưu băng thông và không gián đoạn.
  * Tùy chỉnh phát/tạm dừng, tua nhanh, toàn màn hình.

### 2. Xem Phim Bộ Đa Tầng (Series & Episodic Experience)
* **Cấu trúc phim bộ chuẩn quốc tế**:
  * Phân chia rõ ràng theo từng Mùa (Season 1, Season 2...).
  * Danh sách tập phim (Episodes) trực quan kèm số tập, tiêu đề và thời lượng từng tập.
* **Chọn tập mượt mà**:
  * Dễ dàng chuyển tập tiếp theo trực tiếp ngay trong trình phát video.

### 3. Cá Nhân Hóa (Personalization & My List)
* **Danh sách yêu thích (My List / Favorites)**:
  * Bấm lưu nhanh phim hoặc series yêu thích vào danh sách cá nhân.
  * Quản lý bộ sưu tập đã lưu, xóa khỏi danh sách khi đã xem xong.
* **Hồ sơ cá nhân (User Profile)**:
  * Tùy chỉnh tên hiển thị (Display Name), ảnh đại diện (Avatar) và tiểu sử cá nhân (Bio).

### 4. Xác Thực & Bảo Mật (Auth & Security)
* **Đăng ký & Đăng nhập linh hoạt**:
  * Đăng nhập tiện lợi bằng Email hoặc Username.
  * Đăng ký tài khoản mới nhanh chóng, xác thực mật khẩu bảo mật chuẩn mã hóa công nghiệp (BCrypt).
* **Đăng nhập một lần (Stateless JWT)**:
  * Phiên đăng nhập an toàn, duy trì trạng thái đăng nhập mượt mà trên thiết bị di động.

### 5. Trợ Lý AI Điện Ảnh (AI Movie Assistant — Tính năng cao cấp)
* **Chatbot tư vấn phim thông minh**:
  * Trò chuyện cùng trợ lý AI để nhận gợi ý phim theo tâm trạng, sở thích hoặc hoàn cảnh xem (xem cùng gia đình, xem một mình, phim giải tỏa stress...).
  * Lưu trữ lịch sử đoạn hội thoại với AI.

---

## III. TÍNH NĂNG DÀNH CHO QUẢN TRỊ VIÊN (ADMIN PORTAL)

Dành cho ban quản trị vận hành hệ thống qua Web Dashboard:

### 1. Quản lý Thể loại (Category Management)
* Xem danh sách toàn bộ thể loại phim hiện có trên hệ thống.
* Thêm mới thể loại kèm mô tả.
* Chỉnh sửa thông tin thể loại.
* Xóa mềm (Soft-delete) thể loại mà không làm hỏng dữ liệu liên kết cũ.

### 2. Quản lý Phim Lẻ (Movie Management)
* Quản lý kho phim lẻ: Tìm kiếm, lọc danh sách phim đã xuất bản.
* Thêm mới phim: Tiêu đề, mô tả, liên kết poster, đường dẫn trailer, link stream video, thời lượng, năm phát hành, gắn nhiều thể loại.
* Chỉnh sửa thông tin phim và cập nhật lại danh mục thể loại.
* Xóa phim khỏi hệ thống (xóa an toàn).

### 3. Quản lý Phim Bộ (Series Management)
* Quản lý thông tin chung của Series (Tên series, poster, trailer, năm phát hành).
* Quản lý Mùa phim (Thêm/Sửa các Season trong series).
* Quản lý Tập phim (Đăng tải link video từng tập, số tập, tên tập).

### 4. Quản lý Người dùng & Phân quyền (User Management)
* Danh sách người dùng trong hệ thống.
* Phân định vai trò rõ ràng: `User` (Người dùng thông thường) và `Admin` (Quản trị viên hệ thống).

---

## IV. PHÂN KỲ PHÁT TRIỂN (ROADMAP CHO FRONTEND TIỆN ĐỐI CHIẾU)

Nhằm giúp đội Frontend biết chính xác tính năng nào có API để kết nối ngay:

| Nhóm tính năng | Giai đoạn 1: Sơ khai (MVP test UI) | Giai đoạn 2: Hoàn thiện nâng cao |
|---|:---:|:---:|
| **Đăng ký / Đăng nhập / Lấy thông tin User** | ✅ Có ngay (JWT Token) | Refresh Token, Quên mật khẩu qua Email |
| **Danh mục Thể loại (CRUD)** | ✅ Có ngay (Đầy đủ) | Thống kê số lượng phim theo thể loại |
| **Kho Phim lẻ (Xem, Tìm kiếm, Lọc, Player)** | ✅ Có ngay (Kèm link stream mẫu) | Upload trực tiếp file video lớn từ Admin |
| **Phim bộ (Series, Season, Episode)** | ✅ Có ngay (Đầy đủ cấu trúc) | Tự động chuyển tập tiếp theo khi hết phim |
| **Yêu thích (My List: Thêm/Xóa/Xem)** | ✅ Có ngay (Kết nối DB thật) | Đánh dấu tiến độ đã xem (Continue Watching) |
| **Trợ lý Chatbot AI** | ⏳ Dành cho giai đoạn nâng cấp | Tích hợp Model AI tư vấn trực tiếp |
