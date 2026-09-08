namespace CineStream.DTOs.Series;

// DTO hiển thị từng tập phim
public class EpisodeDto
{
    public int Id { get; set; }
    public int SeasonId { get; set; }
    public int EpisodeNumber { get; set; }
    public string? Title { get; set; }
    public string? VideoUrl { get; set; }
    public int VideoStatus { get; set; }
    public int? Duration { get; set; }
}

public class CreateEpisodeDto
{
    public int EpisodeNumber { get; set; }
    public string? Title { get; set; }
    public string? VideoUrl { get; set; }
    public int? Duration { get; set; }
}

public class UpdateEpisodeDto
{
    public int EpisodeNumber { get; set; }
    public string? Title { get; set; }
    public string? VideoUrl { get; set; }
    public int VideoStatus { get; set; }
    public int? Duration { get; set; }
}

// DTO hiển thị mùa phim kèm các tập
public class SeasonDto
{
    public int Id { get; set; }
    public int SeriesId { get; set; }
    public int SeasonNumber { get; set; }
    public string? Title { get; set; }
    public List<EpisodeDto> Episodes { get; set; } = new();
}

public class CreateSeasonDto
{
    public int SeasonNumber { get; set; }
    public string? Title { get; set; }
}

public class UpdateSeasonDto
{
    public int SeasonNumber { get; set; }
    public string? Title { get; set; }
}

// DTO danh sách phim bộ ngoài trang chủ
public class SeriesDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? TrailerUrl { get; set; }
    public int? ReleaseYear { get; set; }
    public int TotalSeasons { get; set; }
}

// DTO chi tiết phim bộ kèm toàn bộ các mùa và tập
public class SeriesDetailDto : SeriesDto
{
    public List<SeasonDto> Seasons { get; set; } = new();
}

public class CreateSeriesDto
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? TrailerUrl { get; set; }
    public int? ReleaseYear { get; set; }
}

public class UpdateSeriesDto
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? PosterUrl { get; set; }
    public string? TrailerUrl { get; set; }
    public int? ReleaseYear { get; set; }
}
