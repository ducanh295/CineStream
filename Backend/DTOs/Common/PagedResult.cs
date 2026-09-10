using System;
using System.Collections.Generic;

namespace CineStream.DTOs.Common;

// DTO generic dung de dong goi ket qua phan trang cho moi danh sach du lieu
public class PagedResult<T>
{
    // Danh sach cac phan tu thuoc trang hien tai
    public List<T> Items { get; set; } = new();

    // Tong so ban ghi thoa man dieu kien loc tren toan bo he thong
    public int TotalCount { get; set; }

    // So thu tu trang hien tai (1-indexed)
    public int PageNumber { get; set; }

    // So luong ban ghi tren mot trang
    public int PageSize { get; set; }

    // Tong so trang duoc tinh toan tu dong dua tren tong so ban ghi va kich thuoc trang
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling(TotalCount / (double)PageSize) : 0;
}
