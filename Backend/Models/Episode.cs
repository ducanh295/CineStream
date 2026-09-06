namespace CineStream.Models;

public class Episode : BaseEntity
{
    public int SeasonId { get; set; }
    public int EpisodeNumber { get; set; }
    public string? Title { get; set; }

    // 💡 Đường dẫn file master.m3u8 phục vụ phát streaming HLS
    public string? VideoUrl { get; set; }

    // 💡 Trạng thái video: 0 = Chưa có, 1 = Đã upload & sẵn sàng phát
    public int VideoStatus { get; set; } = 0;

    public int? Duration { get; set; }

    // 💡 Navigation Property trỏ ngược về Season cha
    public virtual Season Season { get; set; } = null!;
}