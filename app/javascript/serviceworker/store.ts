import { openDB, DBSchema } from "idb";

interface RequestObject {
  id?: number;
  url: string;
  data: any;
}

interface OfflineDatabase extends DBSchema {
  requests: {
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
      db.createObjectStore("requests", {
        keyPath: "id",
        autoIncrement: true,
      });
    },
  });

  return db.transaction("requests", mode);
};

export const saveRequest = async (url: string, request: Request) => {
  const requestData = await request.formData();
  const data = Object.fromEntries(requestData);

  const tx = await openTx("readwrite");
  await tx.store.add({ url, data });
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
