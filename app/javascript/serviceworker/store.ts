import { openDB, DBSchema } from "idb";

interface RequestObject {
  id?: number;
  url: string;
  body: any;
}

interface OfflineDatabase extends DBSchema {
  delayedRequests: {
    key: number;
    value: RequestObject;
  };
}

interface Db {
  createObjectStore: (
    arg0: string,
    arg1: { keyPath: string; autoIncrement: boolean }
  ) => void;
}

const DB_NAME = "offline";
const DB_VERSION = 1;

const openTx = async (mode: "readwrite" | "readonly") => {
  const db = await openDB<OfflineDatabase>(DB_NAME, DB_VERSION, {
    upgrade(db: Db) {
      db.createObjectStore("delayedRequests", {
        keyPath: "id",
        autoIncrement: true,
      });
    },
  });

  return db.transaction("delayedRequests", mode);
};

export const saveRequest = async (url: string, body: any) => {
  const tx = await openTx("readwrite");
  await tx.store.add({ url, body });
  await tx.done;
};

export const deleteRequest = async (id: number) => {
  const tx = await openTx("readwrite");
  await tx.store.delete(id);
  await tx.done;
};

export const getAllRequests = async (): Promise<RequestObject[]> => {
  const tx = await openTx("readonly");
  const requests = await tx.store.getAll();
  await tx.done;

  return requests;
};
