import { checkOnlineStatus, toggleOnlineStatus } from "./online-status";
import { addAll } from "./cache";

const messageHandlers = {
  TOGGLE_CONNECTION: (event) => {
    event.ports[0].postMessage(toggleOnlineStatus());
  },

  GET_CONNECTION_STATUS: (event) => {
    event.ports[0].postMessage(checkOnlineStatus());
  },

  SAVE_CAMPAIGN_FOR_OFFLINE: async ({ data }) => {
    const campaignId = data.payload["campaignId"];

    addAll([
      `/campaigns/${campaignId}/children`,
      `/campaigns/${campaignId}/children.json`,
      `/campaigns/${campaignId}/children/show-template`,
    ]);
  },
};

export const handler = (event) => {
  if (event.data && event.data.type) {
    messageHandlers[event.data.type](event);
  }
};
