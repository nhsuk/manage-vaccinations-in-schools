import { cacheNames } from "workbox-core";

export const addAll = async (requests) => {
  const cache = await caches.open(cacheNames.runtime);
  return await cache.addAll(requests);
};

export const match = async (url) => {
  const cache = await caches.open(cacheNames.runtime);
  return await cache.match(url);
};

export const cacheResponse = (request, response) => {
  caches.open(cacheNames.runtime).then((cache) => {
    cache.put(request, response);
  });

  return response.clone();
};

export const lookupCachedResponse = async (request) => {
  const cache = await caches.open(cacheNames.runtime);
  const response = await cache.match(request.url);

  return response;
};
