//
//  RootViewController.m
//  BlueTalk
//
//  Created by user on 15-4-8.
//  Copyright (c) 2015年 LHL. All rights reserved.
//

#import "RootViewController.h"
#import "BlueSessionManager.h"
#import "ChatCell.h"
#import "ChatItem.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>


#define kRecordAudioFile @"myRecord.caf"

// 判断大小
#define HEIGHT [UIScreen mainScreen].bounds.size.height
#define WIDTH [UIScreen mainScreen].bounds.size.width
#define ChatHeight 45.0

@interface RootViewController ()<NSStreamDelegate,UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate>
{
    float _sendBackViewHeight;
    float _sendTextViewHeight;
    
    UIImagePickerController * _picker;
    UIView * _backRemindRecordView;
}

// DataAndBlue
@property(strong, nonatomic) BlueSessionManager *sessionManager;

@property(strong, nonatomic) NSMutableArray *datasource;
@property(strong, nonatomic) NSMutableArray * myDataArray;

@property(strong, nonatomic) NSMutableData *streamData;
@property(strong, nonatomic) NSOutputStream *outputStream;
@property(strong, nonatomic) NSInputStream *inputStream;

// UI
@property(strong, nonatomic) UITableView * tableView;
@property(strong, nonatomic) UIView * sendBackView;
@property(strong, nonatomic) UITextView * sendTextView;
@property(strong, nonatomic) UIButton * sendButton;


// 语音播放
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;//音频录音机
//音频播放器，用于播放录音文件
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;

@property (nonatomic,strong) NSTimer *timer;//录音声波监控（注意这里暂时不对播放进行监控）



@property (strong, nonatomic) UIProgressView *audioPower;//音频波动




@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeBlueData];
    
    [self readyUI];
    
    [self buildVideoForWe];
    
    
    // Do any additional setup after loading the view
}




#pragma mark  基本制作

- (void)readyUI
{
    self.title = @"蓝牙设置";
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    NSArray * buttonTitleArray = @[@"寻找设备",@"打开天线"];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:buttonTitleArray[0] style:UIBarButtonItemStyleDone target:self action:@selector(lookOtherDevice)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:buttonTitleArray[1] style:UIBarButtonItemStyleDone target:self action:@selector(showSelfAdvertiser)];
    [self makeUIView];
    
}
- (void)lookOtherDevice
{
    [self.sessionManager browseWithControllerInViewController:self connected:^{
        NSLog(@"connected");
    }                                                 canceled:^{
        NSLog(@"cancelled");
    }];
}


- (void)showSelfAdvertiser
{
    [self.sessionManager advertiseForBrowserViewController];
}

#pragma mark 制作页面UI
- (void)makeUIView
{
//    NSLog(@"width === %f,height===== %f",WIDTH,HEIGHT);
    
    self.myDataArray = [NSMutableArray arrayWithCapacity:0];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, WIDTH, HEIGHT - 64 - ChatHeight - 10)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
   
    [self.view addSubview:self.tableView];
    
   
    
    
   
//-------------------------------------------------------------------------//
    
    self.sendBackView = [[UIView alloc] initWithFrame:CGRectMake(0, HEIGHT - ChatHeight, WIDTH, ChatHeight)];
    self.sendBackView.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0];
    [self.view addSubview:self.sendBackView];
    
//    float heightView = self.sendBackView.frame.size.height;
    
    self.sendTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 5, WIDTH - 10 - 90, 35)];
//    self.sendTextView.backgroundColor = [UIColor lightGrayColor];
    self.sendTextView.returnKeyType = UIReturnKeySend;
    self.sendTextView.font = [UIFont systemFontOfSize:17];
    self.sendTextView.editable = YES;
    self.sendTextView.delegate = self;
    [self.sendBackView addSubview:self.sendTextView];
    
    UIButton * addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    addButton.frame = CGRectMake(WIDTH - 85, 2, 37, 37);
    [addButton addTarget:self action:@selector(addNextImage) forControlEvents:UIControlEventTouchUpInside];
    [self.sendBackView addSubview:addButton];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(WIDTH - 45, 5, 40, 30);
    
    [self.sendButton setImage:[UIImage imageNamed:@"record.png"] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(videoRecord) forControlEvents:UIControlEventTouchUpInside];
    [self.sendBackView addSubview:self.sendButton];
    
  
    
    
    // 增加通知
    [self addTheNoticeForKeyDownUp];
    
}


#pragma mark 图片的传输---------///////

- (void)addNextImage
{
   
    UIActionSheet *chooseImageSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"照相机",@"相册", nil];
    [chooseImageSheet showInView:self.view];
}




#pragma mark UIActionSheetDelegate Method
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    _picker = [[UIImagePickerController alloc] init];
    _picker.delegate = self;
    
    switch (buttonIndex) {
        case 0://Take picture
            
     
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            {
                
                _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            }
        
            [self presentViewController:_picker animated:NO completion:nil];
            
            
      
            break;
            
        case 1:
            //From album
            _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            
            [self presentViewController:_picker animated:NO completion:^{
                
                // 改变状态栏的颜色  为正常  这是这个独有的地方需要处理的
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
            }];
            break;
            
        default:
            
            break;
    }
}







// 相册
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    //当选择的类型是图片
    if ([type isEqualToString:@"public.image"])
    {
        //先把图片转成NSData
        UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSData *data;
        if (UIImagePNGRepresentation(image) == nil)
        {
            data = UIImageJPEGRepresentation(image, 1.0);
        }
        else
        {
            data = UIImagePNGRepresentation(image);
        }
        
        //图片保存的路径
        //这里将图片放在沙盒的documents文件夹中
        NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        
        //文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        //把刚刚图片转换的data对象拷贝至沙盒中 并保存为image.png
        [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
        [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:@"/image.png"] contents:data attributes:nil];
        
        //得到选择后沙盒中图片的完整路径
        NSString * filePath = [[NSString alloc]initWithFormat:@"%@%@",DocumentsPath,  @"/image.png"];
        
        
        
        [_picker dismissViewControllerAnimated:NO completion:^{
            
            // 改变状态栏的颜色  改变为白色
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
            
            
            
            // 这边是真正的发送
            if(!self.sessionManager.isConnected)
            {
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"蓝牙已经断开了，请重新连接！" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil];
                [alertView show];
                return;
            }
            
            ChatItem * chatItem = [[ChatItem alloc] init];
            chatItem.isSelf = YES;
            chatItem.states = picStates;
            chatItem.picImage = image;
            [self.datasource addObject:chatItem];
            
            
            [self insertTheTableToButtom];
            
            
            [self sendAsResource:filePath];
           
        }];
    }

  
}
- (void)sendAsResource:(NSString *)path
{
    
    NSLog(@"dispaly ====%@",self.sessionManager.firstPeer.displayName);
    NSString * name = [NSString stringWithFormat:@"%@ForPic",[[UIDevice currentDevice] name]];
    NSURL * url = [NSURL fileURLWithPath:path];
    
    NSProgress *progress = [self.sessionManager sendResourceWithName:name atURL:url toPeer:self.sessionManager.firstPeer complete:^(NSError *error) {
        if(!error) {
            NSLog(@"finished sending resource");
        }
        else {
            NSLog(@"%@", error);
        }
    }];
    NSLog(@"%@", @(progress.fractionCompleted));
}


#pragma mark 普通数据的传输
- (void)sendWeNeedNews
{
    if(!self.sessionManager.isConnected)
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"蓝牙已经断开了，请重新连接！" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil];
        [alertView show];
        return;
    }
    if([self.sendTextView.text isEqualToString:@""])
    {
        return;
    }
    
    
    ChatItem * chatItem = [[ChatItem alloc] init];
    chatItem.isSelf = YES;
    chatItem.states = textStates;
    chatItem.content = self.sendTextView.text;
    [self.datasource addObject:chatItem];
    // 加到数组里面
    
    // 添加行   indexPath描述位置的具体信息
    [self insertTheTableToButtom];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.sendTextView.text];
    NSError *error = [self.sessionManager sendDataToAllPeers:data];
    if(!error) {
        //there was no error.
    }
    else {
        NSLog(@"%@", error);
    }
    
    [self returnTheNewBack];
}
- (void)returnTheNewBack
{
    // 归零
    self.sendTextView.text = @"";
    [self.sendTextView resignFirstResponder];
    self.tableView.frame = CGRectMake(0, 64, WIDTH, HEIGHT - 64 - ChatHeight - 10 );
    self.sendBackView.frame = CGRectMake(0, HEIGHT - ChatHeight , WIDTH, ChatHeight);
    
}

// 这是一种很好的键盘下移方式
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    
    if ([text isEqualToString:@"\n"]) {
        
        [self sendWeNeedNews];

        return NO;
    }
    
    
    
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{

    // 随机改变其高度
    
    float textHeight = [self heightForString:textView.text fontSize:16 andWidth:textView.frame.size.width];
    _sendTextViewHeight = textHeight;
//    NSLog(@"teztheight ===== %f",textHeight);
    
    
    self.sendTextView.frame = CGRectMake(10, 5, WIDTH - 10 - 90, _sendTextViewHeight);
    self.sendBackView.frame = CGRectMake(0, HEIGHT -  _sendBackViewHeight - _sendTextViewHeight - 10, WIDTH, _sendTextViewHeight + 10);
  
    
}

- (float) heightForString:(NSString *)value fontSize:(float)fontSize andWidth:(float)width
{
    UITextView *detailTextView = [[UITextView alloc]initWithFrame:CGRectMake(0, 0, width, 0)];
    detailTextView.font = [UIFont systemFontOfSize:fontSize];
    detailTextView.text = value;
    CGSize deSize = [detailTextView sizeThatFits:CGSizeMake(width,CGFLOAT_MAX)];
    return deSize.height;
}



#pragma mark 以下是为了配合  键盘上移的变化

- (void)addTheNoticeForKeyDownUp
{
    [ [NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyBoardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [ [NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleKeyBoardDidShow:(NSNotification *)paramNotification
{
    CGSize size = [[paramNotification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    _sendBackViewHeight = size.height;
    
    [UIView animateWithDuration:0.000001 animations:^{
        self.tableView.frame = CGRectMake(0, 64, WIDTH, HEIGHT - 64 - ChatHeight - size.height);
        self.sendBackView.frame = CGRectMake(0, HEIGHT - ChatHeight - size.height, WIDTH, ChatHeight);
        
    }];
    
}
-(void)handleKeyboardWillHide:(NSNotification *)paramNotification
{
    [UIView animateWithDuration:0.1 animations:^{
        if(_sendTextViewHeight > 0)
        {
            self.tableView.frame = CGRectMake(0, 64, WIDTH, HEIGHT - 64 - _sendTextViewHeight + 10 );
            self.sendBackView.frame = CGRectMake(0, HEIGHT - _sendTextViewHeight  - 10, WIDTH, _sendTextViewHeight + 10);
        }
        else
        {
            self.tableView.frame = CGRectMake(0, 64, WIDTH, HEIGHT - 64 - ChatHeight - 10 );
            self.sendBackView.frame = CGRectMake(0, HEIGHT - ChatHeight , WIDTH, ChatHeight);
        }
        
        
    }];
}
/*--------------------------------------------------------------------------------------------*/
- (void)insertTheTableToButtom
{
    // 哪一组 哪一段
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:self.datasource.count- 1 inSection:0];
    // 添加新的一行
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    // 滑动到底部  第二个参数是滑动到底部
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark tableView 代理
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatItem * chatItem = [self.datasource objectAtIndex:indexPath.row];
    if(chatItem.states == picStates)
    {
        NSLog(@"widht====%f,height======%f",chatItem.picImage.size.width,chatItem.picImage.size.height);
        return 50;
        
        
        
    }
    else if(chatItem.states == textStates)
    {
        CGSize size = [chatItem.content boundingRectWithSize:CGSizeMake(250, 1000) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading  attributes:@{NSFontAttributeName :[UIFont systemFontOfSize:14]} context:nil].size;
        
        return size.height + 20 + 10; // 与view的距离 ＋ 与Cell的距离
    }
    else
    {
        return 50;
    }
    
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString * iden = @"iden";
    ChatCell * cell = [tableView dequeueReusableCellWithIdentifier:iden];
    if(cell == nil)
    {
        cell = [[ChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:iden];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        // 让后面选中的没有阴影效果
        
    }
    
    // 模型
    
    ChatItem * chatItem = [self.datasource objectAtIndex:indexPath.row];
   
    CGSize size = [chatItem.content boundingRectWithSize:CGSizeMake(250, 1000) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading  attributes:@{NSFontAttributeName :[UIFont systemFontOfSize:14]} context:nil].size;
    
    //如果自己发的
    if(chatItem.isSelf)
    {
        cell.leftHeadImage.hidden = YES;
        cell.rightHeadImage.hidden = NO;
        
        if(chatItem.states == picStates)
        {
            cell.lefeView.hidden = YES;
            cell.rightView.hidden = YES;
            
            cell.rightPicImage.image = chatItem.picImage;
            cell.leftPicImage.hidden = YES;
            cell.rightPicImage.hidden = NO;
            
            cell.leftVideoButton.hidden = YES;
            cell.rightVideoButton.hidden = YES;
            
            NSLog(@"self send");
           
            
        }
        else if(chatItem.states == textStates)
        {
            cell.rightPicImage.hidden = YES;
            cell.leftPicImage.hidden = YES;
            
            cell.lefeView.hidden = YES;
            cell.rightView.hidden = NO;
            
            cell.leftVideoButton.hidden = YES;
            cell.rightVideoButton.hidden = YES;
            // 复用机制
            cell.rightLabel.frame = CGRectMake(10, 5, size.width, size.height);
            cell.rightView.frame = CGRectMake(WIDTH - 40 -size.width-25, 5, size.width + 25, size.height + 18);
            cell.rightLabel.text = chatItem.content;
        }
        else
        {
            cell.rightView.hidden = YES;
            cell.lefeView.hidden = YES;
            cell.rightView.hidden = YES;
            cell.lefeView.hidden = YES;
            
            cell.leftVideoButton.hidden = YES;
            cell.rightVideoButton.hidden = NO;
            
            cell.rightVideoButton.tag = 300 + indexPath.row;
            [cell.rightVideoButton addTarget:self action:@selector(cellSelectIndex:) forControlEvents:UIControlEventTouchUpInside];
            [cell.rightVideoButton setImage:[UIImage imageNamed:@"record.png"] forState:UIControlStateNormal];
            
        }
        
        
        
        
        
        
        
    }
    else  // 接受得到
    {
        cell.leftHeadImage.hidden = NO;
        cell.rightHeadImage.hidden = YES;
       
        
        
        if(chatItem.states == picStates)
        {
            cell.rightView.hidden = YES;
            cell.lefeView.hidden = YES;
            
            cell.leftVideoButton.hidden = YES;
            cell.rightVideoButton.hidden = YES;
            
            cell.leftPicImage.image = chatItem.picImage;
            cell.rightPicImage.hidden = YES;
            cell.leftPicImage.hidden = NO;
            
           
            
            
        }
        else if(chatItem.states == textStates)
        {
            cell.rightPicImage.hidden = YES;
            cell.leftPicImage.hidden = YES;
            
            cell.rightView.hidden = YES;
            cell.lefeView.hidden = NO;
            
            cell.leftVideoButton.hidden = YES;
            cell.rightVideoButton.hidden = YES;
            
            cell.leftLabel.frame = CGRectMake(15, 5, size.width, size.height);
            
            cell.lefeView.frame = CGRectMake(40, 5, size.width +30, size.height + 25);
            
            cell.leftLabel.text = chatItem.content;
        }
        else
        {
            cell.rightView.hidden = YES;
            cell.lefeView.hidden = YES;
            cell.rightView.hidden = YES;
            cell.lefeView.hidden = YES;
            
            cell.leftVideoButton.hidden = NO;
            cell.rightVideoButton.hidden = YES;
            
            
            cell.leftVideoButton.tag = 300 + indexPath.row;
            [cell.leftVideoButton setImage:[UIImage imageNamed:@"record.png"] forState:UIControlStateNormal];
            [cell.leftVideoButton addTarget:self action:@selector(cellSelectIndex:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        
        
    }

    
    return cell;
}

- (void)cellSelectIndex:(UIButton *)cellBtn
{
    
    ChatItem *chatIden = [self.datasource objectAtIndex:cellBtn.tag - 300];
    if(chatIden.states == videoStates)
    {
        NSLog(@"realy play");
//        [self makeVideoPlayer:[self getVideoStremData]];
        [self makeVideoPlayer:chatIden.recordData];
    }
}


#pragma mark 下面是核心的连接MCSession 和  数据返回的地方

/***************************-------**********************************************/
- (void)makeBlueData
{
      // 这是为了让 在block中弱引用
    __weak typeof (self) weakSelf = self;
    self.datasource = [NSMutableArray arrayWithCapacity:0];
    
    // 初始化  会议室
    self.sessionManager = [[BlueSessionManager alloc]initWithDisplayName:[NSString stringWithFormat:@" %@",  [[UIDevice currentDevice] name]]];
    
    //
    [self.sessionManager didReceiveInvitationFromPeer:^void(MCPeerID *peer, NSData *context) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"是否连接？" message:[NSString stringWithFormat:@"同 %@%@", peer.displayName, @" 连接?"] delegate:strongSelf cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView show];
    }];
    
    [self.sessionManager peerConnectionStatusOnMainQueue:YES block:^(MCPeerID *peer, MCSessionState state) {
        if(state == MCSessionStateConnected) {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"已经连接" message:[NSString stringWithFormat:@"现在连接 %@了！", peer.displayName] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil];
            [alertView show];
        }
    }];
    
    // 发正常数据的返回
    [self.sessionManager receiveDataOnMainQueue:YES block:^(NSData *data, MCPeerID *peer) {
       
        __strong typeof (weakSelf) strongSelf = weakSelf;
        
        NSString *string = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        
        ChatItem * chatItem = [[ChatItem alloc] init];
        chatItem.isSelf = NO;
        chatItem.states = textStates;
        chatItem.content = string;
        [strongSelf.datasource addObject:chatItem];
        // 加到数组里面
        
        [strongSelf insertTheTableToButtom];
        
        
    }];
    
    // 发图片之后的返回
    [self.sessionManager receiveFinalResourceOnMainQueue:YES complete:^(NSString *name, MCPeerID *peer, NSURL *url, NSError *error) {
        
        __strong typeof (weakSelf) strongSelf = weakSelf;
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        ChatItem * chatItem = [[ChatItem alloc] init];
        chatItem.isSelf = NO;
        chatItem.states = picStates;
        chatItem.content = name;
        chatItem.picImage = [UIImage imageWithData:data];
        [strongSelf.datasource addObject:chatItem];
        [strongSelf insertTheTableToButtom];
        
    }];
    
    
    
    // 流
    [self.sessionManager didReceiveStreamFromPeer:^(NSInputStream *stream, MCPeerID *peer, NSString *streamName) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        strongSelf.inputStream = stream;
        strongSelf.inputStream.delegate = self;
        [strongSelf.inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [strongSelf.inputStream open];
        
        NSLog(@"we need");
        
    }];
    
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.sessionManager connectToPeer:buttonIndex == 1];
}





#pragma mark 下面是流的传输

/***********--------------------- 下面是流的传输 ------------------------***********************************/

- (void)videoRecord
{
    // 播放录音
    [self SetTempRecordView];
}


- (void)sendAsStream
{
    if(!self.sessionManager.isConnected)
    {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"蓝牙已经断开了，请重新连接！" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"知道了", nil];
        [alertView show];
        return;
    }
   
    NSError *err;
    self.outputStream = [self.sessionManager streamWithName:@"super stream" toPeer:self.sessionManager.firstPeer error:&err];
    self.outputStream.delegate = self;
    [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    if(err || !self.outputStream) {
        NSLog(@"%@", err);
    }
    else
    {
        
        [self.outputStream open];
    }
}

// 下面是一个代理
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
   
    if(eventCode == NSStreamEventHasBytesAvailable)
    {
         // 有可读的字节，接收到了数据
        NSInputStream *input = (NSInputStream *)aStream;
        uint8_t buffer[1024];
        NSInteger length = [input read:buffer maxLength:1024];
        [self.streamData appendBytes:(const void *)buffer length:(NSUInteger)length];
       // 记住这边的数据陆陆续续的
    }
    else if(eventCode == NSStreamEventHasSpaceAvailable)
    {
        // 可以使用输出流的空间，此时可以发送数据给服务器
        // 发送数据的
        NSData *data = [self getVideoStremData];
        ChatItem * chatItem = [[ChatItem alloc] init];
        chatItem.isSelf = YES;
        chatItem.states = videoStates;
        chatItem.recordData = data;
        
        [self.datasource addObject:chatItem];
        [self insertTheTableToButtom];
        
        NSOutputStream *output = (NSOutputStream *)aStream;
        [output write:data.bytes maxLength:data.length];
        [output close];
    }
    if(eventCode == NSStreamEventEndEncountered)
    {
        // 流结束事件，在此事件中负责做销毁工作
        // 同时也是获得最终数据的好地方
        
        ChatItem * chatItem = [[ChatItem alloc] init];
        chatItem.isSelf = NO;
        chatItem.states = videoStates;
        chatItem.recordData = self.streamData;
        
        [self.datasource addObject:chatItem];
        [self insertTheTableToButtom];
        
        [aStream close];
        [aStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        if([aStream isKindOfClass:[NSInputStream class]])
        {
            self.streamData = nil;
        }
        
    }
    if(eventCode == NSStreamEventErrorOccurred)
    {
        // 发生错误
        NSLog(@"error");
    }
}

- (NSMutableData *)streamData
{
    if(!_streamData) {
        _streamData = [NSMutableData data];
    }
    return _streamData;
}

/***********-----------------------  公用的数据 --------------------***********************************/

- (NSData *)imageData
{
    return [NSData dataWithContentsOfURL:[self imageURL]];
}

- (NSURL *)imageURL {
    NSString *path = [[NSBundle mainBundle]pathForResource:@"301-alien-ship@2x" ofType:@"png"];
    // 这儿有个技术点
    // 那个如何将 image转化成 路径
   
    NSURL *url = [NSURL fileURLWithPath:path];
    return url;
}

/***********----------------------------------------------***********************************/
#pragma mark 尝试空白处的连接

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [[event allTouches] anyObject];
    if(touch.tapCount >= 1)
    {
        [self.sendTextView resignFirstResponder];
    }
}


/***********-------------------语音---------------------------***********************************/

#pragma mark 尝试语音的录制和播出

- (void)buildVideoForWe
{
    // 设置录音会话
    [self setAudioSession];
}

- (void)SetTempRecordView
{
    _backRemindRecordView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 150)];
    _backRemindRecordView.center = self.view.center;
    _backRemindRecordView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_backRemindRecordView];
    
    
    UILabel * beginLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 50, WIDTH -120, 50)];
    beginLabel.backgroundColor = [UIColor greenColor];
    beginLabel.text = @"长按录音开始···";
    beginLabel.tag = 1001;
    beginLabel.textAlignment = NSTextAlignmentCenter;
    beginLabel.userInteractionEnabled = YES;
    [_backRemindRecordView addSubview:beginLabel];
    
    UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressNextDo:)];
    [beginLabel addGestureRecognizer:longPress];
    

    
    
    
    
}



- (void)longPressNextDo:(UILongPressGestureRecognizer * )longPress
{
    if(longPress.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"begin");
        UILabel * label = (UILabel *)[_backRemindRecordView viewWithTag:1001];
        label.text = @"录音正在进行中···";
        label.backgroundColor = [UIColor orangeColor];
        [self BeginRecordClick];
    }
    if(longPress.state == UIGestureRecognizerStateEnded)
    {
        [self OkStopClick];
        [_backRemindRecordView removeFromSuperview];
        [self  sendAsStream];
        NSLog(@"stop");
       
    }
}


#pragma mark - 私有方法
/**
 *  设置音频会话
 */
-(void)setAudioSession
{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

/**
 *  取得录音文件保存路径
 *
 *  @return 录音文件路径
 */
-(NSURL *)getSavePath
{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:kRecordAudioFile];
    NSLog(@"file path:%@",urlStr);
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}

- (NSData *)getVideoStremData
{
    return [NSData dataWithContentsOfURL:[self getSavePath]];
}


/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}

/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
-(AVAudioRecorder *)audioRecorder
{
    if (!_audioRecorder) {
        //创建录音文件保存路径
        NSURL *url=[self getSavePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

/**
 *  创建播放器
 *
 *  @return 播放器
 */


- (void)makeVideoPlayer:(NSData *)data
{
    NSError *error=nil;
    self.audioPlayer=[[AVAudioPlayer alloc]initWithData:data error:&error];
    self.audioPlayer.delegate = self;
    self.audioPlayer.numberOfLoops=0;
    [self.audioPlayer prepareToPlay];
    if (error)
    {
        NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
       
    }
    else
    {
        if (![self.audioPlayer isPlaying]) {
            NSLog(@"play");
                [self.audioPlayer play];
        }
        
    }
}





/**
 *  录音声波监控定制器
 *
 *  @return 定时器
 */
-(NSTimer *)timer{
    if (!_timer) {
        _timer=[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}

/**
 *  录音声波状态设置
 */
-(void)audioPowerChange{
    [self.audioRecorder updateMeters];//更新测量值
    float power= [self.audioRecorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围时-160到0
    CGFloat progress=(1.0/160.0)*(power+160.0);
    [self.audioPower setProgress:progress];
}
#pragma mark - UI事件
/**
 *  点击录音按钮
 *
 *  @param sender 录音按钮
 */
- (void)BeginRecordClick
{
    if (![self.audioRecorder isRecording])
    {
        [self.audioRecorder record];//首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        self.timer.fireDate=[NSDate distantPast];
    }
}

/**
 *  点击暂定按钮
 *
 *  @param sender 暂停按钮
 */
- (void)StopPauseClick
{
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder pause];
        self.timer.fireDate=[NSDate distantFuture];
    }
}


/**
 *  点击停止按钮
 *
 *  @param sender 停止按钮
 */
- (void)OkStopClick
{
    [self.audioRecorder stop];
    self.timer.fireDate=[NSDate distantFuture];
    self.audioPower.progress=0.0;
}

#pragma mark - 录音机代理方法
/**
 *  录音完成，录音完成后播放录音
 *
 *  @param recorder 录音机对象
 *  @param flag     是否成功
 */
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
//    if (![self.audioPlayer isPlaying]) {
//        [self.audioPlayer play];
//    }
    NSLog(@"录音完成!");
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    
    // 每次完成后都将这个对象释放
    player =nil;
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
