import 'dart:math';

import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/latlong.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import 'mapdatastore.dart';
import 'mapreadresult.dart';

/**
 * A MapDatabase that reads and combines data from multiple map files.
 * The MultiMapDatabase supports the following modes for reading from multiple files:
 * - RETURN_FIRST: the data from the first database to support a tile will be returned. This is the
 * fastest operation suitable when you know there is no overlap between map files.
 * - RETURN_ALL: the data from all files will be returned, the data will be combined. This is suitable
 * if more than one file can contain data for a tile, but you know there is no semantic overlap, e.g.
 * one file contains contour lines, another road data.
 * - DEDUPLICATE: the data from all files will be returned but duplicates will be eliminated. This is
 * suitable when multiple maps cover the different areas, but there is some overlap at boundaries. This
 * is the most expensive operation and often it is actually faster to double paint objects as otherwise
 * all objects have to be compared with all others.
 */
class MultiMapDataStore extends MapDataStore {
  BoundingBox boundingBox;
  final DataPolicy dataPolicy;
  final List<MapDataStore> mapDatabases;
  LatLong startPosition;
  int startZoomLevel;

  MultiMapDataStore(this.dataPolicy)
      : mapDatabases = new List(),
        super(null);

  /**
   * adds another mapDataStore
   *
   * @param mapDataStore      the mapDataStore to add
   * @param useStartZoomLevel if true, use the start zoom level of this mapDataStore as the start zoom level
   * @param useStartPosition  if true, use the start position of this mapDataStore as the start position
   */

  void addMapDataStore(MapDataStore mapDataStore, bool useStartZoomLevel, bool useStartPosition) {
    if (this.mapDatabases.contains(mapDataStore)) {
      throw new Exception("Duplicate map database");
    }
    this.mapDatabases.add(mapDataStore);
    if (useStartZoomLevel) {
      this.startZoomLevel = mapDataStore.startZoomLevel;
    }
    if (useStartPosition) {
      this.startPosition = mapDataStore.startPosition;
    }
    if (null == this.boundingBox) {
      this.boundingBox = mapDataStore.boundingBox;
    } else {
      this.boundingBox = this.boundingBox.extendBoundingBox(mapDataStore.boundingBox);
    }
  }

  @override
  void close() {
    for (MapDataStore mdb in mapDatabases) {
      mdb.close();
    }
  }

  /**
   * Returns the timestamp of the data used to render a specific tile.
   * <p/>
   * If the tile uses data from multiple data stores, the most recent timestamp is returned.
   *
   * @param tile A tile.
   * @return the timestamp of the data used to render the tile
   */
  @override
  int getDataTimestamp(Tile tile) {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile)) {
            return mdb.getDataTimestamp(tile);
          }
        }
        return 0;
      case DataPolicy.RETURN_ALL:
      case DataPolicy.DEDUPLICATE:
        int result = 0;
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile)) {
            result = max(result, mdb.getDataTimestamp(tile));
          }
        }
        return result;
    }
    throw new Exception("Invalid data policy for multi map database");
  }

  @override
  Future<MapReadResult> readLabelsSingle(Tile tile) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile)) {
            return mdb.readLabelsSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readLabelsDedup(tile, false);
      case DataPolicy.DEDUPLICATE:
        return _readLabelsDedup(tile, true);
    }
    throw new Exception("Invalid data policy for multi map database");
  }

  Future<MapReadResult> _readLabelsDedup(Tile tile, bool deduplicate) async {
    MapReadResult mapReadResult = new MapReadResult();
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(tile)) {
        MapReadResult result = await mdb.readLabelsSingle(tile);
        if (result == null) {
          continue;
        }
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    return mapReadResult;
  }

  @override
  Future<MapReadResult> readLabels(Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(upperLeft)) {
            return mdb.readLabels(upperLeft, lowerRight);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readLabels(upperLeft, lowerRight, false);
      case DataPolicy.DEDUPLICATE:
        return _readLabels(upperLeft, lowerRight, true);
    }
    throw new Exception("Invalid data policy for multi map database");
  }

  Future<MapReadResult> _readLabels(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    MapReadResult mapReadResult = new MapReadResult();
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(upperLeft)) {
        MapReadResult result = await mdb.readLabels(upperLeft, lowerRight);
        if (result == null) {
          continue;
        }
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    return mapReadResult;
  }

  @override
  Future<MapReadResult> readMapDataSingle(Tile tile) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile)) {
            return mdb.readMapDataSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readMapData(tile, false);
      case DataPolicy.DEDUPLICATE:
        return _readMapData(tile, true);
    }
    throw new Exception("Invalid data policy for multi map database");
  }

  Future<MapReadResult> _readMapData(Tile tile, bool deduplicate) async {
    MapReadResult mapReadResult = new MapReadResult();
    bool found = false;
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(tile)) {
        MapReadResult result = await mdb.readMapDataSingle(tile);
        if (result == null) {
          continue;
        }
        found = true;
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    if (!found) return null;
    return mapReadResult;
  }

  @override
  Future<MapReadResult> readMapData(Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(upperLeft)) {
            return mdb.readMapData(upperLeft, lowerRight);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readMapDataDedup(upperLeft, lowerRight, false);
      case DataPolicy.DEDUPLICATE:
        return _readMapDataDedup(upperLeft, lowerRight, true);
    }
    throw new Exception("Invalid data policy for multi map database");
  }

  Future<MapReadResult> _readMapDataDedup(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    MapReadResult mapReadResult = new MapReadResult();
    bool found = false;
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(upperLeft)) {
        MapReadResult result = await mdb.readMapData(upperLeft, lowerRight);
        if (result == null) {
          continue;
        }
        found = true;
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    if (!found) return null;
    return mapReadResult;
  }

  @override
  Future<MapReadResult> readPoiDataSingle(Tile tile) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(tile)) {
            return mdb.readPoiDataSingle(tile);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readPoiData(tile, false);
      case DataPolicy.DEDUPLICATE:
        return _readPoiData(tile, true);
    }
    throw new Exception("Invalid data policy for multi map database");
  }

  Future<MapReadResult> _readPoiData(Tile tile, bool deduplicate) async {
    MapReadResult mapReadResult = new MapReadResult();
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(tile)) {
        MapReadResult result = await mdb.readPoiDataSingle(tile);
        if (result == null) {
          continue;
        }
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    return mapReadResult;
  }

  @override
  Future<MapReadResult> readPoiData(Tile upperLeft, Tile lowerRight) async {
    switch (this.dataPolicy) {
      case DataPolicy.RETURN_FIRST:
        for (MapDataStore mdb in mapDatabases) {
          if (mdb.supportsTile(upperLeft)) {
            return mdb.readPoiData(upperLeft, lowerRight);
          }
        }
        return null;
      case DataPolicy.RETURN_ALL:
        return _readPoiDataDedup(upperLeft, lowerRight, false);
      case DataPolicy.DEDUPLICATE:
        return _readPoiDataDedup(upperLeft, lowerRight, true);
    }
    throw new Exception("Invalid data policy for multi map database");
  }

  Future<MapReadResult> _readPoiDataDedup(Tile upperLeft, Tile lowerRight, bool deduplicate) async {
    MapReadResult mapReadResult = new MapReadResult();
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(upperLeft)) {
        MapReadResult result = await mdb.readPoiData(upperLeft, lowerRight);
        if (result == null) {
          continue;
        }
        bool isWater = mapReadResult.isWater & result.isWater;
        mapReadResult.isWater = isWater;
        mapReadResult.addDeduplicate(result, deduplicate);
      }
    }
    return mapReadResult;
  }

  void setStartPosition(LatLong startPosition) {
    this.startPosition = startPosition;
  }

  void setStartZoomLevel(int startZoomLevel) {
    this.startZoomLevel = startZoomLevel;
  }

  @override
  LatLong get getStartPosition {
    if (null != this.startPosition) {
      return this.startPosition;
    }
    if (null != this.boundingBox) {
      return this.boundingBox.getCenterPoint();
    }
    return null;
  }

  @override
  bool supportsTile(Tile tile) {
    for (MapDataStore mdb in mapDatabases) {
      if (mdb.supportsTile(tile)) {
        return true;
      }
    }
    return false;
  }
}

/////////////////////////////////////////////////////////////////////////////

enum DataPolicy {
  RETURN_FIRST, // return the first set of data
  RETURN_ALL, // return all data from databases
  DEDUPLICATE // return all data but eliminate duplicates
}