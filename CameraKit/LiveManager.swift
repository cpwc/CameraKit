import UIKit

public class LiveManager: NSObject {

    var isStarted:Bool
    
    var receiveData:NSMutableData
    
    var closure:((image:UIImage) -> ())?
    
    var connection:NSURLConnection?
    
    override public init() {
        self.isStarted = false
        self.receiveData = NSMutableData()
    }
    
    public func start(liveviewUrl:NSString, closure:(image:UIImage) -> ()) {
        
        if(!self.isStarted) {
            self.isStarted = true
            self.closure = closure
            var url = NSURL(string:liveviewUrl)
            
            var request = NSMutableURLRequest(URL:url!, cachePolicy:NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 60.0)
            request.HTTPMethod = "GET"
            
            self.connection = NSURLConnection(request:request, delegate:self, startImmediately:true)
            self.connection!.start()
        }
    }
    
    // MARK: - NSURLConnectionDelegate methods
    func connection(connection:NSURLConnection, didReceiveResponse response:NSURLResponse) {
        synchronized(self) {
            self.receiveData.length = 0
        }
        NSThread.detachNewThreadSelector("getPackets", toTarget:self, withObject:nil)
    }
    
    func connection(connection:NSURLConnection, didReceiveData data:NSData) {
        synchronized(self) {
            self.receiveData.appendData(data)
        }
    }
    
    func connection(connection:NSURLConnection, didFailWithError error:NSError) {
    }
    
    func connectionDidFinishLoading(connection:NSURLConnection) {
    }
    
    // MARK: - Private
    func getPackets() {
        while(self.isStarted) {
            autoreleasepool {
                self.getJpegPacket()
            }
        }
    }
    
    func getJpegPacket() {
        var bytes = UnsafeMutablePointer<UInt8>.alloc(8)
        
        // remove 8 bytes common header
        self.removeBytes(8)
        
        // read for JPEG image
        self.getPayload()
    }
    
    func getPayload() {
        var jpegDataSize = 0
        var jpegPaddingSize = 0
        
        // check for first 4 bytes
        self.checkPayloadHeader(nil)
        
        // get jpeg data size
        var jData = UnsafeMutablePointer<UInt8>.alloc(3)
        self.readBytes(3, buffer:jData)
        jpegDataSize = self.bytesToInt(jData, count:3)
        
        // get jpeg padding size
        var jPadding = UnsafeMutablePointer<UInt8>.alloc(1)
        self.readBytes(1, buffer:jPadding)
        jpegPaddingSize = self.bytesToInt(jPadding, count:1)
        
        // remove reserved bytes
        self.removeBytes(120)
        
        // read jpeg image
        var jpegData = UnsafeMutablePointer<UInt8>.alloc(jpegDataSize)
        self.readBytes(jpegDataSize, buffer:jpegData)
    
        var imageData = NSData(bytes:jpegData, length:jpegDataSize)
        var image = UIImage(data:imageData)
        
        if(self.isJPEGValid(imageData)) {
            self.closure?(image: image!)
        }
     
        // remove padding data
        self.removeBytes(jpegPaddingSize)
    }

    func isJPEGValid(data:NSData) -> Bool {
    
        if(data.length < 2) {
            return false
        }
        var bytes = UnsafePointer<UInt8>(data.bytes)
        return bytes[0] == 0xff && bytes[1] == 0xd8
    }
    
    //check for payload first 4 bytes
    func checkPayloadHeader(buffer:UnsafeMutablePointer<UInt8>) {
        
        // wait until get more than 4 bytes
        while(true) {
            var isValid = true
            synchronized(self) {
                if(self.receiveData.length < 4) {
                    isValid = false
                }
            }
            if(isValid) {
                break
            }
            
            sleep(UInt32(0.01))
        }
        
        var startCodes = UnsafeMutablePointer<UInt8>.alloc(4)
        startCodes[0] = 0x24
        startCodes[1] = 0x35
        startCodes[2] = 0x68
        startCodes[3] = 0x79
        
        var startData = NSData(bytes:startCodes, length:4)
        var isFound = false
        var found:NSRange = NSMakeRange(0,4)
        
        //find start code from receving data
        synchronized(self) {
            found = self.receiveData.rangeOfData(startData, options:NSDataSearchOptions.Anchored, range:found)
        }
        
        // if found, remove the bytes
        if(found.location != NSNotFound) {
            synchronized(self) {
                self.receiveData.replaceBytesInRange(NSMakeRange(0,4), withBytes:nil, length:0)
            }
            return
        }
        
        while(!isFound) {
            var maxRangeLength:CLong = 0
            synchronized(self) {
                maxRangeLength = self.receiveData.length
            }
            var currentRange:NSRange = NSMakeRange(0, maxRangeLength)
            
            synchronized(self) {
                found = self.receiveData.rangeOfData(startData, options:NSDataSearchOptions.Backwards, range:currentRange)
            }
            if(found.location != NSNotFound) {
                var lastFound:NSRange = found
                isFound = true
                synchronized(self) {
                    self.receiveData.replaceBytesInRange(NSMakeRange(0,lastFound.location + 4), withBytes:nil, length:0)
                }
            } else {
                sleep(UInt32(0.01))
            }
        }
    }
    
    func readBytes(length:NSInteger, buffer:UnsafeMutablePointer<UInt8>) {
        self.wait(length)
        synchronized(self) {
            self.receiveData.getBytes(buffer, length:length)
            self.receiveData.replaceBytesInRange(NSMakeRange(0,length), withBytes:nil, length:0)
        }
    }

    func removeBytes(length:NSInteger) {
        self.wait(length)
        synchronized(self) {
            self.receiveData.replaceBytesInRange(NSMakeRange(0,length), withBytes:nil, length:0)
        }
    }
    
    func wait(length:NSInteger) {

        while(true) {
            var isValid = false
            synchronized(self) {
                if(self.receiveData.length > length) {
                    isValid = true
                }
            }
            
            if(isValid) {
                break
            }
            sleep(UInt32(0.5))
        }
    }
    
    func bytesToInt(bytes:UnsafeMutablePointer<UInt8>, count:NSInteger) -> NSInteger {
        var val:NSInteger = 0
        for(var i=0; i<count; i++) {
            val = (val << 8) | NSInteger((bytes[i] & 0xff))
        }
        return val
    }
    
    // the implementation of @synchronized in swift
    func synchronized(obj: AnyObject, closure:() -> ()) {
        objc_sync_enter(obj)
        closure()
        objc_sync_exit(obj)
    }
}