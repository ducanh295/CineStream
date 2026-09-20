// Lớp mô hình đóng gói kết quả phân trang dữ liệu từ máy chủ Backend
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  // Khởi tạo đối tượng phân trang rỗng mặc định
  factory PagedResult.empty() {
    return const PagedResult(
      items: [],
      totalCount: 0,
      pageNumber: 1,
      pageSize: 10,
      totalPages: 0,
    );
  }
}
