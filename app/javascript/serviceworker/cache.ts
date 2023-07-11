import { SimpleCrypto } from "./simple-crypto";
import { add, getByUrl } from "./store";

let secret: SimpleCrypto;

const encryptBlob = async (blob: Blob): Promise<Blob> => {
  const encrypted = await secret.encrypt(await blob.text());
  return new Blob([encrypted], { type: blob.type });
};

const decryptBlob = async (blob: Blob): Promise<Blob> => {
  const decrypted = await secret.decrypt(await blob.text());
  return new Blob([decrypted], { type: blob.type });
};

const urlOf = (request: RequestInfo): string => new Request(request).url;

export const init = async (passphrase: string) => {
  secret = new SimpleCrypto(passphrase, "my-salt");
  await secret.init();
};

export const addAll = async (requests: RequestInfo[]): Promise<void> => {
  const responses = await Promise.all(
    requests.map((request) => fetch(request)),
  );

  await Promise.all(
    requests.map((request, index) => put(urlOf(request), responses[index])),
  );
};

export const match = async (
  request: RequestInfo,
): Promise<Response | undefined> => {
  const requestObject = await getByUrl("cachedResponses", urlOf(request));
  if (!requestObject) return undefined;

  const decryptedBlob = await decryptBlob(requestObject.body);
  return new Response(decryptedBlob);
};

export const put = async (
  request: RequestInfo,
  response: Response,
): Promise<void> => {
  const body = await response.clone().blob();
  const encryptedBlob = await encryptBlob(body);
  return await add("cachedResponses", urlOf(request), encryptedBlob);
};
