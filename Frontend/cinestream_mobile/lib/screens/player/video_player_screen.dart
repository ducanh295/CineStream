import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/api_constants.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
import '../../widgets/app_drawer.dart';

class VideoPlayerScreen extends StatefulWidget {
final Movie? movie;

const VideoPlayerScreen({
super.key,
this.movie,
});

@override
State<VideoPlayerScreen> createState() =>
_VideoPlayerScreenState();
}

class _VideoPlayerScreenState
extends State<VideoPlayerScreen> {
final MovieService _movieService =
MovieService.instance;

Movie? _movie;
MoviePlayback? _playback;

VideoPlayerController? _videoController;
ChewieController? _chewieController;

bool _isLoading = true;
String? _errorMessage;

@override
void initState() {
super.initState();


_movie = widget.movie;
_loadPlayback();


}

@override
void dispose() {
_chewieController?.dispose();
_videoController?.dispose();
super.dispose();
}

Future<void> _loadPlayback() async {
final movie = widget.movie;


if (movie == null) {
  if (!mounted) {
    return;
  }

  setState(() {
    _isLoading = false;
    _errorMessage =
        'Không tìm thấy thông tin bộ phim.';
  });

  return;
}

if (mounted) {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
}

try {
  final playback =
      await _movieService.getPlayback(movie.id);

  if (!mounted) {
    return;
  }

  _playback = playback;

  if (playback.videoStatus != 1) {
    setState(() {
      _isLoading = false;
      _errorMessage =
          'Video chưa sẵn sàng để phát.';
    });

    return;
  }

  final streamUrl = playback.streamUrl;

  if (streamUrl == null ||
      streamUrl.trim().isEmpty) {
    setState(() {
      _isLoading = false;
      _errorMessage =
          'Không tìm thấy đường dẫn video.';
    });

    return;
  }

  final resolvedUrl =
      _resolveStreamUrl(streamUrl);

  await _initializeVideo(resolvedUrl);

  if (!mounted) {
    return;
  }

  setState(() {
    _isLoading = false;
  });
} catch (e) {
  if (!mounted) {
    return;
  }

  setState(() {
    _isLoading = false;
    _errorMessage = _cleanErrorMessage(e);
  });
}


}

Future<void> _initializeVideo(
String streamUrl,
) async {
_chewieController?.dispose();
_videoController?.dispose();


_chewieController = null;
_videoController = null;

final controller =
    VideoPlayerController.networkUrl(
  Uri.parse(streamUrl),
);

_videoController = controller;

try {
  await controller.initialize();

  if (!mounted) {
    await controller.dispose();
    return;
  }

  _chewieController = ChewieController(
    videoPlayerController: controller,
    autoPlay: true,
    looping: false,
    allowFullScreen: true,
    allowMuting: true,
    showControls: true,
    showControlsOnInitialize: true,
    materialProgressColors:
        ChewieProgressColors(
      playedColor: const Color(0xFF6FAF8E),
      handleColor: const Color(0xFF6FAF8E),
      bufferedColor:
          Colors.white.withValues(alpha: 0.35),
      backgroundColor:
          Colors.white.withValues(alpha: 0.15),
    ),
    placeholder: Container(
      color: Colors.black,
    ),
    errorBuilder: (
      context,
      errorMessage,
    ) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      );
    },
  );
} catch (_) {
  await controller.dispose();
  _videoController = null;

  throw Exception(
    'Không thể khởi tạo trình phát video.',
  );
}


}

String _resolveStreamUrl(String streamUrl) {
final value = streamUrl.trim();


final parsed = Uri.tryParse(value);

if (parsed != null &&
    parsed.hasScheme &&
    parsed.host.isNotEmpty) {
  return value;
}

final baseUri =
    Uri.parse(ApiConstants.baseUrl);

final origin = Uri(
  scheme: baseUri.scheme,
  host: baseUri.host,
  port: baseUri.hasPort
      ? baseUri.port
      : null,
);

if (value.startsWith('/')) {
  return origin.resolve(value).toString();
}

return origin.resolve('/$value').toString();


}

String _cleanErrorMessage(Object error) {
return error
.toString()
.replaceFirst('Exception: ', '')
.trim();
}

String _playbackStatus() {
final playback = _playback;


if (playback == null) {
  return 'Chưa có thông tin';
}

return playback.videoStatus == 1
    ? 'Sẵn sàng'
    : 'Chưa sẵn sàng';


}

String _formatDuration(int? duration) {
if (duration == null || duration <= 0) {
return 'Không xác định';
}


final hours = duration ~/ 60;
final minutes = duration % 60;

if (hours > 0) {
  return '$hours giờ $minutes phút';
}

return '$duration phút';


}

@override
Widget build(BuildContext context) {
final movie = _movie;


return Scaffold(
  backgroundColor: const Color(0xFF101512),
  drawerScrimColor:
      Colors.black.withValues(alpha: 0.58),
  drawer: const AppDrawer(
    currentRoute: null,
  ),
  body: SafeArea(
    top: false,
    child: SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildPlayerArea(),
          if (movie != null) ...[
            _buildMovieHeader(movie),
            _buildDescription(movie),
            _buildTechnicalInfo(),
          ],
          const SizedBox(height: 28),
        ],
      ),
    ),
  ),
);


}

Widget _buildPlayerArea() {
if (_isLoading) {
return AspectRatio(
aspectRatio: 16 / 9,
child: Stack(
fit: StackFit.expand,
children: [
_buildPlayerBackground(),
_buildTopControls(),
const Center(
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
CircularProgressIndicator(
color: Colors.white,
),
SizedBox(height: 12),
Text(
'Đang tải video...',
style: TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
],
),
),
],
),
);
}


if (_errorMessage != null) {
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _buildPlayerBackground(),
        Container(
          color: Colors.black.withValues(
            alpha: 0.35,
          ),
        ),
        _buildTopControls(),
        _buildErrorState(),
      ],
    ),
  );
}

final chewieController =
    _chewieController;
final videoController =
    _videoController;

if (chewieController == null ||
    videoController == null ||
    !videoController.value.isInitialized) {
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _buildPlayerBackground(),
        _buildTopControls(),
        _buildErrorState(
          message:
              'Không thể khởi tạo trình phát video.',
        ),
      ],
    ),
  );
}

final aspectRatio =
    videoController.value.aspectRatio > 0
        ? videoController.value.aspectRatio
        : 16 / 9;

return AspectRatio(
  aspectRatio: aspectRatio,
  child: Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(
        color: Colors.black,
        child: Chewie(
          controller: chewieController,
        ),
      ),
      _buildTopControls(),
    ],
  ),
);


}

Widget _buildPlayerBackground() {
final posterUrl = _movie?.posterUrl;


if (posterUrl == null ||
    posterUrl.trim().isEmpty) {
  return Container(
    color: const Color(0xFF0D100E),
    child: const Center(
      child: Icon(
        Icons.movie_outlined,
        color: Colors.white24,
        size: 70,
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
      color: const Color(0xFF0D100E),
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: Colors.white24,
          size: 70,
        ),
      ),
    );
  },
);


}

Widget _buildErrorState({
String? message,
}) {
final text = message ??
_errorMessage ??
'Không thể phát video.';


return Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.white70,
          size: 52,
        ),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _loadPlayback,
          style:
              OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(
              color: Colors.white54,
            ),
          ),
          child: const Text(
            'Thử lại',
          ),
        ),
      ],
    ),
  ),
);


}

Widget _buildTopControls() {
return Positioned(
top: 45,
left: 16,
right: 16,
child: Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
_circleButton(
icon: Icons.arrow_back_rounded,
onTap: () {
Navigator.pop(context);
},
),
Builder(
builder: (scaffoldContext) {
return _circleButton(
icon: Icons.menu_rounded,
onTap: () {
Scaffold.of(
scaffoldContext,
).openDrawer();
},
);
},
),
],
),
);
}

Widget _circleButton({
required IconData icon,
required VoidCallback onTap,
}) {
return Material(
color: Colors.black.withValues(
alpha: 0.38,
),
shape: const CircleBorder(),
child: InkWell(
customBorder: const CircleBorder(),
onTap: onTap,
child: SizedBox(
width: 42,
height: 42,
child: Icon(
icon,
color: Colors.white,
size: 21,
),
),
),
);
}

Widget _buildMovieHeader(Movie movie) {
return Padding(
padding: const EdgeInsets.fromLTRB(
20,
22,
20,
0,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
movie.title,
style: const TextStyle(
color: Colors.white,
fontSize: 29,
height: 1.12,
fontWeight: FontWeight.w700,
fontFamily: 'Georgia',
),
),
const SizedBox(height: 8),
Text(
_movieInfo(movie),
style: const TextStyle(
color: Color(0xFFB8C0BA),
fontSize: 14,
fontWeight: FontWeight.w500,
),
),
],
),
);
}

String _movieInfo(Movie movie) {
final parts = <String>[];


if (movie.releaseYear != null) {
  parts.add(
    movie.releaseYear.toString(),
  );
}

if (movie.duration != null &&
    movie.duration! > 0) {
  parts.add(
    _formatDuration(movie.duration),
  );
}

parts.add(
  movie.isSeries
      ? 'Phim bộ'
      : 'Phim lẻ',
);

return parts.join(' · ');


}

Widget _buildDescription(Movie movie) {
return Container(
margin: const EdgeInsets.fromLTRB(
20,
26,
20,
0,
),
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: const Color(0xFF18211C),
borderRadius:
BorderRadius.circular(20),
border: Border.all(
color: Colors.white.withValues(
alpha: 0.05,
),
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 8,
height: 8,
decoration:
const BoxDecoration(
color: Color(0xFF6FAF8E),
shape: BoxShape.circle,
),
),
const SizedBox(width: 9),
const Text(
'THÔNG TIN PHIM',
style: TextStyle(
color: Color(0xFF6FAF8E),
fontSize: 12,
letterSpacing: 1.2,
fontWeight:
FontWeight.w800,
),
),
],
),
const SizedBox(height: 13),
Text(
movie.description ??
'Chưa có mô tả cho bộ phim này.',
style: const TextStyle(
color: Color(0xFFD7DDD9),
fontSize: 14,
height: 1.65,
),
),
],
),
);
}

Widget _buildTechnicalInfo() {
final playback = _playback;


if (playback == null) {
  return const SizedBox.shrink();
}

return Padding(
  padding: const EdgeInsets.fromLTRB(
    20,
    24,
    20,
    0,
  ),
  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      const Text(
        'THÔNG TIN PHÁT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 14),
      _infoRow(
        icon: Icons.schedule_rounded,
        label: 'Thời lượng',
        value: _formatDuration(
          playback.duration ??
              _movie?.duration,
        ),
      ),
      _infoRow(
        icon:
            Icons.play_circle_outline_rounded,
        label: 'Trạng thái',
        value: _playbackStatus(),
        valueColor:
            playback.videoStatus == 1
                ? const Color(0xFF6FAF8E)
                : const Color(0xFFE57373),
      ),
    ],
  ),
);


}

Widget _infoRow({
required IconData icon,
required String label,
required String value,
Color? valueColor,
}) {
return Container(
margin: const EdgeInsets.only(
bottom: 10,
),
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 13,
),
decoration: BoxDecoration(
color: const Color(0xFF18211C),
borderRadius:
BorderRadius.circular(14),
),
child: Row(
children: [
Icon(
icon,
color: const Color(0xFF6FAF8E),
size: 23,
),
const SizedBox(width: 12),
Expanded(
child: Text(
label,
style: const TextStyle(
color: Color(0xFF8D9690),
fontSize: 12,
),
),
),
Text(
value,
style: TextStyle(
color: valueColor ??
Colors.white,
fontSize: 13,
fontWeight: FontWeight.w700,
),
),
],
),
);
}
}
