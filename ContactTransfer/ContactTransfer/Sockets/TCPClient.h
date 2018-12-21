
#import <Foundation/Foundation.h>


#define NEW_ERROR(num, str) [[NSError alloc] initWithDomain:@"FastSocketErrorDomain" code:(num) userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%s", (str)] forKey:NSLocalizedDescriptionKey]]

@interface TCPClient : NSObject

#pragma mark - Properties


@property (nonatomic, readonly) NSError *lastError;

#pragma mark - Initializers


- (BOOL)configureClientSocketWithPort:(NSString *)_port Ip:(NSString *) _host;

- (BOOL)sendBytes:(NSData *) buf;
@end
