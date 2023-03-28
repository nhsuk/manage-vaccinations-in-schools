import { cacheName } from "./network";

export const addAll = async (requests) => {
  const cache = await caches.open(cacheName);
  return await cache.addAll(requests);
};

export const match = async (url) => {
  const cache = await caches.open(cacheName);
  return await cache.match(url);
};

export const put = async (request, response) => {
  const cache = await caches.open(cacheName);
  return await cache.put(request, response);
};
