// フィーチャーグラフィックを Play 規定の 1024x500 にクロップするツール (#47)。
//
// qlmanage は正方形サムネイルで出力するため、上部 1024x500 を切り出す。
//   dart run tool/crop_feature_graphic.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const String path = 'assets/branding/feature_graphic.png';
  final img.Image src = img.decodePng(File(path).readAsBytesSync())!;
  final img.Image cropped = img.copyCrop(
    src,
    x: 0,
    y: 0,
    width: 1024,
    height: 500,
  );
  File(path).writeAsBytesSync(img.encodePng(cropped));
  stdout.writeln('feature_graphic.png -> 1024x500 にクロップしました');
}
