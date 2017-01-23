//
//  LGTCPSocketClient.h
//  text3
//
//  Created by 东途 on 2016/11/2.
//  Copyright © 2016年 displayten. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef const char cString;
typedef const void cData;

typedef enum : NSUInteger {
    LGTCPSocketClientErrorTypeNONE = 0, // none error
    LGTCPSocketClientErrorTypeOPEN,
    LGTCPSocketClientErrorTypeCONNECT,
    LGTCPSocketClientErrorTypeSEND,
    LGTCPSocketClientErrorTypeSETOPT,
    LGTCPSocketClientErrorTypeTIMEOUT,
} LGTCPSocketClientErrorType;

@interface LGTCPSocketClient : NSObject

/** send tcp recive */
@property (assign, readonly, nonatomic) ssize_t result;

/** get is or not connected to tcp server */
@property (assign, readonly, nonatomic) BOOL isConnected;

/** get socket descriptor */
@property (assign, readonly, nonatomic) int socket_desc;

@property (copy, nonatomic) void(^socketDidDisconnected)(int result);

@property (copy, nonatomic) void(^socketDidReciveMessage)(char *buf);

/** initialized */
+ (instancetype)lg_tcpSocketClientWithIP:(cString *)ip port:(int)port;
- (instancetype)initWithIP:(cString *)ip port:(int)port;

/** connected to tcp server */
- (LGTCPSocketClientErrorType)connect;

/** send message to server */
- (ssize_t)sendTCP:(cData *)cdata length:(long)length;

/** send message from objc data to server */
- (void)sendTCPWithData:(NSData *)data;

/** disconnect to tcp server */
- (void)disConnectTCP;

/** set heartbeat */
- (LGTCPSocketClientErrorType)heartbeat;

- (size_t)receiveWithSize:(size_t)size buffer:(UInt8 *)buf;
//- (void *)receiveTCPWithSize:(unsigned long)size;
@end
