//
//  LGQueueManager.h
//  DTENShare
//
//  Created by 东途 on 2017/1/7.
//  Copyright © 2017年 displayten. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    LGQueueTypeSerial = 1,
    LGQueueTypeConcurrent,
} LGQueueType;

typedef enum : NSUInteger {
    LGQueueSequenceNew = 1,
    LGQueueSequenceOld,
} LGQueueSequence;

@interface LGQueueManager : NSObject

@property (assign, nonatomic) LGQueueType queueType;
+ (instancetype)sharedManager;
- (dispatch_queue_t)createQueueWithDoingBlock:(void(^)(NSData *data))block withSequence:(LGQueueSequence)seq clearElse:(BOOL)clear;
- (void)putData:(NSData *)data inQueue:(dispatch_queue_t)queue;
- (NSArray <NSData *>*)getDatasFromQueue:(dispatch_queue_t)queue;

- (void)pauseQueue:(dispatch_queue_t)queue;
- (void)pauseAllQueue;

- (void)clearDatasInQueue:(dispatch_queue_t)queue;
- (void)clearAllData;
@end
