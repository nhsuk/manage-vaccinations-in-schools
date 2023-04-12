import { add, getByUrl } from "./store";

const urlOf = (request: RequestInfo): string => new Request(request).url;

export const addAll = async (requests: RequestInfo[]): Promise<void> => {
  const responses = await Promise.all(
    requests.map((request) => fetch(request))
  );

  await Promise.all(
    requests.map((request, index) => put(urlOf(request), responses[index]))
  );
};

export const match = async (
  request: RequestInfo
): Promise<Response | undefined> => {
  const requestObject = await getByUrl("cachedResponses", urlOf(request));
  return requestObject ? new Response(requestObject.body) : undefined;
};

export const put = async (
  request: RequestInfo,
  response: Response
): Promise<void> => {
  const body = await response.clone().blob();
  return await add("cachedResponses", urlOf(request), body);
};
