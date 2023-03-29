import { registerRoute } from "workbox-routing";

import { cacheOnly, networkFirst } from "./network";
import { isOnline, refreshOnlineStatus } from "./online-status";
import { handler as messageHandler } from "./messages";
import { childRoute, childRouteHandler } from "./child-route";
import { recordRoute, recordRouteHandler } from "./record-route";
import { getAll, destroy } from "./store";

const setDefaultHandler = () => {
  self.addEventListener("fetch", (event) => {
    event.respondWith(
      isOnline ? networkFirst(event.request) : cacheOnly(event.request)
    );
  });
};

const flushRequest = async (request) => {
  console.debug(
    "[Service Worker refreshOnlineStatus] sending request:",
    request
  );
  try {
    const csrf = await fetch("/csrf");
    const { token } = await csrf.json();
    const response = await fetch(request.url, {
      method: "PUT",
      body: JSON.stringify(request.body),
      redirect: "manual",
      headers: {
        "X-CSRF-Token": token,
      },
    });

    // Unfollowed redirects have a status code of 0
    const requestSuccessful = response.status === 0;

    if (requestSuccessful) {
      destroy("delayedRequests", request.id);
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
  const requests = await getAll("delayedRequests");

  await Promise.all(requests.map(flushRequest));
});

self.addEventListener("message", messageHandler);
console.debug("[Service Worker] registering routes");
registerRoute(childRoute, childRouteHandler);
registerRoute(recordRoute, recordRouteHandler, "POST");
setDefaultHandler();
