 class CacheManager {

   String cachePrefix = "cache/";

  /**
   * Compute the path to the shared cache file from a base file name
   * Avatars are cached seperately and shared between users.
   * @param String filename Name of cache file
   */
   String cachePrefixForFile(String filename) {
    return cachePrefixForFile(filename, "shared");
  }

  /**
   * Compute the path to a group cache file
   * @param String filename Name of cache file
   * @param String groupName Name of group, this is usually the User ID string. Group name "shared" is reserved for shared caches.
   */
   String cachePrefixForFile(String filename, String groupName) {
    return this.cachePrefix + filename + "/" + groupName + ".bin";
  }

  /**
   * Attempts to load a TwitterCachedCall from a local file on disk, and if the local file doesn't exist, it attempts to perform the call and cache the results in the missing file.
   *
   * @return Object|null The object returned from the request. null if there was a failure.
   */
   Object loadFromCacheOrRequest(TwitterCachedCall call) {
    Serializable responseObject = null;
    String cacheFileName = call.getCacheFileName();

    //Try to load the response from the cache
    responseObject = loadFromCache(cacheFileName);

    if (responseObject == null) {
      //Cache miss, perform the actual API call
      println("Executing API call: " + call);
      responseObject = call.executeCall();

      if (responseObject != null) {
        if (call.saveOnCacheMiss()) {
          //Cache the response
          saveToCache(cacheFileName, responseObject);
        }
      } else {
        println("API call " + call + " failed and no cache is available.");
      }
    }
    return responseObject;
  }

  /**
   * Load an object from the cache
   */
   Serializable loadFromCache(String cacheFileName) {
    Serializable cachedObject = null;
    InputStream fis = createInput(cacheFileName);
    if (fis != null) {
      try {
        ObjectInputStream ois = new ObjectInputStream(fis);
        cachedObject = (Serializable)ois.readObject();
        ois.close();
        fis.close();
        println("Successful cache load from " + cacheFileName);
      } catch (Exception e) {
        println("Exception deserializing cache at " + cacheFileName);
      }
    }
    
    return cachedObject;
  }

  /**
   * Save an object to the cache
   */
   void saveToCache(String cacheFileName, Serializable object) {
    OutputStream fos = createOutput(cacheFileName);
    if (fos != null) {
      try {
        ObjectOutputStream oos = new ObjectOutputStream(fos);
        oos.writeObject(object);
        oos.close();
        fos.close();
        println("Wrote " + object + " to cache at " + cacheFileName);
      } catch (IOException ioe) {
        println("IOException writing " + object + " to cache file at " + cacheFileName
            + ". Exception: " + ioe.getMessage());
      }
    }
  }
}
