import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:void_of_course/l10n/app_localizations.dart';

class VersionCheckService {
  static const String _tag = 'VersionCheckService';

  /// iOS 기기에서 Firebase Remote Config를 활용해 앱 업데이트 여부를 확인하고 팝업을 띄웁니다.
  static Future<void> checkForUpdates(BuildContext context) async {
    if (!Platform.isIOS) return;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // 원격 구성 fetch/timeout 설정
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // 기본 fallback 값 지정
      await remoteConfig.setDefaults(<String, dynamic>{
        'ios_min_version': '1.0.0',
        'ios_latest_version': '1.0.0',
        'ios_update_url': 'https://apps.apple.com/app/id6450638547',
      });

      // 서버에서 설정값 로드 및 활성화
      await remoteConfig.fetchAndActivate();

      final minVersion = remoteConfig.getString('ios_min_version');
      final latestVersion = remoteConfig.getString('ios_latest_version');
      final updateUrl = remoteConfig.getString('ios_update_url');

      // 현재 설치된 앱의 로컬 버전 획득
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      developer.log(
        'iOS Version check: current=$currentVersion, min=$minVersion, latest=$latestVersion',
        name: _tag,
      );

      if (_isVersionLessThan(currentVersion, minVersion)) {
        // 필수 업데이트 필요 (강제 업데이트)
        if (context.mounted) {
          _showUpdateDialog(context, updateUrl, isForce: true);
        }
      } else if (_isVersionLessThan(currentVersion, latestVersion)) {
        // 권장 업데이트 필요 (선택 업데이트)
        if (context.mounted) {
          _showUpdateDialog(context, updateUrl, isForce: false);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error checking for iOS update: $e', name: _tag);
      }
    }
  }

  /// 시맨틱 버전을 비교하여 current < target 인 경우 true를 반환합니다.
  static bool _isVersionLessThan(String current, String target) {
    try {
      List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> targetParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int targetPart = i < targetParts.length ? targetParts[i] : 0;
        if (currentPart < targetPart) return true;
        if (currentPart > targetPart) return false;
      }
    } catch (e) {
      developer.log('Error parsing version strings: current=$current, target=$target: $e', name: _tag);
    }
    return false;
  }

  /// 테마에 부합하는 아름다운 모달 팝업 다이얼로그를 생성합니다.
  static void _showUpdateDialog(BuildContext context, String updateUrl, {required bool isForce}) {
    showDialog(
      context: context,
      barrierDismissible: !isForce, // 강제 업데이트는 바깥 터치로 닫을 수 없음
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context)!;

        // 디자인 테마 색상 설정
        final Color backgroundColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
        final Color textColor = isDark ? const Color(0xFFF0EDE5) : const Color(0xFF1A1A2E);
        final Color secondaryTextColor = isDark ? const Color(0xFFB8B5AD) : const Color(0xFF3A3A4A);
        final Color primaryButtonColor = const Color(0xFFD4AF37); // 골드 포인트 컬러
        final Color buttonTextColor = isDark ? const Color(0xFF0F0F1A) : Colors.white;

        return PopScope(
          canPop: !isForce, // 강제 업데이트는 제스처나 백 버튼으로 닫을 수 없음
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 아이콘 영역
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryButtonColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      color: primaryButtonColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 제목
                  Text(
                    isForce ? l10n.updateRequiredTitle : l10n.updateRecommendedTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // 본문
                  Text(
                    isForce ? l10n.updateRequiredBody : l10n.updateRecommendedBody,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // 버튼 영역
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final Uri url = Uri.parse(updateUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.msgAppNotFound),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryButtonColor,
                          foregroundColor: buttonTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.updateNow,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isForce) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: secondaryTextColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            l10n.updateLater,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
