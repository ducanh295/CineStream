namespace VietFlix.DTOs.Common;

// 💡 Generic <T> cho phép bọc bất kỳ kiểu dữ liệu nào (Movie, User, List<Category>...)
public class ApiResponse<T>
{
    // 💡 Cờ xác định request thành công hay thất bại để frontend dễ rẽ nhánh if/else
    public bool Success { get; set; }

    // 💡 Dữ liệu trả về (null nếu API bị lỗi hoặc không có dữ liệu trả về)
    public T? Data { get; set; }

    // 💡 Lời nhắn hiển thị cho người dùng hoặc dev ("Tạo thành công", "Không tìm thấy"...)
    public string? Message { get; set; }

    // 💡 Danh sách lỗi chi tiết (rất tiện khi validate form hoặc nghiệp vụ có nhiều lỗi)
    public List<string>? Errors { get; set; }

    // 💡 Constructor mặc định phục vụ quá trình serialize/deserialize JSON
    public ApiResponse() { }

    // 💡 Constructor đầy đủ tham số
    public ApiResponse(bool success, T? data, string? message = null, List<string>? errors = null)
    {
        Success = success;
        Data = data;
        Message = message;
        Errors = errors;
    }

    // 💡 Helper method trả về kết quả thành công kèm dữ liệu
    public static ApiResponse<T> Ok(T data, string? message = null)
    {
        return new ApiResponse<T>(true, data, message);
    }

    // 💡 Helper method trả về kết quả thất bại với 1 câu thông báo lỗi
    public static ApiResponse<T> Fail(string message, List<string>? errors = null)
    {
        return new ApiResponse<T>(false, default, message, errors);
    }

    // 💡 Helper method trả về kết quả thất bại với danh sách nhiều lỗi
    public static ApiResponse<T> Fail(List<string> errors, string? message = "Validation failed")
    {
        return new ApiResponse<T>(false, default, message, errors);
    }
}

// 💡 Phiên bản không generic: Dùng cho các API không cần trả data (ví dụ Delete, Logout...)
public class ApiResponse : ApiResponse<object>
{
    // 💡 Trả về thành công không kèm dữ liệu
    public static ApiResponse Ok(string? message = null)
    {
        return new ApiResponse { Success = true, Message = message };
    }

    // 💡 Trả về thất bại không kèm dữ liệu
    public static new ApiResponse Fail(string message, List<string>? errors = null)
    {
        return new ApiResponse { Success = false, Message = message, Errors = errors };
    }
}
