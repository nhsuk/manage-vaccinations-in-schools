var CACHE_VERSION = 'v1';
var CACHE_NAME = CACHE_VERSION + ':sw-cache-';

// import routeRequest from 'router.js';
importScripts('/router.js');

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
    routeRequest(event.request)
  )
}


self.addEventListener('install', onInstall);
self.addEventListener('activate', onActivate);
self.addEventListener('fetch', onFetch);

