//
//  BlueSessionManager.h
//  BlueTalk
//
//  Created by user on 15-4-8.
//  Copyright (c) 2015年 YangPeiQiu. All rights reserved.
//

#import <Foundation/Foundation.h>

@import MultipeerConnectivity;

@interface BlueSessionManager : NSObject

/*
 基本知识必须了解的
 
 MCAdvertiserAssistant   //可以接收，并处理设备请求连接的响应。没有回调，会弹出默认的提示框，并处理连接。
 MCNearbyServiceAdvertiser //可以接收，并处理设备请求连接的响应。但是，这个类会有回调，告知有设备要与您的设备连接，然后可以自定义提示框，以及自定义连接处理。
 MCNearbyServiceBrowser  //用于搜索附近的设备，并可以对搜索到的设备发出邀请加入某个会话中。
 MCPeerID //这表明是一个设备
 MCSession //启用和管理Multipeer连接会话中的所有人之间的沟通。 通过Sesion，给别人发送数据。
 
 */
@property(strong, nonatomic, readonly) NSArray *connectedPeers;

@property(strong, nonatomic, readonly) MCSession *session;

@property(nonatomic, readonly, getter = isConnected) BOOL connected;

@property(strong, nonatomic) NSDictionary *discoveryInfo; // 发现设备的特征

@property(strong, nonatomic, readonly) MCPeerID *firstPeer; // 第一个连接的 设备

/**
 * The service type provided for browsing and advertising.
 * This should be a short text string that describes the
 * app's networking protocol. Should be something
 * in the form of `tjl_appname`.
 */
@property(strong, nonatomic) NSString *serviceType;


/**
 *  初始化一个 假设的设备名字
 */
- (instancetype)__attribute__((nonnull(1)))initWithDisplayName:(NSString *)displayName;

/**
 *  扫描纲领性的发现
 */
- (void)browseForProgrammaticDiscovery;

/**
 *  通知扫描性的视图控制器
 */
- (void)advertiseForBrowserViewController;

/**
 *  通知纲领性的发现
 */
- (void)advertiseForProgrammaticDiscovery;




/**
 *  接收到来自 xx 设备的邀请
 *
 *  @param invite （ MCPeerID 设备的id，context 内容）
 */
- (void)didReceiveInvitationFromPeer:(void (^)(MCPeerID *peer, NSData *context))invite;

/**
 *  发送数据给所有的设备
 *
 *  @param data 需要发送的数据
 *
 *  @return 返回发送的错误
 */
- (NSError *)sendDataToAllPeers:(NSData *)data;




/**
 *  发送数据给 数组里的设备
 *
 *  @param data  需要发送的数据
 *  @param peers 设备数组
 *
 *  @return 返回发送的错误
 */
- (NSError *)sendData:(NSData *)data toPeers:(NSArray *)peers;

/**
 *  发送数据给 数组里的设备
 *
 *  @param data  需要发送的数据
 *  @param peers 设备数组
 *  @param mode  发送数据模式， MCSessionSendDataReliable 可靠发送模式，  MCSessionSendDataUnreliable 不可靠发送模式
 *
 *  @return 返回发送的错误
 */
- (NSError *)sendData:(NSData *)data toPeers:(NSArray *)peers withMode:(MCSessionSendDataMode)mode;

/**
 *  接收数据是否在主队列  接收时时刻有回调
 *
 *  @param mainQueue 是否是主队列
 *  @param dataBlock block 获取接收到的数据 和 设备id
 */
- (void)receiveDataOnMainQueue:(BOOL)mainQueue block:(void (^)(NSData *data, MCPeerID *peer))dataBlock;

/**
 *  发送资源文件给设备，完成有回调
 *
 *  @param name      文件名称
 *  @param url       文件地址
 *  @param peer      设备id
 *  @param compelete 完成回调
 *
 *  @return 返回发送文件的进度
 */
- (NSProgress *)sendResourceWithName:(NSString *)name atURL:(NSURL *)url toPeer:(MCPeerID *)peer complete:(void (^)(NSError *error))compelete;

/**
 *  接收最终的资源是否来自主队列 ，接收完成有回调
 *
 *  @param mainQueue 是否为主队列
 *  @param block     完成回调（名称，设备id，路径，错误信息）
 */
- (void)receiveFinalResourceOnMainQueue:(BOOL)mainQueue complete:(void (^)(NSString *name, MCPeerID *peer, NSURL *url, NSError *error))block;

/**
 *  开始接收资源文件，是否在主队列  ，有回调
 *
 *  @param mainQueue 是否为主队列
 *  @param block     回调 （名称，设备id，进度）
 */
- (void)startReceivingResourceOnMainQueue:(BOOL)mainQueue block:(void (^)(NSString *name, MCPeerID *peer, NSProgress *progress))block;

/**
 *  生成发送数据流到设备id的数据流
 *
 *  @param name   数据流文件名称
 *  @param peerID 设备id
 *  @param error  错误信息
 *
 *  @return 得到一个数据流
 */
- (NSOutputStream *)streamWithName:(NSString *)name toPeer:(MCPeerID *)peerID error:(NSError * __autoreleasing *)error;

/**
 *  接收到来自设备id的数据流
 *
 *  @param streamBlock 数据流回调（数据流，设备id，数据流名称）
 */
- (void)didReceiveStreamFromPeer:(void (^)(NSInputStream *inputStream, MCPeerID *peer, NSString *streamName))streamBlock;

/**
 *  设备连接状态
 *
 *  @param mainQueue 是否为主队列
 *  @param status    连接状态， 未连接，正在连接，已连接 （设备id， 连接状态）
 */
- (void)peerConnectionStatusOnMainQueue:(BOOL)mainQueue block:(void (^)(MCPeerID *peer, MCSessionState state))status;

/**
 *  浏览控制器 在某个视图控制器里
 *
 *  @param controller 某个视图控制器
 *  @param connected  连接回调
 *  @param cancelled  取消连接回调
 */
- (void)browseWithControllerInViewController:(UIViewController *)controller connected:(void (^)(void))connected canceled:(void (^)(void))cancelled;

/**
 *  已发现设备信息
 *
 *  @param found 返回设备，及信息
 */
- (void)didFindPeerWithInfo:(void (^)(MCPeerID *peer, NSDictionary *info))found;

/**
 *  连接到设备
 *
 *  @param connect 执行连接到设备
 */
- (void)connectToPeer:(BOOL)connect;

/**
 *  邀请其他设备连接
 *
 *  @param peer      设备
 *  @param connected 连接回调
 */
- (void)invitePeerToConnect:(MCPeerID *)peer connected:(void (^)(void))connected;

/**
 *  解除连接
 */
- (void)disconnectSession;

/**
 *  停止打开自己
 */
- (void)stopAdvertising;

/**
 *  停止扫描
 */
- (void)stopBrowsing;



@end
