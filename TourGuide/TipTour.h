//
//  TipTour.h
//  Hike
//
//  Created by Rohan on 02/05/17.
//  Copyright © 2017 Hike Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FullScreenTip.h"

@interface TipTour : NSObject

- (instancetype)initTourWithTips:(NSArray<FullScreenTip *> *)tips shouldAutoplay:(BOOL)autoplay withDisplayInterval:(NSTimeInterval)displayInterval;
- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;

@end
