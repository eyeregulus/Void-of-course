import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.
import 'package:void_of_course/themes.dart';

// 설정 화면에 들어가는 한 줄짜리 카드를 만드는 위젯이에요.
class SettingCard extends StatelessWidget {
  final IconData icon; // 카드 왼쪽에 보여줄 아이콘 모양
  final String title; // 카드의 제목
  final String? subtitle; // 카드 부제 (선택)
  final Widget trailing; // 카드 오른쪽에 보여줄 위젯 (스위치, 버튼 등)
  final Color iconColor; // 아이콘의 색깔
  final VoidCallback? onTap; // 카드 전체를 눌렀을 때 실행할 동작

  // 카드를 만들 때 필요한 정보들을 꼭 받아야 해요.
  const SettingCard({
    super.key,
    required this.icon, // 아이콘은 꼭 필요해요.
    required this.title, // 제목도 꼭 필요해요.
    this.subtitle,
    required this.trailing, // 오른쪽 위젯도 꼭 필요해요.
    required this.iconColor, // 아이콘 색깔도 꼭 필요해요.
    this.onTap, // 카드 전체 탭 동작 (선택사항)
  });

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // 카드를 담을 상자를 만들어요.
    return Container(
      // 위아래로 8만큼의 여백을 줘서 다른 카드와 간격을 만들어요.
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      // 상자를 예쁘게 꾸며줘요.
      decoration: BoxDecoration(
        // 배경색을 두 가지 색이 섞이도록 만들어요.
        gradient: LinearGradient(
          begin: Alignment.topLeft, // 왼쪽 위에서 시작해서
          end: Alignment.bottomRight, // 오른쪽 아래로 색이 변해요.
          colors: [
            theme.cardColor, // 앱의 기본 카드 색상을 사용해요.
            theme.cardColor.withValues(alpha: 0.8), // 기본 카드 색상을 살짝 투명하게 만들어요.
          ],
        ),
        // 모서리를 둥글게 깎아줘요.
        borderRadius: BorderRadius.circular(20),
        // 그림자를 만들어서 입체적으로 보이게 해요.
        boxShadow: [
          Themes.cardShadow(isDark),
        ],
      ),
      // 잉크 효과를 위해 Material로 감싸요.
      child: Material(
        color: Colors.transparent, // 배경은 투명하게 (Container의 gradient가 보이도록)
        child: InkWell(
          onTap: onTap, // 카드 전체 영역을 눌렀을 때 실행할 동작
          borderRadius: BorderRadius.circular(20), // 물결 효과도 둥근 모서리에 맞춰요.
          child: Padding(
            padding: const EdgeInsets.all(20), // 내용물 주변에 모든 방향으로 20만큼 여백을 줘요.
            child: Row(
              children: [
                // 왼쪽에 동그란 배경을 가진 아이콘을 보여줘요.
                CircleAvatar(
                  radius: 25, // 동그라미의 반지름은 25
                  backgroundColor: iconColor.withValues(alpha: 0.1), // 아이콘 색깔을 아주 연하게 해서 배경색으로 써요.
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ), // 아이콘을 보여주고, 정해진 색깔과 크기로 설정해요.
                ),
                const SizedBox(width: 16),
                // 아이콘 오른쪽에 제목을 보여줘요.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.textTheme.titleLarge?.color,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
