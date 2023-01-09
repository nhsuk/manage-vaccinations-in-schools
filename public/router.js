var CACHE_VERSION = 'v1';
var CACHE_NAME = CACHE_VERSION + ':sw-cache-';

function routeRequest(request) {
  // try to return untouched request from network first
  return fetch(request).then((response) => {
    console.debug('[Serviceworker]', "Fetch received response", response);

    // cache the response, but as the response can only be used once, clone it first
    let responseClone = response.clone();

    caches.open(CACHE_NAME).then((cache) => {
      console.debug('[Serviceworker]', "Cacheing response for request", request);
      cache.put(request, responseClone)
    }).catch((err) => {
      console.error('[Serviceworker]', "Could not open cache", CACHE_NAME, err);
    });

    return response;
  }).catch((err) => {
    console.debug('[Serviceworker]', "Failed to fetch response for request", request, err);

    // if it fails, try to return request from the cache
    return caches.match(request).then(function(response) {
      if (response != undefined) {
        console.debug('[Serviceworker]', "Returning cached response", response);
        return response;
      }

      // if not found in cache, return default offline content for navigate requests
      console.debug('[Serviceworker]', "Request not in cache", request);

      if (request.mode === 'navigate' ||
          (request.method === 'GET' &&
           request.headers.get('accept').includes('text/html'))) {
        console.debug('[Serviceworker]', "Request not in cache", request);

        return caches.match('/offline.html');
      }
    })
  })
}
