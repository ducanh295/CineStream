import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';
import '../movie/movie_detail_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatService _chatService = ChatService.instance;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final List<String> _suggestions = [
    'Phim hay 2024',
    'Tôi muốn cười',
    'Phim hành động',
    'Phim chill',
    'Phim lãng mạn',
    'Phim Sci-Fi',
  ];

  final List<_ChatMessage> _messages = [];

  bool _isLoadingHistory = true;
  bool _isSending = false;
  String? _historyError;
  bool _wasPremium = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isPremium = user?.premiumActive == true || user?.isAdmin == true;

    // Tự động kích hoạt nạp lịch sử khi tài khoản nâng cấp lên Premium
    if (isPremium && !_wasPremium) {
      _wasPremium = true;
      _loadHistory();
    } else if (!isPremium) {
      _wasPremium = false;
      if (_isLoadingHistory) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final isPremium = user?.premiumActive == true || user?.isAdmin == true;

    // Chỉ thực hiện gọi máy chủ khi tài khoản đã được xác thực Premium hoặc Admin
    if (!isPremium) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingHistory = true;
        _historyError = null;
      });
    }

    try {
      final history = await _chatService.getHistory(
        limit: 30,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages
          ..clear()
          ..addAll(
            history.map(
              (log) => _ChatMessage(
                text: log.message,
                isFromBot: log.isFromAI,
                createdAt: log.createdAt,
              ),
            ),
          );

        _isLoadingHistory = false;
      });

      if (_messages.isEmpty) {
        setState(() {
          _messages.add(
            const _ChatMessage(
              text:
                  'Xin chào! Tôi là CineBot. Hãy cho tôi biết tâm trạng hoặc thể loại phim bạn muốn xem hôm nay.',
              isFromBot: true,
            ),
          );
        });
      }

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingHistory = false;
        _historyError = _cleanError(e);

        if (_messages.isEmpty) {
          _messages.add(
            const _ChatMessage(
              text:
                  'Xin chào! Tôi là CineBot. Hãy cho tôi biết tâm trạng hoặc thể loại phim bạn muốn xem hôm nay.',
              isFromBot: true,
            ),
          );
        }
      });
    }
  }

  Future<void> _sendMessage([
    String? message,
  ]) async {
    if (_isSending) {
      return;
    }

    final text = (message ?? _messageController.text).trim();

    if (text.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isFromBot: false,
          createdAt: DateTime.now(),
        ),
      );

      _messageController.clear();
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(text);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text: response.reply.isEmpty
                ? 'CineBot chưa có nội dung trả lời.'
                : response.reply,
            isFromBot: true,
            createdAt: response.createdAt,
            recommendedMovies:
                response.recommendedMovies,
          ),
        );

        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSending = false;

        _messages.add(
          _ChatMessage(
            text: 'Không thể nhận phản hồi từ CineBot.\n\n'
                '${_cleanError(e)}',
            isFromBot: true,
            isError: true,
            createdAt: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  Future<void> _clearHistory() async {
    if (_isSending) {
      return;
    }

    try {
      await _chatService.clearHistory();

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.clear();

        _messages.add(
          const _ChatMessage(
            text:
                'Xin chào! Tôi là CineBot. Hãy cho tôi biết tâm trạng hoặc thể loại phim bạn muốn xem hôm nay.',
            isFromBot: true,
          ),
        );
      });

      _showMessage('Đã xóa lịch sử trò chuyện.');
      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isPremium = user?.premiumActive == true || user?.isAdmin == true;

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawerScrimColor: Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute: AppRoutes.chatbot,
      ),
      appBar: _buildAppBar(isPremium),
      body: SafeArea(
        child: isPremium
            ? Column(
                children: [
                  Expanded(
                    child: _buildChatContent(),
                  ),
                  _buildSuggestionSection(),
                  _buildMessageInput(),
                ],
              )
            : _buildPaywallGatekeeper(context, authProvider),
      ),
      bottomNavigationBar: const AppBottomNavigation(
        currentIndex: 3,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isPremium) {
    return AppBar(
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(
              Icons.menu_rounded,
              color: AppTheme.black,
              size: 28,
            ),
          );
        },
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.darkGreen.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.movie_creation_outlined,
              color: AppTheme.darkGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'CineStream',
            style: TextStyle(
              color: AppTheme.black,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
      actions: [
        if (isPremium)
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppTheme.black,
            ),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Text(
                    'Xóa lịch sử trò chuyện',
                  ),
                ),
              ];
            },
          ),
      ],
    );
  }

  // Giao diện giới thiệu đặc quyền Premium dành riêng cho tính năng AI Chatbot
  Widget _buildPaywallGatekeeper(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final isAuthenticated = authProvider.isAuthenticated;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Huy hiệu biểu tượng Premium mạ vàng
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDE68A),
                  Color(0xFFD97706),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Nhãn đặc quyền gói VIP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              ),
            ),
            child: const Text(
              'ĐẶC QUYỀN GÓI PREMIUM',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tiêu đề chính
          const Text(
            'Trợ Lý Điện Ảnh AI CineBot',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: 'Georgia',
              height: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          // Đoạn mô tả giá trị cốt lõi
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Mở khóa trí tuệ nhân tạo điện ảnh thế hệ mới độc quyền dành riêng cho thành viên gói Premium của CineStream.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 26),

          // Danh sách 3 giá trị nổi bật của CineBot
          _buildBenefitItem(
            icon: Icons.psychology_rounded,
            title: 'Gợi ý phim theo tâm trạng tức thì',
            description:
                'Phân tích cảm xúc và sở thích cá nhân để đưa ra danh sách phim chuẩn gu trong tích tắc.',
          ),
          const SizedBox(height: 14),
          _buildBenefitItem(
            icon: Icons.auto_awesome_rounded,
            title: 'Phân tích kịch bản và diễn viên',
            description:
                'Hỏi đáp chi tiết về cốt truyện, thông điệp ẩn ý, tiểu sử đạo diễn và dàn sao điện ảnh.',
          ),
          const SizedBox(height: 14),
          _buildBenefitItem(
            icon: Icons.bolt_rounded,
            title: 'Trò chuyện không giới hạn 24/7',
            description:
                'Tương tác liên tục với trợ lý AI thông minh qua mô hình Google Gemini tân tiến nhất.',
          ),

          const SizedBox(height: 32),

          // Nút kêu gọi hành động nâng cấp gói
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (!isAuthenticated) {
                  Navigator.pushNamed(context, AppRoutes.login);
                } else {
                  Navigator.pushNamed(context, AppRoutes.payment);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppTheme.darkGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 22,
                    color: Color(0xFFFDE68A),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAuthenticated
                        ? 'Nâng cấp gói Premium ngay'
                        : 'Đăng nhập để nâng cấp Premium',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Chú thích phụ trợ
          const Text(
            'Hỗ trợ thanh toán nhanh chóng qua quét mã QR hoặc cổng thanh toán nội địa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Thẻ hiển thị từng đặc quyền của tính năng AI
  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.darkGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.darkGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearHistoryDialog() async {
    final shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Xóa lịch sử trò chuyện?',
          ),
          content: const Text(
            'Toàn bộ lịch sử CineBot của tài khoản hiện tại sẽ bị xóa.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      await _clearHistory();
    }
  }

  Widget _buildChatContent() {
    if (_isLoadingHistory) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Đang tải lịch sử CineBot...',
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        16,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildBotHeader(),

        if (_historyError != null) ...[
          const SizedBox(height: 10),
          _buildHistoryWarning(),
        ],

        const SizedBox(height: 20),

        ..._messages.map(
          _buildMessageBubble,
        ),

        if (_isSending) ...[
          _buildTypingIndicator(),
        ],
      ],
    );
  }

  Widget _buildHistoryWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Không tải được lịch sử cũ.\n$_historyError',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: _loadHistory,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildBotHeader() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppTheme.darkGreen,
            borderRadius:
                BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.pinkAccent,
            size: 31,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'CineBot AI',
                style: TextStyle(
                  color: AppTheme.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: Colors.green,
                    size: 9,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
    _ChatMessage message,
  ) {
    if (!message.isFromBot) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints:
              const BoxConstraints(
            maxWidth: 290,
          ),
          margin: const EdgeInsets.only(
            bottom: 12,
            left: 45,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.darkGreen,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              margin:
                  const EdgeInsets.only(
                right: 9,
                top: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkGreen,
                borderRadius:
                    BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.pinkAccent,
                size: 19,
              ),
            ),
            Expanded(
              child: Container(
                constraints:
                    const BoxConstraints(
                  maxWidth: 305,
                ),
                margin:
                    const EdgeInsets.only(
                  bottom: 7,
                  right: 20,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: message.isError
                      ? Colors.red.shade50
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: message.isError
                      ? Border.all(
                          color: Colors.red
                              .withValues(
                            alpha: 0.18,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: message.isError
                        ? Colors.red.shade800
                        : AppTheme.black,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),

        if (message
            .recommendedMovies
            .isNotEmpty)
          _buildRecommendedMovies(
            message.recommendedMovies,
          ),
      ],
    );
  }

  Widget _buildRecommendedMovies(
    List<Movie> movies,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 45,
        right: 4,
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
                EdgeInsets.only(bottom: 9),
            child: Text(
              'PHIM CINEBOT GỢI Ý',
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              physics:
                  const BouncingScrollPhysics(),
              itemCount: movies.length,
              separatorBuilder:
                  (context, index) {
                return const SizedBox(
                  width: 10,
                );
              },
              itemBuilder:
                  (context, index) {
                final movie =
                    movies[index];

                return _buildMovieRecommendationCard(
                  movie,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieRecommendationCard(
    Movie movie,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MovieDetailScreen(
              movie: movie,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildMoviePoster(
                    movie.posterUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.black,
                fontSize: 12,
                height: 1.25,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _movieMeta(movie),
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviePoster(
    String? posterUrl,
  ) {
    if (posterUrl == null ||
        posterUrl.trim().isEmpty) {
      return Container(
        color: AppTheme.lightGrey,
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            color: AppTheme.grey,
            size: 36,
          ),
        ),
      );
    }

    return Image.network(
      posterUrl,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          color: AppTheme.lightGrey,
          child: const Center(
            child: Icon(
              Icons.movie_outlined,
              color: AppTheme.grey,
              size: 36,
            ),
          ),
        );
      },
    );
  }

  String _movieMeta(Movie movie) {
    final parts = <String>[];

    if (movie.releaseYear != null) {
      parts.add(
        movie.releaseYear.toString(),
      );
    }

    if (movie.duration != null) {
      parts.add(
        '${movie.duration} phút',
      );
    }

    return parts.isEmpty
        ? 'CineStream'
        : parts.join(' · ');
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          margin:
              const EdgeInsets.only(
            right: 9,
            top: 2,
          ),
          decoration: BoxDecoration(
            color: AppTheme.darkGreen,
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.pinkAccent,
            size: 19,
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          margin:
              const EdgeInsets.only(
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: const SizedBox(
            width: 55,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _TypingDot(),
                _TypingDot(),
                _TypingDot(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        9,
        0,
        10,
      ),
      color: AppTheme.background,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'GỢI Ý NHANH',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount: _suggestions.length,
              padding:
                  const EdgeInsets.only(
                right: 20,
              ),
              separatorBuilder:
                  (context, index) {
                return const SizedBox(
                  width: 8,
                );
              },
              itemBuilder:
                  (context, index) {
                final suggestion =
                    _suggestions[index];

                return GestureDetector(
                  onTap: _isSending
                      ? null
                      : () {
                          _sendMessage(
                            suggestion,
                          );
                        },
                  child: Opacity(
                    opacity:
                        _isSending ? 0.5 : 1,
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(30),
                        border: Border.all(
                          color: AppTheme
                              .darkGreen
                              .withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Text(
                        suggestion,
                        style:
                            const TextStyle(
                          color: AppTheme
                              .darkGreen,
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.darkGreen
                .withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller:
                    _messageController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 3,
                textInputAction:
                    TextInputAction.send,
                onSubmitted: (_) {
                  _sendMessage();
                },
                decoration:
                    const InputDecoration(
                  hintText:
                      'Nhập tin nhắn...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding:
                      EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 7,
              ),
              child: Material(
                color: _isSending
                    ? AppTheme.grey
                    : AppTheme.darkGreen,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  onTap: _isSending
                      ? null
                      : _sendMessage,
                  child: SizedBox(
                    width: 43,
                    height: 43,
                    child: _isSending
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              12,
                            ),
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .arrow_upward_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isFromBot;
  final bool isError;
  final DateTime? createdAt;
  final List<Movie> recommendedMovies;

  const _ChatMessage({
    required this.text,
    required this.isFromBot,
    this.isError = false,
    this.createdAt,
    this.recommendedMovies =
        const <Movie>[],
  });
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppTheme.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}

