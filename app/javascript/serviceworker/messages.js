import { isOnline, toggleOnlineStatus } from "./online-status";

const messageHandlers = {
  TOGGLE_CONNECTION: (event) => {
    event.ports[0].postMessage(toggleOnlineStatus());
  },

  GET_CONNECTION_STATUS: (event) => {
    event.ports[0].postMessage(isOnline());
  },
};

export const handler = (event) => {
  if (event.data && event.data.type) {
    messageHandlers[event.data.type](event);
  }
};
