import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/model/observable.dart';
import 'package:mapsforge_flutter/src/model/observer.dart';
import 'package:mapsforge_flutter/src/utils/workingsetcache.dart';

/**
 * A thread-safe cache for tile images with a variable size and LRU policy.
 */
class MemoryTileCache extends TileCache {
  Observable observable;

  /**
   * @param capacity the maximum number of entries in this cache.
   * @throws IllegalArgumentException if the capacity is negative.
   */
  MemoryTileCache() {
    this.observable = new Observable();
  }

  @override
  void destroy() {
    purge();
  }

  @override
  int getCapacityFirstLevel() {
    return 200;
  }

  @override
  void purge() {}

  /**
   * Sets the new size of this cache. If this cache already contains more items than the new capacity allows, items
   * are discarded based on the cache policy.
   *
   * @param capacity the new maximum number of entries in this cache.
   * @throws IllegalArgumentException if the capacity is negative.
   */
  void setCapacity(int capacity) {}

  @override
  void addObserver(final Observer observer) {
    this.observable.addObserver(observer);
  }

  @override
  void removeObserver(final Observer observer) {
    this.observable.removeObserver(observer);
  }
}