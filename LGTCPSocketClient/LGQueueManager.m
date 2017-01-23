//
//  LGQueueManager.m
//  DTENShare
//
//  Created by 东途 on 2017/1/7.
//  Copyright © 2017年 displayten. All rights reserved.
//

#import "LGQueueManager.h"

@implementation LGQueueManager {
    int _queue_count;
    NSCondition *_condition;
    NSMutableArray *_blocks;
    NSMutableArray *_sems;
    NSMutableArray *_datasArray;
    BOOL _isStart;
}
+ (instancetype)sharedManager {
    static LGQueueManager *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self alloc] init];
    });
    return mgr;
}
- (void)pauseQueue:(dispatch_queue_t)queue {
    if (!queue) {
        return;
    }
//    int index = [self getQueueIndex:queue];
    
}
- (void)pauseAllQueue {
    
}
- (dispatch_queue_t)createQueueWithDoingBlock:(void(^)(NSData *data))block withSequence:(LGQueueSequence)seq clearElse:(BOOL)clear {
    if (!self.queueType) {
        self.queueType = LGQueueTypeSerial;
    }
    if (!_blocks) {
        _blocks = [NSMutableArray array];
    }
    if (!_sems) {
        _sems = [NSMutableArray array];
    }
    if (!_datasArray) {
        _datasArray  = [NSMutableArray array];
    }
    if (!seq) {
        seq = LGQueueSequenceNew;
    }
    
    [_datasArray insertObject:[NSMutableArray array] atIndex:_queue_count];
    [_blocks insertObject:block atIndex:_queue_count];
    [_sems insertObject:dispatch_semaphore_create(0) atIndex:_queue_count];
    NSString *qname = [NSString stringWithFormat:@"lgqct%d", _queue_count];
    
    _queue_count++;
    dispatch_queue_t queue;
    switch (self.queueType) {
        case LGQueueTypeSerial: {
            queue = dispatch_queue_create(qname.UTF8String, DISPATCH_QUEUE_SERIAL);
            [self doQueueInWhile:queue withSequence:seq clearElse:clear];
            return queue;
        } break;
        case LGQueueTypeConcurrent: {
            queue = dispatch_queue_create(qname.UTF8String, DISPATCH_QUEUE_CONCURRENT);
            [self doQueueInWhile:queue withSequence:seq clearElse:clear];
            return queue;
        } break;
            
        default:
            break;
    }
}
- (void)doQueueInWhile:(dispatch_queue_t)queue withSequence:(LGQueueSequence)seq clearElse:(BOOL)clear {
    dispatch_async(queue, ^{
        int index = [self getQueueIndex:queue];
        if (index < 0) {
            return;
        }
        while (1) {
            dispatch_semaphore_wait([_sems objectAtIndex:index], DISPATCH_TIME_FOREVER);
            void(^block)(NSData *dat) = [_blocks objectAtIndex:index];
            if (block) {
                NSMutableArray *datas = [_datasArray objectAtIndex:index];
                @autoreleasepool {
                    NSData *data;
                    @synchronized (datas) {
                        switch (seq) {
                            case LGQueueSequenceNew: {
                                data = datas.firstObject;
                            } break;
                            case LGQueueSequenceOld: {
                                data = datas.lastObject;
                            } break;
                        }
                    }
//                    NSLog(@"当前队列的个数%ld", datas.count);
                    block(data);
                    @synchronized (datas) {
                        if (clear) {
                            [datas removeAllObjects];
                        }
                        else {
                            [datas removeObject:data];
                        }
                    }
                }
            }
        }
    });
}
- (void)putData:(NSData *)data inQueue:(dispatch_queue_t)queue {
    int index = [self getQueueIndex:queue];
    if (index < 0) {
        return;
    }
    NSMutableArray *datas = [_datasArray objectAtIndex:index];
    @synchronized (datas) {
        if (!datas) {
            datas = [NSMutableArray array];
        }
        [datas insertObject:data atIndex:0];
    }
    dispatch_semaphore_t sem = [_sems objectAtIndex:index];
    dispatch_semaphore_signal(sem);
}

- (NSArray<NSData *> *)getDatasFromQueue:(dispatch_queue_t)queue {
    if (!queue) {
        return nil;
    }
    int index = [self getQueueIndex:queue];
    return [_datasArray objectAtIndex:index];
}
- (void)clearDatasInQueue:(dispatch_queue_t)queue {
    if (!queue) {
        return;
    }
    int index = [self getQueueIndex:queue];
    @autoreleasepool {
        NSMutableArray *datas = [_datasArray objectAtIndex:index];
        @synchronized (datas) {
            [datas removeAllObjects];
        }
    }
}
- (void)clearAllData {
    @autoreleasepool {
        for (NSMutableArray *datas in _datasArray) {
            @synchronized (datas) {
                [datas removeAllObjects];
            }
        }
    }
}

- (int)getQueueIndex:(dispatch_queue_t)queue {
    @synchronized (self) {
        if (!queue) return -1;
        const char *qlabel = dispatch_queue_get_label(queue);
        NSString *queueLabel = [NSString stringWithUTF8String:qlabel];
        if (![queueLabel hasPrefix:@"lgqct"]) {
            return -1;
        }
        NSString *count = [queueLabel substringWithRange:NSMakeRange(5, 1)];
        return count.intValue;
    }
}
@end
