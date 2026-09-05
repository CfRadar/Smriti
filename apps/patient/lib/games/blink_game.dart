import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class BlinkGameScreen extends StatefulWidget {
  const BlinkGameScreen({super.key});

  @override
  State<BlinkGameScreen> createState() => _BlinkGameScreenState();
}

class _BlinkGameScreenState extends State<BlinkGameScreen> {
  int score = 0;
  int targetIndex = -1;
  int timeLeft = 20;
  Timer? gameTimer;
  Timer? targetTimer;
  bool isPlaying = false;

  void startGame() {
    setState(() {
      score = 0;
      timeLeft = 20;
      isPlaying = true;
    });

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 1) {
          timeLeft--;
        } else {
          endGame();
        }
      });
    });

    spawnTarget();
  }

  void spawnTarget() {
    if (!isPlaying) return;
    setState(() {
      targetIndex = Random().nextInt(9);
    });
    targetTimer?.cancel();
    targetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (isPlaying) spawnTarget();
    });
  }

  void handleTap(int index) {
    if (!isPlaying) return;
    if (index == targetIndex) {
      setState(() {
        score += 10;
      });
      spawnTarget();
    }
  }

  void endGame() {
    gameTimer?.cancel();
    targetTimer?.cancel();
    setState(() {
      isPlaying = false;
      targetIndex = -1;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    targetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F3),
      appBar: AppBar(
        title: const Text('Smriti — Attention Game', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF315B3E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Score: $score', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF315B3E))),
                Text('Time: ${timeLeft}s', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  bool isTarget = index == targetIndex;
                  return GestureDetector(
                    onTap: () => handleTap(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isTarget ? const Color(0xFFB56A35) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Center(
                        child: isTarget
                            ? const Icon(Icons.touch_app, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF315B3E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isPlaying ? null : startGame,
                child: Text(
                  isPlaying ? 'Tap Orange Target!' : 'Start Game',
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}