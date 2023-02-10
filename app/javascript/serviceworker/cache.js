import { cacheNames } from "workbox-core";

export const addAll = async (requests) => {
  const cache = await caches.open(cacheNames.runtime);
  return await cache.addAll(requests);
};

export const match = async (url) => {
  const cache = await caches.open(cacheNames.runtime);
  return await cache.match(url);
};

export const put = async (request, response) => {
  const cache = await caches.open(cacheNames.runtime);
  return await cache.put(request, response);
};
