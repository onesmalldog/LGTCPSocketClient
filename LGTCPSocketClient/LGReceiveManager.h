//
//  LGReceiveManager.h
//  DTCheck
//
//  Created by 东途 on 2017/1/11.
//  Copyright © 2017年 李振刚. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma pack(1)
typedef struct common_header_s {
    unsigned char   flag;  
    UInt8           type:3;
    UInt8           version:5;
    UInt32          length;
} CommonHeader;

typedef struct packet_header_s {
    UInt8		  type; 
    UInt32		length; 
    UInt8     verify_code[32];
    UInt32		param1;
    UInt32		param2;
} PacketHeader;
#pragma pack()

#pragma mark define your string
#define REP_FILE_NAME @""
#define REP_FILE_HANDLE @""
#define REP_FILE_SIZE @""
#define REP_FILE_VERSION @""
#define REP_CODE @""
#define REP_TYPE @""
#define REP_ERROR_CODE @""
#define REP_ERROR_MESSAGE ""


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
