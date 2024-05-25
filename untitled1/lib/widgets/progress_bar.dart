import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 남은 일수를 계산하는 함수
int calculateRemainingDays(String expiryDate) {
  final dateFormat = DateFormat('yyyy.MM.dd');
  try {
    final endDate = dateFormat.parse(expiryDate);
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  } on FormatException {
    return -1;
  }
}

// 프로그레스 바의 값을 계산하는 함수
double calculateProgress(int remainingDays) {
  // 예시로 365일 기준으로 계산
  return remainingDays < 0 ? 1.0 : (365 - remainingDays) / 365;
}

// 프로그레스 바 위젯
class ExpiryProgressBar extends StatelessWidget {
  final String expiryDate;

  ExpiryProgressBar({Key? key, required this.expiryDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int remainingDays = calculateRemainingDays(expiryDate);
    final double progress = calculateProgress(remainingDays);
    final Color barColor = remainingDays >= 0 ? Color(0xFFB68EEF) : Colors.red;

    return  SizedBox(
      child: Container(
        width: double.infinity, // 프로그레스 바를 컨테이너의 전체 너비로 설정
        height: 4, // 프로그레스 바의 높이 설정
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          // 모서리를 둥글게 처리
          child: LinearProgressIndicator(
            value: progress,
            // 현재 진행 상태를 나타내는 값 (0.0 ~ 1.0)
            backgroundColor: Color(0x226200EE),
            // 배경색 설정
            valueColor: AlwaysStoppedAnimation<Color>(
                remainingDays >= 0 ? Color(0xFFB68EEF) : Colors.red), // 진행색 설정
          ),
        ),
      ),
    );
  }
}
