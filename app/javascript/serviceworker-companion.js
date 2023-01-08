import {Workbox} from 'workbox-window';

const wb = new Workbox('/serviceworker.js');
wb.register();
