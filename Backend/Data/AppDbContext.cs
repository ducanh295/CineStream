using Microsoft.EntityFrameworkCore;
using CineStream.Models;

namespace CineStream.Data;

public class AppDbContext : DbContext
{
    // Khai báo các bảng dữ liệu trong hệ thống CineStream
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    public DbSet<User> Users => Set<User>();
    public DbSet<Profile> Profiles => Set<Profile>();
    public DbSet<Movie> Movies => Set<Movie>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<MovieCategory> MovieCategories => Set<MovieCategory>();
    public DbSet<Favorite> Favorites => Set<Favorite>();

    public DbSet<Series> Series => Set<Series>();

    public DbSet<Season> Seasons => Set<Season>();

    public DbSet<Episode> Episodes => Set<Episode>();

    public DbSet<ChatLog> ChatLogs => Set<ChatLog>();


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<MovieCategory>().HasKey(mc => new { mc.MovieId, mc.CategoryId });

        // Ràng buộc Favorite: Mỗi người dùng chỉ được đánh dấu yêu thích một bộ phim một lần
        modelBuilder.Entity<Favorite>().HasKey(f => new { f.UserId, f.MovieId });

        // Ràng buộc chỉ mục duy nhất: Ngăn chặn trùng lặp Email hoặc Username
        modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();

        modelBuilder.Entity<User>().HasIndex(u => u.Username).IsUnique();

        modelBuilder.Entity<Category>().HasIndex(c => c.Name).IsUnique();
        modelBuilder.Entity<Profile>().HasIndex(p => p.UserId).IsUnique();

        modelBuilder.Entity<User>().HasQueryFilter(u => !u.IsDeleted);
        modelBuilder.Entity<Movie>().HasQueryFilter(m => !m.IsDeleted);
        modelBuilder.Entity<Category>().HasQueryFilter(c => !c.IsDeleted);
        modelBuilder.Entity<Series>().HasQueryFilter(s => !s.IsDeleted);
        modelBuilder.Entity<ChatLog>().HasQueryFilter(cl => !cl.IsDeleted);

        // Đánh chỉ mục cho UserId trong ChatLog để tối ưu hóa tốc độ truy vấn lịch sử trò chuyện
        modelBuilder.Entity<ChatLog>().HasIndex(cl => cl.UserId);
    }

}