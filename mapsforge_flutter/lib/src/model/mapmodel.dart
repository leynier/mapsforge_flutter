import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/cache/symbolcache.dart';
import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/layer/job/jobrenderer.dart';
import 'package:mapsforge_flutter/src/utils/mercatorprojection.dart';
import 'package:rxdart/rxdart.dart';

import 'displaymodel.dart';
import 'mapviewdimension.dart';
import 'mapviewposition.dart';

class MapModel {
  final int DEFAULT_ZOOM = 10;
  final DisplayModel displayModel;
  final MapViewDimension mapViewDimension;
  final GraphicFactory graphicsFactory;
  final JobRenderer renderer;
  final SymbolCache symbolCache;
  MapViewPosition _mapViewPosition;

  Subject<MapViewPosition> _injectPosition = PublishSubject();
  Observable<MapViewPosition> _observePosition;

  Subject<TapEvent> _injectTap = PublishSubject();
  Observable<TapEvent> _observeTap;

  MapModel({
    @required this.displayModel,
    @required this.renderer,
    @required this.graphicsFactory,
    @required this.symbolCache,
  })  : assert(displayModel != null),
        assert(renderer != null),
        assert(graphicsFactory != null),
        assert(symbolCache != null),
        mapViewDimension = MapViewDimension() {
    _observePosition = _injectPosition.asyncMap((pos) async {
      return pos;
    }).asBroadcastStream();

    _observeTap = _injectTap.asBroadcastStream();
  }

  Observable<MapViewPosition> get observePosition => _observePosition;

  Observable<TapEvent> get observeTap => _observeTap;

  MapViewPosition get mapViewPosition => _mapViewPosition;

  void setMapViewPosition(double latitude, double longitude) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition(latitude, longitude, _mapViewPosition.zoomLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(latitude, longitude, DEFAULT_ZOOM);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void zoomIn() {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.zoomIn(_mapViewPosition);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM + 1);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void zoomOut() {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.zoomOut(_mapViewPosition);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM - 1);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void setZoomLevel(int zoomLevel) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition = MapViewPosition.zoom(_mapViewPosition, zoomLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, zoomLevel);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void setLeftUpper(double left, double upper) {
    if (_mapViewPosition != null) {
      MapViewPosition newPosition =
          MapViewPosition.setLeftUpper(_mapViewPosition, left, upper, displayModel.tileSize, mapViewDimension.getDimension());
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    } else {
      MapViewPosition newPosition = MapViewPosition(null, null, DEFAULT_ZOOM - 1);
      _mapViewPosition = newPosition;
      _injectPosition.add(newPosition);
    }
  }

  void tapEvent(double left, double upper) {
    if (_mapViewPosition == null) return;

    int mapSize = MercatorProjection.getMapSize(_mapViewPosition.zoomLevel, displayModel.tileSize);
    TapEvent event = TapEvent(MercatorProjection.pixelYToLatitude(_mapViewPosition.leftUpper.y + upper, mapSize),
        MercatorProjection.pixelXToLongitude(_mapViewPosition.leftUpper.x + left, mapSize), left, upper);
    _injectTap.add(event);
  }
}

/////////////////////////////////////////////////////////////////////////////

class TapEvent {
  final double latitude;

  final double longitude;

  final double x;

  final double y;

  TapEvent(this.latitude, this.longitude, this.x, this.y)
      : assert(latitude != null),
        assert(longitude != null),
        assert(x != null),
        assert(y != null);
}