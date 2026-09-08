using Microsoft.EntityFrameworkCore;
using CineStream.Models;
using CineStream.Models.Enums;

namespace CineStream.Data;

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

    private static async Task SeedUsersAsync(AppDbContext context)
    {
        // Nếu đã có User trong DB rồi thì bỏ qua không tạo nữa
        if (await context.Users.AnyAsync()) return;

        // Tạo tài khoản Admin
        var admin = new User
        {
            Username = "admin",
            Email = "admin@cinestream.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123"),
            Role = UserRole.Admin,
            Profile = new Profile
            {
                DisplayName = "Quản Trị Viên CineStream",
                AvatarUrl = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
                Bio = "Tài khoản quản trị hệ thống"
            }
        };

        // Tạo tài khoản User thường để Frontend test đăng nhập
        var user = new User
        {
            Username = "user",
            Email = "user@cinestream.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("User@123"),
            Role = UserRole.User,
            Profile = new Profile
            {
                DisplayName = "Khách Xem Phim",
                AvatarUrl = "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150",
                Bio = "Thành viên đam mê điện ảnh"
            }
        };

        await context.Users.AddRangeAsync(admin, user);
        await context.SaveChangesAsync();
    }

    private static async Task SeedCategoriesAsync(AppDbContext context)
    {
        // Nếu đã có thể loại thì bỏ qua
        if (await context.Categories.AnyAsync()) return;

        var categories = new List<Category>
        {
            new Category { Name = "Hành Động", Description = "Phim kịch tính, rượt đuổi và chiến đấu mãn nhãn" },
            new Category { Name = "Viễn Tưởng", Description = "Phim khoa học giả tưởng, du hành vũ trụ và tương lai" },
            new Category { Name = "Tình Cảm", Description = "Phim tâm lý, tình cảm lãng mạn" }
        };

        await context.Categories.AddRangeAsync(categories);
        await context.SaveChangesAsync();
    }

    private static async Task SeedMoviesAsync(AppDbContext context)
    {
        if (await context.Movies.AnyAsync()) return;

        var movies = new List<Movie>
        {
            new Movie
            {
                Title = "Tears of Steel (Chiến Binh Thép)",
                Description = "Trong tương lai viễn tưởng, một nhóm các nhà khoa học cố gắng thay đổi quá khứ để cứu nhân loại.",
                PosterUrl = "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600",
                TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                VideoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
                Duration = 12,
                ReleaseYear = 2024,
                Type = MovieType.Single,
                VideoStatus = 1
            },
            new Movie
            {
                Title = "Big Buck Bunny",
                Description = "Bộ phim hoạt hình kinh điển kể về cuộc trả thù hài hước của chú thỏ khổng lồ đối với ba kẻ bắt nạt trong rừng.",
                PosterUrl = "https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?w=600",
                TrailerUrl = "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
                VideoUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                Duration = 10,
                ReleaseYear = 2023,
                Type = MovieType.Single,
                VideoStatus = 1
            }
        };

        await context.Movies.AddRangeAsync(movies);
        await context.SaveChangesAsync();
    }
}
