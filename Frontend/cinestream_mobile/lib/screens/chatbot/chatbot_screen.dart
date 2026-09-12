import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_drawer.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
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

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Xin chào! Tôi là CineBot 🎬 Hãy cho tôi biết tâm trạng hoặc thể loại phim bạn muốn xem hôm nay.',
      isFromBot: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? message]) {
    final text = (message ?? _messageController.text).trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isFromBot: false,
        ),
      );

      _messageController.clear();
    });

    _scrollToBottom();

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _messages.add(
            const _ChatMessage(
              text:
                  'Mình đã nhận được yêu cầu của bạn 🎬 Khi kết nối AI, CineBot sẽ tìm những bộ phim phù hợp nhất.',
              isFromBot: true,
            ),
          );
        });

        _scrollToBottom();
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawerScrimColor: Colors.black.withValues(
        alpha: 0.58,
      ),
      drawer: const AppDrawer(
        currentRoute: AppRoutes.chatbot,
      ),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildChatContent(),
            ),
            _buildSuggestionSection(),
            _buildMessageInput(),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(
        currentIndex: 3,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                _showMessage(
                  'Bạn không có thông báo mới.',
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.black,
                size: 26,
              ),
            ),
            Positioned(
              right: 11,
              top: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.darkGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.background,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatContent() {
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
        const SizedBox(height: 20),
        ..._messages.map(_buildMessageBubble),
      ],
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
            borderRadius: BorderRadius.circular(17),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
          constraints: const BoxConstraints(
            maxWidth: 290,
          ),
          margin: const EdgeInsets.only(
            bottom: 12,
            left: 45,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.darkGreen,
            borderRadius: BorderRadius.circular(18),
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

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(
            right: 9,
            top: 2,
          ),
          decoration: BoxDecoration(
            color: AppTheme.darkGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.pinkAccent,
            size: 19,
          ),
        ),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 305,
            ),
            margin: const EdgeInsets.only(
              bottom: 12,
              right: 20,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: AppTheme.black,
                fontSize: 13,
                height: 1.45,
              ),
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
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              padding: const EdgeInsets.only(
                right: 20,
              ),
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final suggestion =
                    _suggestions[index];

                return GestureDetector(
                  onTap: () {
                    _sendMessage(suggestion);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                        color: AppTheme.darkGreen
                            .withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        color: AppTheme.darkGreen,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.darkGreen.withValues(
              alpha: 0.10,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 3,
                textInputAction:
                    TextInputAction.send,
                onSubmitted: (_) {
                  _sendMessage();
                },
                decoration:
                    const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
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
              padding: const EdgeInsets.only(
                right: 7,
              ),
              child: Material(
                color: AppTheme.darkGreen,
                borderRadius:
                    BorderRadius.circular(15),
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(15),
                  onTap: _sendMessage,
                  child: const SizedBox(
                    width: 43,
                    height: 43,
                    child: Icon(
                      Icons.arrow_upward_rounded,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isFromBot;

  const _ChatMessage({
    required this.text,
    required this.isFromBot,
  });
}