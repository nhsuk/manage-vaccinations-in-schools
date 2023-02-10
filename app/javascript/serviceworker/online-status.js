let online = true;

export const setOfflineMode = () => (online = false);

export const setOnlineMode = () => (online = true);

export const toggleOnlineStatus = () => {
  return online ? setOfflineMode() : setOnlineMode();
};

export const checkOnlineStatus = () => online;
