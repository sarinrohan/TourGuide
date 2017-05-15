//
//  FullScreenTip.m
//  Hike
//
//  Created by Rohan on 02/05/17.
//  Copyright © 2017 Hike Pvt. Ltd. All rights reserved.
//

/************************************************************
 * THIS FILE USES ARC
 *************************************************************/
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC.
#endif

#import "FullScreenTip.h"

static const CGFloat BSBFullScreenTipDefaultYOffset = 50.f;
#define BSBFullScreenTipTitleDefaultFont [UIFont fontWithName:@"FaktSoftPro-Medium" size:16.f]
#define BSBFullScreenTipSubtitleDefaultFont [UIFont fontWithName:@"FaktSoftPro-Normal" size:14.f]
#define distanceBetweenCGPoints(p1, p2) sqrt(pow(p2.x-p1.x,2)+pow(p2.y-p1.y,2))

@interface FullScreenTip ()
@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, weak) UIView *labelContainerView;
@property (nonatomic, weak) UIImageView *iconView;
@property (nonatomic, assign) FullScreenTipType tipType;
@property (nonatomic, weak) UIWindow *mainWindow;
@property (nonatomic, assign) CGRect titleLabelRect;
@property (nonatomic, assign) CGRect subtitleLabelRect;
@property (nonatomic, assign) CGRect targetViewRectInWindow;
@end

@implementation FullScreenTip

- (instancetype)initTipOfType:(FullScreenTipType)tipType withTargetView:(UIView *)targetView {
    if (self = [self initWithFrame:CGRectZero]) {
        if ([targetView isKindOfClass:[UIBarButtonItem class]]) {
            targetView = [targetView valueForKey:@"view"];
        }
        _targetView = targetView;
        _tipType = tipType;
        _mainWindow = [[UIApplication sharedApplication].windows firstObject];
        _yOffset = BSBFullScreenTipDefaultYOffset;
    }
    return self;
}

- (void)initializeStringsIfNeeded {
    if (self.titleAttributedString == nil && self.titleString != nil) {
        NSMutableAttributedString *titleAttrString = [[NSMutableAttributedString alloc] initWithString:self.titleString];
        [titleAttrString addAttribute:NSFontAttributeName value:BSBFullScreenTipTitleDefaultFont range:NSMakeRange(0, self.titleString.length)];
        [titleAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, self.titleString.length)];
        self.titleAttributedString = titleAttrString;
    }

    if (self.subtitleAttributedString == nil && self.subtitleString != nil) {
        NSMutableAttributedString *subtitleAttrString = [[NSMutableAttributedString alloc] initWithString:self.subtitleString];
        [subtitleAttrString addAttribute:NSFontAttributeName value:BSBFullScreenTipSubtitleDefaultFont range:NSMakeRange(0, self.subtitleString.length)];
        [subtitleAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, self.subtitleString.length)];
        self.subtitleAttributedString = subtitleAttrString;
    }
}

- (BOOL)verifyLayoutFeasibility {
    [self initializeStringsIfNeeded];
    CGFloat heightNeeded = 0.f;
    CGFloat widthNeeded = 0.f;
    heightNeeded += self.yOffset;
    if (self.titleAttributedString) {
        self.titleLabelRect = CGRectIntegral([self.titleAttributedString boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.mainWindow.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil]);
        heightNeeded += CGRectGetHeight(self.titleLabelRect);
        widthNeeded = CGRectGetWidth(self.titleLabelRect);
    }
    if (self.subtitleAttributedString) {
        self.subtitleLabelRect = CGRectIntegral([self.subtitleAttributedString boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.mainWindow.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil]);
        heightNeeded += CGRectGetHeight(self.subtitleLabelRect);
        if (CGRectGetWidth(self.subtitleLabelRect) > widthNeeded) {
            widthNeeded = CGRectGetWidth(self.subtitleLabelRect);
        }
    }

    BOOL isFeasible = YES;
    switch (self.textPosition) {
        case FullScreenTipTextPositionTop: {
            isFeasible = self.targetViewRectInWindow.origin.y > heightNeeded;
        }
            break;
        case FullScreenTipTextPositionBottom: {
            isFeasible = (CGRectGetMaxY(self.targetViewRectInWindow) + heightNeeded) < CGRectGetMaxY(self.mainWindow.bounds);
        }
            break;

        default:
            break;
    }

    isFeasible = isFeasible && (widthNeeded < CGRectGetWidth(self.mainWindow.bounds));

    return isFeasible;
}

- (void)prepareForDisplay {
    NSAssert(self.targetView != nil, @"Please provide a correct target view");
    NSAssert(self.targetView.window != nil, @"The target view is not on screen");
    [self.mainWindow endEditing:YES];
    self.hidden = YES;
    self.targetViewRectInWindow = [self.targetView convertRect:self.targetView.bounds toView:self.mainWindow];
    NSAssert([self verifyLayoutFeasibility], @"This layout is infeasible. More space is required on screen");
    if (!self.superview) {
        [self.mainWindow addSubview:self];
        self.frame = self.mainWindow.bounds;
    }
    [self setupLayers];
    [self setupViews];
}

- (void)setupLayers {
    UIBezierPath *completeWindow = [UIBezierPath bezierPathWithRect:self.mainWindow.bounds];
    UIBezierPath *seeThroughPath = nil;

    switch (self.tipType) {
        case FullScreenTipTypeHighlight: {
            CGRect rectForTargetInWindow = [self.targetView convertRect:self.targetView.bounds toView:self.mainWindow];
            seeThroughPath = [UIBezierPath bezierPathWithRect:rectForTargetInWindow];
        }
            break;
        case FullScreenTipTypeBubble: {
            CGPoint bubbleCenter = [self.targetView.superview convertPoint:self.targetView.center toView:self.mainWindow];
            seeThroughPath = [UIBezierPath bezierPathWithArcCenter:bubbleCenter radius:self.bubbleRadius startAngle:0.f endAngle:2*M_PI clockwise:YES];
        }
            break;
        default:
            break;
    }
    [completeWindow appendPath:seeThroughPath];
    [completeWindow setUsesEvenOddFillRule:YES];

    CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
    backgroundLayer.path = completeWindow.CGPath;
    backgroundLayer.fillRule = kCAFillRuleEvenOdd;
    backgroundLayer.fillColor = [UIColor blackColor].CGColor;
    backgroundLayer.opacity = 0.8f;
    [self.layer addSublayer:backgroundLayer];
}

- (void)setupViews {
    UITapGestureRecognizer *tapGestReco = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self addGestureRecognizer:tapGestReco];
    UIView *labelContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:labelContainerView];
    self.labelContainerView = labelContainerView;
    self.labelContainerView.alpha = 0.f;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.attributedText = self.titleAttributedString;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [labelContainerView addSubview:titleLabel];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [titleLabel.centerXAnchor constraintEqualToAnchor:labelContainerView.centerXAnchor].active = YES;
    [titleLabel.topAnchor constraintEqualToAnchor:labelContainerView.topAnchor].active = YES;
    [titleLabel.widthAnchor constraintLessThanOrEqualToAnchor:labelContainerView.widthAnchor].active = YES;

    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.attributedText = self.subtitleAttributedString;
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    subtitleLabel.numberOfLines = 0;
    [labelContainerView addSubview:subtitleLabel];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [subtitleLabel.centerXAnchor constraintEqualToAnchor:labelContainerView.centerXAnchor].active = YES;
    [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor].active = YES;
    [subtitleLabel.widthAnchor constraintLessThanOrEqualToAnchor:labelContainerView.widthAnchor].active = YES;

    CGFloat originYCoord = CGRectGetMinY(self.targetViewRectInWindow);
    if (self.textPosition == FullScreenTipTextPositionBottom) {
        originYCoord += CGRectGetHeight(self.targetViewRectInWindow) + self.yOffset + CGRectGetHeight(self.titleLabelRect) + CGRectGetHeight(self.subtitleLabelRect);
    } else if (self.textPosition == FullScreenTipTextPositionTop) {
        originYCoord -= (self.yOffset + CGRectGetHeight(self.titleLabelRect) + CGRectGetHeight(self.subtitleLabelRect));
    }

    CGFloat contentWidth = CGRectGetWidth(self.titleLabelRect);
    if (contentWidth < CGRectGetWidth(self.subtitleLabelRect)) {
        contentWidth = CGRectGetWidth(self.subtitleLabelRect);
    }
    CGFloat originXCoord = CGRectGetMidX(self.targetViewRectInWindow) - (contentWidth/2.f);
    if (originXCoord < 0) {
        originXCoord = 0;
    } else if (originXCoord + contentWidth > CGRectGetMaxX(self.mainWindow.bounds)) {
        originXCoord = CGRectGetMaxX(self.mainWindow.bounds) - contentWidth;
    }

    labelContainerView.frame = CGRectMake(originXCoord, originYCoord, contentWidth, CGRectGetHeight(self.titleLabelRect) + CGRectGetHeight(self.subtitleLabelRect));
    [labelContainerView setNeedsLayout];
    [self addIconIfNeeded];
}

- (void)showWithAnimation:(BOOL)animated completion:(void (^)(void))completionBlock {
    if (animated) {
        self.hidden = NO;
        self.alpha = 0.f;
        [UIView animateWithDuration:0.5f animations:^{
            self.alpha = 1.f;
        } completion:^(BOOL finished) {
            [self.delegate tipDidAppear:self];
            if (completionBlock) {
                completionBlock();
            }
        }];
    } else {
        self.hidden = NO;
        [self.delegate tipDidAppear:self];
        if (completionBlock) {
            completionBlock();
        }
    }
}

- (void)showContentAnimated:(BOOL)animated completion:(void (^)(void))completionBlock {
    if (animated) {
        self.labelContainerView.alpha = 0.f;
        self.iconView.alpha = 0.f;
        [UIView animateWithDuration:0.5f animations:^{
            self.labelContainerView.alpha = 1.f;
            self.iconView.alpha = 1.f;
        } completion:^(BOOL finished) {
            if (completionBlock) {
                completionBlock();
            }
        }];
    } else {
        self.labelContainerView.alpha = 1.f;
        self.iconView.alpha = 1.f;
        if (completionBlock) {
            completionBlock();
        }
    }
}

- (void)dismissWithAnimation:(BOOL)animated completion:(void (^)(void))completionBlock {
    if (animated) {
        [UIView animateWithDuration:0.5f animations:^{
            self.alpha = 0.f;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            [self.delegate tipDidDismiss:self];
            if (completionBlock) {
                completionBlock();
            }
        }];
    } else {
        [self removeFromSuperview];
        [self.delegate tipDidDismiss:self];
        if (completionBlock) {
            completionBlock();
        }
    }
}

- (void)hideContentAnimated:(BOOL)animated completion:(void (^)(void))completionBlock {
    if (animated) {
        [UIView animateWithDuration:0.5f animations:^{
            self.labelContainerView.alpha = 0.f;
            self.iconView.alpha = 0.f;
        } completion:^(BOOL finished) {
            if (completionBlock) {
                completionBlock();
            }
        }];
    } else {
        self.labelContainerView.alpha = 0.f;
        self.iconView.alpha = 0.f;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.tipType == FullScreenTipTypeHighlight) {
        if (CGRectContainsPoint(self.targetViewRectInWindow, point)) {
            return nil;
        }
    } else if (self.tipType == FullScreenTipTypeBubble) {
        CGPoint targetViewRectCenter = CGPointMake(CGRectGetMidX(self.targetViewRectInWindow), CGRectGetMidY(self.targetViewRectInWindow));
        if (distanceBetweenCGPoints(targetViewRectCenter, point) <= self.bubbleRadius) {
            return nil;
        }
    }

    return self;
}

- (void)handleTap {
    if (self.dismissalBlock) {
        self.dismissalBlock();
    } else {
        [self dismissWithAnimation:YES completion:nil];
    }
}

- (void)addIconIfNeeded {
    if (self.icon) {
        CGFloat iconXCoord = (CGRectGetMidX(self.targetViewRectInWindow) + CGRectGetMidX(self.labelContainerView.frame))/2.f;
        CGFloat iconYCoord = (CGRectGetMidY(self.targetViewRectInWindow) + CGRectGetMidY(self.labelContainerView.frame))/2.f;
        CGFloat adjustment = (self.tipType == FullScreenTipTypeBubble) ? self.bubbleRadius/2.f : CGRectGetHeight(self.targetViewRectInWindow)/4.f;
        adjustment -= CGRectGetHeight(self.labelContainerView.frame)/4.f;
        UIImageView *iconView = [[UIImageView alloc] initWithImage:self.icon];
        CGFloat angle = atan2f(CGRectGetMidY(self.targetViewRectInWindow) - CGRectGetMidY(self.labelContainerView.frame), CGRectGetMidX(self.targetViewRectInWindow) - CGRectGetMidX(self.labelContainerView.frame)) + M_PI/2.f;
        CGAffineTransform rotationTransform = CGAffineTransformIdentity;
        rotationTransform = CGAffineTransformMakeRotation(angle);
        iconView.transform = rotationTransform;
        [self addSubview:iconView];
        self.iconView = iconView;
        iconView.center = CGPointMake(iconXCoord - (cosf(angle - (M_PI/2.f)) * adjustment), iconYCoord - (sinf(angle - (M_PI/2.f)) * adjustment));
        //The icon is placed on the approximate center between the edge of the target view and the labels
        //Here we shift the centre along the line joining the centers of the label and target views
    }
}

@end
