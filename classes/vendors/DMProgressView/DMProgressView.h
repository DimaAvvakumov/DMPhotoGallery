//
//  DMProgressView.h
//  igazeta
//
//  Created by Dima Avvakumov on 09.12.13.
//  Copyright (c) 2013 East-media. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DMProgressView : UIView

- (void) setLineWidth: (float) width;
- (void) setLineColorStart: (UIColor *) startColor end: (UIColor *) endColor;
- (void) setLineBackColor: (UIColor *) backColor;
- (void) setUnderlineColor: (UIColor *) underlineColor;

- (void) startAnimating;
- (void) stopAnimating;

- (void) setProgress: (float) progress;
- (void) setProgress: (float) progress withDuration:(NSTimeInterval)duration;

- (void) showPercentWithFont:(UIFont*)font andOffsetY:(float) offset;

@end
