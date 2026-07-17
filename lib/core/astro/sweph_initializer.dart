import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';

class IsolateSafeAssetLoader implements AssetLoader {
  final String? epheFilesPath;
  const IsolateSafeAssetLoader({this.epheFilesPath});

  @override
  Future<Uint8List> load(String assetPath) async {
    // 디스크에 이미 에셋 파일이 존재하는 경우, 플랫폼 채널을 통한 로드를 건너뜁니다.
    // 이는 배경 Isolate가 에셋 채널 통신을 대기하다가 멈추는(Hang) 현상을 방지하기 위함입니다.
    if (epheFilesPath != null) {
      final destFile = assetPath.split('/').last;
      final file = File('$epheFilesPath/$destFile');
      if (await file.exists()) {
        return Uint8List(0);
      }
    }

    final Uint8List encoded = utf8.encoder.convert(Uri.encodeFull(assetPath));

    BinaryMessenger messenger;
    try {
      messenger = ServicesBinding.instance.defaultBinaryMessenger;
    } catch (_) {
      messenger = BackgroundIsolateBinaryMessenger.instance;
    }

    final ByteData? asset = await messenger.send('flutter/assets', encoded.buffer.asByteData());

    if (asset == null) {
      throw Exception('Unable to load asset: $assetPath');
    }
    return asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes);
  }
}

class SwephInitializer {
  static bool _initialized = false;
  static String? epheFilesPath;

  static Future<void> init({String? customEpheFilesPath}) async {
    if (_initialized) return;

    final path = customEpheFilesPath ??
        epheFilesPath ??
        '${(await getApplicationSupportDirectory()).path}/ephe_files';
    
    epheFilesPath = path;

    await Sweph.init(
      epheAssets: const [
        'assets/sweph/semo_18.se1',
        'assets/sweph/sepl_18.se1',
      ],
      epheFilesPath: path,
      assetLoader: IsolateSafeAssetLoader(epheFilesPath: path),
    );
    _initialized = true;
  }
}
