using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using CineStream.DTOs.Common;
using CineStream.DTOs.Favorites;
using CineStream.Models;
using CineStream.Repositories.Interfaces;
using CineStream.Services.Interfaces;

namespace CineStream.Services.Implementations;

// Trien khai logic nghiep vu quan ly danh sach phim yeu thich cua nguoi dung
public class FavoriteService : IFavoriteService
{
    private readonly IFavoriteRepository _favoriteRepo;
    private readonly IMovieRepository _movieRepo;

    public FavoriteService(IFavoriteRepository favoriteRepo, IMovieRepository movieRepo)
    {
        _favoriteRepo = favoriteRepo;
        _movieRepo = movieRepo;
    }

    public async Task<ApiResponse<List<FavoriteDto>>> GetMyFavoritesAsync(int userId)
    {
        // Truy van danh sach yeu thich cua nguoi dung da duoc nap kem thong tin Phim va The loai
        var favorites = await _favoriteRepo.GetByUserIdAsync(userId);

        var dtos = favorites.Select(MapToFavoriteDto).ToList();
        return ApiResponse<List<FavoriteDto>>.Ok(dtos);
    }

    public async Task<ApiResponse<FavoriteStatusDto>> CheckFavoriteStatusAsync(int userId, int movieId)
    {
        bool isFavorite = await _favoriteRepo.IsFavoriteAsync(userId, movieId);
        var status = new FavoriteStatusDto
        {
            MovieId = movieId,
            IsFavorite = isFavorite
        };

        return ApiResponse<FavoriteStatusDto>.Ok(status);
    }

    public async Task<ApiResponse<bool>> AddFavoriteAsync(int userId, int movieId)
    {
        // Kiem tra bo phim co ton tai trong he thong hay khong
        var movie = await _movieRepo.GetByIdAsync(movieId);
        if (movie == null)
        {
            return ApiResponse<bool>.Fail("Không tìm thấy bộ phim yêu cầu!");
        }

        // Tinh chat luy dang (Idempotent): Neu phim da co trong danh sach thi bao thanh cong
        bool alreadyFavorite = await _favoriteRepo.IsFavoriteAsync(userId, movieId);
        if (alreadyFavorite)
        {
            return ApiResponse<bool>.Ok(true, "Phim đã có sẵn trong danh sách yêu thích!");
        }

        // Them moi vao bang Favorites va luu thay doi
        bool added = await _favoriteRepo.AddAsync(userId, movieId);
        if (!added)
        {
            return ApiResponse<bool>.Fail("Không thể thêm phim vào danh sách yêu thích!");
        }

        await _favoriteRepo.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Đã thêm phim vào danh sách yêu thích!");
    }

    public async Task<ApiResponse<bool>> RemoveFavoriteAsync(int userId, int movieId)
    {
        // Kiem tra phim co dang ton tai trong danh sach yeu thich cua nguoi dung khong
        bool exists = await _favoriteRepo.IsFavoriteAsync(userId, movieId);
        if (!exists)
        {
            return ApiResponse<bool>.Fail("Phim không có trong danh sách yêu thích!");
        }

        // Thuc hien go bo khoi bang Favorites va luu thay doi
        bool removed = await _favoriteRepo.RemoveAsync(userId, movieId);
        if (!removed)
        {
            return ApiResponse<bool>.Fail("Xóa phim khỏi danh sách yêu thích thất bại!");
        }

        await _favoriteRepo.SaveChangesAsync();
        return ApiResponse<bool>.Ok(true, "Đã xóa phim khỏi danh sách yêu thích!");
    }

    private static FavoriteDto MapToFavoriteDto(Favorite favorite)
    {
        var movie = favorite.Movie;
        var categoryNames = movie?.MovieCategories?
            .Where(mc => mc.Category != null)
            .Select(mc => mc.Category.Name)
            .ToList() ?? new List<string>();

        return new FavoriteDto
        {
            MovieId = favorite.MovieId,
            Title = movie?.Title ?? string.Empty,
            Description = movie?.Description,
            PosterUrl = movie?.PosterUrl,
            TrailerUrl = movie?.TrailerUrl,
            Duration = movie?.Duration,
            ReleaseYear = movie?.ReleaseYear,
            Categories = categoryNames,
            AddedAt = favorite.CreatedAt
        };
    }
}
