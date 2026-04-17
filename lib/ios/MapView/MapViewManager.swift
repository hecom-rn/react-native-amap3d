@objc(AMapViewManager)
class AMapViewManager: RCTViewManager {
  override class func requiresMainQueueSetup() -> Bool { true }

  override func view() -> UIView {
    return MapView()
  }

  @objc func moveCamera(_ reactTag: NSNumber, position: NSDictionary, duration: Int) {
    getView(reactTag: reactTag) { view in
      view.moveCamera(position: position, duration: duration)
    }
  }

  @objc func call(_ reactTag: NSNumber, callerId: Double, name: String, args: NSDictionary) {
    getView(reactTag: reactTag) { view in
      view.call(id: callerId, name: name, args: args)
    }
  }

  func getView(reactTag: NSNumber, callback: @escaping (MapView) -> Void) {
    DispatchQueue.main.async {
      if let view = MapView.registry.object(forKey: reactTag) {
        callback(view)
      }
    }
  }
}

// 使用包装器模式而非直接继承 MAMapView，避免 AMap SDK 内部调用 setNeedsLayout
// 在 Fabric 新架构 layout pass 中将 Yoga 节点标记为 dirty，触发
// react_native_assert(!childYogaNode->isDirty()) 断言崩溃
class MapView: UIView, MAMapViewDelegate {
  static let registry = NSMapTable<NSNumber, MapView>.strongToWeakObjects()

  let innerMap: MAMapView

  override var reactTag: NSNumber! {
    didSet {
      if let tag = reactTag {
        MapView.registry.setObject(self, forKey: tag)
      }
    }
  }

  var initialized = false
  var overlayMap: [MABaseOverlay: Overlay] = [:]
  var markerMap: [MAPointAnnotation: Marker] = [:]

  @objc var onLoad: RCTBubblingEventBlock = { _ in }
  @objc var onCameraMove: RCTBubblingEventBlock = { _ in }
  @objc var onCameraIdle: RCTBubblingEventBlock = { _ in }
  @objc var onPress: RCTBubblingEventBlock = { _ in }
  @objc var onPressPoi: RCTBubblingEventBlock = { _ in }
  @objc var onLongPress: RCTBubblingEventBlock = { _ in }
  @objc var onLocation: RCTBubblingEventBlock = { _ in }
  @objc var onCallback: RCTBubblingEventBlock = { _ in }

  @objc var mapType: MAMapType {
    get { innerMap.mapType }
    set { innerMap.mapType = newValue }
  }

  @objc var showsUserLocation: Bool {
    get { innerMap.showsUserLocation }
    set { innerMap.showsUserLocation = newValue }
  }

  @objc var showsBuildings: Bool {
    get { innerMap.isShowsBuildings }
    set { innerMap.isShowsBuildings = newValue }
  }

  @objc var showTraffic: Bool {
    get { innerMap.isShowTraffic }
    set { innerMap.isShowTraffic = newValue }
  }

  @objc var showsIndoorMap: Bool {
    get { innerMap.isShowsIndoorMap }
    set { innerMap.isShowsIndoorMap = newValue }
  }

  @objc var showsCompass: Bool {
    get { innerMap.showsCompass }
    set { innerMap.showsCompass = newValue }
  }

  @objc var showsScale: Bool {
    get { innerMap.showsScale }
    set { innerMap.showsScale = newValue }
  }

  @objc var scrollEnabled: Bool {
    get { innerMap.isScrollEnabled }
    set { innerMap.isScrollEnabled = newValue }
  }

  @objc var zoomEnabled: Bool {
    get { innerMap.isZoomEnabled }
    set { innerMap.isZoomEnabled = newValue }
  }

  @objc var rotateEnabled: Bool {
    get { innerMap.isRotateEnabled }
    set { innerMap.isRotateEnabled = newValue }
  }

  @objc var rotateCameraEnabled: Bool {
    get { innerMap.isRotateCameraEnabled }
    set { innerMap.isRotateCameraEnabled = newValue }
  }

  @objc var minZoomLevel: Double {
    get { Double(innerMap.minZoomLevel) }
    set { innerMap.minZoomLevel = CGFloat(newValue) }
  }

  @objc var maxZoomLevel: Double {
    get { Double(innerMap.maxZoomLevel) }
    set { innerMap.maxZoomLevel = CGFloat(newValue) }
  }

  @objc var distanceFilter: Double {
    get { innerMap.distanceFilter }
    set { innerMap.distanceFilter = newValue }
  }

  @objc var headingFilter: Double {
    get { Double(innerMap.headingFilter) }
    set { innerMap.headingFilter = CGFloat(newValue) }
  }

  override init(frame: CGRect) {
    innerMap = MAMapView(frame: .zero)
    super.init(frame: frame)
    // 禁用 autoresizingMask，完全由 layoutSubviews 手动管理 frame，
    // 避免 Auto Layout 在 Fabric layout pass 中触发 setNeedsLayout 导致断言崩溃
    innerMap.translatesAutoresizingMaskIntoConstraints = false
    addSubview(innerMap)
    innerMap.delegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    innerMap.frame = bounds
  }

  @objc func setInitialCameraPosition(_ json: NSDictionary) {
    if !initialized {
      initialized = true
      moveCamera(position: json)
    }
  }

  func moveCamera(position: NSDictionary, duration: Int = 0) {
    let status = MAMapStatus()
    status.zoomLevel = (position["zoom"] as? Double)?.cgFloat ?? innerMap.zoomLevel
    status.cameraDegree = (position["tilt"] as? Double)?.cgFloat ?? innerMap.cameraDegree
    status.rotationDegree = (position["bearing"] as? Double)?.cgFloat ?? innerMap.rotationDegree
    status.centerCoordinate = (position["target"] as? NSDictionary)?.coordinate ?? innerMap.centerCoordinate
    innerMap.setMapStatus(status, animated: true, duration: Double(duration) / 1000)
  }

  func call(id: Double, name: String, args: NSDictionary) {
    switch name {
    case "getLatLng":
      callback(id: id, data: innerMap.convert(args.point, toCoordinateFrom: innerMap).json)
    default:
      break
    }
  }

  func callback(id: Double, data: [String: Any]) {
    onCallback(["id": id, "data": data])
  }

  override func didAddSubview(_ subview: UIView) {
    if let overlay = (subview as? Overlay)?.getOverlay() {
      overlayMap[overlay] = subview as? Overlay
      innerMap.add(overlay)
    }
    if let annotation = (subview as? Marker)?.annotation {
      markerMap[annotation] = subview as? Marker
      innerMap.addAnnotation(annotation)
    }
  }

  override func removeReactSubview(_ subview: UIView!) {
    super.removeReactSubview(subview)
    if let overlay = (subview as? Overlay)?.getOverlay() {
      overlayMap.removeValue(forKey: overlay)
      innerMap.remove(overlay)
    }
    if let annotation = (subview as? Marker)?.annotation {
      markerMap.removeValue(forKey: annotation)
      innerMap.removeAnnotation(annotation)
    }
  }

  func mapView(_: MAMapView, rendererFor overlay: MAOverlay) -> MAOverlayRenderer? {
    if let key = overlay as? MABaseOverlay {
      return overlayMap[key]?.getRenderer()
    }
    return nil
  }

  func mapView(_: MAMapView!, viewFor annotation: MAAnnotation) -> MAAnnotationView? {
    if let key = annotation as? MAPointAnnotation {
      return markerMap[key]?.getView()
    }
    return nil
  }

  func mapView(_: MAMapView!, annotationView view: MAAnnotationView!, didChange newState: MAAnnotationViewDragState, fromOldState _: MAAnnotationViewDragState) {
    if let key = view.annotation as? MAPointAnnotation {
      let market = markerMap[key]!
      if newState == MAAnnotationViewDragState.starting {
        market.onDragStart(nil)
      }
      if newState == MAAnnotationViewDragState.dragging {
        market.onDrag(nil)
      }
      if newState == MAAnnotationViewDragState.ending {
        market.onDragEnd(view.annotation.coordinate.json)
      }
    }
  }

  func mapView(_: MAMapView!, didAnnotationViewTapped view: MAAnnotationView!) {
    if let key = view.annotation as? MAPointAnnotation {
      markerMap[key]?.onPress(nil)
    }
  }

  func mapInitComplete(_: MAMapView!) {
    onLoad(nil)
  }

  func mapView(_: MAMapView!, didSingleTappedAt coordinate: CLLocationCoordinate2D) {
    onPress(coordinate.json)
  }

  func mapView(_: MAMapView!, didTouchPois pois: [Any]!) {
    let poi = pois[0] as! MATouchPoi
    onPressPoi(["name": poi.name!, "id": poi.uid!, "position": poi.coordinate.json])
  }

  func mapView(_: MAMapView!, didLongPressedAt coordinate: CLLocationCoordinate2D) {
    onLongPress(coordinate.json)
  }

  func mapViewRegionChanged(_: MAMapView!) {
    onCameraMove(innerMap.cameraEvent)
  }

  func mapView(_: MAMapView!, regionDidChangeAnimated _: Bool) {
    onCameraIdle(innerMap.cameraEvent)
  }

  func mapView(_: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation _: Bool) {
    onLocation(userLocation.json)
  }
}
