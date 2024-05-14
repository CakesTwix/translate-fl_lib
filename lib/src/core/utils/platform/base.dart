import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fl_lib/src/core/ext/string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Platforms
enum Pfs {
  android,
  ios,
  linux,
  macos,
  windows,
  web,
  fuchsia,
  unknown;

  static final type = () {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isAndroid) {
      return android;
    }
    if (Platform.isIOS) {
      return ios;
    }
    if (Platform.isLinux) {
      return linux;
    }
    if (Platform.isMacOS) {
      return macos;
    }
    if (Platform.isWindows) {
      return windows;
    }
    if (Platform.isFuchsia) {
      return fuchsia;
    }
    return unknown;
  }();

  @override
  String toString() => switch (this) {
        macos => 'macOS',
        ios => 'iOS',
        final val => val.name.upperFirst,
      };

  static final String seperator = isWindows ? '\\' : '/';

  /// Available only on desktop,
  /// return null on mobile
  static final String? homeDir = () {
    final envVars = Platform.environment;
    if (isMacOS || isLinux) {
      return envVars['HOME'];
    } else if (isWindows) {
      return envVars['UserProfile'];
    }
    return null;
  }();

  static bool get canShare => switch (type) {
        Pfs.windows || Pfs.linux => false,
        _ => true,
      };

  static Future<void> sharePath(String path,
      {String? name, String? mime}) async {
    if (!canShare) return;
    await Share.shareXFiles([XFile(path, name: name, mimeType: mime)]);
  }

  static Future<void> shareStr(String name, String data, {String? mime}) async {
    if (!canShare) return;
    await Share.shareXFiles(
      [XFile.fromData(utf8.encode(data), name: name, mimeType: mime)],
    );
  }

  static Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    return result?.files.single;
  }

  static Future<String?> pickFilePath() async {
    final picked = await pickFile();
    return picked?.path;
  }

  static Future<String?> pickFileString() async {
    final picked = await pickFile();
    if (picked == null) return null;

    switch (Pfs.type) {
      case Pfs.web:
        final bytes = picked.bytes;
        if (bytes == null) return null;
        return utf8.decode(bytes);
      default:
        final path = picked.path;
        if (path == null) return null;
        return await File(path).readAsString();
    }
  }

  static void copy(dynamic data) => switch (data.runtimeType) {
        const (String) => Clipboard.setData(ClipboardData(text: data)),
        final val => throw UnimplementedError(
            'Not supported type: $val(${val.runtimeType})'),
      };

  static Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}

final isAndroid = Pfs.type == Pfs.android;
final isIOS = Pfs.type == Pfs.ios;
final isLinux = Pfs.type == Pfs.linux;
final isMacOS = Pfs.type == Pfs.macos;
final isWindows = Pfs.type == Pfs.windows;
final isWeb = Pfs.type == Pfs.web;
final isMobile = Pfs.type == Pfs.ios || Pfs.type == Pfs.android;
final isDesktop =
    Pfs.type == Pfs.linux || Pfs.type == Pfs.macos || Pfs.type == Pfs.windows;
