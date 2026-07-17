import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckService {
  static const String _tag = 'VersionCheckService';

  /// 업데이트 필요 상태를 나타내는 글로벌 상태 알림이
  static final ValueNotifier<bool> hasUpdate = ValueNotifier<bool>(false);
  
  /// 원격지 최신 버전 정보 저장
  static String latestVersionStr = '';
  
  /// 업데이트 링크 저장
  static String updateUrlStr = '';

  /// Firebase Remote Config를 활용해 앱 업데이트 여부를 확인하고 글로벌 상태를 갱신합니다.
  static Future<void> checkForUpdates(BuildContext context) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;

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
        'android_min_version': '1.0.0',
        'android_latest_version': '1.0.0',
        'android_update_url': 'https://play.google.com/store/apps/details?id=dev.lioluna.voidofcourse',
      });

      // 서버에서 설정값 로드 및 활성화
      await remoteConfig.fetchAndActivate();

      final platformPrefix = Platform.isIOS ? 'ios_' : 'android_';
      final minVersion = remoteConfig.getString('${platformPrefix}min_version');
      final latestVersion = remoteConfig.getString('${platformPrefix}latest_version');
      final updateUrl = remoteConfig.getString('${platformPrefix}update_url');

      // 현재 설치된 앱의 로컬 버전 획득
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      developer.log(
        '${Platform.isIOS ? "iOS" : "Android"} Version check: current=$currentVersion, min=$minVersion, latest=$latestVersion',
        name: _tag,
      );

      // 최소 버전 또는 최신 버전보다 낮은지 판단 (비강제적이므로 두 버전 조건 모두 업데이트 권장에 해당)
      final bool needsUpdate = _isVersionLessThan(currentVersion, latestVersion) || 
                               _isVersionLessThan(currentVersion, minVersion);

      latestVersionStr = latestVersion;
      updateUrlStr = updateUrl;
      hasUpdate.value = needsUpdate;

    } catch (e) {
      if (kDebugMode) {
        developer.log('Error checking for update: $e', name: _tag);
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
}
