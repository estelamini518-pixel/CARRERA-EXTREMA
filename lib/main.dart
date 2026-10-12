import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TurboRacingApp());
}

class TurboRacingApp extends StatelessWidget {
  const TurboRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turbo Racing: Carrera al Vacío',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const RacingHomePage(),
    );
  }
}

class RacingHomePage extends StatefulWidget {
  const RacingHomePage({super.key});

  @override
  State<RacingHomePage> createState() => _RacingHomePageState();
}

class _RacingHomePageState extends State<RacingHomePage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  double _playerX = 0;
  double _progress = 0;
  double _shadowDistance = 1;
  int _score = 0;
  int _level = 1;
  int _lives = 3;
  bool _started = false;
  bool _gameOver = false;
  bool _won = false;
  bool _blackHole = false;

  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (!_started || _gameOver || _won) return;

    final delta = _elapsed == Duration.zero
        ? 0.016
        : (elapsed - _elapsed).inMicroseconds / 1000000;

    _elapsed = elapsed;

    setState(() {
      _progress += delta * (0.045 + _level * 0.008);
      _score += (delta * 10).toInt();

      _shadowDistance -= delta * (0.025 + _level * 0.003);

      if (_shadowDistance <= 0) {
        _lives--;

        if (_lives <= 0) {
          _gameOver = true;
          _started = false;
          _ticker.stop();
        } else {
          _shadowDistance = 1;
          _playerX = 0;
        }
      }

      if (_progress >= 1) {
        _level++;

        if (_level > 10) {
          _won = true;
          _started = false;
          _ticker.stop();
        } else {
          _progress = 0;
          _shadowDistance = 1;
          _blackHole = false;
        }
      }
    });
  }

  void _startGame() {
    setState(() {
      _started = true;
      _gameOver = false;
      _won = false;
      _level = 1;
      _score = 0;
      _lives = 3;
      _progress = 0;
      _shadowDistance = 1;
      _playerX = 0;
      _blackHole = false;
      _elapsed = Duration.zero;
    });

    _ticker.start();
  }

  void _movePlayer(double direction) {
    if (!_started || _gameOver || _won) return;

    setState(() {
      _playerX = (_playerX + direction * 0.18).clamp(-1.0, 1.0);
    });
  }

  void _activateBlackHole() {
    if (!_started || _gameOver || _won) return;

    setState(() {
      _blackHole = true;
      _score += 100;

      if (_shadowDistance < 0.45) {
        _level++;

        if (_level > 10) {
          _won = true;
          _started = false;
          _ticker.stop();
        } else {
          _progress = 0;
          _shadowDistance = 1;
        }
      } else {
        _shadowDistance = 0.8;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF020617),
              Color(0xFF111827),
              Color(0xFF312E81),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SpacePainter(
                          progress: _progress,
                          level: _level,
                        ),
                      ),
                    ),
                    Center(
                      child: Transform.translate(
                        offset: Offset(_playerX * 120, 45),
                        child: const Text(
                          '🚀',
                          style: TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 22,
                      left: 20,
                      right: 20,
                      child: Text(
                        'NIVEL $_level  •  SECTOR GALÁCTICO',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 65,
                      left: 20,
                      right: 20,
                      child: Column(
                        children: [
                          const Text(
                            'LA SOMBRA',
                            style: TextStyle(
                              color: Colors.deepPurpleAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: _shadowDistance.clamp(0.0, 1.0),
                            minHeight: 9,
                            backgroundColor: Colors.black45,
                            color: Colors.deepPurpleAccent,
                          ),
                        ],
                      ),
                    ),
                    if (_blackHole)
                      const Center(
                        child: Text(
                          '🌀',
                          style: TextStyle(fontSize: 90),
                        ),
                      ),
                    if (!_started)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.cyanAccent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _won
                                    ? '¡CARRERA COMPLETADA!'
                                    : _gameOver
                                        ? '¡LA SOMBRA TE ALCANZÓ!'
                                        : 'TURBO RACING',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _won
                                    ? '¡Has conquistado el vacío!'
                                    : _gameOver
                                        ? 'Puntuación: $_score'
                                        : 'Escapa de la sombra y encuentra agujeros negros para avanzar.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: _startGame,
                                icon: const Icon(Icons.rocket_launch),
                                label: Text(
                                  _gameOver || _won
                                      ? 'VOLVER A JUGAR'
                                      : 'INICIAR CARRERA',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '🚀 TURBO RACING',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('⭐ Puntos: $_score'),
              Text('❤️ Vidas: $_lives'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlButton(
                icon: Icons.arrow_left,
                label: 'IZQUIERDA',
                onPressed: () => _movePlayer(-1),
              ),
              _controlButton(
                icon: Icons.arrow_right,
                label: 'DERECHA',
                onPressed: () => _movePlayer(1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _activateBlackHole,
              icon: const Icon(Icons.blur_circular),
              label: const Text(
                'ENTRAR AL AGUJERO NEGRO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF164E63),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
      ),
    );
  }
}

class SpacePainter extends CustomPainter {
  final double progress;
  final int level;

  SpacePainter({
    required this.progress,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75);

    for (int i = 0; i < 65; i++) {
      final x = (i * 83.0 + progress * size.width * 2) % size.width;
      final y = (i * 47.0 + progress * size.height * 3) % size.height;

      canvas.drawCircle(
        Offset(x, y),
        i % 5 == 0 ? 2 : 1,
        starPaint,
      );
    }

    final trackPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 7; i++) {
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * (0.25 + i * 0.16),
        height: size.height * (0.12 + i * 0.14),
      );

      canvas.drawOval(rect, trackPaint);
    }

    final holePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Colors.deepPurpleAccent,
          Colors.black,
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.35),
          radius: 55,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.35),
      55,
      holePaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'SECTOR $level',
        style: TextStyle(
          color: Colors.cyanAccent.withValues(alpha: 0.3),
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        size.height * 0.78,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant SpacePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.level != level;
  }
}
