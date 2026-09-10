using System.Collections.Generic;
using System.Threading.Tasks;
using CineStream.DTOs.Common;
using CineStream.DTOs.Favorites;

namespace CineStream.Services.Interfaces;

// Giao dien nghiep vu quan ly phim yeu thich danh cho nguoi dung
public interface IFavoriteService
{
    // Lay toan bo danh sach phim yeu thich cua nguoi dung hien tai kem the loai
    Task<ApiResponse<List<FavoriteDto>>> GetMyFavoritesAsync(int userId);

    // Kiem tra trang thai mot bo phim da duoc danh dau yeu thich hay chua
    Task<ApiResponse<FavoriteStatusDto>> CheckFavoriteStatusAsync(int userId, int movieId);

    // Them mot bo phim vao danh sach yeu thich cua nguoi dung
    Task<ApiResponse<bool>> AddFavoriteAsync(int userId, int movieId);

    // Xoa mot bo phim khoi danh sach yeu thich cua nguoi dung
    Task<ApiResponse<bool>> RemoveFavoriteAsync(int userId, int movieId);
}
