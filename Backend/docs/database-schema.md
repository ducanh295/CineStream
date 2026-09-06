# 🗄️ VietFlix Database Schema — Bản Thiết Kế Chi Tiết

> **Mục đích**: File này là bản vẽ chính xác từng bảng, từng cột.
> Khi viết Entity class trong `Models/`, bạn mở file này ra và code theo.

---

## Quy ước chung

| Ký hiệu | Ý nghĩa |
|----------|---------|
| **PK** | Primary Key (khóa chính) |
| **FK** | Foreign Key (khóa ngoại) |
| **UQ** | Unique (không được trùng) |
| **NN** | Not Null (bắt buộc phải có giá trị) |
| **?** | Nullable (có thể trống) |
| **DEF** | Default value (giá trị mặc định) |

---

## BaseEntity (Lớp cơ sở — không phải bảng riêng)

> Mọi bảng bên dưới có đánh dấu ✅ đều kế thừa các cột này.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| Id | `int` | `integer` | PK, auto-increment | EF Core tự nhận diện |
| CreatedAt | `DateTime` | `timestamp` | NN, DEF: `UtcNow` | Ngày tạo |
| UpdatedAt | `DateTime?` | `timestamp` | ? | Ngày cập nhật gần nhất |
| IsDeleted | `bool` | `boolean` | NN, DEF: `false` | Soft delete flag |
| DeletedAt | `DateTime?` | `timestamp` | ? | Ngày xóa mềm |

---

## 1. Users ✅ BaseEntity

> Tài khoản đăng nhập. Đăng nhập bằng Email HOẶC Username.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| Username | `string` | `varchar(50)` | NN, UQ | Tên đăng nhập, không trùng |
| Email | `string` | `varchar(255)` | NN, UQ | Email, không trùng |
| PasswordHash | `string` | `text` | NN | Mật khẩu đã mã hóa (KHÔNG lưu plain text) |
| Role | `UserRole` | `integer` | NN, DEF: `0` | 0 = User, 1 = Admin |

**Quan hệ:**
- 1 User → 1 Profile
- 1 User → N Favorite
- 1 User → N Rating
- 1 User → N ChatLog

---

## 2. Profiles ✅ BaseEntity

> Thông tin cá nhân. Tách khỏi User để sau này mở rộng dễ hơn.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| UserId | `int` | `integer` | FK → Users.Id, UQ | Mỗi user chỉ có 1 profile |
| DisplayName | `string?` | `varchar(100)` | ? | Tên hiển thị (khác Username) |
| AvatarUrl | `string?` | `varchar(500)` | ? | Link ảnh đại diện |
| Bio | `string?` | `varchar(500)` | ? | Giới thiệu ngắn |

---

## 3. Movies ✅ BaseEntity

> Phim lẻ (type = Single) hoặc đánh dấu phim bộ (type = Series).

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| Title | `string` | `varchar(255)` | NN | Tên phim |
| Description | `string?` | `text` | ? | Mô tả nội dung |
| PosterUrl | `string?` | `varchar(500)` | ? | Link ảnh poster |
| VideoUrl | `string?` | `varchar(500)` | ? | Link file master.m3u8 (HLS) |
| VideoStatus | `int` | `integer` | NN, DEF: `0` | Trạng thái: 0=Chưa có, 1=Đã upload |
| TrailerUrl | `string?` | `varchar(500)` | ? | Link trailer |
| Duration | `int?` | `integer` | ? | Thời lượng (phút), cho phim lẻ |
| ReleaseYear | `int?` | `integer` | ? | Năm phát hành |
| Type | `MovieType` | `integer` | NN, DEF: `0` | 0 = Single, 1 = Series |
| AverageRating | `double` | `double precision` | NN, DEF: `0` | Điểm trung bình (tính từ Rating) |
| ViewCount | `int` | `integer` | NN, DEF: `0` | Lượt xem |

**Quan hệ:**
- 1 Movie ↔ N Category (qua MovieCategory)
- 1 Movie ↔ N Actor (qua MovieActor)
- 1 Movie → N Rating
- 1 Movie → N Favorite

---

## 4. Series ✅ BaseEntity

> Phim bộ — chứa nhiều Season.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| Title | `string` | `varchar(255)` | NN | Tên phim bộ |
| Description | `string?` | `text` | ? | Mô tả nội dung |
| PosterUrl | `string?` | `varchar(500)` | ? | Poster chính |
| TrailerUrl | `string?` | `varchar(500)` | ? | Trailer |
| ReleaseYear | `int?` | `integer` | ? | Năm phát hành |
| AverageRating | `double` | `double precision` | NN, DEF: `0` | Điểm trung bình |
| ViewCount | `int` | `integer` | NN, DEF: `0` | Tổng lượt xem |

**Quan hệ:**
- 1 Series → N Season

---

## 5. Seasons ✅ BaseEntity

> Mùa phim của 1 Series.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| SeriesId | `int` | `integer` | FK → Series.Id, NN | Thuộc series nào |
| SeasonNumber | `int` | `integer` | NN | Mùa thứ mấy (1, 2, 3...) |
| Title | `string?` | `varchar(255)` | ? | Tên mùa (VD: "Season 1: Origin") |

**Quan hệ:**
- 1 Season → N Episode

---

## 6. Episodes ✅ BaseEntity

> Tập phim của 1 Season.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| SeasonId | `int` | `integer` | FK → Seasons.Id, NN | Thuộc season nào |
| EpisodeNumber | `int` | `integer` | NN | Tập thứ mấy |
| Title | `string?` | `varchar(255)` | ? | Tên tập |
| VideoUrl | `string?` | `varchar(500)` | ? | Link file master.m3u8 (HLS) |
| VideoStatus | `int` | `integer` | NN, DEF: `0` | Trạng thái: 0=Chưa có, 1=Đã upload |
| Duration | `int?` | `integer` | ? | Thời lượng (phút) |

---

## 7. Categories ✅ BaseEntity

> Thể loại phim (Action, Comedy, Horror...).

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| Name | `string` | `varchar(100)` | NN, UQ | Tên thể loại, không trùng |
| Description | `string?` | `varchar(500)` | ? | Mô tả thể loại |

---

## 8. Actors ✅ BaseEntity

> Diễn viên.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| Name | `string` | `varchar(100)` | NN | Tên diễn viên |
| PhotoUrl | `string?` | `varchar(500)` | ? | Ảnh diễn viên |

---

## 9. MovieCategories ❌ KHÔNG kế thừa BaseEntity

> Bảng trung gian: quan hệ N:N giữa Movie và Category.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| MovieId | `int` | `integer` | PK, FK → Movies.Id | Composite PK (khóa chính kép) |
| CategoryId | `int` | `integer` | PK, FK → Categories.Id | Composite PK |

---

## 10. MovieActors ❌ KHÔNG kế thừa BaseEntity

> Bảng trung gian: quan hệ N:N giữa Movie và Actor.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| MovieId | `int` | `integer` | PK, FK → Movies.Id | Composite PK |
| ActorId | `int` | `integer` | PK, FK → Actors.Id | Composite PK |

---

## 11. Favorites ❌ KHÔNG kế thừa BaseEntity

> Phim yêu thích của user. Chỉ cần Composite PK + thời gian thêm.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| UserId | `int` | `integer` | PK, FK → Users.Id | Composite PK |
| MovieId | `int` | `integer` | PK, FK → Movies.Id | Composite PK |
| CreatedAt | `DateTime` | `timestamp` | NN, DEF: `UtcNow` | Ngày thêm vào yêu thích |

---

## 12. Ratings ✅ BaseEntity

> Đánh giá phim. Mỗi user chỉ đánh giá 1 lần/phim.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| UserId | `int` | `integer` | FK → Users.Id, NN | Ai đánh giá |
| MovieId | `int` | `integer` | FK → Movies.Id, NN | Phim nào |
| Score | `int` | `integer` | NN | Điểm (1-10) |
| Comment | `string?` | `varchar(1000)` | ? | Nhận xét (tùy chọn) |

**Ràng buộc đặc biệt:** Unique(UserId, MovieId) — mỗi user chỉ rate 1 phim 1 lần.

---

## 13. ChatLogs ✅ BaseEntity

> Lịch sử chat AI.

| Cột | Kiểu C# | Kiểu DB | Ràng buộc | Ghi chú |
|-----|---------|---------|-----------|---------|
| *(BaseEntity)* | | | | Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt |
| UserId | `int` | `integer` | FK → Users.Id, NN | Ai chat |
| Message | `string` | `text` | NN | Nội dung tin nhắn |
| IsFromAI | `bool` | `boolean` | NN, DEF: `false` | true = AI trả lời, false = user gửi |

---

## Enums

### UserRole
| Giá trị | Số | Ý nghĩa |
|---------|------|---------|
| User | 0 | Người dùng thường |
| Admin | 1 | Quản trị viên |

### MovieType
| Giá trị | Số | Ý nghĩa |
|---------|------|---------|
| Single | 0 | Phim lẻ |
| Series | 1 | Phim bộ |

---

## Sơ đồ quan hệ tổng quan


Users ──1:1──► Profiles
Users ──1:N──► Favorites ◄──N:1── Movies
Users ──1:N──► Ratings   ◄──N:1── Movies
Users ──1:N──► ChatLogs

Movies ──M:N──► Categories   (qua MovieCategories)
Movies ──M:N──► Actors       (qua MovieActors)

Series ──1:N──► Seasons ──1:N──► Episodes


---

## Checklist: Bảng nào kế thừa BaseEntity?

| Bảng | Kế thừa? | Lý do |
|------|----------|-------|
| User | ✅ | Cần soft delete, audit |
| Profile | ✅ | Cần audit |
| Movie | ✅ | Cần soft delete, audit |
| Series | ✅ | Cần soft delete, audit |
| Season | ✅ | Cần audit |
| Episode | ✅ | Cần audit |
| Category | ✅ | Cần soft delete |
| Actor | ✅ | Cần soft delete |
| Rating | ✅ | Cần audit (sửa đánh giá) |
| ChatLog | ✅ | Cần audit |
| MovieCategory | ❌ | Bảng trung gian, chỉ cần 2 FK |
| MovieActor | ❌ | Bảng trung gian, chỉ cần 2 FK |
| Favorite | ❌ | Bảng trung gian + CreatedAt riêng |
