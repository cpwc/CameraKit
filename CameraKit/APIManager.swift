import UIKit

public class APIManager: NSObject {
   
    public var api:API?

    public var liveManager:LiveManager
    
    public var isCameraIdle:Bool

    public var isSupportedVersion:Bool
    
    public var apiList:NSArray?
    
    public var fetchImageClosure:((image:UIImage, error:NSError) -> ())?
    
    override public init() {
        self.liveManager = LiveManager()
        self.isCameraIdle = true
        self.isSupportedVersion = false
        super.init()
    }

    //call this method after calling openConnection
    public func startLiveImage(closure:(image:UIImage, error:NSError?) -> ()) -> Bool {
        self.fetchImageClosure = closure
        
        if(!self.isApiAvailable(APIList.StartLiveview)) {
            return false
        }
        
        if(!self.liveManager.isStarted) {
            var response = self.api!.startLiveView()
            
            dispatch_async(dispatch_get_main_queue(), { [unowned self] in
                var array = self.parseResponse(response)
                var liveViewUrl = array![0] as NSString
                NSLog("liveViewUrl is %@", liveViewUrl)
                
                self.liveManager.start(liveViewUrl, closure:{(image:UIImage) -> () in
                    closure(image:image, error:nil)
                })
            });
        }
        return true
    }

    // open connection method finds available devices and get information
    public func openConnection(closure:(result:Bool, error:NSError?) -> ()) {
        
        self.discoveryDevices({[unowned self] (devices:NSArray?, error:NSError?) -> () in
            if(devices != nil && devices!.count != 0) {
                
                //use first device
                self.api = API(device:devices!.firstObject as Device)
                var result = self.getInformation()
                
                if(result) {
                    self.callEventAPI(true)
                    closure(result:true, error:nil)
                } else {
                    var error = self.createError("couldn't open connection")
                    closure(result:false, error:error)
                }
                
            } else {
                closure(result:false, error:error)
            }
        })
    }
    
    // find available device by parsing XML file from  Camera
    public func discoveryDevices(closure:(devices:NSArray?, error:NSError?) -> ()) {
        
        var request:UdpRequest = UdpRequest()
        request.execute({[unowned self] (ddUrl:String!, uuId:[AnyObject]!) -> () in

            if(ddUrl != nil) {
                var parser = XMLParser()
            
                parser.execute(ddUrl, closure:{[unowned self] (devices:NSArray) -> () in
                    
                    if(devices.count != 0) {
                        closure(devices:devices, error:nil)
                    } else {
                        var error = self.createError("device not found")
                        closure(devices:nil, error:error)
                    }
                })
            } else {
                var error = self.createError("ddUrl not found")
                closure(devices:nil, error:error)
            }
        })
    }

    // get information, like api list, app info from server
    public func getInformation() -> Bool {

        // get available api list
        var response = self.api?.getAvailableApiList()
        if(response == nil) {
            return false
        }

        var result:NSArray? = self.parseResponse(response!)
        if(result == nil) {
            return false
        }
        
        self.apiList = result![0] as? NSArray;
        
        // get application info
        if(!self.isApiAvailable(APIList.GetApplicationInfo)) {
            return false
        }
        response = self.api?.getApplicationInfo()
        if(response == nil) {
            return false
        }
        
        result = self.parseResponse(response!)
        if(result == nil || result!.count == 0) {
            return false
        }
        
        var serverName = result![0] as NSString
        var serverVersion = result![1] as NSString
        //NSLog("parseGetApplicationInfo serverName = %@", serverName);
        //NSLog("parseGetApplicationInfo serverVersion = %@", serverVersion);
        self.isSupportedVersion = self.isSupportedServerVersion(serverVersion);

        return self.isSupportedVersion
    }
    
    public func callEventAPI(longPolling:Bool) {
        self.api?.getEvent(longPolling, closure:{ [unowned self] (json:NSDictionary, isSucceeded:Bool) -> () in
            var array = json.objectForKey("result") as? NSArray
            var dic = array?.objectAtIndex(1) as? NSDictionary
            if(dic != nil) {
                var status = dic!.objectForKey("cameraStatus") as NSString
                self.isCameraIdle = status.isEqualToString("IDLE")
            }
        })
    }
    
    // the api method to take picture
    public func takePicture(closure:APIResponseClosure) {
        
        if(self.isCameraIdle) {
            
            self.api?.actTakePicture(closure)
        } else {
            
            self.api?.getEvent(false, closure:{ [unowned self] (json:NSDictionary, isSucceeded:Bool) in
                var array = json.objectForKey("result") as? NSArray
                var dic = array?.objectAtIndex(1) as? NSDictionary
                var status = dic?.objectForKey("cameraStatus") as? NSString
                
                if(status != nil){
                    self.isCameraIdle = status!.isEqualToString("IDLE")
                    if(self.isCameraIdle) {
                        self.api?.actTakePicture(closure)
                        return
                    }
                }
                
                closure(json:NSDictionary(), isSucceeded:false)
            })
        }
    }
    
    // get UIImage from takePicture's response
    public func didTakePicture(json:NSDictionary) -> UIImage? {
        var array = json.objectForKey("result") as? NSArray
        var endpoint = (array?.objectAtIndex(0) as? NSArray)?.objectAtIndex(0) as? NSString
        if(endpoint == nil) {
            return nil
        }
        
        var url = NSURL(string:endpoint!)
        var data = NSData(contentsOfURL:url!)
        return (data != nil) ? UIImage(data:data!) : nil
    }
    
    public func parseResponse(response:NSData) -> NSArray? {
        
        var e:NSError?
        var dict:NSDictionary = NSJSONSerialization.JSONObjectWithData(response, options:NSJSONReadingOptions.MutableContainers, error:&e) as NSDictionary
        
        var resultArray:NSArray?;
        
        if(e != nil) {
            NSLog("parseResponse error parsing JSON string")
            
        } else {
            resultArray = dict["result"] as NSArray?
            var errorArray = dict["error"] as NSArray?
            if(errorArray != nil) {
                NSLog("parseResponse has error")
            }
        }

        return resultArray
    }
    
    public func isApiAvailable(api:APIList) -> Bool {
        if(self.apiList != nil && self.apiList!.count > 0 && self.apiList!.containsObject(api.rawValue)) {
            return true
        } else {
            return false
        }
    }
    
    public func isSupportedServerVersion(version:NSString) -> Bool {
        var versionModeList = version.componentsSeparatedByString(".") as NSArray
        if(versionModeList.count > 0) {
            var major:CLong = versionModeList[0].integerValue
            if(2 <= major) {
                NSLog("this version is supported")
                return true
            } else {
                NSLog("this version is not supported")
            }
        }
        
        return false
    }
    
    public func createError(message:NSString) -> NSError {
        var error = NSError(domain:"com.camera", code:35, userInfo:[NSLocalizedDescriptionKey:message])
        return error
    }
    
}
