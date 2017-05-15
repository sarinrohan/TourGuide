//
//  TipTour.m
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

#import "TipTour.h"

@interface TipTour ()
@property (nonatomic, assign) BOOL isAutoPlaying;
@property (nonatomic, assign) NSTimeInterval displayInterval;
@property (nonatomic, strong) FullScreenTip *currentlyDisplayedTip;
@property (nonatomic, strong) NSMutableArray<FullScreenTip *> *tourTips;
@property (nonatomic, strong) NSTimer *autoplayTimer;
@end

@implementation TipTour
- (instancetype)initTourWithTips:(NSArray<FullScreenTip *> *)tips shouldAutoplay:(BOOL)autoplay withDisplayInterval:(NSTimeInterval)displayInterval {
    if (self = [super init]) {
        _tourTips = [tips mutableCopy];
        _isAutoPlaying = autoplay;
        _displayInterval = displayInterval;
    }
    return self;
}

- (void)start {
    if (self.tourTips.count > 0) {
        if (self.isAutoPlaying) {
            [self scheduleTimer];
        }
        self.currentlyDisplayedTip = self.tourTips.firstObject;
        [self.tourTips removeObject:self.currentlyDisplayedTip];
        __weak TipTour *weakSelf = self;
        self.currentlyDisplayedTip.dismissalBlock = ^{
            [weakSelf showNextTip];
        };
        [self.currentlyDisplayedTip prepareForDisplay];
        [self.currentlyDisplayedTip showContentAnimated:NO completion:^{
            [self.currentlyDisplayedTip showWithAnimation:YES completion:nil];
        }];
    }
}

- (void)pause {
    [self.currentlyDisplayedTip dismissWithAnimation:YES completion:nil];
    self.currentlyDisplayedTip = nil;
    [self invalidateTimer];
}

- (void)resume {
    [self start];
}

- (void)stop {
    [self.currentlyDisplayedTip dismissWithAnimation:YES completion:nil];
    self.currentlyDisplayedTip = nil;
    [self invalidateTimer];
}

- (void)scheduleTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.autoplayTimer == nil) {
            self.autoplayTimer = [NSTimer timerWithTimeInterval:self.displayInterval target:self selector:@selector(showNextTip) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.autoplayTimer forMode:NSRunLoopCommonModes];
        }
    });
}

- (void)invalidateTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.autoplayTimer != nil) {
            [self.autoplayTimer invalidate];
            self.autoplayTimer = nil;
        }
    });
}

- (void)showNextTip {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.tourTips.count == 0) {
            [self stop];
            return;
        }
        [self invalidateTimer];
        if (self.currentlyDisplayedTip) {
            [self.currentlyDisplayedTip hideContentAnimated:YES completion:^{
                [self.currentlyDisplayedTip dismissWithAnimation:NO completion:^{
                    self.currentlyDisplayedTip = self.tourTips.firstObject;
                    [self.tourTips removeObject:self.currentlyDisplayedTip];
                    [self scheduleTimer];
                    __weak TipTour *weakSelf = self;
                    self.currentlyDisplayedTip.dismissalBlock = ^{
                        [weakSelf showNextTip];
                    };
                    [self.currentlyDisplayedTip prepareForDisplay];
                    [self.currentlyDisplayedTip showWithAnimation:NO completion:^{
                        [self.currentlyDisplayedTip showContentAnimated:YES completion:nil];
                    }];
                }];
            }];
        }
    });
}
@end
