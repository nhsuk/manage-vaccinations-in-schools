import { openDB, DBSchema } from "idb";

type StoreName = "cachedResponses" | "delayedRequests";

interface RequestObject {
  id?: number;
  url: string;
  body: any;
}

interface OfflineDatabase extends DBSchema {
  delayedRequests: {
    key: number;
    value: RequestObject;
    indexes: { url: string };
  };
  cachedResponses: {
    key: number;
    value: RequestObject;
    indexes: { url: string };
  };
}

const DB_NAME = "offline";
const DB_VERSION = 2;

const openTx = async (storeName: StoreName, mode: "readwrite" | "readonly") => {
  const db = await openDB<OfflineDatabase>(DB_NAME, DB_VERSION, {
    upgrade(db) {
      const delayedStore = db.createObjectStore("delayedRequests", {
        keyPath: "id",
        autoIncrement: true,
      });

      delayedStore.createIndex("url", "url", { unique: false });

      const cachedStore = db.createObjectStore("cachedResponses", {
        keyPath: "id",
        autoIncrement: true,
      });

      cachedStore.createIndex("url", "url", { unique: true });
    },
  });

  return db.transaction(storeName, mode);
};

export const add = async (storeName: StoreName, url: string, body: any) => {
  const tx = await openTx(storeName, "readwrite");
  const request = await tx.store.index("url").get(url);

  if (storeName === "cachedResponses" && request) {
    await tx.store.put({ ...request, body });
  } else {
    await tx.store.add({ url, body });
  }

  await tx.done;
};

export const destroy = async (storeName: StoreName, id: number) => {
  const tx = await openTx(storeName, "readwrite");
  await tx.store.delete(id);
  await tx.done;
};

export const getByUrl = async (
  storeName: StoreName,
  url: string
): Promise<RequestObject | undefined> => {
  const tx = await openTx(storeName, "readonly");
  const request = await tx.store.index("url").get(url);
  await tx.done;

  return request;
};

export const getAll = async (
  storeName: StoreName
): Promise<RequestObject[]> => {
  const tx = await openTx(storeName, "readonly");
  const requests = await tx.store.getAll();
  await tx.done;

  return requests;
};
