# Sprint 6: Advanced Auth & Favorites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bổ sung phân hệ xác thực nâng cao (Đăng ký xác thực qua Email, Đăng nhập Username/Email kiểm tra kích hoạt, Đăng xuất, Quên và Đặt lại mật khẩu) và phân hệ Phim yêu thích (Favorites / My List) cho CineStream Backend.

**Architecture:** Mở rộng thực thể `User` với các trường xác thực email và token đặt lại mật khẩu; xây dựng `IEmailService` (Console/Logger trong môi trường đồ án, sẵn sàng mở rộng SMTP); nâng cấp `AuthService` với chu trình xác minh và reset mật khẩu; tận dụng bảng `Favorites` đã có trong EF Core để triển khai trọn vẹn `IFavoriteService` và `FavoritesController` bảo vệ bằng JWT `[Authorize]`.

**Tech Stack:** ASP.NET Core (.NET 10), Entity Framework Core 10, Npgsql (PostgreSQL), JWT Bearer Authentication, BCrypt.Net-Next, Data Annotations.

## Global Constraints
- Tuân thủ 100% quy chuẩn `GEMINI.md`: CẤM TUYỆT ĐỐI DÙNG ICON/EMOJI trong code, comment và tài liệu.
- Comment code văn phong kỹ sư chuyên nghiệp, tiếng Việt chuẩn mực, giải thích rõ logic nghiệp vụ.
- Tuân thủ quy trình kiểm thử TDD (Red -> Green -> Refactor) và kiểm chứng lệnh thực tế trước khi hoàn thành.
- Không tự ý chạy `git push` (Người dùng tự kiểm soát việc đẩy code lên remote).
- Đảm bảo tài khoản mẫu `admin@cinestream.com` và `user@cinestream.com` luôn có `IsEmailConfirmed = true` để không gây lỗi gián đoạn kịch bản demo đồ án.

---

## File Structure & Responsibilities

### Advanced Authentication Subsystem
- `Backend/Models/User.cs`: Bổ sung `IsEmailConfirmed`, `EmailConfirmationToken`, `EmailConfirmationTokenExpiresAt`, `PasswordResetToken`, `PasswordResetTokenExpiresAt`.
- `Backend/Services/Interfaces/IEmailService.cs`: Định nghĩa hợp đồng gửi email thông báo mã kích hoạt và mã đặt lại mật khẩu.
- `Backend/Services/Implementations/ConsoleEmailService.cs`: Hiện thực dịch vụ email ghi log định dạng chuẩn ra Terminal/Logger trong môi trường dev/demo (bảo đảm an toàn tuyệt đối khi chấm thi không phụ thuộc vào SMTP bên ngoài).
- `Backend/DTOs/Auth/AuthDtos.cs`: Bổ sung `VerifyEmailRequestDto`, `ResendVerificationEmailDto`, `ForgotPasswordRequestDto`, `ResetPasswordRequestDto`.
- `Backend/Services/Interfaces/IAuthService.cs`: Thêm các phương thức xác thực email và quên mật khẩu.
- `Backend/Services/Implementations/AuthService.cs`: Cài đặt logic sinh mã 6 số OTP/Token, xác minh thời hạn, kiểm tra trạng thái kích hoạt khi đăng nhập, băm lại mật khẩu mới.
- `Backend/Controllers/AuthController.cs`: Mở các endpoints RESTful mới (`/verify-email`, `/resend-verification`, `/forgot-password`, `/reset-password`, `/logout`).

### Favorites Subsystem
- `Backend/DTOs/Favorite/FavoriteDtos.cs`: Tạo `FavoriteDto` (thông tin phim yêu thích và ngày lưu), `FavoriteCheckDto`.
- `Backend/Services/Interfaces/IFavoriteService.cs`: Hợp đồng nghiệp vụ quản lý phim yêu thích.
- `Backend/Services/Implementations/FavoriteService.cs`: Xử lý thêm, xóa, kiểm tra và truy vấn danh sách phim yêu thích theo `UserId`.
- `Backend/Controllers/FavoritesController.cs`: Cung cấp 4 endpoints yêu thích được bảo vệ bằng `[Authorize]`.

---

### Task 1: User Entity Model Upgrade & Database Migration

**Files:**
- Modify: `Backend/Models/User.cs`
- Modify: `Backend/Data/DataSeeder.cs`
- Database Migration: `AddAdvancedAuthFieldsToUser`

- [ ] **Step 1: Cập nhật thực thể User**
Thêm các thuộc tính vào `Backend/Models/User.cs`:
```csharp
public bool IsEmailConfirmed { get; set; } = false;
public string? EmailConfirmationToken { get; set; }
public DateTime? EmailConfirmationTokenExpiresAt { get; set; }
public string? PasswordResetToken { get; set; }
public DateTime? PasswordResetTokenExpiresAt { get; set; }
```

- [ ] **Step 2: Tạo và thực thi Migration EF Core**
Chạy lệnh trong terminal:
```powershell
dotnet ef migrations add AddAdvancedAuthFieldsToUser --project Backend/Backend.csproj --startup-project Backend/Backend.csproj
dotnet ef database update --project Backend/Backend.csproj --startup-project Backend/Backend.csproj
```

- [ ] **Step 3: Cập nhật DataSeeder**
Đảm bảo khi seed `admin` và `user`, trường `IsEmailConfirmed = true` để phục vụ demo không bị gián đoạn.

- [ ] **Step 4: Kiểm tra biên dịch**
Run: `dotnet build Backend/Backend.csproj`
Expected: 0 Error(s).

---

### Task 2: Email Service Abstraction & Implementation

**Files:**
- Create: `Backend/Services/Interfaces/IEmailService.cs`
- Create: `Backend/Services/Implementations/ConsoleEmailService.cs`
- Modify: `Backend/Program.cs` (Đăng ký DI `IEmailService`)

- [ ] **Step 1: Tạo Interface IEmailService**
```csharp
namespace CineStream.Services.Interfaces;

public interface IEmailService
{
    Task SendEmailConfirmationAsync(string toEmail, string tokenOrCode);
    Task SendPasswordResetAsync(string toEmail, string tokenOrCode);
}
```

- [ ] **Step 2: Tạo ConsoleEmailService**
Ghi nhận mã kích hoạt/reset ra Console Logger và cung cấp link demo rõ ràng:
```csharp
namespace CineStream.Services.Implementations;

public class ConsoleEmailService : IEmailService
{
    private readonly ILogger<ConsoleEmailService> _logger;
    public ConsoleEmailService(ILogger<ConsoleEmailService> logger) => _logger = logger;
    // Ghi log chi tiet ma xac thuc
}
```

- [ ] **Step 3: Đăng ký Dependency Injection trong Program.cs**
`builder.Services.AddScoped<IEmailService, ConsoleEmailService>();`

---

### Task 3: DTOs cho Advanced Auth

**Files:**
- Modify: `Backend/DTOs/Auth/AuthDtos.cs`

- [ ] **Step 1: Thêm DTOs với Data Annotations**
```csharp
public class VerifyEmailRequestDto
{
    [Required(ErrorMessage = "Email khong duoc de trong!")]
    [EmailAddress(ErrorMessage = "Dinh dang email khong hop le!")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ma xac thuc khong duoc de trong!")]
    public string Code { get; set; } = string.Empty;
}

public class ResendVerificationEmailDto
{
    [Required(ErrorMessage = "Email khong duoc de trong!")]
    [EmailAddress(ErrorMessage = "Dinh dang email khong hop le!")]
    public string Email { get; set; } = string.Empty;
}

public class ForgotPasswordRequestDto
{
    [Required(ErrorMessage = "Email khong duoc de trong!")]
    [EmailAddress(ErrorMessage = "Dinh dang email khong hop le!")]
    public string Email { get; set; } = string.Empty;
}

public class ResetPasswordRequestDto
{
    [Required(ErrorMessage = "Email khong duoc de trong!")]
    [EmailAddress(ErrorMessage = "Dinh dang email khong hop le!")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ma xac thuc dat lai mat khau khong duoc de trong!")]
    public string Code { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mat khau moi khong duoc de trong!")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Mat khau moi phai co it nhat 6 ky tu!")]
    public string NewPassword { get; set; } = string.Empty;
}
```

---

### Task 4: Nâng cấp Nghiệp vụ AuthService

**Files:**
- Modify: `Backend/Services/Interfaces/IAuthService.cs`
- Modify: `Backend/Services/Implementations/AuthService.cs`

- [ ] **Step 1: Mở rộng IAuthService**
Thêm 4 phương thức:
- `Task<bool> VerifyEmailAsync(VerifyEmailRequestDto request);`
- `Task ResendVerificationEmailAsync(ResendVerificationEmailDto request);`
- `Task ForgotPasswordAsync(ForgotPasswordRequestDto request);`
- `Task<bool> ResetPasswordAsync(ResetPasswordRequestDto request);`

- [ ] **Step 2: Nâng cấp RegisterAsync**
Sinh mã OTP 6 số ngẫu nhiên, lưu vào `user.EmailConfirmationToken` với thời hạn 24 giờ (`EmailConfirmationTokenExpiresAt = DateTime.UtcNow.AddHours(24)`). Gọi `_emailService.SendEmailConfirmationAsync`.

- [ ] **Step 3: Nâng cấp LoginAsync**
Nếu `!user.IsEmailConfirmed`, quăng ngoại lệ hoặc trả về cảnh báo yêu cầu xác nhận email trước khi đăng nhập.

- [ ] **Step 4: Cài đặt VerifyEmailAsync, ForgotPasswordAsync, ResetPasswordAsync**
Kiểm tra mã code khớp và thời hạn còn hiệu lực; cập nhật mật khẩu băm mới khi reset.

---

### Task 5: AuthController Endpoints

**Files:**
- Modify: `Backend/Controllers/AuthController.cs`

- [ ] **Step 1: Viết endpoints mới trong AuthController**
- `POST /api/auth/verify-email`: Xác nhận tài khoản người dùng qua mã.
- `POST /api/auth/resend-verification`: Gửi lại mã kích hoạt.
- `POST /api/auth/forgot-password`: Yêu cầu cấp mã đặt lại mật khẩu.
- `POST /api/auth/reset-password`: Đổi mật khẩu mới kèm mã xác thực.
- `POST /api/auth/logout`: Đăng xuất (xác nhận thành công từ máy chủ).

---

### Task 6: Favorites DTOs & Service

**Files:**
- Create: `Backend/DTOs/Favorite/FavoriteDtos.cs`
- Create: `Backend/Services/Interfaces/IFavoriteService.cs`
- Create: `Backend/Services/Implementations/FavoriteService.cs`
- Modify: `Backend/Program.cs` (Đăng ký DI `IFavoriteService`)

- [ ] **Step 1: Tạo FavoriteDtos**
```csharp
public class FavoriteDto
{
    public int MovieId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? PosterUrl { get; set; }
    public int? ReleaseYear { get; set; }
    public int? Duration { get; set; }
    public List<string> Categories { get; set; } = new();
    public DateTime AddedAt { get; set; }
}

public class FavoriteStatusDto
{
    public int MovieId { get; set; }
    public bool IsFavorite { get; set; }
}
```

- [ ] **Step 2: Tạo IFavoriteService & FavoriteService**
- `GetMyFavoritesAsync(int userId)`: Lấy danh sách phim yêu thích sắp xếp giảm dần theo ngày thêm.
- `AddFavoriteAsync(int userId, int movieId)`: Kiểm tra phim tồn tại, thêm vào bảng `Favorites`.
- `RemoveFavoriteAsync(int userId, int movieId)`: Xóa khỏi bảng `Favorites`.
- `IsFavoriteAsync(int userId, int movieId)`: Kiểm tra trạng thái.

- [ ] **Step 3: Đăng ký DI trong Program.cs**
`builder.Services.AddScoped<IFavoriteService, FavoriteService>();`

---

### Task 7: FavoritesController

**Files:**
- Create: `Backend/Controllers/FavoritesController.cs`

- [ ] **Step 1: Xây dựng Controller với [Authorize]**
- `GET /api/favorites`: Lấy danh sách phim yêu thích của user từ JWT Claim `sub`/`nameidentifier`.
- `POST /api/favorites/{movieId}`: Thêm phim vào danh sách yêu thích.
- `DELETE /api/favorites/{movieId}`: Xóa phim khỏi danh sách yêu thích.
- `GET /api/favorites/check/{movieId}`: Kiểm tra trạng thái phim có trong yêu thích không.

---

### Task 8: Kiểm thử Toàn diện Sprint 6 (TDD & Verification)

**Files:**
- Create: `Backend/scratch/test_sprint6_suite.py`

- [ ] **Step 1: Viết kịch bản kiểm thử TDD tự động**
Kiểm thử tuần tự các ca:
1. Đăng ký tài khoản mới -> Nhận mã kích hoạt -> Thử đăng nhập khi chưa kích hoạt (bị từ chối 400).
2. Xác minh email với mã code -> Đăng nhập thành công (HTTP 200).
3. Quên mật khẩu -> Gửi email reset -> Đổi mật khẩu mới -> Đăng nhập bằng mật khẩu mới (HTTP 200).
4. Gọi đăng xuất (HTTP 200).
5. Thêm phim vào yêu thích (HTTP 200) -> Kiểm tra `isFavorite == true` -> Xem danh sách yêu thích (có phim).
6. Xóa phim khỏi yêu thích (HTTP 200) -> Kiểm tra `isFavorite == false`.
7. User chưa đăng nhập gọi Favorites -> Bị chặn `401 Unauthorized`.

- [ ] **Step 2: Thực thi kiểm thử và xác nhận 100% PASS**
Run: `python Backend/scratch/test_sprint6_suite.py`

---

### Task 9: Hoàn thiện Tài liệu & Đồng bộ Tri thức

**Files:**
- Modify: `README.md`
- Modify: `DEFENSE_GUIDE.md`
- Modify: `task.md`
- Run: `graphify update .`
