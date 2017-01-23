//
//  LGReceiveManager.m
//  DTCheck
//
//  Created by 东途 on 2017/1/11.
//  Copyright © 2017年 李振刚. All rights reserved.
//

#import "LGReceiveManager.h"
#import "LGTCPSocketClient.h"

@interface LGReceiveManager()
@property (strong, nonatomic) NSMutableData *headerData;
@property (strong, nonatomic) NSMutableData *bodyData;
@end
@implementation LGReceiveManager {
    
    LGTCPSocketClient *_socket;
    
    dispatch_queue_t _receiveQueue;
    dispatch_queue_t _analyzeQueue;
    
    dispatch_semaphore_t _receiveQueueSem;
    dispatch_semaphore_t _analyzeSem;
    BOOL _headerFinish;
}

+ (instancetype)receiveWithSocket:(LGTCPSocketClient *)socket {
    return [[self alloc] initWithSocket:socket];
}
- (instancetype)initWithSocket:(LGTCPSocketClient *)socket {
    if (self = [super init]) {
        if (!socket) {
            return nil;
        }
        _socket = socket;
    }
    return self;
}

- (void)startReceive {
    [self startReceiveQueue];
}

- (void)startReceiveQueue {
    
    if (!_receiveQueue) {
        _receiveQueue = dispatch_queue_create("recsktq", DISPATCH_QUEUE_SERIAL);
        dispatch_async(_receiveQueue, ^{
            if (!_receiveQueueSem) {
                _receiveQueueSem = dispatch_semaphore_create(0);
            }
            if (!_analyzeSem) {
                _analyzeSem = dispatch_semaphore_create(0);
            }
            
            UInt8 *buf = malloc(8*1024);
            
            
#warning Set your Common header            
            // your common header
            size_t headerSize = sizeof(CommonHeader);
            CommonHeader header = {0};
            
            
            
            
            while (1) {
                if (!_socket.isConnected) {
                    dispatch_semaphore_wait(_receiveQueueSem, DISPATCH_TIME_FOREVER);
                }
                
                size_t len = [_socket receiveWithSize:headerSize buffer:(UInt8 *)&header];
                if (len != headerSize) {
                    [self disConnectSocket];
                    continue;
                }
                
                if (![self validateCommomHeader:header]) {
                    [self disConnectSocket];
                    continue;
                }
                
                header.length = ntohl(header.length);
                if (header.length > 1024*1024) {
                    [self disConnectSocket];
                    continue;
                }
                
                if (header.length > 0) {
                    len = [_socket receiveWithSize:header.length buffer:buf];
                    if (len != header.length) {
                        [self disConnectSocket];
                        continue;
                    }
                }
                
                if ([self.delegate respondsToSelector:@selector(receiveDidReceiveData:header:)]) {
                    [self.delegate receiveDidReceiveData:buf header:header];
                }
                
                
                continue;
                
                switch (header.type) {
                    case 0: { //
                        NSLog(@"%s", buf);
                    } break;
                    case 1: { //
                        NSLog(@"%s", buf);
                        NSData *data = [NSData dataWithBytes:buf length:header.length];
                        NSError *error;
                        NSString *dict = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        
                        NSLog(@"%@", dict);
                        if (error) {
                            
                        }
                    } break;
                    case 2: {
                        NSLog(@"%s", buf);
                    } break;
                        
                    default: {
                        [_socket disConnectTCP];
                        continue;
                    } break;
                }
                
                
                continue;
                if (!_headerFinish) {
                    [self.headerData appendBytes:buf length:sizeof(buf)];
                }
                else {
                    [self.bodyData appendBytes:buf length:sizeof(buf)];
                }
                dispatch_semaphore_signal(_analyzeSem);
            }
            free(buf);
            buf = NULL;
        });
    }
    else {
        if (_receiveQueueSem) {
            dispatch_semaphore_signal(_receiveQueueSem);
        }
    }
}

- (void)disConnectSocket {
    [_socket disConnectTCP];
    if ([self.delegate respondsToSelector:@selector(receiveDidShutdownSocket)]) {
        [self.delegate receiveDidShutdownSocket];
    }
}

- (BOOL)validateCommomHeader:(CommonHeader)header {
    if (header.flag != 0xEE) {
        return false;
    }
    if (header.version != 0) {
        return false;
    }
    
    if (header.type > 2 || header.type < 0) {
        return false;
    }
    return true;
}
- (void)clearMuData:(NSMutableData *)data {
    [data resetBytesInRange:NSMakeRange(0, data.length)];
    [data setLength:0];
}

- (NSMutableData *)headerData {
    if (!_headerData) {
        _headerData = [NSMutableData dataWithLength:6];
    }
    return _headerData;
}
- (NSMutableData *)bodyData {
    if (!_bodyData) {
        _bodyData = [NSMutableData dataWithLength:8192];
    }
    return _bodyData;
}
@end
