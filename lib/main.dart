import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const BalanceApp());
}

class BalanceApp extends StatelessWidget {
  const BalanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BalanceScreen(),
    );
  }
}

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({Key? key}) : super(key: key);

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  StreamSubscription? _accelerometerSubscription;

  double x = 0.0;
  double y = 0.0;

  bool isBalanced = false;
  int secondsBalanced = 0;
  final int targetSeconds = 5;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
          setState(() {
            x = event.x;
            y = event.y;

            const double tolerance = 0.5;

            if (x.abs() < tolerance && y.abs() < tolerance) {
              if (!isBalanced) {
                isBalanced = true;
                _startTimer();
              }
            } else {
              if (isBalanced) {
                isBalanced = false;
                _stopTimer();
                _vibrate();
              }
            }
          });
        });
  }

  void _startTimer() {
    _timer?.cancel();
    secondsBalanced = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secondsBalanced++;
        if (secondsBalanced >= targetSeconds) {
          timer.cancel();
          _showSuccessDialog();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    secondsBalanced = 0;
  }

  Future<void> _vibrate() async {
    HapticFeedback.mediumImpact();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Complimenti!"),
        content: const Text("Hai tenuto il telefono in bolla per 5 secondi!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                secondsBalanced = 0;
              });
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isBalanced ? Colors.green[200] : Colors.red[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Mantieni il telefono in bolla",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Text(
              "Secondi: $secondsBalanced / $targetSeconds",
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.screen_rotation,
              size: 80,
              color: isBalanced ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

