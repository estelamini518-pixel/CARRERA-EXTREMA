import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TurboRacingApp());
}

class TurboRacingApp extends StatelessWidget {
  const TurboRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turbo Racing: Carrera al Vacío',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RaceScreen(),
    );
  }
}

class RaceScreen extends StatefulWidget {
  const RaceScreen({super.key});

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _shipX = 0.22;
  double _shipY = 0.52;
  double _shadowX = 0.0;
  double _blackHoleX = 0.85;
  double _time = 0;
  double _obstacleX = 1.15;
  double _obstacleY = 0.3;
  int _level = 1;
  int _score = 0;
  int _lives = 3;
  bool _running = false;
  bool _gameOver = false;
  bool _won = false;
  bool _holeUsed = false;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    if (!_running || _gameOver || _won) {
      _last = elapsed;
      return;
    }
    final dt = (_last == Duration.zero
            ? 0.016
            : (elapsed - _last).inMicroseconds / 1000000)
        .clamp(0.0, 0.05);
    _last = elapsed;
    setState(() {
      _time += dt;
      final speed = 0.15 + _level * 0.012;
      _obstacleX -= speed * dt;
      _shadowX += (0.045 + _level * 0.004) * dt;
      _blackHoleX -= speed * 0.42 * dt;
      if (_obstacleX < -0.08) {
        _obstacleX = 1.1;
        _obstacleY = 0.15 + _random.nextDouble() * 0.68;
        _score += 10;
      }
      if (_blackHoleX < -0.12) {
        _blackHoleX = 1.15 + _random.nextDouble() * 0.55;
        _holeUsed = false;
      }
      if (_shadowX > 0.96) {
        _lives--;
        _shadowX = 0.05;
        if (_lives <= 0) {
          _gameOver = true;
          _running = false;
        }
      }
      final dx = (_obstacleX - _shipX).abs();
      final dy = (_obstacleY - _shipY).abs();
      if (dx < 0.055 && dy < 0.13) {
        _score += 5;
        _obstacleX = -0.2;
      }
    });
  }

  void _start() => setState(() {
        _running = true;
        _gameOver = false;
        _won = false;
        _last = Duration.zero;
      });

  void _move(double dx, double dy) {
    if (!_running) return;
    setState(() {
      _shipX = (_shipX + dx).clamp(0.08, 0.83);
      _shipY = (_shipY + dy).clamp(0.12, 0.88);
      if ((_shipX - _blackHoleX).abs() < 0.09 &&
          (_shipY - 0.5).abs() < 0.22 &&
          !_holeUsed) {
        _holeUsed = true;
        _score += 100;
        _level++;
        _shadowX = 0.03;
        _blackHoleX = 1.2;
        _obstacleX = 1.05;
        if (_level > 5) {
          _won = true;
          _running = false;
        }
      }
    });
  }

  void _restart() {
    setState(() {
      _shipX = 0.22;
      _shipY = 0.52;
      _shadowX = 0;
      _blackHoleX = 0.85;
      _obstacleX = 1.15;
      _level = 1;
      _score = 0;
      _lives = 3;
      _running = false;
      _gameOver = false;
      _won = false;
      _holeUsed = false;
      _time = 0;
      _last = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: SpacePainter(
                    time: _time,
                    shipX: _shipX,
                    shipY: _shipY,
                    shadowX: _shadowX,
                    obstacleX: _obstacleX,
                    obstacleY: _obstacleY,
                    blackHoleX: _blackHoleX,
                    level: _level,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 10,
                child: _hud('NIVEL $_level', Icons.rocket_launch),
              ),
              Positioned(
                right: 14,
                top: 10,
                child: _hud('PUNTOS $_score   ♥ $_lives', Icons.bolt),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Row(
                  children: [
                    _control('◀', () => _move(-0.045, 0)),
                    const SizedBox(width: 8),
                    _control('▲', () => _move(0, -0.06)),
                    const SizedBox(width: 8),
                    _control('▼', () => _move(0, 0.06)),
                    const SizedBox(width: 8),
                    _control('▶', () => _move(0.045, 0)),
                  ],
                ),
              ),
              if (!_running && !_gameOver && !_won)
                _overlay(
                  'CARRERA AL VACÍO',
                  'Esquiva meteoritos y alcanza el agujero negro cuando la sombra se acerque.',
                  'INICIAR CARRERA',
                  _start,
                ),
              if (_gameOver)
                _overlay(
                  '¡TE ALCANZÓ LA SOMBRA!',
                  'Puntuación: $_score',
                  'VOLVER A INTENTAR',
                  _restart,
                ),
              if (_won)
                _overlay(
                  '¡MISIÓN COMPLETADA!',
                  'Llegaste al nivel $_level • Puntuación: $_score',
                  'JUGAR DE NUEVO',
                  _restart,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _hud(String text, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 18),
            const SizedBox(width: 7),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _control(String label, VoidCallback onTap) => SizedBox(
        width: 48,
        height: 44,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: const Color(0xCC09233A),
            foregroundColor: const Color(0xFF00E5FF),
            side: const BorderSide(color: Color(0xFF00E5FF)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 22)),
        ),
      );

  Widget _overlay(
    String title,
    String subtitle,
    String button,
    VoidCallback action,
  ) =>
      Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.68),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                color: const Color(0xFF07182A),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rocket_launch,
                          size: 48, color: Color(0xFF00E5FF)),
                      const SizedBox(height: 10),
                      Text(title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Text(subtitle, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: action,
                        child: Text(button),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class SpacePainter extends CustomPainter {
  SpacePainter({
    required this.time,
    required this.shipX,
    required this.shipY,
    required this.shadowX,
    required this.obstacleX,
    required this.obstacleY,
    required this.blackHoleX,
    required this.level,
  });

  final double time;
  final double shipX;
  final double shipY;
  final double shadowX;
  final double obstacleX;
  final double obstacleY;
  final double blackHoleX;
  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = [
      const Color(0xFF020617),
      const Color(0xFF160B2D),
      const Color(0xFF031F2E),
      const Color(0xFF25100A),
      const Color(0xFF071A35),
    ];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [colors[(level - 1) % colors.length], const Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );

    final stars = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (int i = 0; i < 95; i++) {
      final x = ((i * 73.0 + time * (18 + i % 5) * 3) % size.width);
      final y = ((i * 47.0) % size.height);
      canvas.drawCircle(Offset(x, y), i % 7 == 0 ? 1.8 : 0.8, stars);
    }

    final horizon = size.height * 0.78;
    final grid = Paint()
      ..color = const Color(0xFF00B8D4).withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (int i = 0; i < 12; i++) {
      final y = horizon + i * i * 1.8;
      if (y < size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }
    for (int i = -8; i <= 8; i++) {
      canvas.drawLine(
        Offset(size.width / 2 + i * 10, horizon),
        Offset(size.width / 2 + i * size.width / 8, size.height),
        grid,
      );
    }

    // Agujero negro con disco de acreción.
    final hole = Offset(blackHoleX * size.width, size.height * 0.5);
    final radius = size.height * 0.105;
    canvas.drawCircle(
      hole,
      radius * 1.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF8A2BE2).withValues(alpha: 0.05),
            const Color(0xFF00E5FF).withValues(alpha: 0.65),
            const Color(0xFF8A2BE2).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: hole, radius: radius * 1.6)),
    );
    canvas.save();
    canvas.translate(hole.dx, hole.dy);
    canvas.rotate(-0.15);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 3.0, height: radius),
      Paint()
        ..color = const Color(0xFFFF8C42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 2.4, height: radius * 0.65),
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(Offset.zero, radius * 0.62, Paint()..color = Colors.black);
    canvas.restore();

    // Meteorito.
    final rock = Offset(obstacleX * size.width, obstacleY * size.height);
    canvas.drawCircle(
      rock,
      size.height * 0.035,
      Paint()..color = const Color(0xFFFF7043),
    );
    canvas.drawCircle(
      rock.translate(-4, -3),
      size.height * 0.012,
      Paint()..color = const Color(0xFFFFCC80),
    );

    // Sombra que persigue la nave.
    final shadow = Offset(shadowX * size.width, size.height * 0.5);
    canvas.drawCircle(
      shadow,
      size.height * 0.11,
      Paint()..color = const Color(0xFF8B0000).withValues(alpha: 0.18),
    );
    final shadowPaint = Paint()
      ..color = const Color(0xFFB71C1C).withValues(alpha: 0.8);
    final path = Path()
      ..moveTo(shadow.dx, shadow.dy - size.height * 0.08)
      ..lineTo(shadow.dx - size.height * 0.07, shadow.dy + size.height * 0.07)
      ..lineTo(shadow.dx + size.height * 0.07, shadow.dy + size.height * 0.07)
      ..close();
    canvas.drawPath(path, shadowPaint);

    // Nave espacial: fuselaje, alas, cabina y propulsor.
    final ship = Offset(shipX * size.width, shipY * size.height);
    final scale = size.height / 650;
    final flame = Path()
      ..moveTo(ship.dx - 25 * scale, ship.dy)
      ..lineTo(ship.dx - 43 * scale, ship.dy - 8 * scale)
      ..lineTo(ship.dx - 39 * scale, ship.dy)
      ..lineTo(ship.dx - 43 * scale, ship.dy + 8 * scale)
      ..close();
    canvas.drawPath(
      flame,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.yellow, Colors.deepOrange, Colors.transparent],
        ).createShader(Rect.fromCenter(
          center: ship.translate(-34 * scale, 0),
          width: 20 * scale,
          height: 18 * scale,
        )),
    );

    final body = Path()
      ..moveTo(ship.dx + 29 * scale, ship.dy)
      ..lineTo(ship.dx - 18 * scale, ship.dy - 13 * scale)
      ..lineTo(ship.dx - 11 * scale, ship.dy)
      ..lineTo(ship.dx - 18 * scale, ship.dy + 13 * scale)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFF00B8D4), Color(0xFF145DA0)],
        ).createShader(Rect.fromCenter(
          center: ship,
          width: 50 * scale,
          height: 30 * scale,
        )),
    );
    final wings = Path()
      ..moveTo(ship.dx - 6 * scale, ship.dy - 5 * scale)
      ..lineTo(ship.dx - 23 * scale, ship.dy - 22 * scale)
      ..lineTo(ship.dx - 19 * scale, ship.dy - 3 * scale)
      ..lineTo(ship.dx - 6 * scale, ship.dy + 5 * scale)
      ..lineTo(ship.dx - 23 * scale, ship.dy + 22 * scale)
      ..lineTo(ship.dx - 19 * scale, ship.dy + 3 * scale)
      ..close();
    canvas.drawPath(wings, Paint()..color = const Color(0xFF90CAF9));
    canvas.drawOval(
      Rect.fromCenter(
        center: ship.translate(5 * scale, 0),
        width: 12 * scale,
        height: 7 * scale,
      ),
      Paint()..color = const Color(0xFF8EFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant SpacePainter oldDelegate) => true;
}
