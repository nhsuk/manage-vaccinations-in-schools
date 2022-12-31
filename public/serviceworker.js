var CACHE_VERSION = 'v1';
var CACHE_NAME = CACHE_VERSION + ':sw-cache-';

function onInstall(event) {
  console.debug('[Serviceworker]', "Installing!", event);
  event.waitUntil(
    caches.open(CACHE_NAME).then(function prefill(cache) {
      return cache.addAll([
        // make sure serviceworker.js is not required by application.js
        // if you want to reference application.js from here
        // '/assets/application-15244ee87d84cca4f40328cd774886a0cb92f4c1.js',
        // <%= asset_path "application.js" %>
        // '/assets/application-2d7a8b89d39d0df553348acf3e44c90e6c6b741c.css',
        '/offline.html',

      ]);
    })
  );
}

function onActivate(event) {
  console.debug('[Serviceworker]', "Activating!", event);
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.filter(function(cacheName) {
          // Return true if you want to remove this cache,
          // but remember that caches are shared across
          // the whole origin
          return cacheName.indexOf(CACHE_VERSION) !== 0;
        }).map(function(cacheName) {
          return caches.delete(cacheName);
        })
      );
    })
  );
}

// Borrowed from https://github.com/TalAter/UpUp
function onFetch(event) {
  event.respondWith(
    // try to return untouched request from network first
    fetch(event.request).then((response) => {
      console.debug('[Serviceworker]', "Fetch received response", response);

      // cache the response, but as the response can only be used once, clone it first
      let responseClone = response.clone();

      caches.open(CACHE_NAME).then((cache) => {
        console.debug('[Serviceworker]', "Cacheing response for request", event.request);
        cache.put(event.request, responseClone)
      }).catch((err) => {
        console.error('[Serviceworker]', "Could not open cache", CACHE_NAME, err);
      });

      return response;
    }).catch((err) => {
      console.debug('[Serviceworker]', "Failed to fetch response for request", event.request, err);

      // if it fails, try to return request from the cache
      return caches.match(event.request).then(function(response) {
        if (response != undefined) {
          console.debug('[Serviceworker]', "Returning cached response", response);
          return response;
        }

        // if not found in cache, return default offline content for navigate requests
        console.debug('[Serviceworker]', "Request not in cache", event.request);

        if (event.request.mode === 'navigate' ||
              (event.request.method === 'GET' &&
               event.request.headers.get('accept').includes('text/html'))) {
          console.debug('[Serviceworker]', "Request not in cache", event.request);

          return caches.match('/offline.html');
        }
      })
    })
  );
}

self.addEventListener('install', onInstall);
self.addEventListener('activate', onActivate);
self.addEventListener('fetch', onFetch);
