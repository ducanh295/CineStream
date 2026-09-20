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
            // Phim 1: Đại Thoại Tây Du (Châu Tinh Trì) - Luồng HLS Dai_thoai_tay_du
            (
                new Movie
                {
                    Title = "Đại Thoại Tây Du (Châu Tinh Trì)",
                    Description = "Tác phẩm kinh điển của điện ảnh Hồng Kông kết hợp giữa thần thoại Tây Du Ký và phong cách hài hước độc đáo của Châu Tinh Trì, kể về mối tình bi tráng giữa Tôn Ngộ Không (Chí Tôn Bảo) và Tử Hà Tiên Tử.",
                    PosterUrl = "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/Dai_thoai_tay_du/master.m3u8",
                    Duration = 106,
                    ReleaseYear = 1995,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = true,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Hài Hước", "Hành Động", "Võ Thuật" }
            ),
            // Phim 2: Tears of Steel (Chiến Binh Thép) - Luồng HLS lao_dao_hoa
            (
                new Movie
                {
                    Title = "Tears of Steel (Chiến Binh Thép)",
                    Description = "Trong bối cảnh tương lai viễn tưởng tại Amsterdam, một nhóm các nhà khoa học và chiến binh cố gắng thay đổi quá khứ bằng công nghệ du hành thời gian để giải cứu nhân loại khỏi sự thống trị của đội quân robot.",
                    PosterUrl = "https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/lao_dao_hoa/master.m3u8",
                    Duration = 12,
                    ReleaseYear = 2024,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = true,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Viễn Tưởng", "Hành Động" }
            ),
            // Phim 3: Big Buck Bunny (Chú Thỏ Nổi Giận) - Luồng HLS Demo_2
            (
                new Movie
                {
                    Title = "Big Buck Bunny (Chú Thỏ Nổi Giận)",
                    Description = "Bộ phim hoạt hình 3D nổi tiếng của Blender Foundation kể về cuộc trả đũa hài hước đầy sáng tạo của chú thỏ khổng lồ tốt bụng trước ba kẻ chuyên ức hiếp muôn thú trong rừng già.",
                    PosterUrl = "https://images.unsplash.com/photo-1574375927938-d5a98e8ffe85?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
                    VideoUrl = "/videos/Demo_2/master.m3u8",
                    Duration = 10,
                    ReleaseYear = 2023,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Hoạt Hình", "Hài Hước" }
            ),
            // Phim 4: Sintel (Hành Trình Tìm Rồng) - Luồng HLS lao_dao_hoa
            (
                new Movie
                {
                    Title = "Sintel (Hành Trình Tìm Rồng)",
                    Description = "Câu chuyện phiêu lưu xúc động về cô gái trẻ Sintel vượt qua sa mạc khắc nghiệt và vùng đất băng tuyết hiểm trở để tìm lại chú rồng nhỏ Scales mà cô đã cưu mang.",
                    PosterUrl = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=eRsGyueVLvQ",
                    VideoUrl = "/videos/lao_dao_hoa/master.m3u8",
                    Duration = 15,
                    ReleaseYear = 2022,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Hoạt Hình", "Phiêu Lưu" }
            ),
            // Phim 5: Elephant's Dream (Giấc Mơ Cơ Khí) - Luồng HLS Demo_2
            (
                new Movie
                {
                    Title = "Elephant's Dream (Giấc Mơ Cơ Khí)",
                    Description = "Một chuyến du hành thị giác kỳ ảo vào bên trong cỗ máy khổng lồ vô tận, nơi hai nhân vật Proog và Emo đối mặt với những ảo ảnh cơ khí và sự bất đồng trong nhận thức thế giới.",
                    PosterUrl = "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=TLkA0RELQ1E",
                    VideoUrl = "/videos/Demo_2/master.m3u8",
                    Duration = 11,
                    ReleaseYear = 2021,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Viễn Tưởng", "Hành Động" }
            ),
            // Phim 6: Lão Đạo Hỏa (Rực Lửa Chiến Tuyến) - Luồng HLS lao_dao_hoa
            (
                new Movie
                {
                    Title = "Lão Đạo Hỏa: Rực Lửa Chiến Tuyến",
                    Description = "Bộ phim hành động hình sự kịch tính với những pha đối đầu tay đôi nghẹt thở giữa cảnh sát đặc nhiệm và băng đảng tội phạm nguy hiểm xuyên quốc gia.",
                    PosterUrl = "https://images.unsplash.com/photo-1509281373149-e957c6296406?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/lao_dao_hoa/master.m3u8",
                    Duration = 98,
                    ReleaseYear = 2023,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = true,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Hành Động", "Võ Thuật" }
            ),
            // Phim 7: Cuộc Chiến Robot: Hậu Tận Thế - Luồng HLS Demo_2
            (
                new Movie
                {
                    Title = "Cuộc Chiến Robot: Hậu Tận Thế",
                    Description = "Sau khi trí tuệ nhân tạo mất kiểm soát, tàn tích nền văn minh con người phải tập hợp lực lượng cuối cùng để đánh sập máy chủ trung tâm bảo vệ sinh tồn.",
                    PosterUrl = "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=TLkA0RELQ1E",
                    VideoUrl = "/videos/Demo_2/master.m3u8",
                    Duration = 115,
                    ReleaseYear = 2024,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Viễn Tưởng", "Hành Động" }
            ),
            // Phim 8: Hiệp Khách Vô Danh: Phong Vân Tái Khởi - Luồng HLS Dai_thoai_tay_du
            (
                new Movie
                {
                    Title = "Hiệp Khách Vô Danh: Phong Vân Tái Khởi",
                    Description = "Hành trình rửa hận của tay kiếm cự phách chốn giang hồ, đối mặt với những cạm bẫy quyền mưu chốn triều đình và bí kíp võ học thất truyền.",
                    PosterUrl = "https://images.unsplash.com/photo-1514533450685-4493e01d1fdc?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/Dai_thoai_tay_du/master.m3u8",
                    Duration = 102,
                    ReleaseYear = 2022,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Võ Thuật", "Phiêu Lưu" }
            ),
            // Phim 9: Kỷ Nguyên Vũ Trụ: Hành Tinh Chết - Luồng HLS lao_dao_hoa
            (
                new Movie
                {
                    Title = "Kỷ Nguyên Vũ Trụ: Hành Tinh Chết",
                    Description = "Tàu thám hiểm viễn chinh đáp xuống một thiên thể bí ẩn ngoài rìa dải ngân hà và phát hiện tàn tích của một nền văn minh cổ đại đã bị diệt vong.",
                    PosterUrl = "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=TLkA0RELQ1E",
                    VideoUrl = "/videos/lao_dao_hoa/master.m3u8",
                    Duration = 125,
                    ReleaseYear = 2024,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Viễn Tưởng", "Phiêu Lưu" }
            ),
            // Phim 10: Vua Bịp Ma Cao: Bão Táp Sòng Bạc - Luồng HLS Dai_thoai_tay_du
            (
                new Movie
                {
                    Title = "Vua Bịp Ma Cao: Bão Táp Sòng Bạc",
                    Description = "Những ván cược sinh tử cân não kết hợp yếu tố hài hước vui nhộn xoay quanh thiên tài bài bịp tái xuất giang hồ để lật đổ đế chế ngầm.",
                    PosterUrl = "https://images.unsplash.com/photo-1511193311914-0346f16efe90?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
                    VideoUrl = "/videos/Dai_thoai_tay_du/master.m3u8",
                    Duration = 94,
                    ReleaseYear = 2021,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Hài Hước", "Hành Động" }
            ),
            // Phim 11: Mật Vụ Băng Đăng: Lời Thề Danh Dự - Luồng HLS Demo_2
            (
                new Movie
                {
                    Title = "Mật Vụ Băng Đăng: Lời Thề Danh Dự",
                    Description = "Một chiến dịch tuyệt mật giữa vùng tuyết trắng Siberia, nơi ranh giới giữa chính nghĩa và phản bội bị xóa nhòa bởi tham vọng chính trị.",
                    PosterUrl = "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/Demo_2/master.m3u8",
                    Duration = 110,
                    ReleaseYear = 2023,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Hành Động", "Viễn Tưởng" }
            ),
            // Phim 12: Mối Tình Ngân Hà: Vượt Thời Gian - Luồng HLS lao_dao_hoa
            (
                new Movie
                {
                    Title = "Mối Tình Ngân Hà: Vượt Thời Gian",
                    Description = "Câu chuyện tình lãng mạn đầy xúc động giữa hai phi hành gia bị ngăn cách bởi độ trễ thời gian của hố đen vũ trụ vô tận.",
                    PosterUrl = "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=eRsGyueVLvQ",
                    VideoUrl = "/videos/lao_dao_hoa/master.m3u8",
                    Duration = 118,
                    ReleaseYear = 2022,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Tình Cảm", "Viễn Tưởng" }
            ),
            // Phim 13: Xích Bích: Hỏa Thiêu Chiến Thuyền - Luồng HLS Dai_thoai_tay_du
            (
                new Movie
                {
                    Title = "Xích Bích: Hỏa Thiêu Chiến Thuyền",
                    Description = "Tái hiện trận đại chiến vang danh lịch sử thời Tam Quốc, nơi mưu trí của Gia Cát Lượng và Chu Du đối đầu cùng đại quân trăm vạn của Tào Tháo.",
                    PosterUrl = "https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/Dai_thoai_tay_du/master.m3u8",
                    Duration = 135,
                    ReleaseYear = 2020,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Hành Động", "Võ Thuật" }
            ),
            // Phim 14: Cuộc Phiêu Lưu Của Vẹt Xanh - Luồng HLS Demo_2
            (
                new Movie
                {
                    Title = "Cuộc Phiêu Lưu Của Vẹt Xanh",
                    Description = "Bộ phim hoạt hình rực rỡ sắc màu về hành trình trốn khỏi sở thú tìm đường trở về rừng nhiệt đới Amazon của chú vẹt tinh nghịch.",
                    PosterUrl = "https://images.unsplash.com/photo-1552728089-57bdde30beb3?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
                    VideoUrl = "/videos/Demo_2/master.m3u8",
                    Duration = 88,
                    ReleaseYear = 2023,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Hoạt Hình", "Hài Hước", "Phiêu Lưu" }
            ),
            // Phim 15: Bản Đồ Kho Báu Rừng Amazon - Luồng HLS lao_dao_hoa
            (
                new Movie
                {
                    Title = "Bản Đồ Kho Báu Rừng Amazon",
                    Description = "Đoàn khảo cổ liều lĩnh thâm nhập sâu vào rừng rậm nhiệt đới để tìm kiếm thành phố vàng El Dorado được ghi chép trong truyền thuyết.",
                    PosterUrl = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=TLkA0RELQ1E",
                    VideoUrl = "/videos/lao_dao_hoa/master.m3u8",
                    Duration = 104,
                    ReleaseYear = 2024,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Phiêu Lưu", "Hành Động" }
            ),
            // Phim 16: Thần Điêu Hiệp Lữ: Kiếm Vũ Giang Hồ - Luồng HLS Dai_thoai_tay_du
            (
                new Movie
                {
                    Title = "Thần Điêu Hiệp Lữ: Kiếm Vũ Giang Hồ",
                    Description = "Mối tình thủy chung son sắt chốn võ lâm kiếm hiệp cùng những màn thi triển khinh công và kiếm pháp kỳ ảo đỉnh cao.",
                    PosterUrl = "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/Dai_thoai_tay_du/master.m3u8",
                    Duration = 112,
                    ReleaseYear = 2021,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.Published
                },
                new[] { "Võ Thuật", "Tình Cảm" }
            ),
            // Phim 17: Avatar 3: Hỏa Ngục Pandora (SẮP CHIẾU / COMING SOON) - Luồng HLS lao_dao_hoa
            (
                new Movie
                {
                    Title = "Avatar 3: Hỏa Ngục Pandora",
                    Description = "Phần tiếp theo của siêu phẩm điện ảnh toàn cầu khám phá tộc người Tro Tàn (Ash People) bí hiểm và hung bạo trên mặt trăng Pandora.",
                    PosterUrl = "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=R6MlUcmOul8",
                    VideoUrl = "/videos/lao_dao_hoa/master.m3u8",
                    Duration = 165,
                    ReleaseYear = 2026,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.ComingSoon
                },
                new[] { "Viễn Tưởng", "Hành Động", "Phiêu Lưu" }
            ),
            // Phim 18: Deadpool & Wolverine: Đa Vũ Trụ (SẮP CHIẾU / COMING SOON) - Luồng HLS Demo_2
            (
                new Movie
                {
                    Title = "Deadpool & Wolverine: Đa Vũ Trụ Hỗn Loạn",
                    Description = "Sự kết hợp không tưởng giữa hai dị nhân biểu tượng trong một nhiệm vụ xuyên không gian cứu rỗi dòng thời gian Marvel.",
                    PosterUrl = "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=TLkA0RELQ1E",
                    VideoUrl = "/videos/Demo_2/master.m3u8",
                    Duration = 127,
                    ReleaseYear = 2026,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.ComingSoon
                },
                new[] { "Hành Động", "Hài Hước", "Viễn Tưởng" }
            ),
            // Phim 19: Tôn Ngộ Không: Đại Náo Tam Giới (SẮP CHIẾU / COMING SOON) - Luồng HLS Dai_thoai_tay_du
            (
                new Movie
                {
                    Title = "Tôn Ngộ Không: Đại Náo Tam Giới",
                    Description = "Bản hoạt họa kỹ xảo 3D đỉnh cao tái hiện hành trình tầm sư học đạo và cuộc đại chiến kinh thiên động địa trên Thiên Cung.",
                    PosterUrl = "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600",
                    TrailerUrl = "https://www.youtube.com/watch?v=aqz-KE-bpKQ",
                    VideoUrl = "/videos/Dai_thoai_tay_du/master.m3u8",
                    Duration = 95,
                    ReleaseYear = 2026,
                    Type = MovieType.Single,
                    VideoStatus = 1,
                    IsFeatured = false,
                    PublishStatus = MoviePublishStatus.ComingSoon
                },
                new[] { "Hoạt Hình", "Võ Thuật", "Phiêu Lưu" }
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
                }

                // Cập nhật đường dẫn HLS nội bộ chuẩn xác và trạng thái phát hành
                existingMovie.VideoUrl = item.Movie.VideoUrl;
                existingMovie.VideoStatus = 1;
                existingMovie.PublishStatus = item.Movie.PublishStatus;
                existingMovie.IsFeatured = item.Movie.IsFeatured;
                existingMovie.PosterUrl = item.Movie.PosterUrl;
                existingMovie.TrailerUrl = item.Movie.TrailerUrl;
                existingMovie.Description = item.Movie.Description;
                existingMovie.Duration = item.Movie.Duration;
                existingMovie.ReleaseYear = item.Movie.ReleaseYear;
                existingMovie.UpdatedAt = DateTime.UtcNow;

                // Đồng bộ lại thể loại cho các phim có sẵn
                existingMovie.MovieCategories.Clear();
                foreach (var catName in item.Categories)
                {
                    if (categoryMap.TryGetValue(catName.ToLower(), out int catId))
                    {
                        existingMovie.MovieCategories.Add(new MovieCategory { CategoryId = catId, MovieId = existingMovie.Id });
                    }
                }
            }
        }

        await context.SaveChangesAsync();
    }
}
