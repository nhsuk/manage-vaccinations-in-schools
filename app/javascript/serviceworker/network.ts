const defaultCacheName = "offline-v1";

export const cacheName = defaultCacheName;

export const cacheOnly = async (
  request: Request,
  cacheName: string = defaultCacheName
): Promise<Response> => {
  const cache = await caches.open(cacheName);
  const cachedResponse = await cache.match(request, { ignoreVary: true });
  return cachedResponse;
};

export const networkFirst = async (
  request: Request,
  cacheName: string = defaultCacheName
): Promise<Response> => {
  try {
    const networkResponse = await fetch(request);
    const cache = await caches.open(cacheName);
    await cache.put(request, networkResponse.clone());
    return networkResponse;
  } catch (err) {
    return cacheOnly(request, cacheName);
  }
};
