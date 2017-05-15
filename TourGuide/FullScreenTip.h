//
//  FullScreenTip.h
//  Hike
//
//  Created by Rohan on 02/05/17.
//  Copyright © 2017 Hike Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(int, FullScreenTipType) {
    FullScreenTipTypeBubble = 0,
    FullScreenTipTypeHighlight,
};

typedef NS_ENUM(int, FullScreenTipTextPosition) {
    FullScreenTipTextPositionTop = 0,
    FullScreenTipTextPositionBottom,
};

@class FullScreenTip;

@protocol FullScreenTipDelegate <NSObject>

- (void)tipDidAppear:(FullScreenTip *)tip;
- (void)tipDidDismiss:(FullScreenTip *)tip;

@end

@interface FullScreenTip : UIView

@property (nonatomic, copy) NSAttributedString *titleAttributedString;
@property (nonatomic, copy) NSAttributedString *subtitleAttributedString;
@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, copy) NSString *subtitleString;
@property (nonatomic, assign) CGFloat bubbleRadius;
@property (nonatomic, assign) CGFloat yOffset;
@property (nonatomic, weak) id<FullScreenTipDelegate> delegate;
@property (nonatomic, assign) FullScreenTipTextPosition textPosition;
@property (nonatomic, copy) void (^dismissalBlock)(void);
@property (nonatomic, copy) UIImage *icon;

- (instancetype)initTipOfType:(FullScreenTipType)tipType withTargetView:(UIView *)targetView;
- (void)prepareForDisplay;
- (void)showWithAnimation:(BOOL)animated completion:(void(^)(void))completionBlock;
- (void)showContentAnimated:(BOOL)animated completion:(void(^)(void))completionBlock;
- (void)dismissWithAnimation:(BOOL)animated completion:(void(^)(void))completionBlock;
- (void)hideContentAnimated:(BOOL)animated completion:(void(^)(void))completionBlock;

@end
