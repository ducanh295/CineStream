using CineStream.DTOs.Common;
using CineStream.DTOs.Movies;

namespace CineStream.Services.Interfaces;

// Giao diện dịch vụ quản lý phim lẻ, định nghĩa các thao tác nghiệp vụ CRUD, tìm kiếm và lọc dữ liệu
public interface IMovieService
{
    // Lấy danh sách phim lẻ phân trang, hỗ trợ lọc theo thể loại và tìm kiếm theo tên phim
    Task<ApiResponse<PagedResult<MovieDto>>> GetAllAsync(int? categoryId = null, string? search = null, int pageNumber = 1, int pageSize = 10);

    // Lấy thông tin chi tiết của một bộ phim theo định danh, bao gồm đường dẫn video phát stream
    Task<ApiResponse<MovieDetailDto>> GetByIdAsync(int id);

    // Tạo mới một bộ phim kèm theo danh sách thể loại được chọn
    Task<ApiResponse<MovieDetailDto>> CreateAsync(CreateMovieDto dto);

    // Cập nhật thông tin phim và danh sách thể loại tương ứng
    Task<ApiResponse<MovieDetailDto>> UpdateAsync(int id, UpdateMovieDto dto);

    // Lấy thông tin luồng phát video chuyên biệt cho trình phát Player (hỗ trợ cả HLS và CDN Direct MP4)
    Task<ApiResponse<MoviePlaybackDto>> GetPlaybackAsync(int id);

    // Xóa mềm một bộ phim theo định danh
    Task<ApiResponse<bool>> DeleteAsync(int id);

    // Quét và lấy danh sách các luồng phát video HLS có sẵn trong kho lưu trữ và các video mẫu CDN
    Task<ApiResponse<AvailableStreamsResponseDto>> GetAvailableStreamsAsync();

    // Lấy danh sách phim nổi bật hiển thị trên Banner Carousel trang chủ (tối đa theo limit, có fallback nếu chưa đánh dấu)
    Task<ApiResponse<List<MovieDto>>> GetFeaturedMoviesAsync(int limit = 5);

    // Chuyển đổi nhanh trạng thái phim nổi bật (Bật / Tắt) cho Quản trị viên
    Task<ApiResponse<bool>> ToggleFeaturedAsync(int id);
}
