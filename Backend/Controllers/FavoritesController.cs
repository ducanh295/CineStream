using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CineStream.DTOs.Common;
using CineStream.DTOs.Favorites;
using CineStream.Services.Interfaces;

namespace CineStream.Controllers;

// Controller xu ly cac thao tac quan ly phim yeu thich (My List) cua nguoi dung
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly IFavoriteService _favoriteService;

    public FavoritesController(IFavoriteService favoriteService)
    {
        _favoriteService = favoriteService;
    }

    // GET /api/favorites - Lay toan bo danh sach phim yeu thich cua nguoi dung hien tai
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<FavoriteDto>>>> GetMyFavorites()
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(ApiResponse<List<FavoriteDto>>.Fail("Không xác định được danh tính người dùng!"));
        }

        var result = await _favoriteService.GetMyFavoritesAsync(userId.Value);
        return Ok(result);
    }

    // GET /api/favorites/check/{movieId} - Kiem tra trang thai bo phim da duoc yeu thich chua
    [HttpGet("check/{movieId:int}")]
    public async Task<ActionResult<ApiResponse<FavoriteStatusDto>>> CheckFavoriteStatus([FromRoute] int movieId)
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(ApiResponse<FavoriteStatusDto>.Fail("Không xác định được danh tính người dùng!"));
        }

        var result = await _favoriteService.CheckFavoriteStatusAsync(userId.Value, movieId);
        return Ok(result);
    }

    // POST /api/favorites/{movieId} - Them mot bo phim vao danh sach yeu thich
    [HttpPost("{movieId:int}")]
    public async Task<ActionResult<ApiResponse<bool>>> AddFavorite([FromRoute] int movieId)
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(ApiResponse<bool>.Fail("Không xác định được danh tính người dùng!"));
        }

        var result = await _favoriteService.AddFavoriteAsync(userId.Value, movieId);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // DELETE /api/favorites/{movieId} - Xoa mot bo phim khoi danh sach yeu thich
    [HttpDelete("{movieId:int}")]
    public async Task<ActionResult<ApiResponse<bool>>> RemoveFavorite([FromRoute] int movieId)
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(ApiResponse<bool>.Fail("Không xác định được danh tính người dùng!"));
        }

        var result = await _favoriteService.RemoveFavoriteAsync(userId.Value, movieId);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    // Trich xuat an toan dinh danh UserId tu JWT Claims
    private int? GetCurrentUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(claim) || !int.TryParse(claim, out int userId))
        {
            return null;
        }
        return userId;
    }
}
