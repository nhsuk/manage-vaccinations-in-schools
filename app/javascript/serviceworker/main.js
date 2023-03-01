import { setDefaultHandler, registerRoute } from "workbox-routing";
import { NetworkFirst, CacheOnly } from "workbox-strategies";

import { isOnline, refreshOnlineStatus } from "./online-status";
import { handler as messageHandler } from "./messages";
import { childRoute, childRouteHandler } from "./child-route";
import { recordRoute, recordRouteHandler } from "./record-route";
import { getAllRequests, deleteRequest } from "./store";

const defaultHandler = async (event) => {
  // Requests manually added to the cache (such as via .addAll) may have a Vary
  // header. It will be different for requests cached through navigation versus
  // ones cached via .add, so we should ignore it when matching. See:
  // https://github.com/GoogleChrome/workbox/issues/1550#issuecomment-768002808
  const options = { matchOptions: { ignoreVary: true } };

  const Strategy = isOnline() ? NetworkFirst : CacheOnly;

  return new Strategy(options).handle(event);
};

const flushRequest = async (request) => {
  console.debug(
    "[Service Worker refreshOnlineStatus] sending request:",
    request
  );
  try {
    const response = await fetch(request.url, {
      method: "PUT",
      body: JSON.stringify(request.data),
    });

    if (response.status === 200) {
      deleteRequest(request.id);
    } else {
      console.debug(
        "[Service Worker refreshOnlineStatus] error sending request:",
        request,
        response
      );
    }
  } catch (err) {
    console.debug(
      "[Service Worker refreshOnlineStatus] error sending request:",
      err
    );
  }
};

refreshOnlineStatus(async () => {
  const requests = await getAllRequests();

  await Promise.all(requests.map(flushRequest));
});

self.addEventListener("message", messageHandler);
console.debug("[Service Worker] registering routes");
registerRoute(childRoute, childRouteHandler);
registerRoute(recordRoute, recordRouteHandler, "POST");
setDefaultHandler(defaultHandler);
