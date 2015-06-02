//
//  BlueSessionManager.m
//  BlueTalk
//
//  Created by user on 15-4-8.
//  Copyright (c) 2015年 LHL. All rights reserved.
//

#import "BlueSessionManager.h"

#define ServiceType @"MyService"

/*
 
 MCAdvertiserAssistant   //可以接收，并处理用户请求连接的响应。没有回调，会弹出默认的提示框，并处理连接。
 MCNearbyServiceAdvertiser //可以接收，并处理用户请求连接的响应。但是，这个类会有回调，告知有用户要与您的设备连接，然后可以自定义提示框，以及自定义连接处理。
 MCNearbyServiceBrowser  //用于搜索附近的用户，并可以对搜索到的用户发出邀请加入某个会话中。
 MCPeerID //这表明是一个用户
 MCSession //启用和管理Multipeer连接会话中的所有人之间的沟通。 通过Sesion，给别人发送数据。
 
 */

@interface BlueSessionManager ()<MCAdvertiserAssistantDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate, UIAlertViewDelegate>

@property(strong, nonatomic) MCSession *currentSession; // 当前会议
@property(strong, nonatomic) MCAdvertiserAssistant *advertisingAssistant; // 宣传助手
@property(strong, nonatomic) MCNearbyServiceAdvertiser *advertiser; // 服务助手
@property(strong, nonatomic) MCNearbyServiceBrowser *browser; // 搜索蓝牙者
@property(strong, nonatomic) MCPeerID *peerID; // 用户

//  以下都是用到的block
@property(nonatomic, copy) void(^receiveDataBlock)(NSData *data, MCPeerID *peer);
@property(nonatomic, copy) void(^receiveResourceBlock)(MCPeerID *peer, NSURL *url);
@property(nonatomic, copy) void(^connectionStatus)(MCPeerID *peer, MCSessionState state);
@property(nonatomic, copy) void(^browserConnected)(void);
@property(nonatomic, copy) void(^browserCancelled)(void);
@property(nonatomic, copy) void(^didFindPeer)(MCPeerID *peer, NSDictionary *info);
@property(nonatomic, copy) void(^invitationHandler)(BOOL connect, MCSession *session);
@property(nonatomic, copy) void(^inviteBlock)(MCPeerID *peer, NSData *context);
@property(nonatomic, copy) void(^didStartReceivingResource)(NSString *name, MCPeerID *peer, NSProgress *progress);
@property(nonatomic, copy) void(^finalResource)(NSString *name, MCPeerID *peer, NSURL *url, NSError *error);
@property(nonatomic, copy) void(^streamBlock)(NSInputStream *inputStream, MCPeerID *peer, NSString *streamName);


// 各种判断
@property(nonatomic, assign) BOOL receiveOnMainQueue;
@property(nonatomic, assign) BOOL statusOnMainQueue;
@property(nonatomic, assign) BOOL resourceFinalOnMainQueue;
@property(nonatomic, assign) BOOL resourceStart;

@end

@implementation BlueSessionManager

#pragma mark 初始化自己
- (instancetype)initWithDisplayName:(NSString *)displayName
{
    return [self initWithDisplayName:displayName securityIdentity:nil encryptionPreferences:MCEncryptionNone serviceType:ServiceType];
}

/**
 *  为上面自定义 用户
 *
 *  @param displayName 显示名称
 *  @param security    安全标示
 *  @param preference  加密偏好  0 可选的加密 1 需要加密 2 无加密
 *  @param type        服务类型
 *
 *  @return 生成一个对话管理者
 */
- (instancetype)initWithDisplayName:(NSString *)displayName securityIdentity:(NSArray *)security encryptionPreferences:(MCEncryptionPreference)preference serviceType:(NSString *)type
{
    self = [super init];
    if(!self) {
        return nil;
    }
    self.peerID = [[MCPeerID alloc]initWithDisplayName:displayName];
    self.currentSession = [[MCSession alloc]initWithPeer:self.peerID securityIdentity:security encryptionPreference:preference];
    self.session.delegate = self;
    self.serviceType = type;
    return self;
}

#pragma mark 宣传自己
/**
 *  通知扫描设备
 */
- (void)advertiseForBrowserViewController
{
    [self advertiseForBrowserViewControllerWithDiscoveryInfo:nil];
}

/**
 *  通知扫描设备
 *
 *  @param info 消息
 */
- (void)advertiseForBrowserViewControllerWithDiscoveryInfo:(NSDictionary *)info
{
    //
    self.advertiser = [[MCNearbyServiceAdvertiser alloc]initWithPeer:self.peerID discoveryInfo:info serviceType:self.serviceType];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
}

/**
 *  打开天线，广播
 */
- (void)advertiseForProgrammaticDiscovery
{
    [self advertiseForProgrammaticDiscoveryWithDiscoveryInfo:nil];
}

/**
 *  打开天线，广播消息
 *
 *  @param info 消息
 */
- (void)advertiseForProgrammaticDiscoveryWithDiscoveryInfo:(NSDictionary *)info
{
    //自定义自己，为了让其他设备搜索到自己
    self.advertisingAssistant = [[MCAdvertiserAssistant alloc]initWithServiceType:self.serviceType discoveryInfo:info session:self.session];
    self.advertisingAssistant.delegate = self;
    [self.advertisingAssistant start];
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler {
    self.invitationHandler = [invitationHandler copy];
    if(self.inviteBlock) self.inviteBlock(peerID, context);
}

#pragma mark 下面是MCAdvertiserAssistant的两个代理
/**
 *  有搜索 不连接
 *
 *  @param advertiserAssistant
 */
- (void)advertiserAssistantDidDismissInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{
    //TODO implement
    NSLog(@"DidDismiss");
}

/**
 *  有搜索将要被要求
 *
 *  @param advertiserAssistant <#advertiserAssistant description#>
 */
- (void)advertiserAssitantWillPresentInvitation:(MCAdvertiserAssistant *)advertiserAssistant {
    //TODO implement
    NSLog(@"WillPresent");
}

#pragma mark  扫描其他的设备
- (void)browseForProgrammaticDiscovery
{
    self.browser = [[MCNearbyServiceBrowser alloc]initWithPeer:self.peerID serviceType:self.serviceType];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}

#pragma mark MCNearbyServiceBrowserDelegate 
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    //TODO implement
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    if(self.didFindPeer)
    {
        self.didFindPeer(peerID, info);
    }
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    //TODO implement
}

#pragma mark 参加会议  也是会议的代理
//   也是  ----- MCSessionDelegate

//  这是完成会议的结果···
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
    if(self.resourceFinalOnMainQueue)
    {
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            if(self.finalResource)
            {
                self.finalResource(resourceName, peerID, localURL, error);
            }
        }];
    }
    else
    {
        if(self.finalResource)
        {
            self.finalResource(resourceName, peerID, localURL, error);
        }
    }
    
}

// 这是参加  普通数据的会议
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    if(self.receiveOnMainQueue)
    {
       
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            if(self.receiveDataBlock)
            {
                self.receiveDataBlock(data, peerID);
            }
        }];
    }
    else
    {
        if(self.receiveDataBlock)
        {
            self.receiveDataBlock(data, peerID);
        }
    }
}


// 这是参加  普通流的会议
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
   
    if(self.streamBlock)
    {
        self.streamBlock(stream, peerID, streamName);
    }
}



// 这是参加  图片资源的会议
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    if(self.resourceStart)
    {
        
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            if(self.didStartReceivingResource)
            {
                self.didStartReceivingResource(resourceName, peerID, progress);
            }
        }];
    }
    else
    {
      
        if(self.didStartReceivingResource)
        {
            self.didStartReceivingResource(resourceName, peerID, progress);
        }
    }
}


// 这是不同数据，系那是不同会议时候的状态

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    // 这个地方是当两个蓝牙设备一旦连接起来，就会形成的一个会议
    if(self.statusOnMainQueue)
    {
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            if(self.connectionStatus)
            {
                self.connectionStatus(peerID, state);
            }
        }];
    }
    else
    {
        if(self.connectionStatus)
        {
            self.connectionStatus(peerID, state);
        }
    }
}



#pragma mark  send And receive
//--------------------------------------------------------------------------------------------//
// 发送消息
// 用户多个
- (NSError *)sendDataToAllPeers:(NSData *)data
{
    // 普通数据的发送

    return [self sendDataToAllPeers:data withMode:MCSessionSendDataReliable];
}

- (NSError *)sendDataToAllPeers:(NSData *)data withMode:(MCSessionSendDataMode)mode
{
    // 确实进入会议
    
    NSError *error;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:mode error:&error];
    return error;
}

// 用户确定一个
- (NSError *)sendData:(NSData *)data toPeers:(NSArray *)peers
{
    return [self sendData:data toPeers:peers withMode:MCSessionSendDataReliable];
}

- (NSError *)sendData:(NSData *)data toPeers:(NSArray *)peers withMode:(MCSessionSendDataMode)mode
{
    NSError *error;
    [self.session sendData:data toPeers:peers withMode:mode error:&error];
    return error;
}


// 接收消息
- (void)receiveDataOnMainQueue:(BOOL)mainQueue block:(void (^)(NSData *data, MCPeerID *peer))dataBlock
{
    
    self.receiveDataBlock = [dataBlock copy];
    self.receiveOnMainQueue = mainQueue;
}
//--------------------------------------------------------------------------------------------//

- (NSProgress *)sendResourceWithName:(NSString *)name atURL:(NSURL *)url toPeer:(MCPeerID *)peer complete:(void (^)(NSError *error))compelete
{
    // 图片资源数据的发送
    
    return [self.session sendResourceAtURL:url withName:name toPeer:peer withCompletionHandler:compelete];
}

// 用户连接确定 
- (void)peerConnectionStatusOnMainQueue:(BOOL)mainQueue block:(void (^)(MCPeerID *peer, MCSessionState state))status
{
    self.connectionStatus = [status copy];
    self.statusOnMainQueue = mainQueue;
}


#pragma mark 自带的MCBrowserViewController类
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:^{
        if(self.browserConnected) self.browserConnected();
    }];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:^{
        if(self.browserCancelled) self.browserCancelled();
    }];
}

- (void)browseWithControllerInViewController:(UIViewController *)controller connected:(void (^)(void))connected canceled:(void (^)(void))cancelled
{
    self.browserConnected = [connected copy];
    self.browserCancelled = [cancelled copy];
    // 注意这个自带的类
    MCBrowserViewController *browser = [[MCBrowserViewController alloc]initWithServiceType:self.serviceType session:self.session];
    browser.delegate = self;
    [controller presentViewController:browser animated:YES completion:nil];
}

- (NSArray *)connectedPeers
{
    return self.session.connectedPeers;
}

// 邀请某某连接
- (void)didReceiveInvitationFromPeer:(void (^)(MCPeerID *peer, NSData *context))invite;
{
    self.inviteBlock = [invite copy];
}

- (void)invitePeerToConnect:(MCPeerID *)peer connected:(void (^)(void))connected
{
    [self.browser invitePeer:peer toSession:self.session withContext:nil timeout:30];
}

- (void)startReceivingResourceOnMainQueue:(BOOL)mainQueue block:(void (^)(NSString *name, MCPeerID *peer, NSProgress *progress))block
{
    
    self.didStartReceivingResource = [block copy];
    self.resourceStart = mainQueue;
}

// 接收某某资源
- (void)receiveFinalResourceOnMainQueue:(BOOL)mainQueue complete:(void (^)(NSString *name, MCPeerID *peer, NSURL *url, NSError *error))block
{
    
    self.finalResource = [block copy];
    self.resourceFinalOnMainQueue = mainQueue;
}

- (NSOutputStream *)streamWithName:(NSString *)name toPeer:(MCPeerID *)peerID error:(NSError * __autoreleasing *)error
{
    return [self.session startStreamWithName:name toPeer:peerID error:error];
}

// 开始转化为流
- (void)didReceiveStreamFromPeer:(void (^)(NSInputStream *inputStream, MCPeerID *peer, NSString *streamName))streamBlock
{
    self.streamBlock = [streamBlock copy];
}

- (void)didFindPeerWithInfo:(void (^)(MCPeerID *peer, NSDictionary *info))found
{
    self.didFindPeer = [found copy];
}


#pragma mark  一些断开的情况
- (void)disconnectSession
{
    [self.session disconnect];
}

- (void)stopAdvertising
{
    [self.advertiser stopAdvertisingPeer];
    [self.advertisingAssistant stop];
}

- (void)stopBrowsing
{
    [self.browser stopBrowsingForPeers];
}

- (BOOL)isConnected {
    return self.session.connectedPeers && self.session.connectedPeers.count > 0;
}

// 是否连接 它
- (void)connectToPeer:(BOOL)connect {
    self.invitationHandler(connect, self.session);
}

- (MCSession *)session {
    return self.currentSession;
}

- (MCPeerID *)firstPeer {
    return self.session.connectedPeers.firstObject;
}

@end
