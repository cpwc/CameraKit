import Foundation

class HttpAsynchronousRequest:NSObject {
    
    var apiName:NSString
    
    var receiveData:NSMutableData
    
    var closure:APIResponseClosure
    
    var url:NSString
    
    var params:NSString
    
    init(url:NSString, postParams params:NSString, apiName name:NSString, closure:APIResponseClosure) {
        self.receiveData = NSMutableData()
        self.url = url
        self.params = params
        self.apiName = name
        self.closure = closure
    }
    
    func execute(){
        var url = NSURL(string:self.url)
        var request = NSMutableURLRequest(URL:url!, cachePolicy:NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval:10.0)
        request.HTTPMethod = "POST"
        request.HTTPBody = self.params.dataUsingEncoding(NSUTF8StringEncoding)
        
        var connection = NSURLConnection(request:request, delegate:self, startImmediately:false)
        connection!.start()
    }
    
    func connection(connection:NSURLConnection, didReceiveResponse response:NSURLResponse) {
        self.receiveData.length = 0
    }
    
    func connection(connection:NSURLConnection, didReceiveData data:NSData) {
        self.receiveData.appendData(data)
    }

    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        NSLog("HttpRequest didFailWithError = %@", error)
        var errorResponse = "{ \"id\"= 0 , \"error\"=[16,\"Transport Error\"]}"
        var data = errorResponse.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

        var e:NSError?
        var dict = NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers, error:&e) as NSDictionary
        self.closure(json:dict, isSucceeded:false)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        var e:NSError?
        var dict = NSJSONSerialization.JSONObjectWithData(self.receiveData, options:NSJSONReadingOptions.MutableContainers, error: &e) as NSDictionary
        self.closure(json:dict, isSucceeded:true)
    }

}