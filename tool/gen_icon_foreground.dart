// アプリアイコンの Adaptive 前景 (透過 PNG) を生成するデバッグ専用ツール (#86)。
//
// qlmanage は SVG の透過を白で塗りつぶすため、Adaptive Icon / Android 12 スプラッシュ
// 用の前景は透過を保証する必要がある。本スクリプトで真の透過 PNG を生成する。
//
//   dart run tool/gen_icon_foreground.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const int size = 1024;
  final img.Image image = img.Image(width: size, height: size, numChannels: 4);
  // 透過で初期化。
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final img.ColorRgba8 white = img.ColorRgba8(255, 255, 255, 255);
  final img.ColorRgba8 red = img.ColorRgba8(0xF4, 0x43, 0x5E, 255);

  // 心拍/活動ラインの頂点 (セーフゾーン中央寄り)。
  const List<List<int>> pts = <List<int>>[
    [280, 540],
    [380, 540],
    [415, 540],
    [450, 468],
    [490, 612],
    [534, 404],
    [575, 540],
    [640, 540],
    [700, 484],
    [744, 484],
  ];
  const int thickness = 42;

  for (int i = 0; i < pts.length - 1; i++) {
    img.drawLine(
      image,
      x1: pts[i][0],
      y1: pts[i][1],
      x2: pts[i + 1][0],
      y2: pts[i + 1][1],
      color: white,
      thickness: thickness,
    );
  }
  // 角を丸めるため各頂点に半径=太さ/2 の円を置く。
  for (final List<int> p in pts) {
    img.fillCircle(
      image,
      x: p[0],
      y: p[1],
      radius: thickness ~/ 2,
      color: white,
      antialias: true,
    );
  }
  // 末端の赤ドット。
  img.fillCircle(image, x: 744, y: 484, radius: 26, color: red, antialias: true);

  File(
    'assets/branding/app_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('app_icon_foreground.png (transparent) を生成しました');
}
