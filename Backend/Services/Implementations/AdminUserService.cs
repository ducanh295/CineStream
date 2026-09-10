using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CineStream.DTOs.Admin;
using CineStream.DTOs.Auth;
using CineStream.DTOs.Common;
using CineStream.Models;
using CineStream.Models.Enums;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

// Trien khai logic nghiep vu quan tri nguoi dung cho Quan tri vien
public class AdminUserService : IAdminUserService
{
    private readonly IUserRepository _userRepo;

    public AdminUserService(IUserRepository userRepo)
    {
        _userRepo = userRepo;
    }

    public async Task<ApiResponse<PagedResult<AdminUserDto>>> GetUsersAsync(string? search, UserRole? role, bool? isLocked, int page = 1, int pageSize = 10)
    {
        // Chuan hoa tham so phan trang phong ngua ngoai le hoac tai nguyen qua tai
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var users = await _userRepo.GetPagedAsync(search, role, isLocked, page, pageSize);
        var totalCount = await _userRepo.CountAsync(search, role, isLocked);

        var dtos = users.Select(MapToAdminUserDto).ToList();

        var result = new PagedResult<AdminUserDto>
        {
            Items = dtos,
            TotalCount = totalCount,
            PageNumber = page,
            PageSize = pageSize
        };

        return ApiResponse<PagedResult<AdminUserDto>>.Ok(result);
    }

    public async Task<ApiResponse<AdminUserDetailDto>> GetUserDetailAsync(int id)
    {
        var user = await _userRepo.GetDetailWithStatsAsync(id);
        if (user == null)
        {
            return ApiResponse<AdminUserDetailDto>.Fail("Không tìm thấy người dùng!");
        }

        var lastFavorite = user.Favorites?.OrderByDescending(f => f.CreatedAt).FirstOrDefault()?.CreatedAt;

        var dto = new AdminUserDetailDto
        {
            Id = user.Id,
            Username = user.Username,
            Email = user.Email,
            Role = user.Role,
            IsEmailConfirmed = user.IsEmailConfirmed,
            IsLocked = user.IsLocked,
            LockReason = user.LockReason,
            CreatedAt = user.CreatedAt,
            Profile = user.Profile != null ? new ProfileDto
            {
                DisplayName = user.Profile.DisplayName,
                AvatarUrl = user.Profile.AvatarUrl,
                Bio = user.Profile.Bio
            } : null,
            FavoriteCount = user.Favorites?.Count ?? 0,
            ChatLogCount = user.ChatLogs?.Count ?? 0,
            LastFavoriteAt = lastFavorite
        };

        return ApiResponse<AdminUserDetailDto>.Ok(dto);
    }

    public async Task<ApiResponse<bool>> LockUserAsync(int targetUserId, LockUserRequestDto request, int currentAdminId)
    {
        // Phong ve nghiep vu: Khong cho phep Quan tri vien tu khoa chinh minh
        if (targetUserId == currentAdminId)
        {
            return ApiResponse<bool>.Fail("Quản trị viên không thể tự khóa tài khoản của chính mình!");
        }

        var user = await _userRepo.GetByIdAsync(targetUserId);
        if (user == null)
        {
            return ApiResponse<bool>.Fail("Không tìm thấy người dùng!");
        }

        if (user.IsLocked)
        {
            return ApiResponse<bool>.Fail("Tài khoản này đã bị khóa từ trước!");
        }

        user.IsLocked = true;
        user.LockReason = request.Reason.Trim();

        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync();

        return ApiResponse<bool>.Ok(true, "Khóa tài khoản người dùng thành công!");
    }

    public async Task<ApiResponse<bool>> UnlockUserAsync(int targetUserId)
    {
        var user = await _userRepo.GetByIdAsync(targetUserId);
        if (user == null)
        {
            return ApiResponse<bool>.Fail("Không tìm thấy người dùng!");
        }

        if (!user.IsLocked)
        {
            return ApiResponse<bool>.Fail("Tài khoản này hiện không bị khóa!");
        }

        user.IsLocked = false;
        user.LockReason = null;

        _userRepo.Update(user);
        await _userRepo.SaveChangesAsync();

        return ApiResponse<bool>.Ok(true, "Mở khóa tài khoản người dùng thành công!");
    }

    public async Task<ApiResponse<bool>> DeleteUserAsync(int targetUserId, int currentAdminId)
    {
        // Phong ve nghiep vu: Khong cho phep Quan tri vien tu xoa chinh minh
        if (targetUserId == currentAdminId)
        {
            return ApiResponse<bool>.Fail("Quản trị viên không thể tự xóa tài khoản của chính mình!");
        }

        bool deleted = await _userRepo.DeleteAsync(targetUserId);
        if (!deleted)
        {
            return ApiResponse<bool>.Fail("Không tìm thấy người dùng hoặc xóa thất bại!");
        }

        await _userRepo.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Xóa tài khoản người dùng thành công!");
    }

    private static AdminUserDto MapToAdminUserDto(User user)
    {
        return new AdminUserDto
        {
            Id = user.Id,
            Username = user.Username,
            Email = user.Email,
            Role = user.Role,
            IsEmailConfirmed = user.IsEmailConfirmed,
            IsLocked = user.IsLocked,
            LockReason = user.LockReason,
            CreatedAt = user.CreatedAt,
            Profile = user.Profile != null ? new ProfileDto
            {
                DisplayName = user.Profile.DisplayName,
                AvatarUrl = user.Profile.AvatarUrl,
                Bio = user.Profile.Bio
            } : null
        };
    }
}
