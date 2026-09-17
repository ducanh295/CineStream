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

    // GET /api/movies?categoryId=X&search=Y&page=1&pageSize=10 - Lấy danh sách phim phân trang, hỗ trợ lọc và tìm kiếm
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResult<MovieDto>>>> GetAll(
        [FromQuery] int? categoryId = null,
        [FromQuery] string? search = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var result = await _movieService.GetAllAsync(categoryId, search, page, pageSize);
        return Ok(result);
    }

    // GET /api/movies/{id} - Lấy chi tiết một bộ phim kèm đường dẫn video phát stream
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

    // GET /api/movies/{id}/playback - Lấy thông tin luồng phát video chuyên biệt cho Player (hỗ trợ cả HLS và CDN Direct MP4)
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

    // GET /api/movies/available-streams - Quét và lấy danh sách luồng phát HLS nội bộ cùng các video mẫu CDN
    [HttpGet("available-streams")]
    public async Task<ActionResult<ApiResponse<AvailableStreamsResponseDto>>> GetAvailableStreams()
    {
        var result = await _movieService.GetAvailableStreamsAsync();
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
