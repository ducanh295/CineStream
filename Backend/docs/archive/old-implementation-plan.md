# 🎬 CineStream Backend — Kế Hoạch Triển Khai

> **Nguyên tắc**: File nào → Code gì → Thứ tự nào → Kiểm tra bằng cách nào.
> **Approach**: Code-First (EF Core) — viết Entity class → Migration tự tạo DB.

---

## Quyết Định Kỹ Thuật (Đã Chốt)

| Quyết định | Chọn | Lý do |
|-----------|------|-------|
| .NET version | .NET 10 | Đã có sẵn trong project |
| Database | PostgreSQL + EF Core (Code-First) | Bạn chọn |
| Architecture | 3-Layer (Controller → Service → Repository) | Đủ clean cho portfolio, dễ hiểu |
| PK type | `int` auto-increment | Đơn giản, hiệu quả cho single-server |
| Naming convention | PascalCase (C# default) | Theo chuẩn .NET |
| Soft delete | Có (IsDeleted + DeletedAt) | Bảo vệ data quan trọng |
| Audit fields | Có (CreatedAt, UpdatedAt) | Tracking thay đổi |
| Auth | JWT Bearer Token | Stateless, phù hợp cho mobile + web |
| Response format | Wrapper chung `ApiResponse<T>` | Nhất quán cho frontend |

---

## Cấu Trúc Thư Mục (Toàn Bộ Project)

```
Backend/
├── Controllers/           ← Nhận request HTTP, gọi Service, trả response
├── Services/              ← Business logic (xử lý nghiệp vụ)
│   └── Interfaces/        ← Interface cho mỗi service
├── Repositories/          ← Truy vấn database qua EF Core
│   └── Interfaces/        ← Interface cho mỗi repository
├── Models/                ← Entity classes (map 1:1 với bảng DB)
│   └── Enums/             ← Các enum dùng chung
├── DTOs/                  ← Dữ liệu gửi/nhận từ client (không phải entity)
│   ├── Auth/
│   ├── Movies/
│   ├── Series/
│   ├── Categories/
│   └── Users/
├── Data/                  ← DbContext + cấu hình EF Core
│   └── Configurations/    ← Fluent API config cho từng entity
├── Middleware/             ← Xử lý lỗi, logging toàn cục
├── Helpers/               ← Tiện ích dùng chung (JWT, Pagination...)
├── docs/                  ← Tài liệu kế hoạch (file này)
├── Program.cs             ← Entry point + đăng ký DI
├── appsettings.json       ← Cấu hình (connection string, JWT secret...)
└── Backend.csproj         ← NuGet packages
```

---

## Danh Sách Entity Classes (Code-First)

Đây là tất cả entity bạn sẽ tạo trong thư mục `Models/`:

```
Models/
├── User.cs               ← Tài khoản người dùng
├── Profile.cs            ← Thông tin cá nhân (avatar, bio...)
├── Movie.cs              ← Phim lẻ
├── Series.cs             ← Phim bộ (chứa nhiều Season)
├── Season.cs             ← Mùa phim (chứa nhiều Episode)
├── Episode.cs            ← Tập phim
├── Category.cs           ← Thể loại phim (Action, Comedy...)
├── Actor.cs              ← Diễn viên
├── MovieCategory.cs      ← Bảng trung gian: Phim ↔ Thể loại (M:N)
├── MovieActor.cs         ← Bảng trung gian: Phim ↔ Diễn viên (M:N)
├── Favorite.cs           ← Phim yêu thích của user
├── Rating.cs             ← Đánh giá phim của user
├── ChatLog.cs            ← Lịch sử chat AI
└── Enums/
    ├── UserRole.cs       ← Admin, User
    └── MovieType.cs      ← Single (phim lẻ), Series (phim bộ)
```

**Quan hệ giữa các entity:**
```
User ──1:1──► Profile
User ──1:N──► Favorite
User ──1:N──► Rating
User ──1:N──► ChatLog

Movie ──M:N──► Category    (qua MovieCategory)
Movie ──M:N──► Actor       (qua MovieActor)
Movie ──1:N──► Rating
Movie ──1:N──► Favorite

Series ──1:N──► Season
Season ──1:N──► Episode
```

---

## Danh Sách API Endpoints

### Auth
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| POST | `/api/auth/register` | Guest | Đăng ký tài khoản |
| POST | `/api/auth/login` | Guest | Đăng nhập, nhận JWT |
| POST | `/api/auth/refresh-token` | User | Làm mới token |

### Users
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| GET | `/api/users` | Admin | Danh sách users (có pagination) |
| GET | `/api/users/{id}` | Admin/Self | Chi tiết user |
| PUT | `/api/users/{id}` | Admin/Self | Cập nhật user |
| DELETE | `/api/users/{id}` | Admin | Xóa user (soft delete) |
| GET | `/api/users/{id}/profile` | Admin/Self | Lấy profile |
| PUT | `/api/users/{id}/profile` | Self | Cập nhật profile |

### Movies
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| GET | `/api/movies` | All | Danh sách phim (pagination, filter, search) |
| GET | `/api/movies/{id}` | All | Chi tiết phim |
| POST | `/api/movies` | Admin | Thêm phim mới |
| PUT | `/api/movies/{id}` | Admin | Sửa phim |
| DELETE | `/api/movies/{id}` | Admin | Xóa phim (soft delete) |

### Series
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| GET | `/api/series` | All | Danh sách series |
| GET | `/api/series/{id}` | All | Chi tiết series (kèm seasons) |
| POST | `/api/series` | Admin | Thêm series |
| PUT | `/api/series/{id}` | Admin | Sửa series |
| DELETE | `/api/series/{id}` | Admin | Xóa series |
| GET | `/api/series/{id}/seasons` | All | Danh sách season của series |
| POST | `/api/series/{id}/seasons` | Admin | Thêm season |
| GET | `/api/seasons/{id}/episodes` | All | Danh sách episode của season |
| POST | `/api/seasons/{id}/episodes` | Admin | Thêm episode |

### Categories
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| GET | `/api/categories` | All | Danh sách thể loại |
| POST | `/api/categories` | Admin | Thêm thể loại |
| PUT | `/api/categories/{id}` | Admin | Sửa thể loại |
| DELETE | `/api/categories/{id}` | Admin | Xóa thể loại |

### Favorites
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| GET | `/api/favorites` | User | Danh sách phim yêu thích của mình |
| POST | `/api/favorites` | User | Thêm phim vào yêu thích |
| DELETE | `/api/favorites/{movieId}` | User | Bỏ phim khỏi yêu thích |

### Ratings
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| POST | `/api/movies/{id}/ratings` | User | Đánh giá phim |
| GET | `/api/movies/{id}/ratings` | All | Xem đánh giá của phim |

### File Upload (Phase sau)
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| POST | `/api/upload/poster` | Admin | Upload ảnh poster |
| POST | `/api/upload/video` | Admin | Upload video |

### AI Chatbox (Phase sau)
| Method | Endpoint | Ai dùng | Mô tả |
|--------|----------|---------|-------|
| POST | `/api/chat` | User | Gửi tin nhắn cho AI |
| GET | `/api/chat/history` | User | Lịch sử chat |

---

## Lộ Trình Triển Khai

### Phase 0: Nền Tảng (Foundation)

**Mục tiêu**: Project build được, kết nối DB được, có base classes dùng chung.

**Điều kiện trước**: Bạn cần cài PostgreSQL trên máy (hoặc dùng Docker). Đảm bảo PostgreSQL đang chạy.

---

#### Bước 0.1 — Cài NuGet packages

Mở terminal tại thư mục `Backend/`, chạy lần lượt:

```bash
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package AutoMapper.Extensions.Microsoft.DependencyInjection
dotnet add package FluentValidation.AspNetCore
```

Giải thích từng package:
| Package | Tác dụng |
|---------|---------|
| `Npgsql.EntityFrameworkCore.PostgreSQL` | Cho EF Core kết nối được với PostgreSQL |
| `Microsoft.EntityFrameworkCore.Design` | Cung cấp lệnh `dotnet ef migrations` trên terminal |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | Cho ASP.NET hiểu JWT token trong header Authorization |
| `AutoMapper.Extensions.Microsoft.DependencyInjection` | Tự động map Entity ↔ DTO (không cần gán từng field) |
| `FluentValidation.AspNetCore` | Viết validation rules (email hợp lệ, password đủ dài...) |

Cài thêm tool EF Core (chạy 1 lần, dùng mãi):
```bash
dotnet tool install --global dotnet-ef
```

**Kiểm tra**: Chạy `dotnet build` — phải thành công, không lỗi.

---

#### Bước 0.2 — Cấu hình connection string

Mở `appsettings.json`, thêm ConnectionString để kết nối PostgreSQL:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=CineStreamDb;Username=postgres;Password=YOUR_PASSWORD"
  },
  "Jwt": {
    "Key": "your-super-secret-key-at-least-32-characters-long",
    "Issuer": "CineStream",
    "Audience": "CineStreamApp",
    "ExpireMinutes": 60
  }
}
```

---

#### Bước 0.3 — Tạo base classes (Models)

Tạo các file theo thứ tự:

```
1. Models/Enums/UserRole.cs          ← enum: Admin, User
2. Models/Enums/MovieType.cs         ← enum: Single, Series
3. Models/BaseEntity.cs              ← class chung: Id, CreatedAt, UpdatedAt, IsDeleted, DeletedAt
4. Models/User.cs                    ← entity đầu tiên (kế thừa BaseEntity)
```

---

#### Bước 0.4 — Tạo DbContext + Configuration

```
5. Data/AppDbContext.cs                       ← DbContext chính (đăng ký entity, override SaveChanges cho audit fields)
6. Data/Configurations/UserConfiguration.cs   ← Fluent API: index, ràng buộc, max length...
```

---

#### Bước 0.5 — Tạo Response wrapper + Error middleware

```
7. DTOs/Common/ApiResponse.cs                    ← Class chung cho mọi response: { success, data, message, errors }
8. Middleware/ExceptionHandlingMiddleware.cs       ← Bắt mọi exception → trả JSON lỗi thay vì crash
```

---

#### Bước 0.6 — Cập nhật Program.cs

Sửa `Program.cs` để đăng ký:
- DbContext (kết nối PostgreSQL)
- CORS (cho frontend gọi được API)
- Exception middleware
- Swagger (để test API trên trình duyệt)

---

#### Bước 0.7 — Tạo Migration + Database

Chạy trên terminal:
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

**Kiểm tra Phase 0 hoàn thành:**
```
✅ dotnet build                    → thành công, không lỗi
✅ dotnet ef database update       → DB "CineStreamDb" xuất hiện trong PostgreSQL
✅ dotnet run                      → server chạy, mở Swagger trên trình duyệt được
```

---

### Phase 1: Authentication & Users

**Mục tiêu**: Đăng ký, đăng nhập, JWT hoạt động.

**Files cần tạo (theo thứ tự):**

```
1.  Models/Profile.cs                 ← Entity profile
2.  Data/Configurations/ProfileConfiguration.cs
3.  DTOs/Auth/RegisterRequest.cs      ← Dữ liệu đăng ký
4.  DTOs/Auth/LoginRequest.cs         ← Dữ liệu đăng nhập
5.  DTOs/Auth/AuthResponse.cs         ← Trả về JWT token
6.  DTOs/Users/UserDto.cs             ← Trả về thông tin user
7.  Helpers/JwtHelper.cs              ← Tạo + xác thực JWT token
8.  Repositories/Interfaces/IUserRepository.cs
9.  Repositories/UserRepository.cs
10. Services/Interfaces/IAuthService.cs
11. Services/AuthService.cs
12. Controllers/AuthController.cs     ← Register + Login endpoints
13. Services/Interfaces/IUserService.cs
14. Services/UserService.cs
15. Controllers/UsersController.cs    ← CRUD user endpoints
16. Program.cs                        ← Cập nhật: thêm JWT auth, DI cho services
```

**Kiểm tra**: Dùng Swagger hoặc .http file:
- POST `/api/auth/register` → tạo user thành công
- POST `/api/auth/login` → nhận JWT token
- GET `/api/users` (có token Admin) → danh sách users
- GET `/api/users` (không token) → 401 Unauthorized

---

### Phase 2: Movies & Categories

**Mục tiêu**: Admin CRUD phim + thể loại. User tìm kiếm + xem chi tiết.

**Files cần tạo (theo thứ tự):**

```
1.  Models/Category.cs
2.  Models/Movie.cs
3.  Models/Actor.cs
4.  Models/MovieCategory.cs           ← Bảng trung gian
5.  Models/MovieActor.cs              ← Bảng trung gian
6.  Data/Configurations/MovieConfiguration.cs
7.  Data/Configurations/CategoryConfiguration.cs
8.  Data/Configurations/ActorConfiguration.cs
9.  DTOs/Categories/CategoryDto.cs
10. DTOs/Categories/CreateCategoryRequest.cs
11. DTOs/Movies/MovieDto.cs
12. DTOs/Movies/MovieDetailDto.cs
13. DTOs/Movies/CreateMovieRequest.cs
14. DTOs/Movies/UpdateMovieRequest.cs
15. DTOs/Common/PaginationRequest.cs
16. DTOs/Common/PaginatedResponse.cs
17. Helpers/PaginationHelper.cs
18. Repositories/Interfaces/ICategoryRepository.cs
19. Repositories/CategoryRepository.cs
20. Services/Interfaces/ICategoryService.cs
21. Services/CategoryService.cs
22. Controllers/CategoriesController.cs
23. Repositories/Interfaces/IMovieRepository.cs
24. Repositories/MovieRepository.cs
25. Services/Interfaces/IMovieService.cs
26. Services/MovieService.cs
27. Controllers/MoviesController.cs
```

**Kiểm tra**:
- CRUD Categories hoạt động
- CRUD Movies hoạt động (có gắn categories)
- GET `/api/movies?search=avenger&page=1&pageSize=10` → pagination + search hoạt động

---

### Phase 3: Series & Episodes

**Mục tiêu**: Quản lý phim bộ (Series → Season → Episode).

**Files cần tạo:**

```
1.  Models/Series.cs
2.  Models/Season.cs
3.  Models/Episode.cs
4.  Data/Configurations/SeriesConfiguration.cs
5.  Data/Configurations/SeasonConfiguration.cs
6.  Data/Configurations/EpisodeConfiguration.cs
7.  DTOs/Series/SeriesDto.cs
8.  DTOs/Series/CreateSeriesRequest.cs
9.  DTOs/Series/SeasonDto.cs
10. DTOs/Series/EpisodeDto.cs
11. Repositories/Interfaces/ISeriesRepository.cs
12. Repositories/SeriesRepository.cs
13. Services/Interfaces/ISeriesService.cs
14. Services/SeriesService.cs
15. Controllers/SeriesController.cs
```

**Kiểm tra**: CRUD Series + Season + Episode hoạt động, quan hệ lồng nhau đúng.

---

### Phase 4: User Interactions (Favorites + Ratings)

**Mục tiêu**: User thêm phim yêu thích, đánh giá phim.

**Files cần tạo:**

```
1.  Models/Favorite.cs
2.  Models/Rating.cs
3.  Data/Configurations/FavoriteConfiguration.cs
4.  Data/Configurations/RatingConfiguration.cs
5.  DTOs/Favorites/FavoriteDto.cs
6.  DTOs/Ratings/CreateRatingRequest.cs
7.  DTOs/Ratings/RatingDto.cs
8.  Repositories/Interfaces/IFavoriteRepository.cs
9.  Repositories/FavoriteRepository.cs
10. Services/Interfaces/IFavoriteService.cs
11. Services/FavoriteService.cs
12. Controllers/FavoritesController.cs
13. Repositories/Interfaces/IRatingRepository.cs
14. Repositories/RatingRepository.cs
15. Services/Interfaces/IRatingService.cs
16. Services/RatingService.cs
17. Controllers/RatingsController.cs
```

**Kiểm tra**: User thêm/xóa favorite, đánh giá phim hoạt động.

---

### Phase 5+ (Sau khi Phase 0-4 xong)
- File Upload (poster, video)
- AI Chatbox
- Statistics Dashboard
- Movie Recommendation

*(Kế hoạch chi tiết sẽ viết khi đến lúc)*

---

## Tóm Tắt: Bạn Sẽ Làm Gì

```
Phase 0 (Foundation)   → 10 files  → Kết quả: Build + DB + Base classes
Phase 1 (Auth + Users) → 16 files  → Kết quả: Đăng nhập + JWT + CRUD Users
Phase 2 (Movies + Cat) → 27 files  → Kết quả: CRUD phim + thể loại + search
Phase 3 (Series)       → 15 files  → Kết quả: CRUD phim bộ
Phase 4 (Interactions) → 17 files  → Kết quả: Yêu thích + đánh giá
─────────────────────────────────────────────────────────────
Tổng Phase 0-4:        ~85 files   → Backend CRUD hoàn chỉnh
```
