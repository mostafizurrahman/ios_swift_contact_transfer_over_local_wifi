
#import <Foundation/Foundation.h>


#define NEW_ERROR(num, str) [[NSError alloc] initWithDomain:@"CSSocketErrorDomain"\
code:(num) userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%s",\
(str)] forKey:NSLocalizedDescriptionKey]]

@interface CSClientSocket : NSObject

#pragma mark - Properties

@property (nonatomic, readonly) int socket_descriptor;
@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSString *port;
@property (nonatomic, readonly) NSError *lastError;

#pragma mark - Initializers


- (id)initWithHost:(NSString *)host andPort:(NSString *)port __attribute__((nonnull));

- (id)initWithFileDescriptor:(int)fd;

- (void)buffer:(void **)buf size:(long *)size __attribute__((nonnull));

#pragma mark - Actions

- (BOOL)connect;

- (BOOL)connect:(long)timeout;

- (BOOL)close;

- (long)sendBytes:(const void *)buf count:(long)count __attribute__((nonnull));

- (long)receiveBytes:(void *)buf limit:(long)limit __attribute__((nonnull));
@end
