import {NetworkFirst} from 'workbox-strategies';
import {registerRoute} from 'workbox-routing';

registerRoute(new RegExp('.*'), new NetworkFirst());
