import Foundation

public typealias APIResponseClosure = (json:NSDictionary, isSucceeded:Bool) -> ()

public enum APIList: NSString {
    
    // server information
    case GetAvailableApiList = "getAvailableApiList"
    case GetApplicationInfo = "getApplicationInfo"
    case GetEvent = "getEvent"
    case GetVersions = "getVersions"
    case GetMethodTypes = "getMethodTypes"
    
    //shoot api
    case GetShootMode = "getShootMode"
    case SetShootMode = "setShootMode"
    case GetAvailableShootMode = "getAvailableShootMode"
    case GetSupportedShootMode = "getSupportedShootMode"
    
    //liveview api
    case StartLiveview = "startLiveview"
    case StopLiveview = "stopLiveview"
    case ActTakePicture = "actTakePicture"
    case ActZoom = "actZoom"
    
    //shutter api
    case ActHalfPressShutter = "actHalfPressShutter"
    case CancelHalfPressShutter = "cancelHalfPressShutter"
    
    //af position api
    case SetTouchAfPosition = "setTouchAFPosition"
    case GetTouchAfPosition = "getTouchAFPosition"
    case CancelTouchAfPosition = "cancelTouchAFPosition"
    
    //exposure mode api
    case SetExposureMode = "setExposureMode"
    case GetExposureMode = "getExposureMode"
    case GetSupportedExposureMode = "getSupportedExposureMode"
    case GetAvailableExposureMode = "getAvailableExposureMode"
    
    //iso spped rate api
    case SetIsoSpeedRate = "setIsoSpeedRate"
    case GetIsoSpeedRate = "getIsoSpeedRate"
    case GetSupportedIsoSpeedRate = "getSupportedIsoSpeedRate"
    case GetAvailableIsoSpeedRate = "getAvailableIsoSpeedRate"
    
    //white balance api
    case SetWhiteBalance = "setWhiteBalance"
    case GetWhiteBalance = "getWhiteBalance"
    case GetSupportedWhiteBalance = "getSupportedWhiteBalance"
    case GetAvailableWhiteBalance = "getAvailableWhiteBalance"
    
    //still size api
    case GetStillSize = "getStillSize"
    case SetStillSize = "setStillSize"
    case GetSupportedStillSize = "getSupportedStillSize"
    case GetAvailableStillSize = "getAvailableStillSize"
    
    //postview api
    case GetPostviewImageSize = "getPostviewImageSize"
    case SetPostviewImageSize = "setPostviewImageSize"
    case GetSupportedPostviewImageSize = "getSupportedPostviewImageSize"
    case GetAvailablePostviewImageSize = "getAvailablePostviewImageSize"
    
    //beepmode api
    case GetBeepMode = "getBeepMode"
    case SetBeepMode = "setBeepMode"
    case GetSupportedBeepMode = "getSupportedBeepMode"
    case GetAvailableBeepMode = "getAvailableBeepMode"
}

public class API {

    var device:Device
    
    var id:Int
    
    init(device:Device) {
        self.device = device
        self.id = 1
    }
    
    // MARK: - serverinformation methods
    public func getAvailableApiList() -> NSData? {
        var url = self.device.findActionListUrl("camera")
        var params = self.createRequestJson(APIList.GetAvailableApiList)
        return self.call(url, postParams:params)
    }
    
    public func getApplicationInfo() -> NSData? {
        var url = self.device.findActionListUrl("camera")
        var params = self.createRequestJson(APIList.GetApplicationInfo)
        return self.call(url, postParams:params)
    }
    
    public func getVersions() -> NSData? {
        var url = self.device.findActionListUrl("camera")
        var params = self.createRequestJson(APIList.GetVersions)
        return self.call(url, postParams:params)
    }

    public func getMethodTypes(version:NSString, closure:APIResponseClosure) {
        var params = "[\"\(version)\"]"
        createPostRequest(APIList.GetMethodTypes, params:params, closure:closure)
    }

    public func getEvent(longPolling:Bool, closure:APIResponseClosure) {
        var param = longPolling ? "true" : "false"
        var params = "[\(param)]"
        createPostRequest(APIList.GetEvent, params:params, closure:closure)
    }

    // MARK: - Zoom methods
    public func startZoomIn(closure:APIResponseClosure) {
        var params = "[\"in\",\"start\"]"
        createPostRequest(APIList.ActZoom, params:params, closure:closure)
    }

    public func stopZoomIn(closure:APIResponseClosure) {
        var params = "[\"in\",\"stop\"]"
        createPostRequest(APIList.ActZoom, params:params, closure:closure)
    }

    public func startZoomOut(closure:APIResponseClosure) {
        var params = "[\"out\",\"start\"]"
        createPostRequest(APIList.ActZoom, params:params, closure:closure)
    }
    
    public func stopZoomOut(closure:APIResponseClosure) {
        var params = "[\"out\",\"stop\"]"
        createPostRequest(APIList.ActZoom, params:params, closure:closure)
    }

    // MARK: - StillSize methods
    public func getSupportedStillSize(closure:APIResponseClosure) {
        createGetRequest(APIList.GetSupportedStillSize, closure:closure)
    }

    public func getAvailableStillSize(closure:APIResponseClosure) {
        createGetRequest(APIList.GetAvailableStillSize, closure:closure)
    }
    
    public func getStillSize(closure:APIResponseClosure) {
        createGetRequest(APIList.GetStillSize, closure:closure)
    }

    public func setStillSize(aspect:NSString, size:NSString, closure:APIResponseClosure) {
        var params = "[\"\(aspect)\",\"\(size)\"]"
        createPostRequest(APIList.SetStillSize, params:params, closure:closure)
    }

    // MARK: - PostView methods
    public func getSupportedPostviewImageSize(closure:APIResponseClosure) {
        createGetRequest(APIList.GetSupportedPostviewImageSize, closure:closure)
    }
    
    public func getAvailablePostviewImageSize(closure:APIResponseClosure) {
        createGetRequest(APIList.GetAvailablePostviewImageSize, closure:closure)
    }
    
    public func getPostviewImageSize(closure:APIResponseClosure) {
        createGetRequest(APIList.GetPostviewImageSize, closure:closure)
    }
    
    public func setPostviewImageSize(size:NSString, closure:APIResponseClosure) {
        var params = "[\"\(size)\"]"
        createPostRequest(APIList.SetPostviewImageSize, params:params, closure:closure)
    }

    // MARK: - StillCapture methods
    public func actTakePicture(closure:APIResponseClosure) {
        createGetRequest(APIList.ActTakePicture, closure:closure)
    }
  
    // MARK: - HalfPress methods
    public func actHalfPressShutter(closure:APIResponseClosure) {
        createGetRequest(APIList.ActHalfPressShutter, closure:closure)
    }

    public func cancelHalfPressShutter(closure:APIResponseClosure) {
        createGetRequest(APIList.CancelHalfPressShutter, closure:closure)
    }
    
    // MARK: - TouchAF methods
    public func setTouchAFPosition(x:CGFloat, y:CGFloat, closure:APIResponseClosure) {
        var params = "[\(x), \(y)]"
        createPostRequest(APIList.SetTouchAfPosition, params:params, closure:closure)
    }
    
    public func getTouchAFPosition(closure:APIResponseClosure) {
        createGetRequest(APIList.GetTouchAfPosition, closure:closure)
    }

    public func cancelTouchAFPosition(closure:APIResponseClosure) {
        createGetRequest(APIList.CancelTouchAfPosition, closure:closure)
    }
    
    // MARK: - ExposureMode methods
    public func getSupportedExposureMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetSupportedExposureMode, closure:closure)
    }
    
    public func getAvailableExposureMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetAvailableExposureMode, closure:closure)
    }
    
    public func getExposureMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetExposureMode, closure:closure)
    }
    
    public func setExposureMode(mode:NSString, closure:APIResponseClosure) {
        var params = "[\"\(mode)\"]"
        createPostRequest(APIList.SetExposureMode, params:params, closure:closure)
    }
    
    // MARK: - IsoSpeedRate methods
    public func getSupportedIsoSpeedRate(closure:APIResponseClosure) {
        createGetRequest(APIList.GetSupportedIsoSpeedRate, closure:closure)
    }
    
    public func getAvailableIsoSpeedRate(closure:APIResponseClosure) {
        createGetRequest(APIList.GetAvailableIsoSpeedRate, closure:closure)
    }
    
    public func getIsoSpeedRate(closure:APIResponseClosure) {
        createGetRequest(APIList.GetIsoSpeedRate, closure:closure)
    }
    
    public func setIsoSpeedRate(rate:NSString, closure:APIResponseClosure) {
        var params = "[\"\(rate)\"]"
        createPostRequest(APIList.SetIsoSpeedRate, params:params, closure:closure)
    }

    // MARK: - WhiteBalance methods
    public func getSupportedWhiteBalance(closure:APIResponseClosure) {
        createGetRequest(APIList.GetSupportedWhiteBalance, closure:closure)
    }
    
    public func getAvailableWhiteBalance(closure:APIResponseClosure) {
        createGetRequest(APIList.GetAvailableWhiteBalance, closure:closure)
    }
    
    public func getWhiteBalance(closure:APIResponseClosure) {
        createGetRequest(APIList.GetWhiteBalance, closure:closure)
    }
    
    public func setWhiteBalance(balance:NSString, closure:APIResponseClosure) {
        var params = "[\"\(balance)\"]"
        createPostRequest(APIList.SetWhiteBalance, params:params, closure:closure)
    }

    // MARK: - Shoot methods
    public func getSupportedShootMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetSupportedShootMode, closure:closure)
    }
    
    public func getAvailableShootMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetAvailableShootMode, closure:closure)
    }
    
    public func getShootMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetShootMode, closure:closure)
    }
    
    public func setShootMode(mode:NSString, closure:APIResponseClosure) {
        var params = "[\"\(mode)\"]"
        createPostRequest(APIList.SetShootMode, params:params, closure:closure)
    }
    
    // MARK: - LiveView methods
    public func startLiveView() -> NSData {
        var url = self.device.findActionListUrl("camera")
        var params = self.createRequestJson(APIList.StartLiveview)
        return self.call(url, postParams:params)
    }

    public func stopLiveView() -> NSData {
        var url = self.device.findActionListUrl("camera")
        var params = self.createRequestJson(APIList.StopLiveview)
        return self.call(url, postParams:params)
    }

    // MARK: - BeepMode methods
    public func getSupportedBeepMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetSupportedBeepMode, closure:closure)
    }
    
    public func getAvailableBeepMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetAvailableBeepMode, closure:closure)
    }
    
    public func getBeepMode(closure:APIResponseClosure) {
        createGetRequest(APIList.GetBeepMode, closure:closure)
    }

    public func setBeepMode(mode:NSString, closure:APIResponseClosure) {
        var params = "[\"\(mode)\"]"
        createPostRequest(APIList.SetBeepMode, params:params, closure:closure)
    }

    // MARK: - Private methods
    func getId() -> Int {
        return self.id++
    }
    
    func createGetRequest(api:APIList, closure:APIResponseClosure) {
        var params = self.createRequestJson(api)
        self.createAsynchronousRequest(api, params:params, closure:closure)
    }

    func createPostRequest(api:APIList, params:NSString, closure:APIResponseClosure) {
        var params = self.createRequestJson(api, params:params)
        self.createAsynchronousRequest(api, params:params, closure:closure)
    }
    
    func createAsynchronousRequest(api:APIList, params:NSString, closure:APIResponseClosure) {
        var url = self.device.findActionListUrl("camera")
        var request = HttpAsynchronousRequest(url:url, postParams:params, apiName:api.rawValue, closure:closure)
        request.execute()
    }
    
    func createRequestJson(method:APIList) -> NSString {
        return self.createRequestJson(method, params:"[]")
    }

    func createRequestJson(method:APIList, params:NSString) -> NSString {
        var version = "1.0"
        var json = NSString(format:"{ \"method\":\"%@\",\"params\":%@,\"version\":\"%@\",\"id\":%d }", method.rawValue, params, version, self.getId())
        return json
    }

    func call(url:NSString, postParams params:NSString) -> NSData {
        
        var url = NSURL(string:url)
        var request = NSMutableURLRequest(URL:url!, cachePolicy:NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60.0)
        request.HTTPMethod = "POST"
        request.HTTPBody = params.dataUsingEncoding(NSUTF8StringEncoding)
        
        var response:NSURLResponse? = nil
        var error:NSError? = nil
        var data = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&error)

        return data!
    }
    
}