import { setDefaultHandler, registerRoute } from "workbox-routing";
import { isOnline, refreshOnlineStatus } from "./online-status";
import { put, match } from "./cache";
import { handler as messageHandler } from "./messages";
import { childRoute, childRouteHandler } from "./child-route";
import { recordRoute, recordRouteHandler } from "./record-route";
import { getAllRequests, deleteRequest } from "./store";

const defaultHandlerCB = async ({ request }) => {
  console.debug("[Service Worker defaultHandlerCB] request:", request);

  if (!isOnline()) {
    return await match(request.url);
  }

  try {
    const response = await fetch(request);
    console.debug(
      "[Service Worker defaultHandlerCB] response:",
      response.clone()
    );

    put(request, response.clone());
    return response;
  } catch (err) {
    console.debug(
      "[Service Worker defaultHandlerCB] no response, we're offline:",
      err
    );

    return await match(request.url);
  }
};

refreshOnlineStatus(async () => {
  const requests = await getAllRequests();
  requests.forEach(async (request) => {
    console.debug(
      "[Service Worker refreshOnlineStatus] sending request:",
      request
    );
    try {
      const response = await fetch(request.url, {
        method: "PUT",
        body: JSON.stringify(request.data),
        redirect: "manual",
      });

      // Unfollowed redirects have a status code of 0
      const requestSuccessful = response.status === 0;

      if (requestSuccessful) {
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
  });
});

self.addEventListener("message", messageHandler);
console.debug("[Service Worker] registering routes");
registerRoute(childRoute, childRouteHandler);
registerRoute(recordRoute, recordRouteHandler, "POST");
setDefaultHandler(defaultHandlerCB);
