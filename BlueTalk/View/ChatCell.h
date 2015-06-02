//
//  ChatCell.h
//  UInet Bubble
//
//  Created by qianfeng on 14-7-23.
//  Copyright (c) 2014年 qianfeng. All rights reserved.
//

#import <UIKit/UIKit.h>

//@protocol CellSelectIndex <NSObject>
//
//- (void)cellSelectIndex;
//
//@end


@interface ChatCell : UITableViewCell



@property(nonatomic,strong)UIImageView * lefeView;
@property(nonatomic,strong)UIImageView * rightView;
@property(nonatomic,strong)UILabel * leftLabel;
@property(nonatomic,strong)UILabel * rightLabel;


@property(nonatomic,strong)UIImageView * leftHeadImage;
@property(nonatomic,strong)UIImageView * rightHeadImage;

@property(nonatomic,strong)UIImageView * leftPicImage;
@property(nonatomic,strong)UIImageView * rightPicImage;


@property(nonatomic ,strong)UIButton * leftVideoButton;
@property(nonatomic, strong)UIButton * rightVideoButton;

//@property(nonatomic,weak)id <CellSelectIndex> delegate;

// 不能用名字相同的属性
//  记住自动的时候，讲一下 weak  and strong 

@end
