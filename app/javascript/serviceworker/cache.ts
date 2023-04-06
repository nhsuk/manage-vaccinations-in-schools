import { cacheName } from "./network";

export const addAll = async (requests: RequestInfo[]): Promise<void> => {
  const cache = await caches.open(cacheName);
  return await cache.addAll(requests);
};

export const match = async (
  url: RequestInfo
): Promise<Response | undefined> => {
  const cache = await caches.open(cacheName);
  return await cache.match(url);
};

export const put = async (
  request: RequestInfo,
  response: Response
): Promise<void> => {
  const cache = await caches.open(cacheName);
  return await cache.put(request, response);
};
