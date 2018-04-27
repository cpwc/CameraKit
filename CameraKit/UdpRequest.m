#import "UdpRequest.h"
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <ifaddrs.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <sys/socket.h>
#import <arpa/inet.h>
#include <netdb.h>

@interface UdpRequest ()

@property CFSocketRef sendSocket;
@property CFSocketRef listenSocket;
@property bool didReceiveSsdp;
@property (strong, nonatomic) NSThread *timeoutThread;
@end

static NSMutableArray *_deviceUuidList;
static CompletionBlock _block;

@implementation UdpRequest

int _SSDP_RECEIVE_TIMEOUT = 10; // seconds
int _SSDP_PORT = 1900;
int _SSDP_MX = 1;

//for malticast messages
NSString* _SSDP_ADDR = @"239.255.255.250";
NSString* _SSDP_ST = @"urn:schemas-sony-com:service:ScalarWebAPI:1";

- (id)init {
    if (self = [super init]) {
        _deviceUuidList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    //release static variable
    _deviceUuidList = nil;
    _block = nil;
}

- (void)execute:(CompletionBlock)block {
    _block = block;
    _didReceiveSsdp = false;
    self.timeoutThread = [[NSThread alloc] initWithTarget:self selector:@selector(timeout) object:nil];
    [_timeoutThread start];
    [self listen];
}

- (void)stop {
    CFRunLoopRef rl = CFRunLoopGetCurrent();
    CFRunLoopStop(rl);
}

-(void)timeout
{
    int i = 0;
    while((i < _SSDP_RECEIVE_TIMEOUT) && ![_timeoutThread isCancelled]) {
        sleep(1);
        i++;
    }
    
    if(CFSocketIsValid(_sendSocket)) {
        _sendSocket = NULL;
    }
    
    if(CFSocketIsValid(_listenSocket)) {
        _listenSocket = NULL;
    }
    
    if(!_didReceiveSsdp) {
        _block(nil, nil);
    }
}

- (void)listen {
    
    _sendSocket = [self createSocket:_sendSocket];
    if(!_sendSocket) {
        return;
    }
    
    // SSDP protocol: discovery request
    NSString* _message = [NSString stringWithFormat:@"M-SEARCH * HTTP/1.1\r\nHOST:%@:%d\r\nMAN:\"ssdp:discover\"\r\nMX:%d\r\nST:%@\r\n\r\n", _SSDP_ADDR,_SSDP_PORT,_SSDP_MX,_SSDP_ST];
    CFDataRef data = CFDataCreate(NULL, (const UInt8*)[_message UTF8String], [_message lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    
    /* Set the port and address we want to send to */
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr([_SSDP_ADDR UTF8String]);
    addr.sin_port = htons(_SSDP_PORT);
    
    NSData *address = [NSData dataWithBytes:&addr length:sizeof(addr)];
    
    if(CFSocketSendData(_sendSocket, (__bridge CFDataRef)address, data, 0.0) == kCFSocketSuccess) {
        NSLog(@"UdpRequest callCFSocket Sending data");
    }
    
    _listenSocket = [self createSocket:_listenSocket];
    if(!_listenSocket) {
        CFRelease(data);
        return;
    }
    
    /* Set the port and address we want to listen on */
    if (CFSocketSetAddress(_listenSocket, (__bridge CFDataRef)(address)) != kCFSocketSuccess) {
        NSLog(@"UdpRequest callCFSocket CFSocketSetAddress() failed\n = %d", errno);
    }
    
    // Listen from socket
    CFRunLoopSourceRef cfSourceSend = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _sendSocket, 0);
    CFRunLoopSourceRef cfSourceListen = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _listenSocket, 0);
    
    if(cfSourceSend == NULL && cfSourceListen == NULL){
        NSLog(@"UdpRequest callCFSocket CFRunLoopSourceRef is null");
        CFRelease(_sendSocket);
        CFRelease(_listenSocket);
        CFRelease(data);
        return;
    }
    
    if(cfSourceSend != NULL) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSourceSend, kCFRunLoopDefaultMode);
        CFRelease(cfSourceSend);
    }
    
    if(cfSourceListen != NULL) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSourceListen, kCFRunLoopDefaultMode);
        CFRelease(cfSourceListen);
    }
    
    CFRelease(_sendSocket);
    CFRelease(_listenSocket);
    CFRelease(data);
    CFRunLoopRun();
    NSLog(@"UdpRequest callCFSocket CFRunLoopRun finish");
    
}

- (CFSocketRef)createSocket:(CFSocketRef)socket {
    CFSocketContext socketContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
    
    socket = CFSocketCreate(NULL, PF_INET, SOCK_DGRAM, IPPROTO_UDP,
                            kCFSocketAcceptCallBack | kCFSocketDataCallBack , (CFSocketCallBack)receiveData, &socketContext);

    if(socket == NULL) {
        NSLog(@"UDP socket could not be created");
        return socket;
    }
    
    CFSocketSetSocketFlags(socket, kCFSocketCloseOnInvalidate);
    
    struct ip_mreq mreq;
    mreq.imr_multiaddr.s_addr = inet_addr([_SSDP_ADDR UTF8String]);
    mreq.imr_interface.s_addr = inet_addr([[self getIPAddress]UTF8String]);
    
    if(setsockopt(CFSocketGetNative(socket), IPPROTO_IP, IP_ADD_MEMBERSHIP, (const void *)&mreq, sizeof(struct ip_mreq))) {
        NSLog(@"UdpRequest callCFSocket IP_ADD_MEMBERSHIP error");
        return nil;
    }
    return socket;
}

void receiveData(CFSocketRef s,
                 CFSocketCallBackType type,
                 CFDataRef address,
                 const void *data,
                 void *info)
{
    if(data)
    {
        NSString* response = [[NSString alloc] initWithData:(__bridge NSData *)((CFDataRef)data) encoding:NSUTF8StringEncoding];
        NSLog(@"UdpRequest CFSocket receiveData response = %@", response);
        
        UdpRequest *udpRequest = (__bridge UdpRequest *)info;
        NSString* ddUrl = [udpRequest parseDdUrl:response];
        if(ddUrl != NULL)
        {
            ddUrl = [ddUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        
        NSString* uuid = [udpRequest parseUuid:response];
        if(uuid != NULL)
        {
            uuid = [uuid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        
        NSLog(@"UdpRequest CFSocket receiveData didReceiveDdUrl = %@", ddUrl);
        
        if(![_deviceUuidList containsObject:uuid])
        {
            if(uuid != NULL)
            {
                [_deviceUuidList addObject:uuid];
                NSLog(@"UdpRequest CFSocket receiveData uuid = %@", uuid);
            }
            
            _block(ddUrl, _deviceUuidList);
        }
        CFSocketInvalidate(s);
    }
}

- (NSString*)parseDdUrl:(NSString*)response {
    NSString* ret = NULL;
    if(response == NULL) {
        return ret;
    }
    
    NSArray* first = [response componentsSeparatedByString:@"LOCATION:"];
    if(first!=nil && first.count == 2)
    {
        NSArray* second = [first[1] componentsSeparatedByString:@"\r\n"];
        if(second!=nil && second.count >= 2)
        {
            if(![second[0] isEqualToString:@""])
            {
                ret = second[0];
                _didReceiveSsdp = true;
            }
        }
    }
    return ret;
}

- (NSString*)parseUuid:(NSString*)response {
    NSString* ret = NULL;
    if(response == NULL)
    {
        return ret;
    }
    NSArray* first = [response componentsSeparatedByString:@"USN:"];
    if(first!=nil && first.count == 2)
    {
        NSArray* second = [first[1] componentsSeparatedByString:@":"];
        if(second!=nil && second.count >= 2)
        {
            if(![second[1] isEqualToString:@""])
            {
                ret = second[1];
            }
        }
    }
    return ret;
}

- (NSString *)getIPAddress {
    NSString *address = @"0.0.0.0";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                NSLog(@"UdpRequest getIPAddress NIF = %@", @(temp_addr->ifa_name));
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([@(temp_addr->ifa_name) isEqualToString:@"en0"])
                {
                    address = @(inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr));
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    NSLog(@"UdpRequest getIPAddress = %@", address);
    return address;
}

@end
