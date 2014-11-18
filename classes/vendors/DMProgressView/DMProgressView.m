//
//  DMProgressView.m
//  igazeta
//
//  Created by Dima Avvakumov on 09.12.13.
//  Copyright (c) 2013 East-media. All rights reserved.
//

#import "DMProgressView.h"

@interface DMProgressView() {
    float _lineHeight;
    float _animationAngel;
    NSTimeInterval _animationRate;
    float _progress;
    
    float _progressStartValue, _progressEndValue;
    NSTimeInterval _progressAnimationStartTime, _progressAnimationDuration;
    
    BOOL _needGenerateUndeterminateCircle;
}

@property (strong, nonatomic) UIColor *startColor;
@property (strong, nonatomic) UIColor *endColor;
@property (strong, nonatomic) UIColor *backColor;
@property (strong, nonatomic) UIColor *internalUnderlineColor;

@property (strong, nonatomic) NSTimer *animationTimer;
@property (strong, nonatomic) NSTimer *progressAnimationTimer;

@property (strong, nonatomic) UIImageView *undeterminateCircleView;

@property (strong, nonatomic) UILabel *percentLabel;

@end

@implementation DMProgressView

#pragma mark - Init methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initView];
        
    }
    
    return self;
}

- (void) initView {
    // set up view
    self.backgroundColor = [UIColor clearColor];
    
    // set up internal
    _lineHeight = 1.0;
    _animationAngel = 0.0;
    _needGenerateUndeterminateCircle = YES;
    _animationRate = 0.04;
    self.startColor = nil;
    self.endColor = nil;
    
    // image view
    CGRect imageViewRect = CGRectZero;
    imageViewRect.size = self.frame.size;
    UIImageView *undeterminateCircleView = [[UIImageView alloc] initWithFrame:imageViewRect];
    undeterminateCircleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview: undeterminateCircleView];
    self.undeterminateCircleView = undeterminateCircleView;
    
    // startup generation
    [self generateUndeterminateCircleView];
}

- (void) dealloc {
    [_animationTimer invalidate];
    [_progressAnimationTimer invalidate];
}

- (void) showPercentWithFont:(UIFont*)font andOffsetY:(float) offset {
    if (!self.percentLabel) {
        self.percentLabel = [[UILabel alloc] initWithFrame:CGRectMake(.0, offset, self.frame.size.width, self.frame.size.height)];
//        [_percentLabel setBackgroundColor:[UIColor whiteColor]];
        [_percentLabel setTextColor:self.startColor];
        [_percentLabel setFont:font];
        [_percentLabel setTextAlignment:NSTextAlignmentCenter];
        [self.percentLabel setText:@""];
        [self addSubview:_percentLabel];
    }
}

#pragma mark - Set up methods

- (void) setLineWidth: (float) width {
    _lineHeight = width;
    
    _needGenerateUndeterminateCircle = YES;
    [self setNeedsDisplay];
}

- (void) setLineColorStart: (UIColor *) startColor end: (UIColor *) endColor {
    self.startColor = startColor;
    self.endColor = endColor;
    
    _needGenerateUndeterminateCircle = YES;
    [self setNeedsDisplay];
}

- (void) setLineBackColor: (UIColor *) backColor {
    self.backColor = backColor;
    
    [self setNeedsDisplay];
}

- (void) setUnderlineColor: (UIColor *) underlineColor {
    self.internalUnderlineColor = underlineColor;
    
    [self setNeedsDisplay];
}

- (void) setProgress: (float) progress {
    [self stopAnimating];
    [_undeterminateCircleView setHidden: (_progress > 0)];
    
    if (progress < 0.0) progress = 0.0;
    if (progress > 1.0) progress = 1.0;
    
    _progress = progress;
    if (_progress > .1) {
        [_percentLabel setText:[NSString stringWithFormat:@"%.0f%%", (double)(_progress*100.0)]];
    }
    
    [self setNeedsDisplay];
}

- (void) setProgress:(float)progress withDuration:(NSTimeInterval)duration {
    if (duration == 0.0) {
        [self setProgress: progress];
        
        return;
    }
    
    [self stopAnimating];
    [_undeterminateCircleView setHidden: (progress > 0)];
    
    if (progress < 0.0) progress = 0.0;
    if (progress > 1.0) progress = 1.0;
    
    _progressAnimationStartTime = [NSDate timeIntervalSinceReferenceDate];
    _progressAnimationDuration = duration;
    _progressStartValue = _progress;
    _progressEndValue = progress;
    
    if (_progressAnimationTimer == nil) {
        self.progressAnimationTimer = [NSTimer timerWithTimeInterval: _animationRate target: self selector:@selector(updateProgressAnimation:) userInfo: nil repeats: YES];
        [[NSRunLoop mainRunLoop] addTimer: _progressAnimationTimer forMode:NSRunLoopCommonModes];
    }
}

- (void) updateProgressAnimation: (NSTimer *) timer {
    NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (curTime > _progressAnimationStartTime + _progressAnimationDuration) {
        _progress = _progressEndValue;
        [self setNeedsDisplay];
        
        [_progressAnimationTimer invalidate];
        self.progressAnimationTimer = nil;
        
        return;
    }
    
    float percent = (curTime - _progressAnimationStartTime) / _progressAnimationDuration;
    _progress = percent * ( _progressEndValue - _progressStartValue );
    
    if (_progress > .1) {
        [_percentLabel setText:[NSString stringWithFormat:@"%.0f%%", (double)(_progress*100.0)+2.0]];
    }
    
    [self setNeedsDisplay];
}

- (void) startAnimating {
    if (_animationTimer) [_animationTimer invalidate];
    
    self.animationTimer = [NSTimer timerWithTimeInterval: _animationRate target: self selector:@selector(updateAnimation:) userInfo: nil repeats: YES];
    [[NSRunLoop mainRunLoop] addTimer: _animationTimer forMode:NSRunLoopCommonModes];
}

- (void) stopAnimating {
    if (_animationTimer) [_animationTimer invalidate];
    
    self.animationTimer = nil;
}

- (void) updateAnimation: (NSTimer *) timer {
    _animationAngel += 0.2;
    
    CGAffineTransform t = CGAffineTransformMakeRotation(_animationAngel);
    [_undeterminateCircleView setTransform:t];
}

#pragma mark - Draw rect circle

- (void) generateUndeterminateCircleView {
    
    CGSize contextSize = self.frame.size;
    UIGraphicsBeginImageContextWithOptions(contextSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // initial variables
    CGFloat radius = floorf(self.frame.size.width / 2.0);
    int countSlices = 12;
    CGFloat delta = 2.0 * M_PI / (float) countSlices;
    
    // color component original red/green/blue start/end
    CGFloat ccorStart = 1.0;
    CGFloat ccogStart = 1.0;
    CGFloat ccobStart = 1.0;
    CGFloat ccoaStart = 0.0;
    CGFloat ccorEnd = 1.0;
    CGFloat ccogEnd = 1.0;
    CGFloat ccobEnd = 1.0;
    CGFloat ccoaEnd = 1.0;
    
//    if (_startColor) {
//        [_startColor getRed:&ccorStart green:&ccogStart blue:&ccobStart alpha:&ccoaStart];
//        [_startColor getRed:&ccorEnd green:&ccogEnd blue:&ccobEnd alpha:nil];
//    }
//    if (_endColor) {
//        [_endColor getRed:&ccorEnd green:&ccogEnd blue:&ccobEnd alpha:&ccoaEnd];
//    }
    if (_startColor) {
        [_startColor getRed:&ccorEnd green:&ccogEnd blue:&ccobEnd alpha:&ccoaEnd];
        [_startColor getRed:&ccorStart green:&ccogStart blue:&ccobStart alpha:nil];
    }
    if (_endColor) {
        [_endColor getRed:&ccorStart green:&ccogStart blue:&ccobStart alpha:&ccoaStart];
    }
    
    for (int i = 0; i < countSlices; i++) {
        CGContextSaveGState(context);
        
        CGFloat startAngel = i * delta;
        CGFloat endAngel = startAngel + delta;
        
        // draw clip area
        CGContextBeginPath(context);
        CGContextAddArc(context, radius, radius, radius, startAngel, endAngel, 0);
        CGContextAddArc(context, radius, radius, radius - _lineHeight, endAngel, startAngel, 1);
        CGContextClosePath(context);
        CGContextClip(context);
        
		//Gradient colours
        float countComponents = (float) (countSlices + 1.0f);
        float ccrStart = ccorStart + (float) i * ((ccorEnd - ccorStart) / countComponents);
        float ccgStart = ccogStart + (float) i * ((ccogEnd - ccogStart) / countComponents);
        float ccbStart = ccobStart + (float) i * ((ccobEnd - ccobStart) / countComponents);
        float ccaStart = ccoaStart + (float) i * ((ccoaEnd - ccoaStart) / countComponents);
        float ccrEnd = ccorStart + ((float) i + 1.0f) * ((ccorEnd - ccorStart) / countComponents);
        float ccgEnd = ccogStart + ((float) i + 1.0f) * ((ccogEnd - ccogStart) / countComponents);
        float ccbEnd = ccobStart + ((float) i + 1.0f) * ((ccobEnd - ccobStart) / countComponents);
        float ccaEnd = ccoaStart + ((float) i + 1.0f) * ((ccoaEnd - ccoaStart) / countComponents);
        
		size_t gradLocationsNum = 2;
		CGFloat gradLocations[2] = {0.0f, 1.0f};
		CGFloat gradColors[8] = {ccrStart,ccgStart,ccbStart,ccaStart,ccrEnd,ccgEnd,ccbEnd,ccaEnd};
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, gradColors, gradLocations, gradLocationsNum);
		CGColorSpaceRelease(colorSpace);
        
        CGPoint startPoint;
        startPoint.x = radius + radius * cosf(startAngel);
        startPoint.y = radius + radius * sinf(startAngel);
        CGPoint endPoint;
        endPoint.x = radius + radius * cosf(endAngel);
        endPoint.y = radius + radius * sinf(endAngel);
        
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

        CGContextRestoreGState(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [_undeterminateCircleView setImage:image];
    
    _needGenerateUndeterminateCircle = NO;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (_needGenerateUndeterminateCircle) {
        [self generateUndeterminateCircleView];
    }
    
    if (_progress > 0.0) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // initial variables
        CGFloat radius = floorf(self.frame.size.width / 2.0);
        UIColor *drawColor, *backColor, *underlineColor = nil;
        
        if (_startColor) {
            drawColor = _startColor;
        } else {
            drawColor = [UIColor whiteColor];
        }
        if (_backColor) {
            backColor = _backColor;
        } else {
            backColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
        }
        if (_internalUnderlineColor) {
            underlineColor = _internalUnderlineColor;
        }
        
        // draw underline color
        if (underlineColor) {
            CGContextSetFillColorWithColor(context, underlineColor.CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(0.0, 0.0, 2.0 * radius, 2.0 * radius));
        }
        
        CGFloat startAngel = 0.0 - M_PI / 2.0;
        CGFloat endAngel = _progress * 2.0 * M_PI - M_PI / 2.0;
        
        // draw line
        CGContextBeginPath(context);
        CGContextAddArc(context, radius, radius, radius, 0.0, 2.0 * M_PI, 0);
        CGContextAddArc(context, radius, radius, radius - _lineHeight, 2.0 * M_PI, 0.0, 1);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, backColor.CGColor);
        CGContextFillPath(context);

        // draw progress arc
        CGContextBeginPath(context);
        CGContextAddArc(context, radius, radius, radius, startAngel, endAngel, 0);
        CGContextAddArc(context, radius, radius, radius - _lineHeight, endAngel, startAngel, 1);
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, drawColor.CGColor);
        CGContextFillPath(context);
    }
}

@end
