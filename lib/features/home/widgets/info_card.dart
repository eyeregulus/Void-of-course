
import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.

// 정보를 보여주는 예쁜 카드를 만드는 위젯이에요.
class InfoCard extends StatelessWidget {
  final IconData icon; // 카드 왼쪽에 보여줄 아이콘 모양
  final String title; // 카드의 제목
  final String subtitle; // 제목 아래에 들어갈 내용
  final Color iconColor; // 아이콘의 색깔

  // 카드를 만들 때 필요한 정보들을 꼭 받아야 해요.
  const InfoCard({
    super.key,
    required this.icon, // 아이콘은 꼭 필요해요.
    required this.title, // 제목도 꼭 필요해요.
    required this.subtitle, // 부제목도 꼭 필요해요.
    required this.iconColor, // 아이콘 색깔도 꼭 필요해요.
  });

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 카드를 담을 상자를 만들어요.
    return Container(
      // 상자를 예쁘게 꾸며줘요.
      decoration: BoxDecoration(
        // 배경색을 두 가지 색이 섞이도록 만들어요.
        gradient: LinearGradient(
          begin: Alignment.topLeft, // 왼쪽 위에서 시작해서
          end: Alignment.bottomRight, // 오른쪽 아래로 색이 변해요.
          colors: [
            Theme.of(context).cardColor, // 앱의 기본 카드 색상을 사용해요.
            Theme.of(context).cardColor.withValues(alpha: 0.8), // 기본 카드 색상을 살짝 투명하게 만들어요.
          ],
        ),
        // 모서리를 둥글게 깎아줘요.
        borderRadius: BorderRadius.circular(20),
        // 그림자를 만들어서 입체적으로 보이게 해요.
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1), // 앱의 기본 그림자 색상을 아주 살짝 보이게 해요.
            blurRadius: 10, // 그림자를 부드럽게 퍼지게 해요.
            offset: const Offset(0, 5), // 그림자를 아래쪽으로 5만큼 이동시켜요.
          ),
        ],
      ),
      // 카드 안에 들어갈 내용(아이콘, 글자 등)을 설정해요.
      child: ListTile(
        contentPadding: const EdgeInsets.all(10), // 내용물 주변에 모든 방향으로 10만큼 여백을 줘요.
        // 왼쪽에 동그란 배경을 가진 아이콘을 보여줘요.
        leading: CircleAvatar(
          radius: 25, // 동그라미의 반지름은 25
          backgroundColor: iconColor.withValues(alpha: 0.1), // 아이콘 색깔을 아주 연하게 해서 배경색으로 써요.
          child: Icon(icon, color: iconColor, size: 28), // 아이콘을 보여주고, 정해진 색깔과 크기로 설정해요.
        ),
        // 아이콘 오른쪽에 제목을 보여줘요.
        title: Padding(
          padding: const EdgeInsets.only(bottom: 10.0), // 제목 아래에 10만큼 여백을 줘요.
          child: Text(
            title, // '우리는 누구인가요?' 같은 제목을 보여줘요.
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color, // 앱의 큰 제목 글자 색상을 사용해요.
              fontSize: 20, // 글자 크기는 20
              fontWeight: FontWeight.w600, // 글자를 살짝 두껍게 만들어요.
            ),
          ),
        ),
        // 제목 아래에 부가적인 내용을 보여줘요.
        subtitle: Text(
          subtitle, // '스튜디오 사안의 사명...' 같은 내용을 보여줘요.
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color, // 앱의 보통 글자 색상을 사용해요.
            fontSize: 14, // 글자 크기는 14
            height: 1.4, // 줄 간격을 1.4배로 넓혀서 읽기 편하게 해요.
          ),
        ),
      ),
    );
  }
}
