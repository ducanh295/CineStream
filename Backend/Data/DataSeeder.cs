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
                Title = "Quan Xẩm Lốc Cốc (Châu Tinh Trì)",
                Description = "Phim hài hành động kinh điển của Châu Tinh Trì, phát sóng chuẩn HLS Adaptive Bitrate.",
                PosterUrl = "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600",
                TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                VideoUrl = "http://localhost:5182/videos/1/master.m3u8",
                Duration = 106,
                ReleaseYear = 1994,
                Type = MovieType.Single,
                VideoStatus = 1,
                MovieCategories = new List<MovieCategory>
                {
                    new MovieCategory { CategoryId = 1 },
                    new MovieCategory { CategoryId = 2 }
                }
            },
            new Movie
            {
                Title = "Gettr Sample Video (CDN Direct MP4)",
                Description = "Đoạn phim mẫu chất lượng cao phát trực tiếp từ máy chủ mạng phân phối nội dung CDN Gettr.",
                PosterUrl = "https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?w=600",
                TrailerUrl = "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
                VideoUrl = "https://media.gettr.com/group5/getter/2026/09/03/15/d7ba41f2-d24f-826f-5a50-eeede8c36074/6b38c8a6e89c85f9cb2c83f43311c4a2.mp4",
                Duration = 1,
                ReleaseYear = 2026,
                Type = MovieType.Single,
                VideoStatus = 1,
                MovieCategories = new List<MovieCategory>
                {
                    new MovieCategory { CategoryId = 1 }
                }
            }
        };

        await context.Movies.AddRangeAsync(movies);
        await context.SaveChangesAsync();
    }
}
