import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/flutterresourcebitmap.dart';

///
/// A cache for symbols (small bitmaps)
class SymbolCache {
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 = "jar:/org/mapsforge/android/maps/rendertheme";

  /**
   * Default size is 20x20px (400px) at baseline mdpi (160dpi).
   */
  static int DEFAULT_SIZE = 20;

  Map<String, ResourceBitmap> _cache = Map();

  SymbolCache();

  void dispose() {
    _cache.forEach((key, bitmap) {
      bitmap.decrementRefCount();
    });
    _cache.clear();
  }

  Future<ResourceBitmap> getOrCreateBitmap(GraphicFactory graphicFactory, String src, int width, int height, int percent) async {
    if (src == null || src.length == 0) {
// no image source defined
      return null;
    }
    String key = "$src-$width-$height-$percent";
    ResourceBitmap bitmap = _cache[key];
    if (bitmap != null) return bitmap;
    bitmap = await _createBitmap(graphicFactory, null, src, width, height, percent);
    if (bitmap != null) {
      bitmap.incrementRefCount();
      _cache[key] = bitmap;
    }
    return bitmap;
  }

  Future<ResourceBitmap> _createBitmap(
      GraphicFactory graphicFactory, String relativePathPrefix, String src, int width, int height, int percent) async {
    if (src == null || src.length == 0) {
// no image source defined
      return null;
    }

    if (src.startsWith(PREFIX_JAR) || src.startsWith(PREFIX_JAR_V1)) {
      if (src.startsWith(PREFIX_JAR)) {
        src = src.substring(PREFIX_JAR.length);
      } else if (src.startsWith(PREFIX_JAR_V1)) {
        src = src.substring(PREFIX_JAR_V1.length);
      }
      src = "packages/mapsforge_flutter/assets/" + src;
    }

//    InputStream inputStream = createInputStream(graphicFactory, relativePathPrefix, src);
//      String absoluteName = getAbsoluteName(relativePathPrefix, src);
// we need to hash with the width/height included as the same symbol could be required
// in a different size and must be cached with a size-specific hash
    if (src.toLowerCase().endsWith(".svg")) {
      //var resource = new Resource(src);
      //Uint8List content = await resource.readAsBytes();
      ByteData content = await rootBundle.load(src);

      final DrawableRoot svgRoot = await svg.fromSvgBytes(content.buffer.asUint8List(), src);

// If you only want the final Picture output, just use
      final ui.Picture picture = svgRoot.toPicture(
          size:
              ui.Size(width != 0 ? width.toDouble() : DEFAULT_SIZE.toDouble(), height != 0 ? height.toDouble() : DEFAULT_SIZE.toDouble()));
      ui.Image image = await picture.toImage(width != 0 ? width : DEFAULT_SIZE, height != 0 ? height : DEFAULT_SIZE);
      //print("image: " + image.toString());
      FlutterResourceBitmap result = FlutterResourceBitmap(image);
      return result;

      //final Widget svg = new SvgPicture.asset(assetName, semanticsLabel: 'Acme Logo');

      //return graphicFactory.renderSvg(inputStream, displayModel.getScaleFactor(), width, height, percent);
    } else if (src.toLowerCase().endsWith(".png")) {
      ByteData content = await rootBundle.load(src);
      if (width != 0 && height != 0) {
//        imag.Image image = imag.decodeImage(content.buffer.asUint8List());
//        image = imag.copyResize(image, width: width, height: height);

//        var codec = await ui.instantiateImageCodec(imag.encodePng(image));
        var codec = await ui.instantiateImageCodec(content.buffer.asUint8List(), targetHeight: height, targetWidth: width);
        // add additional checking for number of frames etc here
        var frame = await codec.getNextFrame();
        ui.Image img = frame.image;

        FlutterResourceBitmap result = FlutterResourceBitmap(img);
        return result;
      } else {
        var codec = await ui.instantiateImageCodec(content.buffer.asUint8List());
        // add additional checking for number of frames etc here
        var frame = await codec.getNextFrame();
        ui.Image img = frame.image;

        FlutterResourceBitmap result = FlutterResourceBitmap(img);
        return result;
      }

      //Image img = Image.memory(content.buffer.asUint8List());
      //MemoryImage image = MemoryImage(content.buffer.asUint8List());

    } else {
      throw Exception("Unknown resource fileformat $src");
    }
  }
}
