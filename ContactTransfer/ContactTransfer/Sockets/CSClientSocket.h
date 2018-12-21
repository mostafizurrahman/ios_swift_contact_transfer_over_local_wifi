
#import <Foundation/Foundation.h>


#define NEW_ERROR(num, str) [[NSError alloc] initWithDomain:@"CSSocketErrorDomain"\
code:(num) userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%s",\
(str)] forKey:NSLocalizedDescriptionKey]]

@interface CSClientSocket : NSObject

#pragma mark - Properties

@property (nonatomic, readonly) int client_socket;
@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSString *port;
@property (nonatomic, readonly) NSError *lastError;

#pragma mark - Initializers


- (instancetype)initWithHost:(NSString *)remoteHost
                        port:(NSString *)remotePort;

- (instancetype)initWithFileDescriptor:(int)socket_descriptor;

- (void)getBuffer:(char *)outBuffer size:(long *)outSize;

#pragma mark - Actions

- (BOOL)connect;

- (BOOL)connect:(long)timeout;

- (BOOL)close;

- (long)sendBytes:(const char *)sendBuffer
           length:(const long)dataLength;

- (long)receiveBytes:(void *)outBuffer
              length:(const long)dataLength;
@end
