import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class RotatingTextView extends StatefulWidget {
  @override
  _RotatingTextViewState createState() => _RotatingTextViewState();
}

class _RotatingTextViewState extends State<RotatingTextView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<double> angles = [0.0, 0.0, 0.0, 0.0]; // 各円の回転角度
  List<int> currentIndices = [0, 0, 0, 0]; // 各円の現在のタップインデックス
  List<Set<int>> disabledIndices = [Set(), Set(), Set(), Set()]; // 各円のタップ済みインデックス
  int activeCircle = 0; // 現在アクティブな円
  List<String> currentStrings = [
    "妙法蓮華経如来寿量品第十六",
    "自我得仏来所経諸劫数無量百千万",
    "億載阿僧祇常説法教化無数億衆生",
    "四季折々花鳥風月",
  ]; // 現在表示中の文字列
  final List<String> allStrings = [
    "妙法蓮華経如来寿量品第十六",
    "自我得仏来所経諸劫数無量百千万",
    "億載阿僧祇常説法教化無数億衆生",
    "四季折々花鳥風月",
  ]; // 全ての文字列

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        for (int i = 0; i < angles.length; i++) {
          angles[i] += (i % 2 == 0 ? -1.0 : 1.0);
          if (angles[i].abs() >= 360) angles[i] = 0.0;
        }
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void handleTap(int circleIndex, int charIndex, String char) async {
    if (circleIndex != activeCircle) return; // アクティブでない円はタップ無効
    final correctChar = currentStrings[circleIndex][currentIndices[circleIndex]];
    if (char == correctChar) {
      setState(() {
        disabledIndices[circleIndex].add(charIndex);
        currentIndices[circleIndex]++;
        if (currentIndices[circleIndex] == currentStrings[circleIndex].length) {
          moveStringsForward(); // 次の文字列を移動
        }
      });
      await _audioPlayer.play(AssetSource('assets/太鼓.mp3'));
    }
  }

  void moveStringsForward() {
    setState(() {
      // 文字列を内側から外側へ移動
      for (int i = currentStrings.length - 1; i > 0; i--) {
        currentStrings[i] = currentStrings[i - 1];
        currentIndices[i] = currentIndices[i - 1];
        disabledIndices[i] = Set.from(disabledIndices[i - 1]);
      }

      // 外側の円に新しい文字列を設定
      activeCircle = 0;
      currentStrings[0] = allStrings[(allStrings.indexOf(currentStrings[0]) + 1) % allStrings.length];
      currentIndices[0] = 0;
      disabledIndices[0].clear();
    });
  }

  Widget createCircle(
      List<String> texts, double angle, double radius, int circleIndex) {
    return Stack(
      children: texts.asMap().entries.map((entry) {
        int index = entry.key;
        String char = entry.value;
        double angleOffset = index * (360.0 / texts.length);
        double xPosition = cos((angle + angleOffset) * pi / 180) * radius +
            MediaQuery.of(context).size.width / 2 - 20; // 中央調整
        double yPosition = sin((angle + angleOffset) * pi / 180) * radius +
            MediaQuery.of(context).size.height / 2 - 20; // 中央調整

        return Positioned(
          left: xPosition,
          top: yPosition,
          child: GestureDetector(
            onTap: disabledIndices[circleIndex].contains(index)
                ? null
                : () => handleTap(circleIndex, index, char),
            child: Text(
              char,
              style: TextStyle(
                fontSize: 20 - circleIndex * 2.0,
                color: disabledIndices[circleIndex].contains(index)
                    ? Colors.grey
                    : (circleIndex == activeCircle ? Colors.black : Colors.grey),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < currentStrings.length; i++)
            createCircle(
              currentStrings[i].split(''),
              angles[i],
              150.0 - i * 30, // 円の半径を小さくして内側に配置
              i,
            ),
        ],
      ),
    );
  }
}