import 'package:flutter/material.dart';

void showPremiumInfoCarousel(BuildContext context, bool isKo) {
  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          height: 500,
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  children: [
                    _buildCarouselPage(
                      imagePath: 'assets/app_Image/Void Widget.jpg',
                      title: isKo ? '보이드 홈 위젯' : 'Void Home Widget',
                      desc: isKo
                          ? '바탕화면에서 언제든지\n다음 보이드 기간을 확인하고 미리 대비하세요.'
                          : 'Check the next Void of Course period right from your home screen.',
                    ),
                    _buildCarouselPage(
                      imagePath: 'assets/app_Image/Google Calender.png',
                      title: isKo ? '구글 캘린더 동기화' : 'Google Calendar Sync',
                      desc: isKo
                          ? '번거로운 일정 등록 없이, 구글 캘린더에\n보이드 기간을 한눈에 표시해 드립니다.'
                          : 'Seamlessly sync and view all Void periods directly in your Google Calendar.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swipe, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      isKo ? '좌우로 스와이프하여 넘겨보세요' : 'Swipe left or right',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isKo ? '닫기' : 'Close'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildCarouselPage({
  required String imagePath,
  required String title,
  required String desc,
}) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}
