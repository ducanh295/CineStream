using System;
using System.ComponentModel.DataAnnotations;
using CineStream.DTOs.Auth;
using CineStream.Models.Enums;

namespace CineStream.DTOs.Admin;

// DTO tom tat thong tin nguoi dung danh cho Quan tri vien xem danh sach phan trang
public class AdminUserDto
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public UserRole Role { get; set; }
    public bool IsEmailConfirmed { get; set; }
    public bool IsLocked { get; set; }
    public string? LockReason { get; set; }
    public bool IsPremium { get; set; }
    public DateTime? PremiumExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public ProfileDto? Profile { get; set; }
}

// DTO chi tiet nguoi dung kem theo so lieu thong ke hoat dong thuc te
public class AdminUserDetailDto : AdminUserDto
{
    // Tong so bo phim nguoi dung da them vao danh sach yeu thich
    public int FavoriteCount { get; set; }

    // Tong so doan hoi thoai nguoi dung da tuong tac voi Chatbot AI
    public int ChatLogCount { get; set; }

    // Thoi diem them phim yeu thich gan nhat
    public DateTime? LastFavoriteAt { get; set; }
}

// DTO tiep nhan yeu cau khoa tai khoan nguoi dung kem ly do vi pham
public class LockUserRequestDto
{
    [Required(ErrorMessage = "Ly do khoa tai khoan khong duoc de trong!")]
    [StringLength(500, ErrorMessage = "Ly do khoa khong duoc vuot qua 500 ky tu!")]
    public string Reason { get; set; } = string.Empty;
}

// DTO cho thao tac cap, gia han hoac thu hoi Premium boi quan tri vien
public class UpdatePremiumRequestDto
{
    public bool IsPremium { get; set; }

    [Range(1, 3650, ErrorMessage = "Thoi han Premium phai tu 1 den 3650 ngay.")]
    public int? DurationDays { get; set; }

    [StringLength(500, ErrorMessage = "Ghi chu khong duoc vuot qua 500 ky tu.")]
    public string? Reason { get; set; }
}

// DTO tiep nhan yeu cau dieu chinh goi Premium thu cong tu Quan tri vien
public class SetPremiumRequestDto
{
    // Bat hoac tat dac quyen Premium cho nguoi dung
    public bool IsPremium { get; set; }

    // So ngay cap moi hoac cong don them vao thoi han hien tai (vi du: 7, 30, 90, 365).
    public int? DurationDays { get; set; }

    // Ghi chu hoac ly do dieu chinh tu Quan tri vien
    [StringLength(500, ErrorMessage = "Ghi chu khong duoc vuot qua 500 ky tu!")]
    public string? Reason { get; set; }
}
