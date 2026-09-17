using Microsoft.EntityFrameworkCore;
using CineStream.Models;
using CineStream.Models.Enums;

namespace CineStream.Data;

// Khởi tạo dữ liệu mẫu cho hệ thống CineStream phục vụ bảo vệ đồ án tốt nghiệp
public static class DataSeeder
{
    public static async Task SeedAsync(WebApplication app)
    {
        using var scope = app.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await context.Database.MigrateAsync();

        await SeedUsersAsync(context);

        await SeedCategoriesAsync(context);

        await SeedMoviesAsync(context);
    }

    // Khởi tạo danh sách tài khoản người dùng và quản trị viên mặc định
    private static async Task SeedUsersAsync(AppDbContext context)
    {
        // 1. Tài khoản Quản trị viên (Admin)
        var existingAdmin = await context.Users.IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Username == "admin" || u.Email == "admin@cinestream.com");

        if (existingAdmin == null)
        {
            var admin = new User
            {
                Username = "admin",
                Email = "admin@cinestream.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"),
                Role = UserRole.Admin,
                IsEmailConfirmed = true,
                Profile = new Profile
                {
                    DisplayName = "Quản Trị Viên CineStream",
                    AvatarUrl = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
                    Bio = "Tài khoản quản trị hệ thống"
                }
            };
            await context.Users.AddAsync(admin);
        }
        else
        {
            if (existingAdmin.IsDeleted)
            {
                existingAdmin.IsDeleted = false;
                existingAdmin.DeletedAt = null;
                existingAdmin.UpdatedAt = DateTime.UtcNow;
            }

            if (!existingAdmin.IsEmailConfirmed)
            {
                existingAdmin.IsEmailConfirmed = true;
                existingAdmin.UpdatedAt = DateTime.UtcNow;
            }
        }

        // 2. Tài khoản Người dùng thông thường (User)
        var existingUser = await context.Users.IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Username == "user" || u.Email == "user@cinestream.com");

        if (existingUser == null)
        {
            var user = new User
            {
                Username = "user",
                Email = "user@cinestream.com",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("User@123"),
                Role = UserRole.User,
                IsEmailConfirmed = true,
                Profile = new Profile
                {
                    DisplayName = "Khách Xem Phim",
                    AvatarUrl = "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150",
                    Bio = "Thành viên đam mê điện ảnh"
                }
            };
            await context.Users.AddAsync(user);
        }
        else
        {
            if (existingUser.IsDeleted)
            {
                existingUser.IsDeleted = false;
                existingUser.DeletedAt = null;
                existingUser.UpdatedAt = DateTime.UtcNow;
            }

            if (!existingUser.IsEmailConfirmed)
            {
                existingUser.IsEmailConfirmed = true;
                existingUser.UpdatedAt = DateTime.UtcNow;
            }
        }

        await context.SaveChangesAsync();
    }

    // Khởi tạo danh mục các thể loại phim đa dạng
    private static async Task SeedCategoriesAsync(AppDbContext context)
    {
        var sampleCategories = new List<Category>
        {
            new Category { Name = "Hành Động", Description = "Phim kịch tính, rượt đuổi và chiến đấu mãn nhãn" },
            new Category { Name = "Hài Hước", Description = "Phim dí dỏm, tiếng cười sảng khoái và giải trí nhẹ nhàng" },
            new Category { Name = "Viễn Tưởng", Description = "Phim khoa học giả tưởng, du hành vũ trụ và tương lai" },
            new Category { Name = "Tình Cảm", Description = "Phim tâm lý, tình cảm lãng mạn và xúc động" },
            new Category { Name = "Hoạt Hình", Description = "Phim hoạt họa kỹ xảo 3D sống động phù hợp mọi lứa tuổi" },
            new Category { Name = "Võ Thuật", Description = "Phim võ thuật cổ truyền, đấu võ đỉnh cao" },
            new Category { Name = "Phiêu Lưu", Description = "Phim thám hiểm vùng đất mới và hành trình kỳ thú" }
        };

        foreach (var cat in sampleCategories)
        {
            var existingCat = await context.Categories.IgnoreQueryFilters()
                .FirstOrDefaultAsync(c => c.Name.ToLower() == cat.Name.ToLower());

            if (existingCat == null)
            {
                await context.Categories.AddAsync(cat);
            }
            else
            {
                // Khoi phuc the loai va cap nhat mo ta chuan cho du lieu demo luon hoan hao
                if (existingCat.IsDeleted)
                {
                    existingCat.IsDeleted = false;
                    existingCat.DeletedAt = null;
                }
                existingCat.Description = cat.Description;
                existingCat.UpdatedAt = DateTime.UtcNow;
            }
        }

        await context.SaveChangesAsync();
    }

    // Khởi tạo danh sách phim mẫu bao gồm luồng phát chuẩn HLS và Direct MP4
    private static async Task SeedMoviesAsync(AppDbContext context)
    {
        // Lấy danh mục ID của các thể loại đang hoạt động
        var categoryMap = await context.Categories
            .ToDictionaryAsync(c => c.Name.ToLower(), c => c.Id);

        var sampleMovies = new List<(Movie Movie, string[] Categories)>
        {
            // Phim 1: Đại Thoại Tây Du - Phim biểu tượng phát luồng HLS m3u8 (611 phân đoạn)
            (
                new Movie
                {
                    Title = "Đại Thoại Tây Du (Châu Tinh Trì)",
                    Description = "Tác phẩm kinh điển của điện ảnh Hồng Kông kết hợp giữa thần thoại Tây Du Ký và phong cách hài hước độc đáo của Châu Tinh Trì, kể về mối tình ngang trái và bi tráng giữa Tôn Ngộ Không (Chí Tôn Bảo) và Tử Hà Tiên Tử.",
                    PosterUrl = "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/1/master.m3u8",
                    Duration = 106,
                    ReleaseYear = 1995,
                    Type = MovieType.Single,
                    VideoStatus = 1
                },
                new[] { "Hài Hước", "Hành Động", "Võ Thuật" }
            ),
            // Phim 2: Tears of Steel - Phim viễn tưởng kỹ xảo VFX chuẩn HLS m3u8
            (
                new Movie
                {
                    Title = "Tears of Steel (Chiến Binh Thép)",
                    Description = "Trong bối cảnh tương lai viễn tưởng tại Amsterdam, một nhóm các nhà khoa học và chiến binh cố gắng thay đổi quá khứ bằng công nghệ du hành thời gian để giải cứu nhân loại khỏi sự thống trị của đội quân robot.",
                    PosterUrl = "https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/2/master.m3u8",
                    Duration = 12,
                    ReleaseYear = 2024,
                    Type = MovieType.Single,
                    VideoStatus = 1
                },
                new[] { "Viễn Tưởng", "Hành Động" }
            ),
            // Phim 3: Big Buck Bunny - Phim hoạt hình 3D hài hước phát CDN Direct MP4
            (
                new Movie
                {
                    Title = "Big Buck Bunny (Chú Thỏ Nổi Giận)",
                    Description = "Bộ phim hoạt hình 3D nổi tiếng của Blender Foundation kể về cuộc trả đũa hài hước đầy sáng tạo của chú thỏ khổng lồ tốt bụng trước ba kẻ chuyên ức hiếp muôn thú trong rừng già.",
                    PosterUrl = "https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
                    VideoUrl = "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4",
                    Duration = 10,
                    ReleaseYear = 2023,
                    Type = MovieType.Single,
                    VideoStatus = 1
                },
                new[] { "Hoạt Hình", "Hài Hước" }
            ),
            // Phim 4: Sintel - Phim phiêu lưu hoạt họa 3D phát CDN Direct MP4
            (
                new Movie
                {
                    Title = "Sintel (Hành Trình Tìm Rồng)",
                    Description = "Câu chuyện phiêu lưu xúc động về cô gái trẻ Sintel vượt qua sa mạc khắc nghiệt và vùng đất băng tuyết hiểm trở để tìm lại chú rồng nhỏ Scales mà cô đã cưu mang.",
                    PosterUrl = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=eRsGyueVLvQ",
                    VideoUrl = "https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4",
                    Duration = 15,
                    ReleaseYear = 2022,
                    Type = MovieType.Single,
                    VideoStatus = 1
                },
                new[] { "Hoạt Hình", "Phiêu Lưu" }
            ),
            // Phim 5: Elephant's Dream - Phim khoa học viễn tưởng máy móc phát CDN Direct MP4
            (
                new Movie
                {
                    Title = "Elephant's Dream (Giấc Mơ Cơ Khí)",
                    Description = "Một chuyến du hành thị giác kỳ ảo vào bên trong cỗ máy khổng lồ vô tận, nơi hai nhân vật Proog và Emo đối mặt với những ảo ảnh cơ khí và sự bất đồng trong nhận thức thế giới.",
                    PosterUrl = "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=TLkA0RELQ1E",
                    VideoUrl = "https://vjs.zencdn.net/v/oceans.mp4",
                    Duration = 11,
                    ReleaseYear = 2021,
                    Type = MovieType.Single,
                    VideoStatus = 1
                },
                new[] { "Viễn Tưởng", "Hành Động" }
            )
        };

        foreach (var item in sampleMovies)
        {
            var existingMovie = await context.Movies.IgnoreQueryFilters()
                .Include(m => m.MovieCategories)
                .FirstOrDefaultAsync(m => m.Title.ToLower() == item.Movie.Title.ToLower());

            if (existingMovie == null)
            {
                var movie = item.Movie;
                movie.MovieCategories = new List<MovieCategory>();

                foreach (var catName in item.Categories)
                {
                    if (categoryMap.TryGetValue(catName.ToLower(), out int catId))
                    {
                        movie.MovieCategories.Add(new MovieCategory { CategoryId = catId });
                    }
                }

                await context.Movies.AddAsync(movie);
            }
            else
            {
                // Khôi phục nếu bị xóa mềm
                if (existingMovie.IsDeleted)
                {
                    existingMovie.IsDeleted = false;
                    existingMovie.DeletedAt = null;
                    existingMovie.UpdatedAt = DateTime.UtcNow;
                }

                // Cập nhật đường dẫn video chuẩn nếu chưa có hoặc đang chứa URL cũ Google Storage bị lỗi 403
                if (string.IsNullOrWhiteSpace(existingMovie.VideoUrl) ||
                    existingMovie.VideoStatus == 0 ||
                    existingMovie.VideoUrl.Contains("googleapis.com", StringComparison.OrdinalIgnoreCase))
                {
                    existingMovie.VideoUrl = item.Movie.VideoUrl;
                    existingMovie.VideoStatus = 1;
                    existingMovie.UpdatedAt = DateTime.UtcNow;
                }
            }
        }

        await context.SaveChangesAsync();
    }
}
