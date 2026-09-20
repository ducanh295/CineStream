namespace CineStream.Models.Enums;

// Định nghĩa 3 trạng thái phát hành của bộ phim
public enum MoviePublishStatus
{
    // Bản nháp: Phim đang biên tập, ẩn hoàn toàn khỏi ứng dụng di động của người dùng
    Draft = 0,

    // Sắp chiếu: Phim chuẩn bị ra mắt, hiển thị với nhãn Sắp chiếu và cho phép xem trailer
    ComingSoon = 1,

    // Đã phát hành: Phim chính thức công chiếu, sẵn sàng cho người dùng thưởng thức
    Published = 2
}
