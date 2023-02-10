import { cacheNames } from "workbox-core";

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
