import { isOnline, toggleOnlineStatus } from "./online-status";
import { init as initCache, addAll } from "./cache";

const messageHandlers = {
  TOGGLE_CONNECTION: (event) => {
    event.ports[0].postMessage(toggleOnlineStatus());
  },

  GET_CONNECTION_STATUS: (event) => {
    event.ports[0].postMessage(isOnline());
  },

  SAVE_CAMPAIGN_FOR_OFFLINE: async (event) => {
    const campaignId = event.data.payload["campaignId"];
    const password = event.data.payload["password"];

    await initCache(password);

    await addAll([
      ...event.data.payload["additionalItems"],
      `/favicon.ico`,
      `/dashboard`,
      `/campaigns/${campaignId}`,
      `/campaigns/${campaignId}/children`,
      `/campaigns/${campaignId}/children.json`,
      `/campaigns/${campaignId}/children/record-template`,
      `/campaigns/${campaignId}/children/show-template`,
    ]);

    event.ports[0].postMessage(true);
  },
};

export const handler = (event) => {
  if (event.data && event.data.type) {
    messageHandlers[event.data.type](event);
  }
};
