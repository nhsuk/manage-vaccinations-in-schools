import { match, put } from "./cache";

export const cacheOnly = async (request: Request): Promise<Response> => {
  return await match(request, { ignoreVary: true });
};

export const networkFirst = async (request: Request): Promise<Response> => {
  try {
    const networkResponse = await fetch(request);
    await put(request, networkResponse.clone());
    return networkResponse;
  } catch (err) {
    return cacheOnly(request);
  }
};
