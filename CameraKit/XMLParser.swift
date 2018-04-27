import Foundation

class XMLParser: NSObject, NSXMLParserDelegate {
    
    var devices:NSMutableArray
    
    var parseStatus:NSInteger
    
    var isCameraDevice:Bool
    
    var isParsingService:Bool

    var parser:NSXMLParser?
    
    var closure:((devices:NSArray) -> ())?
    
    var device:Device?
    
    var currentServiceName:NSString?
    
    override init() {
        self.devices = NSMutableArray()
        self.parseStatus = -1
        self.isCameraDevice = false
        self.isParsingService = false
    }
    
    func execute(url:NSString, closure:((devices:NSArray) -> ())) {
        self.closure = closure
        
        var request = NSMutableURLRequest(URL:NSURL(string:url)!)
        var xmlData = NSURLConnection.sendSynchronousRequest(request, returningResponse:nil, error:nil)
        var parser = NSXMLParser(data:xmlData)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false
        parser.shouldResolveExternalEntities = false
        self.parser = parser
        self.parser!.parse()
    }
    
    func parserDidStartDocument(parser:NSXMLParser!) {
        NSLog("XML File found and parsing started");
    }
    
    func parser(parser:NSXMLParser!, parseErrorOccurred parseError:NSError!) {
        var errorString = NSString(format: "Error Code %li", parseError.code)
        NSLog("Error: parsing XML: %@", errorString);
    }
    
    func parser(parser:NSXMLParser!, didStartElement elementName:String!, namespaceURI:String!, qualifiedName qName:String!, attributes attributeDict: [NSObject : AnyObject]!) {
        
        if(elementName == "device") {
            self.device = Device()
            self.isCameraDevice = false
        }
        else if(elementName == "friendlyName") {
            self.parseStatus = 0
        }
        else if(elementName == "av:X_ScalarWebAPI_Version") {
            self.parseStatus = 1
        }
        else if(elementName == "av:X_ScalarWebAPI_Service") {
            self.isParsingService = true
        }
        else if(elementName == "av:X_ScalarWebAPI_ServiceType") {
            self.parseStatus = 2
        }
        else if(elementName == "av:X_ScalarWebAPI_ActionList_URL") {
            self.parseStatus = 3
        }
    }
    
    func parser(parser:NSXMLParser!, foundCharacters string:String!) {
        if(self.parseStatus == 0) {
            self.device?.friendlyName = string
        }
        else if(self.parseStatus == 1) {
            self.device?.version = string
        }
        else if(self.parseStatus == 2 && self.isParsingService) {
            self.currentServiceName = string
            if(self.currentServiceName! == "camera") {
                self.isCameraDevice = true
            }
        }
        else if(self.parseStatus == 3 && self.isParsingService) {
            self.device?.addService(serviceName:self.currentServiceName!, serviceUrl:string)
            self.currentServiceName = nil
        }
    }
    
    func parser(parser:NSXMLParser!, didEndElement elementName:String!, namespaceURI:String!, qualifiedName qName:String!) {
        
        if(elementName == "device") {
            if(self.isCameraDevice) {
                self.devices.addObject(self.device!)
            }
            self.isCameraDevice = false
        }
        else if(elementName == "friendlyName") {
            self.parseStatus = -1
        }
        else if(elementName == "av:X_ScalarWebAPI_Version") {
            self.parseStatus = -1
        }
        else if(elementName == "av:X_ScalarWebAPI_Service") {
            self.isParsingService = false
        }
        else if(elementName == "av:X_ScalarWebAPI_ServiceType") {
            self.parseStatus = -1
        }
        else if(elementName == "av:X_ScalarWebAPI_ActionList_URL") {
            self.parseStatus = -1
        }
    }
    
    func parserDidEndDocument(parser:NSXMLParser!) {
        self.closure!(devices:self.devices)
    }

}