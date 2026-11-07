import 'dart:async';
import 'package:flutter/material.dart';
import 'main_navigation_page.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  int _durasiDetik = 10; // Tantangan Live Tweak 2: Durasi 10 Detik
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _mulaiHitungMundur();
  }

  void _mulaiHitungMundur() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_durasiDetik > 1) {
        setState(() {
          _durasiDetik--;
        });
      } else {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  size: 72,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SmartKasir',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Aplikasi Kasir Point of Sale Digital',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 36),
              const CircularProgressIndicator(color: Colors.amber),
              const SizedBox(height: 14),
              Text(
                'Menyiapkan sistem SmartKasir ($_durasiDetik detik)...',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
