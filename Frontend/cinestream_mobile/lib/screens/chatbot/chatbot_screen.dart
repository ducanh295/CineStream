import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() =>
      _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final ChatService _chatService =
      ChatService.instance;

  final List<String> _suggestions = const [
    'Phim hay 2024',
    'Tôi muốn cười',
    'Phim hành động',
    'Phim chill',
    'Phim lãng mạn',
    'Phim Sci-Fi',
  ];

  final List<ChatMessage> _messages = [];

  bool _isLoadingHistory = true;
  bool _isSending = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingHistory = false;
        _errorMessage =
            'Bạn cần đăng nhập để sử dụng CineBot.';
      });

      return;
    }

    setState(() {
      _isLoadingHistory = true;
      _errorMessage = null;
    });

    try {
      final history =
          await _chatService.getHistory(
        limit: 30,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages
          ..clear()
          ..addAll(history);

        _isLoadingHistory = false;
      });

      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      _scrollToBottom(
        animated: false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingHistory = false;
        _errorMessage =
            _cleanErrorMessage(e);
      });

      _addWelcomeMessage();
    }
  }

  Future<void> _sendMessage([
    String? message,
  ]) async {
    if (_isSending) {
      return;
    }

    final text =
        (message ??
                _messageController.text)
            .trim();

    if (text.isEmpty) {
      return;
    }

    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showMessage(
        'Bạn cần đăng nhập để chat với CineBot.',
      );
      return;
    }

    _messageController.clear();

    setState(() {
      _errorMessage = null;
      _isSending = true;

      _messages.add(
        ChatMessage(
          text: text,
          isFromBot: false,
          createdAt: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    try {
      final response =
          await _chatService.sendMessage(
        text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.reply,
            isFromBot: true,
            createdAt:
                response.createdAt,
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

      final errorMessage =
          _cleanErrorMessage(e);

      setState(() {
        _isSending = false;
        _errorMessage = errorMessage;
      });

      _showMessage(errorMessage);

      _scrollToBottom();
    }
  }

  Future<void> _clearHistory() async {
    if (_isSending) {
      return;
    }

    final authProvider =
        context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showMessage(
        'Bạn cần đăng nhập.',
      );
      return;
    }

    final confirmed =
        await _showClearHistoryDialog();

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _chatService.clearHistory();

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.clear();
        _errorMessage = null;
      });

      _addWelcomeMessage();

      _showMessage(
        'Đã xóa lịch sử trò chuyện.',
      );

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanErrorMessage(e),
      );
    }
  }

  Future<bool> _showClearHistoryDialog() async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
          ),
          title: const Text(
            'Xóa lịch sử chat',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện với CineBot không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color:
                      AppTheme.grey,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Xóa',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _addWelcomeMessage() {
    if (!mounted ||
        _messages.isNotEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        const ChatMessage(
          text:
              'Xin chào! Tôi là CineBot 🎬 Hãy cho tôi biết tâm trạng hoặc thể loại phim bạn muốn xem hôm nay.',
          isFromBot: true,
        ),
      );
    });
  }

  void _openMovieDetail(
    Movie movie,
  ) {
    Navigator.pushNamed(
      context,
      AppRoutes.movieDetail,
      arguments: movie,
    );
  }

  void _scrollToBottom({
    bool animated = true,
  }) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      final target =
          _scrollController.position.maxScrollExtent;

      if (!animated) {
        _scrollController.jumpTo(target);
        return;
      }

      _scrollController.animateTo(
        target,
        duration:
            const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _cleanErrorMessage(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final authProvider =
        context.watch<AuthProvider>();

    final isAuthenticated =
        authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor:
          AppTheme.background,
      drawerScrimColor:
          Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute:
            AppRoutes.chatbot,
      ),
      appBar: _buildAppBar(
        isAuthenticated:
            isAuthenticated,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  _buildChatContent(
                isAuthenticated:
                    isAuthenticated,
              ),
            ),
            if (isAuthenticated) ...[
              _buildSuggestionSection(),
              _buildMessageInput(),
            ],
          ],
        ),
      ),
      bottomNavigationBar:
          const AppBottomNavigation(
        currentIndex: 3,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({
    required bool isAuthenticated,
  }) {
    return AppBar(
      backgroundColor:
          AppTheme.background,
      surfaceTintColor:
          Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            onPressed: () {
              Scaffold.of(context)
                  .openDrawer();
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
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration:
                BoxDecoration(
              color: AppTheme.darkGreen
                  .withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(9),
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
              fontWeight:
                  FontWeight.w900,
              fontFamily: 'Georgia',
            ),
          ),
        ],
      ),
      actions: [
        if (isAuthenticated)
          IconButton(
            tooltip:
                'Xóa lịch sử chat',
            onPressed:
                _isSending
                    ? null
                    : _clearHistory,
            icon: const Icon(
              Icons
                  .delete_outline_rounded,
              color: AppTheme.black,
              size: 24,
            ),
          ),
      ],
    );
  }

  Widget _buildChatContent({
    required bool isAuthenticated,
  }) {
    if (!isAuthenticated) {
      return _buildLoginRequired();
    }

    if (_isLoadingHistory) {
      return const Center(
        child:
            CircularProgressIndicator(
        color:
            AppTheme.darkGreen,
      ));
    }

    return ListView(
      controller:
          _scrollController,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        16,
      ),
      physics:
          const BouncingScrollPhysics(),
      children: [
        _buildBotHeader(),
        const SizedBox(height: 20),
        if (_errorMessage != null)
          _buildErrorBanner(),
        ..._messages.map(
          _buildMessageBubble,
        ),
        if (_isSending)
          _buildTypingBubble(),
      ],
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.darkGreen,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color:
                    Colors.pinkAccent,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Đăng nhập để sử dụng CineBot',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 19,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'CineBot có thể trò chuyện và hỗ trợ bạn tìm phim phù hợp.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.login,
                );
              },
              icon: const Icon(
                Icons.login_rounded,
              ),
              label:
                  const Text(
                'Đăng nhập',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotHeader() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration:
              BoxDecoration(
            color:
                AppTheme.darkGreen,
            borderRadius:
                BorderRadius.circular(
              17,
            ),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color:
                Colors.pinkAccent,
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
                  color:
                      AppTheme.black,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color:
                        Colors.green,
                    size: 9,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      color:
                          Colors.green,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
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

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            color:
                Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style:
                  const TextStyle(
                color:
                    Colors.redAccent,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
  ) {
    if (!message.isFromBot) {
      return Align(
        alignment:
            Alignment.centerRight,
        child: Container(
          constraints:
              const BoxConstraints(
            maxWidth: 290,
          ),
          margin:
              const EdgeInsets.only(
            bottom: 12,
            left: 45,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          decoration:
              BoxDecoration(
            color:
                AppTheme.darkGreen,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          child: Text(
            message.text,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
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
            decoration:
                BoxDecoration(
              color:
                  AppTheme.darkGreen,
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color:
                  Colors.pinkAccent,
              size: 19,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  margin:
                      const EdgeInsets.only(
                    right: 20,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style:
                        const TextStyle(
                      color:
                          AppTheme.black,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
                if (message
                    .recommendedMovies
                    .isNotEmpty)
                  _buildRecommendedMovies(
                    message
                        .recommendedMovies,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedMovies(
    List<Movie> movies,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        top: 10,
        right: 4,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
                EdgeInsets.only(
              left: 2,
              bottom: 8,
            ),
            child: Text(
              'PHIM ĐỀ XUẤT',
              style: TextStyle(
                color:
                    AppTheme.grey,
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            height: 214,
            child:
                ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  movies.length,
              separatorBuilder:
                  (context, index) {
                return const SizedBox(
                  width: 10,
                );
              },
              itemBuilder:
                  (context, index) {
                return _buildMovieCard(
                  movies[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(
    Movie movie,
  ) {
    final posterUrl =
        movie.posterUrl?.trim();

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          _openMovieDetail(movie);
        },
        borderRadius:
            BorderRadius.circular(16),
        child: SizedBox(
          width: 138,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.only(
                  topLeft:
                      Radius.circular(16),
                  topRight:
                      Radius.circular(16),
                ),
                child: SizedBox(
                  width: 138,
                  height: 148,
                  child: posterUrl ==
                              null ||
                          posterUrl.isEmpty
                      ? _buildMoviePlaceholder()
                      : Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return _buildMoviePlaceholder();
                          },
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    9,
                    8,
                    9,
                    7,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .black,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _movieInfo(movie),
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .grey,
                          fontSize: 9.5,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoviePlaceholder() {
    return Container(
      color:
          AppTheme.lightGrey,
      alignment:
          Alignment.center,
      child: const Icon(
        Icons.movie_outlined,
        color:
            AppTheme.grey,
        size: 34,
      ),
    );
  }

  String _movieInfo(
    Movie movie,
  ) {
    final parts =
        <String>[];

    if (movie.releaseYear !=
        null) {
      parts.add(
        movie.releaseYear!.toString(),
      );
    }

    if (movie.duration !=
            null &&
        movie.duration! > 0) {
      parts.add(
        '${movie.duration} phút',
      );
    }

    parts.add(
      movie.isSeries
          ? 'Phim bộ'
          : 'Phim lẻ',
    );

    return parts.join(' • ');
  }

  Widget _buildTypingBubble() {
    return Row(
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
          decoration:
              BoxDecoration(
            color:
                AppTheme.darkGreen,
            borderRadius:
                BorderRadius.circular(
              11,
            ),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color:
                Colors.pinkAccent,
            size: 19,
          ),
        ),
        Container(
          margin:
              const EdgeInsets.only(
            bottom: 12,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          child: const SizedBox(
            width: 22,
            height: 18,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionSection() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        9,
        0,
        10,
      ),
      color:
          AppTheme.background,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'GỢI Ý NHANH',
            style: TextStyle(
              color:
                  AppTheme.grey,
              fontSize: 10.5,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(
            height: 9,
          ),
          SizedBox(
            height: 38,
            child:
                ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  _suggestions.length,
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
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        30,
                      ),
                      border:
                          Border.all(
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
                        color:
                            AppTheme
                                .darkGreen,
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w600,
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
      color:
          AppTheme.background,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        12,
      ),
      child: Container(
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color: AppTheme
                .darkGreen
                .withValues(
              alpha: 0.10,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller:
                    _messageController,
                minLines: 1,
                maxLines: 3,
                enabled: !_isSending,
                textInputAction:
                    TextInputAction.send,
                onSubmitted: (_) {
                  _sendMessage();
                },
                decoration:
                    const InputDecoration(
                  hintText:
                      'Nhập tin nhắn...',
                  border:
                      InputBorder.none,
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
                  child:
                      const SizedBox(
                    width: 43,
                    height: 43,
                    child: Icon(
                      Icons
                          .arrow_upward_rounded,
                      color:
                          Colors.white,
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
}