const desiredCapConstraints = {
  systemPort: {
    isNumber: true
  },
  showServerLogs: {
    isBoolean: true
  },
  bootstrapRoot: {
    isString: true
  },
  depsLoadTimeout: {
    isNumber: true
  },
  serverStartupTimeout: {
    isNumber: true
  },
  bundleId: {
    isString: true
  },
  arguments: {
    isArray: true
  },
  environment: {
    isObject: true
  },
  skipAppKill: {
    isBoolean: true
  }
};

export { desiredCapConstraints };
