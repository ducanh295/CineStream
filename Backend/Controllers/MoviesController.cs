using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CineStream.DTOs.Common;
using CineStream.DTOs.Movies;
using CineStream.Services.Interfaces;

namespace CineStream.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MoviesController : ControllerBase
{
    private readonly IMovieService _movieService;

    public MoviesController(IMovieService movieService)
    {
        _movieService = movieService;
    }

    // GET /api/movies?categoryId=X&search=Y - Lay danh sach phim, ho tro loc the loai va tim kiem theo ten
    [HttpGet]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<MovieDto>>>> GetAll([FromQuery] int? categoryId = null, [FromQuery] string? search = null)
    {
        var result = await _movieService.GetAllAsync(categoryId, search);
        return Ok(result);
    }

    // GET /api/movies/{id} - Lay chi tiet mot bo phim kem duong dan video phat stream
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<MovieDetailDto>>> GetById(int id)
    {
        var result = await _movieService.GetByIdAsync(id);
        if (!result.Success)
        {
            return NotFound(result);
        }
        return Ok(result);
    }

    // GET /api/movies/{id}/playback - Lay thong tin luong phat video chuyen biet cho Player (ho tro ca HLS va CDN Direct MP4)
    [HttpGet("{id}/playback")]
    public async Task<ActionResult<ApiResponse<MoviePlaybackDto>>> GetPlayback(int id)
    {
        var result = await _movieService.GetPlaybackAsync(id);
        if (!result.Success)
        {
            return NotFound(result);
        }
        return Ok(result);
    }

    // POST /api/movies - Tạo mới một bộ phim kèm danh sách thể loại liên kết (Chỉ Quản trị viên)
    [Authorize(Policy = "AdminOnly")]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<MovieDetailDto>>> Create([FromBody] CreateMovieDto dto)
    {
        var result = await _movieService.CreateAsync(dto);
        if (!result.Success)
        {
            return BadRequest(result);
        }
        return CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, result);
    }

    // PUT /api/movies/{id} - Cập nhật thông tin phim và đồng bộ thể loại liên kết (Chỉ Quản trị viên)
    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<MovieDetailDto>>> Update(int id, [FromBody] UpdateMovieDto dto)
    {
        var result = await _movieService.UpdateAsync(id, dto);
        if (!result.Success)
        {
            // Nếu không tìm thấy phim thì trả về 404 NotFound theo chuẩn RESTful
            if (result.Message == "Khong tim thay phim!")
            {
                return NotFound(result);
            }
            return BadRequest(result);
        }
        return Ok(result);
    }

    // DELETE /api/movies/{id} - Xóa mềm một bộ phim (Chỉ Quản trị viên)
    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<bool>>> Delete(int id)
    {
        var result = await _movieService.DeleteAsync(id);
        if (!result.Success)
        {
            return NotFound(result);
        }
        return Ok(result);
    }
}
