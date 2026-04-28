@objc(AMapSdk)
class AMapSdk: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool {
    false
  }

  @objc func initSDK(_ apiKey: String) {
    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)
    AMapServices.shared().apiKey = apiKey
    MAMapView.updatePrivacyAgree(AMapPrivacyAgreeStatus.didAgree)
    MAMapView.updatePrivacyShow(AMapPrivacyShowStatus.didShow, privacyInfo: AMapPrivacyInfoStatus.didContain)
  }
  
  @objc func getVersion(_ resolve: RCTPromiseResolveBlock, reject _: RCTPromiseRejectBlock) {
    resolve("9.7.0")
  }
}
