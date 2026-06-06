// Google Play 準拠へストア素材を整形するツール (#47)。
//
//   dart run tool/prepare_store_assets.dart
//
// - app_icon: 512x512 (Play ストアアイコン規定)
// - feature_graphic: 24bit RGB (アルファ除去, 1024x500)
// - screenshots: 縦横比を 2:1 以内へ (1080x2400 → 1200x2400 に左右パディング), RGB
import 'dart:io';

import 'package:image/image.dart' as img;

const String bg = '#F5F6FA';

img.ColorRgb8 _hex(String h) => img.ColorRgb8(
  int.parse(h.substring(1, 3), radix: 16),
  int.parse(h.substring(3, 5), radix: 16),
  int.parse(h.substring(5, 7), radix: 16),
);

void main() {
  // 1) ストアアイコン 512x512。
  final img.Image icon = img.decodePng(
    File('docs/store/app_icon.png').readAsBytesSync(),
  )!;
  final img.Image icon512 = img.copyResize(
    icon,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.average,
  );
  File('docs/store/app_icon.png').writeAsBytesSync(img.encodePng(icon512));

  // 2) フィーチャーグラフィックのアルファ除去 (24bit RGB)。
  final img.Image fg = img.decodePng(
    File('docs/store/feature_graphic.png').readAsBytesSync(),
  )!;
  File(
    'docs/store/feature_graphic.png',
  ).writeAsBytesSync(img.encodePng(fg.convert(numChannels: 3)));

  // 3) スクリーンショットを 2:1 以内へパディング + RGB。
  final Directory dir = Directory('docs/store/screenshots');
  final img.ColorRgb8 pad = _hex(bg);
  for (final FileSystemEntity e in dir.listSync()) {
    if (!e.path.endsWith('.png')) continue;
    final img.Image s = img.decodePng(File(e.path).readAsBytesSync())!;
    // 長辺/短辺 <= 2 になるよう短辺(幅)を拡張。
    final int targetW = (s.height / 2).ceil();
    final int w = targetW > s.width ? targetW : s.width;
    final img.Image canvas = img.Image(
      width: w,
      height: s.height,
      numChannels: 3,
    );
    img.fill(canvas, color: pad);
    img.compositeImage(canvas, s, dstX: ((w - s.width) / 2).round());
    File(e.path).writeAsBytesSync(img.encodePng(canvas));
  }
  stdout.writeln('ストア素材を Play 準拠へ整形しました');
}
