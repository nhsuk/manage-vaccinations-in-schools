import { match, put } from "./cache";

export const cacheOnly = async (request: Request): Promise<Response> => {
  return await match(request);
};

export const networkFirst = async (request: Request): Promise<Response> => {
  try {
    var networkResponse = await fetch(request);
  } catch (err) {
    return cacheOnly(request);
  }

  await put(request, networkResponse.clone());
  return networkResponse;
};
