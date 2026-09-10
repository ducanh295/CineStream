using System.Threading.Tasks;
using CineStream.DTOs.Admin;
using CineStream.DTOs.Common;
using CineStream.Models.Enums;

namespace CineStream.Services.Interfaces;

// Giao dien nghiep vu quan tri nguoi dung danh rieng cho Quan tri vien
public interface IAdminUserService
{
    // Lay danh sach nguoi dung phan trang ket hop cac bo loc tim kiem, vai tro va trang thai khoa
    Task<ApiResponse<PagedResult<AdminUserDto>>> GetUsersAsync(string? search, UserRole? role, bool? isLocked, int page = 1, int pageSize = 10);

    // Lay thong tin chi tiet mot nguoi dung kem theo cac chi so thong ke hoat dong thuc te
    Task<ApiResponse<AdminUserDetailDto>> GetUserDetailAsync(int id);

    // Khoa tai khoan nguoi dung vi pham kem ly do cu the (ngan chan tu khoa chinh minh)
    Task<ApiResponse<bool>> LockUserAsync(int targetUserId, LockUserRequestDto request, int currentAdminId);

    // Mo khoa tai khoan nguoi dung da bi khoa truoc do
    Task<ApiResponse<bool>> UnlockUserAsync(int targetUserId);

    // Xoa mem tai khoan nguoi dung khoi he thong (ngan chan tu xoa chinh minh)
    Task<ApiResponse<bool>> DeleteUserAsync(int targetUserId, int currentAdminId);
}
