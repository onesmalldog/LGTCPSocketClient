//
//  LGTCPSocketClient.m
//  text3
//
//  Created by 东途 on 2016/11/2.
//  Copyright © 2016年 displayten. All rights reserved.
//

#import "LGTCPSocketClient.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <signal.h>

#include <strings.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <memory.h>
#include <sys/ioctl.h>
#include <netinet/tcp.h>

#define ONE_KB 1024
#define LG_TCP_CONNECT_INVALID @"LG_TCP_CONNECT_INVALID"


@implementation LGTCPSocketClient {
    cString *           _ip;
    int                 _port;
    int                 _socket_descriptor;
    struct sockaddr_in  _client_addr;
    __block BOOL        _canSend;
    ssize_t             _sresult;
    
    dispatch_queue_t _socketAliveQ;
    dispatch_queue_t _socketRecvQ;
    
    char *_buf;
}
- (BOOL)isConnected {
    return _canSend;
}
- (int)socket_desc {
    return _socket_descriptor;
}
// 链接断开
- (void)invalidConnected:(NSNotification *)noti {
    [self connect];
}
- (void)dealloc {
    [self disConnectTCP];
}
- (void)disConnectTCP {
    _canSend = false;
    shutdown(_socket_descriptor, SHUT_RDWR);
    //    close(_socket_descriptor);
    _socket_descriptor = 0;
    NSLog(@"断开socket链接");
}
+ (instancetype)lg_tcpSocketClientWithIP:(cString *)ip port:(int)port {
    return [[self alloc] initWithIP:ip port:port];
    
    //    static LGTCPSocketClient *socket;
    //    if (socket) {
    //        [socket connect];
    //    }
    //    static dispatch_once_t onceToken;
    //    dispatch_once(&onceToken, ^{
    //        socket = [[self alloc] initWithIP:ip port:port];
    //    });
    //    return socket;
}

- (instancetype)initWithIP:(cString *)ip port:(int)port {
    if (self = [super init]) {
        
        //        [self initliazedTCPSocketWithIP:ip port:port];
        _ip = ip;
        _port = port;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidConnected:) name:LG_TCP_CONNECT_INVALID object:nil];
    }
    return self;
}

- (LGTCPSocketClientErrorType)initliazedTCPSocketWithIP:(cString *)ip port:(int)port {
    
    _ip = ip;
    _port = port;
    
    bzero(&_client_addr,sizeof(_client_addr));
    _client_addr.sin_family = AF_INET;
    //htonl()将主机的无符号长整形数转换成网络字节顺序
    _client_addr.sin_addr.s_addr = inet_addr(ip);//htonl(INADDR_ANY);//s_addr按照网络字节顺序存储IP地址
    //in_addr 32位的IPv4地址  h_addr_list中的第一地址
    //pin.sin_addr.s_addr=((struct in_addr *)(server_host_name->h_addr))->s_addr;// 跟书上不一样 必须是h_addr
    
    _client_addr.sin_port = htons(port);
    
    /*申请一个通信端口*/
    if (!_socket_descriptor) {
        
        if((_socket_descriptor = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))==-1) {
            perror("Error opening socket \n");
            return LGTCPSocketClientErrorTypeOPEN;
        }
    }
    
    //    int res = bind(_socket_descriptor, (const struct sockaddr *)&_client_addr, sizeof(_client_addr));
    
    int  set = 1;
    int res = setsockopt(_socket_descriptor, SOL_SOCKET, SO_NOSIGPIPE, (void  *)&set, sizeof(int));
    
    
    // Disable the Nagle (TCP No Delay) algorithm
    int flag = 1;
    res = setsockopt(_socket_descriptor, IPPROTO_TCP, TCP_NODELAY, (char *)&flag, sizeof(flag));
    
    //    int res = fcntl(_socket_descriptor,F_SETFL,fcntl(_socket_descriptor,F_GETFL,0) | O_NONBLOCK);
    
    // 手动设置发送和接收 socket 缓冲区大小
    /*
     * BDP = link_bandwidth * RTT
     
     * 如果应用程序是通过一个 100Mbps 的局域网进行通信，其 RRT 为 50 ms，那么 BDP 就是：
     
     * 100MBps * 0.050 sec / 8 = 0.625MB = 625KB
     */
    
    
    int ret, sock_buf_size;
    sock_buf_size = 8*1024;//BDP;
    ret = setsockopt( _socket_descriptor, SOL_SOCKET, SO_SNDBUF, (char *)&sock_buf_size, sizeof(sock_buf_size) );
    ret = setsockopt( _socket_descriptor, SOL_SOCKET, SO_RCVBUF, (char *)&sock_buf_size, sizeof(sock_buf_size) );
    
    
    //    unsigned long ul = 5;
    //    ioctl(_socket_descriptor, FIONBIO, &ul); //设置为非阻塞模式
    
    
    //    LGTCPSocketClientErrorType type = [self connect];
    //    if (type != LGTCPSocketClientErrorTypeNONE) {
    //        return type;
    //    }
    
    //    _canSend = YES;
    return LGTCPSocketClientErrorTypeNONE;
}

- (LGTCPSocketClientErrorType)connect {
    if (!_socket_descriptor) {
        LGTCPSocketClientErrorType type = [self initliazedTCPSocketWithIP:_ip port:_port];
        NSLog(@"申请完socket:[%d]", _socket_descriptor);
        //        NSLog(@"重连socket:[%d]", _socket_descriptor);
        if (type != LGTCPSocketClientErrorTypeNONE) {
            return type;
        }
    }
    [NSThread sleepForTimeInterval:1.f];
    NSLog(@"连接socket:[%d]", _socket_descriptor);
    if (connect(_socket_descriptor,(struct sockaddr*)&_client_addr,sizeof(_client_addr))==-1) {
        NSLog(@"连接失败socket:[%d]", _socket_descriptor);
        [self disConnectTCP];
        _canSend = false;
        return LGTCPSocketClientErrorTypeCONNECT;
    }
    NSLog(@"连接成功socket:[%d]", _socket_descriptor);
    //    fd_set error;
    //    select(_socket_descriptor, NULL, NULL, NULL, <#struct timeval *restrict#>)
    //    unsigned long ul = 1;
    //    ioctl(_socket_descriptor, FIONBIO, &ul); //设置为阻塞模式
    
    //    __block int result = set_tcpkeepAlive(_socket_descriptor, 10.f, 5.f, 3);
    
    __weak typeof(self)weakSelf = self;
    
    //    if (!_socketAliveQ) {
    //        _socketAliveQ = dispatch_queue_create("socketisalive", DISPATCH_QUEUE_SERIAL);
    //    }
    
    // 监听socket link链接
    //    dispatch_async(_socketAliveQ, ^{
    //        while (1) {
    //            result = checksock(_socket_descriptor);
    //            NSLog(@"socket alive:[%d]", result);
    //            if (result == -1) {
    //                if (weakSelf.socketDidDisconnected) {
    //                    weakSelf.socketDidDisconnected(result);
    //                }
    //                break;
    //            }
    //            [NSThread sleepForTimeInterval:6.f];
    //        }
    //    });
    
    _canSend = true;
    return LGTCPSocketClientErrorTypeNONE;
    if (!_socketRecvQ) {
        _socketRecvQ = dispatch_queue_create("rdq", DISPATCH_QUEUE_SERIAL);
    }
    char *buf = malloc(4);
    __block ssize_t length = 0;
    bzero(buf, sizeof(buf));
    // 触控回传
    dispatch_async(_socketRecvQ, ^{
        while (_canSend) {
            
            length = recv(_socket_descriptor, buf, 4, 0);
            if (length < 0) {
                bzero(buf, sizeof(buf));
                continue;
            }
            if (weakSelf.socketDidReciveMessage) {
                weakSelf.socketDidReciveMessage(buf);
            }
            bzero(buf, sizeof(buf));
        }
    });
    
    return LGTCPSocketClientErrorTypeNONE;
}

- (size_t)receiveWithSize:(size_t)size buffer:(UInt8 *)buf {
    
    ssize_t res = 0;
    ssize_t left = size;
    while (left > 0) {
        res = recv(_socket_descriptor, (buf+(size-left)), left, 0);
        if (res > 0) {
            left -= res;
        }
        else if (res < 0) {
            break;
        }
    }
    return size - left;
}
// receive heart beat
- (void *)receiveTCPWithSize:(unsigned long)size {
    if (!_buf) {
        _buf = malloc(8*ONE_KB);
    }
    
    memset(_buf, 0, size);
    ssize_t res = 0;
    ssize_t left = size;
    while (left > 0) {
        res = recv(_socket_descriptor, (_buf+(size-left)), left, 0);
        if (res > 0) {
            left -= size;
        }
        else if (res < 0) {
            break;
        }
    }
    
    if (left != 0) {
        return NULL;
    }
    else {
        return _buf;
    }
}
- (ssize_t)sendTCP:(cData *)cdata length:(long)length {
    ssize_t res;
    ssize_t left = length;
    while (left > 0) {
        res = send(_socket_descriptor, cdata, length, 0);
        if (res > 0) {
            left -= res;
        }
        else if (res < 0) {
            break;
        }
    }
    if (left != 0) {
        return -1;
    }
    else return length;
}

- (void)sendTCPWithData:(NSData *)data {
    __weak typeof(self)weakSelf = self;
    [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        
        long lDataLen = byteRange.length;
        long lSendLen = 0;
        long RealLen  = 8192;
        size_t result = 0;
        while (lDataLen>0) {
            
            RealLen = RealLen > lDataLen ? lDataLen : RealLen;
            result = [weakSelf sendTCP:(bytes+lSendLen) length:RealLen];
            if (result<=0) {
                perror("Error in send\n");
                break;
            }
            
            lSendLen += result;
            lDataLen -= result;
        }
    }];
}

- (ssize_t)result {
    return _sresult;
}

- (LGTCPSocketClientErrorType)heartbeat {
    int result =set_tcpkeepAlive(_socket_descriptor, 180, 10, 3);
    if (result == -1) {
        perror("set error...");
        return LGTCPSocketClientErrorTypeSETOPT;
    }
    else printf("success!");
    return LGTCPSocketClientErrorTypeNONE;
}
//fd:网络连接描述符
//start:首次心跳侦测包发送之间的空闲时间
//interval:两次心跳侦测包之间的间隔时间
//count:探测次数，即将几次探测失败判定为TCP断开
int set_tcpkeepAlive(int fd, int start, int interval, int count) {
    int keepAlive = 1;
    if (fd<0 || start<0 || interval<0 || count<0) return -1;
    
    if (setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, (void *)&keepAlive, sizeof(keepAlive)) == -1) {
        perror("start heartbeat error");
        return -1;
    }
    // 7200000  TCP_KEEPIDLE
    if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPALIVE, (void *)&start, sizeof(start)) == -1) {
        perror("set first heartbeat time");
        return -1;
    }
    
    if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPINTVL, (void *)&interval, sizeof(interval)) == -1) {
        perror("margin time");
        return -1;
    }
    
    if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPCNT, (void *)&count, sizeof(count)) == -1) {
        perror("count of heartbeat");
        return -1;
    }
    return  0;
}
int checksock(int s) {
    fd_set   fds;
    char buf[2];
    ssize_t nbread;
    FD_ZERO(&fds);
    FD_SET(s,&fds);
    if ( select(s+1, &fds, (fd_set *)0, (fd_set *)0, NULL) == -1 ) {
        //        log(LOG_ERR,"select(): %s\n",strerror(errno)) ;
        return -1;
    }
    if (!FD_ISSET(s,&fds)) {
        //log(LOG_ERR,"select() returns OK but FD_ISSET not\n") ;
        return -1;
    }
    /* read one byte from socket */
    nbread = recv(s, buf, 1, MSG_PEEK);
    if (nbread <= 0)
        return -1;
    return 0;
}
@end
