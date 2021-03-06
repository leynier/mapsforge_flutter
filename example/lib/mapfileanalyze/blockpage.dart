import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/mapreadresult.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/reader/queryparameters.dart';
import 'package:mapsforge_flutter/src/reader/subfileparameter.dart';

class BlockPage extends StatelessWidget {
  final MapFile mapFile;

  final SubFileParameter subFileParameter;

  const BlockPage({Key key, this.mapFile, this.subFileParameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _readBlock(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.data == null)
          return Center(
            child: CircularProgressIndicator(),
          );
        if (snapshot.hasError || snapshot.error != null) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }
        MapReadResult mapReadResult = snapshot.data;
        int items = mapReadResult.ways.length < 1000
            ? mapReadResult.ways.fold(
                0,
                (previousValue, element) =>
                    previousValue + element.latLongs.fold(0, (previousValue, element) => previousValue + element.length))
            : -1;
        return ListView(
          children: <Widget>[
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("IsWater ${mapReadResult.isWater}, "),
                  Text("Pois ${mapReadResult.pointOfInterests.length}, "),
                  Text("Ways ${mapReadResult.ways.length}, sum ${items} LatLongs, "),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<MapReadResult> _readBlock() async {
    try {
      ReadBufferMaster readBufferMaster = ReadBufferMaster(mapFile.filename);

      QueryParameters queryParameters = new QueryParameters();
      queryParameters.queryZoomLevel = subFileParameter.baseZoomLevel;
      Tile upperLeft = Tile(subFileParameter.boundaryTileLeft, subFileParameter.boundaryTileTop, subFileParameter.baseZoomLevel, 256);
      Tile lowerRight = Tile(subFileParameter.boundaryTileRight, subFileParameter.boundaryTileBottom, subFileParameter.baseZoomLevel, 256);
      queryParameters.calculateBaseTiles(upperLeft, lowerRight, subFileParameter);
      queryParameters.calculateBlocks(subFileParameter);
      print(
          "Querying from ${queryParameters.fromBlockX} - ${queryParameters.toBlockX} and ${queryParameters.fromBlockY} - ${queryParameters.toBlockY}");

      BoundingBox boundingBox = Tile.getBoundingBoxStatic(upperLeft, lowerRight);
      Selector selector = Selector.ALL;
      MapReadResult result = await mapFile.processBlocks(readBufferMaster, queryParameters, subFileParameter, boundingBox, selector);
      //print("result: $result");
      return result;
    } catch (e, stacktrace) {
      print("${e.toString()}");
      print("${stacktrace.toString()}");
      throw e;
    }
  }
}
