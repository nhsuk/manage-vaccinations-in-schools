if (navigator.serviceWorker) {
  console.log('[Companion]', 'Registering service worker ...');
  navigator.serviceWorker.register('/serviceworker.js', { scope: './' })
    .then(function(reg) {
      console.log('[Companion]', 'Service worker registered!');
    });
}
