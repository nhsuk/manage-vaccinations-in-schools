import {NetworkFirst} from 'workbox-strategies';
import {registerRoute} from 'workbox-routing';

let offlineMode = false;

registerRoute(new RegExp('.*'), new NetworkFirst());

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'TOGGLE_CONNECTION') {
    console.log("toggling our connection");
    offlineMode = !offlineMode;
    event.ports[0].postMessage(offlineMode)
  }
});
