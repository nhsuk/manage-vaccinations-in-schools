const defaultCacheName = "offline-v1";

export const cacheName = defaultCacheName;

export const addAll = async (requests: RequestInfo[]): Promise<void> => {
  const cache = await caches.open(cacheName);
  return await cache.addAll(requests);
};

export const match = async (
  request: RequestInfo,
  options: CacheQueryOptions = {}
): Promise<Response | undefined> => {
  const cache = await caches.open(cacheName);
  return await cache.match(request, options);
};

export const put = async (
  request: RequestInfo,
  response: Response
): Promise<void> => {
  const cache = await caches.open(cacheName);
  return await cache.put(request, response);
};
