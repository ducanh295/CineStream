using CineStream.DTOs.Common;
using CineStream.DTOs.Movies;

namespace CineStream.Services.Interfaces;

// Giao dien dich vu quan ly phim le, dinh nghia cac thao tac nghiep vu CRUD va tim kiem/loc
public interface IMovieService
{
    // Lay danh sach phim le, ho tro loc theo the loai va tim kiem theo ten phim
    Task<ApiResponse<IReadOnlyList<MovieDto>>> GetAllAsync(int? categoryId = null, string? search = null);

    // Lay thong tin chi tiet cua mot bo phim theo dinh danh, bao gom duong dan video phat stream
    Task<ApiResponse<MovieDetailDto>> GetByIdAsync(int id);

    // Tao moi mot bo phim kem theo danh sach the loai duoc chon
    Task<ApiResponse<MovieDetailDto>> CreateAsync(CreateMovieDto dto);

    // Cap nhat thong tin phim va danh sach the loai tuong ung
    Task<ApiResponse<MovieDetailDto>> UpdateAsync(int id, UpdateMovieDto dto);

    // Xoa mem mot bo phim theo dinh danh
    Task<ApiResponse<bool>> DeleteAsync(int id);
}
