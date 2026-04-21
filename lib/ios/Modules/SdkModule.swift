@objc(AMapSdk)
class AMapSdk: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool {
    false
  }

  @objc func setApiKey(_ apiKey: String) {
    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)
    AMapServices.shared().apiKey = apiKey
  }
  
  @objc func getVersion(_ resolve: RCTPromiseResolveBlock, reject _: RCTPromiseRejectBlock) {
    resolve("9.7.0")
  }
}
