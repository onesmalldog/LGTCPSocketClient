//
//  LGReceiveManager.h
//  DTCheck
//
//  Created by 东途 on 2017/1/11.
//  Copyright © 2017年 李振刚. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark define your string

@class LGTCPSocketClient;

@protocol LGReceiveDelegate <NSObject>
- (void)receiveDidShutdownSocket;
- (void)receiveDidReceiveData:(UInt8 *)buf header:(CommonHeader)header;
@end

@interface LGReceiveManager : NSObject

@property (weak, nonatomic) id <LGReceiveDelegate> delegate;
+ (instancetype)receiveWithSocket:(LGTCPSocketClient *)socket;
- (void)startReceive;
@end
