using System.ComponentModel.DataAnnotations;

namespace CineStream.DTOs.Common;

// DTO nhan yeu cau phan trang tu Client gui len voi cac rang buoc hop le
public class PagedRequestDto
{
    // So trang can lay, mac dinh la trang dau tien (trang 1)
    [Range(1, int.MaxValue, ErrorMessage = "So trang phai lon hon hoac bang 1")]
    public int PageNumber { get; set; } = 1;

    // So luong ban ghi tren moi trang, gioi han tu 1 den 100 de tranh lam dung bo nho
    [Range(1, 100, ErrorMessage = "Kich thuoc trang phai nam trong khoang tu 1 den 100")]
    public int PageSize { get; set; } = 10;
}
