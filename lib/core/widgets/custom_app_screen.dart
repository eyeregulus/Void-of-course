// 플러터의 기본 디자인 라이브러리를 가져와요. 화면에 보이는 것들을 만들 때 필요해요.
import 'package:flutter/material.dart';

// 앱의 화면을 만들 때 공통적으로 사용되는 틀을 제공하는 위젯이에요. (예: 앱 바, 배경 등)
class CustomAppScreen extends StatelessWidget {
  final String title; // 화면의 제목을 저장하는 상자예요.
  final IconData icon; // 화면 제목 옆에 보여줄 아이콘을 저장하는 상자예요.
  final Widget body; // 화면의 주요 내용을 저장하는 상자예요. (다른 위젯이 들어갈 수 있어요)
  final Color? iconColor; // 아이콘의 색깔을 저장하는 상자예요. 색깔이 없을 수도 있어서 물음표(?)가 붙어있어요.

  // 이 위젯을 만들 때 필요한 것들을 꼭 받아야 해요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const CustomAppScreen({
    super.key,
    required this.title, // 제목은 꼭 필요해요.
    required this.icon, // 아이콘도 꼭 필요해요.
    required this.body, // 몸통(내용)도 꼭 필요해요.
    this.iconColor, // 아이콘 색깔은 선택 사항이에요.
  });

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // 화면의 전체적인 구조를 짜요. Scaffold는 기본적인 앱 디자인을 제공하는 위젯이에요.
    return Scaffold(
      // 화면 상단의 앱 바(제목 바)예요. AppBar는 앱의 맨 위에 있는 막대기예요.
      appBar: AppBar(
        // 제목 부분에 아이콘과 글자를 가로로 나란히 놓아요. Row는 위젯들을 가로로 나란히 놓을 때 사용해요.
        title: Row(
          children: [
            // 아이콘을 보여줘요. Icon은 그림 아이콘을 보여줘요.
            Icon(
              icon, // 위에서 받은 아이콘을 사용해요.
              // 아이콘 색깔을 정해요. 만약 iconColor가 없으면(null이면) 앱 테마의 기본 색깔을 사용해요.
              color: iconColor ?? Theme.of(context).colorScheme.primary,
              size: 24, // 아이콘 크기는 24
            ),
            const SizedBox(width: 8), // 아이콘과 글자 사이에 작은 공간을 만들어요. SizedBox는 빈 공간을 만들어요.
            // 제목을 보여줘요. Text는 글자를 보여줘요.
            Text(
              title, // 위에서 받은 제목을 사용해요.
              style: TextStyle(
                // 현재 테마가 다크 모드인지에 따라 글자색을 정해요.
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white // 어두운 모드면 하얀색 글자
                    : Colors.black87, // 아니면 거의 검은색 글자
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // 앱 바의 배경색을 테마에 맞게 설정해요.
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // 앱 바의 글자/아이콘 색을 테마에 맞게 설정해요.
        elevation: Theme.of(context).appBarTheme.elevation, // 앱 바의 그림자 높이를 테마에 맞게 설정해요. (높을수록 그림자가 진해져요)
      ),
      // 화면의 주요 내용이 들어가는 부분이에요. body는 Scaffold의 몸통 부분이에요.
      body: Container(
        width: double.infinity, // 너비를 화면 끝까지 채워요. (double.infinity는 무한대라는 뜻이에요)
        height: double.infinity, // 높이를 화면 끝까지 채워요.
        // 화면 배경을 예쁘게 꾸며줘요. decoration은 꾸미는 도구예요.
        decoration: BoxDecoration(
          // 배경색을 위에서 아래로 변하게 만들어요. LinearGradient는 색깔이 자연스럽게 변하는 효과를 줘요.
          gradient: LinearGradient(
            begin: Alignment.topCenter, // 위쪽 가운데에서 시작해서
            end: Alignment.bottomCenter, // 아래쪽 가운데로 색이 변해요.
            colors: [
              Theme.of(context).colorScheme.surface, // 앱 테마의 배경색 (예: 하얀색 또는 어두운 회색)
              Theme.of(context).colorScheme.surface, // 앱 테마의 표면색 (예: 하얀색 또는 더 어두운 회색)
            ],
          ),
        ),
        // 휴대폰의 상태표시줄 같은 시스템 UI를 피해서 내용을 보여줘요. SafeArea는 화면의 안전한 영역에 위젯을 배치해요.
        child: SafeArea(
          child: body, // 위에서 받은 body 위젯을 여기에 그대로 보여줘요.
        ),
      ),
    );
  }
}