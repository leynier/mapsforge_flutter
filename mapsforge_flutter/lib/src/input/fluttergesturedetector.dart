import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import '../../core.dart';

class FlutterGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  final MapViewPosition position;

  final Widget child;

  const FlutterGestureDetector({Key key, @required this.mapModel, this.position, @required this.child})
      : assert(mapModel != null),
        assert(child != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FlutterGestureDetectorState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class FlutterGestureDetectorState extends State<FlutterGestureDetector> {
  Mappoint startLeftUpper;

  Offset startOffset;

  Offset _doubleTapOffset;

  double _lastScale;

  @override
  Widget build(BuildContext context) {
    //RenderBox positionRed = context.findRenderObject();
    //Offset positionRelative = positionRed?.localToGlobal(Offset.zero);
    //print("positionRelative: ${positionRelative.toString()}");
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        // for doubleTap
        _doubleTapOffset = details.localPosition;
      },
      onTapUp: (TapUpDetails details) {
        //print(details.globalPosition.toString());
        //if (positionRelative == null) return;
        //widget.mapModel.tapEvent(details.globalPosition.dx - positionRelative.dx, details.globalPosition.dy - positionRelative.dy);
        widget.mapModel.tapEvent(details.localPosition.dx, details.localPosition.dy);
        widget.mapModel.gestureEvent();
      },
      onDoubleTap: () {
        if (_doubleTapOffset != null) {
          //if (positionRelative == null) return;
//          _log.info(" double tap at ${_doubleTapOffset.toString()}");
//          double xCenter = widget.mapModel.mapViewPosition.leftUpper.x
          BoundingBox boundingBox = widget.mapModel.mapViewPosition.calculateBoundingBox(widget.mapModel.mapViewDimension.getDimension());
          // lat/lon of the position where we double-clicked
          double latitude = widget.mapModel.mapViewPosition.mercatorProjection
              .pixelYToLatitude(widget.mapModel.mapViewPosition.leftUpper.y + _doubleTapOffset.dy);
          double longitude = widget.mapModel.mapViewPosition.mercatorProjection
              .pixelXToLongitude(widget.mapModel.mapViewPosition.leftUpper.x + _doubleTapOffset.dx);
          // interpolate the new center between the old center and where we pressed now. The new center is half-way between our double-pressed point and the old-center

          widget.mapModel.zoomInAround((latitude - widget.mapModel.mapViewPosition.latitude) / 2 + widget.mapModel.mapViewPosition.latitude,
              (longitude - widget.mapModel.mapViewPosition.longitude) / 2 + widget.mapModel.mapViewPosition.longitude);
        } else {
          widget.mapModel.zoomIn();
        }
        widget.mapModel.gestureEvent();
        _doubleTapOffset = null;
      },
      onScaleStart: (ScaleStartDetails details) {
        startOffset = details.focalPoint;
        startLeftUpper = widget.position?.leftUpper;
        _lastScale = null;
        print(details.toString());
        widget.mapModel.gestureEvent();
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        if (details.scale == 1) {
          // move around
          //print(details.toString());
          if (startLeftUpper == null) return;
          // do not react if less than 5 points dragged
          if ((startOffset.dx - details.focalPoint.dx).abs() < 5 && (startOffset.dy - details.focalPoint.dy).abs() < 5) return;
          widget.mapModel.setLeftUpper(
              startLeftUpper.x + startOffset.dx - details.focalPoint.dx, startLeftUpper.y + startOffset.dy - details.focalPoint.dy);
        } else {
          // zoom
          // do not send tiny changes
          if (_lastScale != null && ((details.scale / _lastScale) - 1).abs() < 0.01) return;
          //print("GestureDetector scale ${details.scale} around ${details.focalPoint.toString()} or ${details.localFocalPoint.toString()}");
          _lastScale = details.scale;
          MapViewPosition newPost = widget.mapModel.setScale(Mappoint(details.localFocalPoint.dx, details.localFocalPoint.dy), _lastScale);
        }
      },
      onScaleEnd: (ScaleEndDetails details) {
        //print(details.toString());
        if (_lastScale == null) return;
        // no zoom: 0, double zoom: 1, half zoom: -1
        double zoomLevelOffset = log(this._lastScale) / log(2);
        if (zoomLevelOffset.abs() >= 0.5) {
          // Complete large zooms towards gesture direction
//            zoomLevelDiff = (zoomLevelOffset < 0 ? zoomLevelOffset.floor() : zoomLevelOffset.ceil()).round();
          int zoomLevelDiff = zoomLevelOffset.round();
          if (zoomLevelDiff != 0) {
//            print("zooming now at $zoomLevelDiff for ${widget.position.toString()}");
            MapViewPosition newPost =
                widget.mapModel.setZoomLevel((widget.position?.zoomLevel ?? widget.mapModel.DEFAULT_ZOOM) + zoomLevelDiff);
//            print(
//                "  resulting in ${newPost.toString()} or ${newPost.mercatorProjection} or ${newPost.calculateBoundingBox(widget.mapModel.mapViewDimension.getDimension())} and now ${newPost.toString()}");
          }
        } else if (_lastScale != 1) {
          // no significant zoom. Restore the old zoom
          MapViewPosition newPost = widget.mapModel.setZoomLevel((widget.position?.zoomLevel ?? widget.mapModel.DEFAULT_ZOOM));
        }
      },
      child: widget.child,
    );
  }
}
