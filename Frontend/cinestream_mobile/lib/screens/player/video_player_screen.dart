import 'package:flutter/material.dart';
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

bool _isLoading = true;
String? _errorMessage;

@override
void initState() {
super.initState();


_movie = widget.movie;
_loadPlayback();


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

setState(() {
  _isLoading = true;
  _errorMessage = null;
});

try {
  final playback =
      await _movieService.getPlayback(movie.id);

  if (!mounted) {
    return;
  }

  setState(() {
    _playback = playback;
    _isLoading = false;
  });
} catch (e) {
  if (!mounted) {
    return;
  }

  setState(() {
    _isLoading = false;
    _errorMessage =
        e.toString().replaceFirst(
              'Exception: ',
              '',
            );
  });
}


}

@override
Widget build(BuildContext context) {
final movie = _movie;


return Scaffold(
  backgroundColor: const Color(0xFF101512),
  drawerScrimColor: Colors.black.withValues(
    alpha: 0.58,
  ),
  drawer: const AppDrawer(
    currentRoute: null,
  ),
  body: SafeArea(
    top: false,
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
return AspectRatio(
aspectRatio: 16 / 9,
child: Stack(
fit: StackFit.expand,
children: [
_buildPlayerBackground(),
_buildTopControls(),
Center(
child: _buildPlayerState(),
),
],
),
);
}

Widget _buildPlayerBackground() {
final posterUrl = _movie?.posterUrl;


if (posterUrl == null ||
    posterUrl.isEmpty) {
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

Widget _buildPlayerState() {
if (_isLoading) {
return const Column(
mainAxisSize: MainAxisSize.min,
children: [
CircularProgressIndicator(
color: Colors.white,
),
SizedBox(height: 12),
Text(
'Đang lấy thông tin phát...',
style: TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
],
);
}


if (_errorMessage != null) {
  return Padding(
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
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _loadPlayback,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(
              color: Colors.white54,
            ),
          ),
          child: const Text('Thử lại'),
        ),
      ],
    ),
  );
}

final playback = _playback;

if (playback == null) {
  return const Text(
    'Không có dữ liệu phát.',
    style: TextStyle(
      color: Colors.white70,
    ),
  );
}

if (playback.videoStatus != 1 ||
    playback.streamUrl == null ||
    playback.streamUrl!.isEmpty) {
  return const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.videocam_off_rounded,
        color: Colors.white70,
        size: 52,
      ),
      SizedBox(height: 12),
      Text(
        'Video chưa sẵn sàng phát.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

return Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.45,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 42,
      ),
    ),
    const SizedBox(height: 12),
    Text(
      playback.streamType,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  ],
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

if (movie.duration != null) {
  parts.add(
    '${movie.duration} phút',
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
borderRadius: BorderRadius.circular(20),
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
decoration: const BoxDecoration(
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
fontWeight: FontWeight.w800,
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
        'Kiểu phát',
        playback.streamType,
      ),
      _infoRow(
        'Trạng thái',
        playback.videoStatus == 1
            ? 'Sẵn sàng'
            : 'Chưa sẵn sàng',
      ),
      if (playback.duration != null)
        _infoRow(
          'Thời lượng',
          '${playback.duration} phút',
        ),
      if (playback.streamUrl != null &&
          playback.streamUrl!.isNotEmpty)
        _infoRow(
          'Stream URL',
          playback.streamUrl!,
        ),
    ],
  ),
);


}

Widget _infoRow(
String label,
String value,
) {
return Padding(
padding: const EdgeInsets.only(
bottom: 10,
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
SizedBox(
width: 105,
child: Text(
label,
style: const TextStyle(
color: Color(0xFF8D9690),
fontSize: 12,
),
),
),
Expanded(
child: Text(
value,
style: const TextStyle(
color: Colors.white,
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
),
],
),
);
}
}
