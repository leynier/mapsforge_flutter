import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/input/fluttergesturedetector.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/tilelayer.dart';
import 'package:mapsforge_flutter/src/model/mapmodel.dart';
import 'package:mapsforge_flutter/src/view/mapview.dart';

import '../../../core.dart';
import 'contextmenu.dart';
import 'layerpainter.dart';

class FlutterMapView extends StatefulWidget implements MapView {
  final MapModel mapModel;

  const FlutterMapView({
    Key key,
    @required this.mapModel,
  })  : assert(mapModel != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FlutterMapState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _FlutterMapState extends State<FlutterMapView> {
  static final _log = new Logger('_FlutterMapState');

  TileLayer _tileLayer;

  TapEvent _lastTapEvent;

  GlobalKey _keyView = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tileLayer = TileLayer(
      displayModel: widget.mapModel.displayModel,
      jobRenderer: widget.mapModel.renderer,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log.info("draw");
    return StreamBuilder<MapViewPosition>(
      stream: widget.mapModel.observePosition,
      builder: (BuildContext context, AsyncSnapshot<MapViewPosition> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.hasPosition()) {
            return _buildMapView(snapshot.data);
          }
          return Center(
            child: Text("No Position"),
          );
        }
        if (widget.mapModel.mapViewPosition != null && widget.mapModel.mapViewPosition.hasPosition()) {
          return _buildMapView(widget.mapModel.mapViewPosition);
        }
        return Center(
          child: Text("No Position"),
        );
      },
    );
  }

  Widget _buildMapView(MapViewPosition position) {
    return Stack(
      key: _keyView,
      children: <Widget>[
        FlutterGestureDetector(
          mapModel: widget.mapModel,
          child: Stack(
            children: <Widget>[
              StreamBuilder<Job>(
                stream: _tileLayer.observeJob,
                builder: (BuildContext context, AsyncSnapshot<Job> snapshot) {
                  if (snapshot.hasData) {
                    _tileLayer.jobResult(snapshot.data);
                  }
                  return CustomPaint(
                    foregroundPainter: LayerPainter(widget.mapModel.mapViewDimension, _tileLayer, position),
                    child: Container(),
                  );
                },
              ),
            ],
          ),
        ),
        StreamBuilder<TapEvent>(
          stream: widget.mapModel.observeTap,
          builder: (BuildContext context, AsyncSnapshot<TapEvent> snapshot) {
            if (!snapshot.hasData) return Container();
            TapEvent event = snapshot.data;
            final RenderBox renderBox = _keyView.currentContext.findRenderObject();
            final positionRed = renderBox.localToGlobal(Offset.zero);
            return ContextMenu(
              mapModel: widget.mapModel,
              position: position,
              viewOffset: positionRed,
              event: event,
            );
          },
        ),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////////////////