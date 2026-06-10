import 'package:health/core/config/env_config.dart';

/// Chuẩn hóa URL phát nhạc — hỗ trợ presigned https và path local `/uploads/...`.
String resolvePlaybackUrl(String streamUrl) {
  final trimmed = streamUrl.trim();
  if (trimmed.isEmpty) return trimmed;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  final base = EnvConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (base.isEmpty) return trimmed;

  if (trimmed.startsWith('/')) {
    return '$base$trimmed';
  }

  return '$base/$trimmed';
}
