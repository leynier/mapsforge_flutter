import 'package:mapsforge_flutter/cache/tilecache.dart';
import 'package:mapsforge_flutter/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/layer/job/job.dart';
import 'package:mapsforge_flutter/model/observable.dart';
import 'package:mapsforge_flutter/model/observer.dart';
import 'package:mapsforge_flutter/utils/workingsetcache.dart';

/**
 * A thread-safe cache for tile images with a variable size and LRU policy.
 */
class MemoryTileCache implements TileCache {
  BitmapLRUCache lruCache;
  Observable observable;

  /**
   * @param capacity the maximum number of entries in this cache.
   * @throws IllegalArgumentException if the capacity is negative.
   */
  MemoryTileCache(int capacity) {
    this.lruCache = new BitmapLRUCache(capacity);
    this.observable = new Observable();
  }

  @override
  bool containsKey(Job key) {
    return this.lruCache.containsKey(key);
  }

  @override
  void destroy() {
    purge();
  }

  @override
  TileBitmap get(Job key) {
    TileBitmap bitmap = this.lruCache.get(key);
    if (bitmap != null) {
      bitmap.incrementRefCount();
    }
    return bitmap;
  }

  @override
  int getCapacity() {
    return this.lruCache.capacity;
  }

  @override
  int getCapacityFirstLevel() {
    return getCapacity();
  }

  @override
  TileBitmap getImmediately(Job key) {
    return get(key);
  }

  @override
  void purge() {
    this.lruCache.values.map((f) => f.value).forEach((bitmap) {
      bitmap.decrementRefCount();
    });
    this.lruCache.clear();
  }

  @override
  void put(Job key, TileBitmap bitmap) {
    if (key == null) {
      throw new Exception("key must not be null");
    } else if (bitmap == null) {
      throw new Exception("bitmap must not be null");
    }

    TileBitmap old = this.lruCache.get(key);
    if (old != null) {
      old.decrementRefCount();
    }

    this.lruCache.put(key, bitmap);
    bitmap.incrementRefCount();
    this.observable.notifyObservers();
  }

  /**
   * Sets the new size of this cache. If this cache already contains more items than the new capacity allows, items
   * are discarded based on the cache policy.
   *
   * @param capacity the new maximum number of entries in this cache.
   * @throws IllegalArgumentException if the capacity is negative.
   */
  void setCapacity(int capacity) {
    BitmapLRUCache lruCacheNew = new BitmapLRUCache(capacity);
    //lruCacheNew.putAll(this.lruCache);
    this.lruCache = lruCacheNew;
  }

  @override
  void setWorkingSet(Set<Job> jobs) {
    this.lruCache.setWorkingSet(jobs);
  }

  @override
  void addObserver(final Observer observer) {
    this.observable.addObserver(observer);
  }

  @override
  void removeObserver(final Observer observer) {
    this.observable.removeObserver(observer);
  }
}

/////////////////////////////////////////////////////////////////////////////

class BitmapLRUCache extends WorkingSetCache<Job, TileBitmap> {
  BitmapLRUCache(int capacity) : super(capacity);

//  @override
//  bool removeEldestEntry(Map.Entry<Job, TileBitmap> eldest) {
//    if (size() > this.capacity) {
//      TileBitmap bitmap = eldest.getValue();
//      if (bitmap != null) {
//        bitmap.decrementRefCount();
//      }
//      return true;
//    }
//    return false;
//  }
}
