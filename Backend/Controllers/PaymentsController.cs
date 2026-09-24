using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CineStream.DTOs.Common;
using CineStream.DTOs.Payments;
using CineStream.Services.Interfaces;

namespace CineStream.Controllers;

// Controller xu ly tao don thanh toan VietQR va tiep nhan Webhook tu SePay
[ApiController]
[Route("api/[controller]")]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PaymentsController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    // POST /api/payments/create - Nguoi dung khoi tao don thanh toan goi VIP
    [HttpPost("create")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<PaymentResponseDto>>> CreatePayment([FromBody] CreatePaymentRequestDto dto)
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(ApiResponse<PaymentResponseDto>.Fail("Khong xac dinh duoc danh tinh nguoi dung!"));
        }

        try
        {
            var result = await _paymentService.CreatePaymentAsync(userId.Value, dto);
            return Ok(ApiResponse<PaymentResponseDto>.Ok(result, "Khoi tao don thanh toan thanh cong!"));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<PaymentResponseDto>.Fail(ex.Message));
        }
    }

    // POST /api/payments/sepay-webhook - SePay ban thong bao bien dong so du khi nhan tien
    [HttpPost("sepay-webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> ProcessSePayWebhook(
        [FromHeader(Name = "Authorization")] string? authHeader,
        [FromBody] SePayWebhookDto webhookDto)
    {
        var success = await _paymentService.ProcessSePayWebhookAsync(authHeader, webhookDto);
        if (!success)
        {
            return Unauthorized(new { success = false, message = "Xac thuc webhook that bai hoac sai API Key!" });
        }

        return Ok(new { success = true, message = "Xu ly webhook thanh cong!" });
    }

    // GET /api/payments/status/{orderCode} - Frontend polling kiem tra trang thai don hang
    [HttpGet("status/{orderCode}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<PaymentStatusResponseDto>>> GetPaymentStatus([FromRoute] string orderCode)
    {
        var status = await _paymentService.GetPaymentStatusAsync(orderCode);
        if (status == null)
        {
            return NotFound(ApiResponse<PaymentStatusResponseDto>.Fail("Khong tim thay don hang!"));
        }

        return Ok(ApiResponse<PaymentStatusResponseDto>.Ok(status));
    }

    // GET /api/payments/plans - Lay danh sach bang gia cac goi VIP CineStream
    [HttpGet("plans")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<SubscriptionPlanDto>>>> GetPlans()
    {
        var plans = await _paymentService.GetSubscriptionPlansAsync();
        return Ok(ApiResponse<IReadOnlyList<SubscriptionPlanDto>>.Ok(plans));
    }

    // PUT /api/payments/plans/{planType} - Quan tri vien cap nhat gia cho goi VIP
    [HttpPut("plans/{planType}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ApiResponse<SubscriptionPlanDto>>> UpdatePlanPrice(
        [FromRoute] string planType,
        [FromBody] UpdatePlanPriceDto dto)
    {
        try
        {
            var updated = await _paymentService.UpdatePlanPriceAsync(planType, dto.Price);
            return Ok(ApiResponse<SubscriptionPlanDto>.Ok(updated, $"Cap nhat gia goi {updated.Name} thanh cong!"));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<SubscriptionPlanDto>.Fail(ex.Message));
        }
    }

    // POST /api/payments/simulate/{orderCode} - Gia lap thanh toan thanh cong phuc vu demo do an
    [HttpPost("simulate/{orderCode}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ApiResponse<bool>>> SimulatePayment([FromRoute] string orderCode)
    {
        var success = await _paymentService.SimulatePaymentSuccessAsync(orderCode);
        if (!success)
        {
            return BadRequest(ApiResponse<bool>.Fail("Khong the gia lap don hang khong ton tai hoac da xu ly!"));
        }

        return Ok(ApiResponse<bool>.Ok(true, "Gia lap thanh toan thanh cong! Tai khoan da duoc nang cap VIP."));
    }

    // GET /api/payments/history - Nguoi dung xem lich su giao dich nap tien ca nhan
    [HttpGet("history")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<PaymentTransactionDto>>>> GetMyHistory()
    {
        var userId = GetCurrentUserId();
        if (!userId.HasValue)
        {
            return Unauthorized(ApiResponse<IReadOnlyList<PaymentTransactionDto>>.Fail("Khong xac dinh duoc danh tinh nguoi dung!"));
        }

        var items = await _paymentService.GetUserHistoryAsync(userId.Value);
        return Ok(ApiResponse<IReadOnlyList<PaymentTransactionDto>>.Ok(items));
    }

    // GET /api/payments/admin/all - Quan tri vien xem toan bo giao dich he thong phan trang
    [HttpGet("admin/all")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminAllTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var (items, totalCount) = await _paymentService.GetAdminAllTransactionsAsync(page, pageSize);
        return Ok(new
        {
            success = true,
            data = items,
            total = totalCount,
            page,
            pageSize
        });
    }

    // Trich xuat UserId tu Claim JWT
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
