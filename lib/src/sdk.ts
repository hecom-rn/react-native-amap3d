import { NativeModules, Platform } from "react-native";

const { AMapSdk } = NativeModules;

export function init(apiKey?: string) {
  if (Platform.OS === 'ios') {
    AMapSdk.setApiKey(apiKey); // iOS 不能使用init方法
  } else {
    AMapSdk.init(apiKey);
  }
}

export function getVersion(): Promise<string> {
  return AMapSdk.getVersion();
}
