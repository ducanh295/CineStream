using Microsoft.EntityFrameworkCore;
using VietFlix.Models;

namespace VietFlix.Data;

public class AppDbContext : DbContext
{
    //khai báo các bảng
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
        //Favorite: mỗi user chỉ được thích 1 bộ phim 1 lần
        modelBuilder.Entity<Favorite>().HasKey(f => new { f.UserId, f.MovieId });
        // bắt trùng email hoặc username
        modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();

        modelBuilder.Entity<User>().HasIndex(u => u.Username).IsUnique();

        modelBuilder.Entity<Category>().HasIndex(c => c.Name).IsUnique();
        modelBuilder.Entity<Profile>().HasIndex(p => p.UserId).IsUnique();

        modelBuilder.Entity<User>().HasQueryFilter(u => !u.IsDeleted);
        modelBuilder.Entity<Movie>().HasQueryFilter(m => !m.IsDeleted);
        modelBuilder.Entity<Category>().HasQueryFilter(c => !c.IsDeleted);
        modelBuilder.Entity<Series>().HasQueryFilter(s => !s.IsDeleted);
    }

}