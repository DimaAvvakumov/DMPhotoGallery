//
//  DMPhotoGalleryItemViewController.m
//  DMPhotoGallery
//
//  Created by Dima Avvakumov on 15.03.12.
//  Copyright (c) 2012 Dima Avvakumov. All rights reserved.
//

#import "DMPhotoGalleryItemViewController.h"
#import "StandardPaths.h"

// vendors
#import "M13ProgressViewRing.h"
#import "DMImageManager.h"

#define DMPhotoGalleryItemViewController_MaxScale 4.0

@interface DMPhotoGalleryItemViewController () {
    float _minScale;
    float _maxScale;
    float _renderScale;
    
    CGPoint _zoomRelationPos;
}

@property (strong, nonatomic) DMPhotoGalleryModel *itemModel;
@property (strong, nonatomic) UIImage *storeImage;
@property (assign, nonatomic) CGSize storeImageSize;

// IBOutlet progress view
@property (weak, nonatomic) IBOutlet M13ProgressViewRing *pieProgressView;

// IBOutlet scroll view
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *placeholderImageView;

// IBOutlet bottom image view
@property (weak, nonatomic) IBOutlet UIImageView *bottomGradient;

// IBOutlet text label
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@property (assign, nonatomic) BOOL isPhone;
@property (assign, nonatomic) BOOL viewIsPresented;

@property (assign, nonatomic) BOOL interfaceHidden;
@property (assign, nonatomic) UIInterfaceOrientation interfaceOrientation;

@property (assign, nonatomic) CGFloat lastRenderedWidth;

@end

@implementation DMPhotoGalleryItemViewController

- (id)initWithModel:(DMPhotoGalleryModel *)galleryItem andLazyLoad:(BOOL)lazyLoad {
    self = [super initWithNibName:@"DMPhotoGalleryItemViewController" bundle: nil];
    if (self) {
        BOOL imageExist = [[NSFileManager defaultManager] fileExistsAtPath:galleryItem.imagePath];
        
        self.lazyLoad = !imageExist || lazyLoad;
        self.itemModel = galleryItem;
        
        self.mainColor = [UIColor whiteColor];
        self.fontName = @"HelveticaNeue";
        self.fontSize = 12.0;
        
        self.interfaceHidden = NO;
        self.interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        self.lastRenderedWidth = 0.0;
        
        _minScale = 1.0;
        _maxScale = 1.0;
        _renderScale = 1.0;
        
        UIUserInterfaceIdiom ideom = [[UIDevice currentDevice] userInterfaceIdiom];
        self.isPhone = (ideom == UIUserInterfaceIdiomPhone);
        
        self.viewIsPresented = NO;
        
        DMPhotoGalleryItemViewController __weak *weakSelf = self;
        
        NSString *imagePath = _itemModel.imagePath;
        if (imagePath == nil) {
            NSURL *imageURL = _itemModel.imageURL;
            if (imageURL) {
                NSString *localPath = [imageURL.path stringByReplacingOccurrencesOfString:@"://" withString:@"_"];
                imagePath = [[NSFileManager defaultManager] pathForCacheFile:localPath];
            }
        }
        
        if (_lazyLoad) {
            DMImageOperation *operation = [[DMImageOperation alloc] initWithImagePath:imagePath identifer:nil andBlock:^(UIImage *image) {
                
                // store image
                weakSelf.storeImage = image;
                weakSelf.storeImageSize = image.size;
                
                if ([weakSelf isViewLoaded]) {
                    [_pieProgressView setHidden:YES];
                    
                    [weakSelf setupImage:image];
                    [_imageView setAlpha: 0.0];
                    [_placeholderImageView setAlpha: 0.0];
                    [UIView animateWithDuration: 0.3 animations:^{
                        [_imageView setAlpha: 1.0];
                        [_placeholderImageView setAlpha: 1.0];
                    }];
                }
                
            }];
            operation.downloadURL = _itemModel.imageURL;
            [operation setProgressBlock:^(NSNumber *progress) {
                if ([weakSelf isViewLoaded]) {
                    [_pieProgressView setHidden: NO];
                    [_pieProgressView setProgress:[progress floatValue] animated:YES];
                }
            }];
            [[DMImageManager defaultManager] addOperation: operation];
        }
    }
    return self;
}

- (UIImage *) bottomGradientImage {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    UIColor *startColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    UIColor *endColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    NSArray *colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGSize size = CGSizeMake(1.0, 100.0);
    CGPoint startPoint = CGPointMake(0.0, 0.0);
    CGPoint endPoint = CGPointMake(0.0, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // progress view
//    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0];
    [_pieProgressView setProgress:0.0 animated:NO];
//    [_pieProgressView setLineWidth:5.0];
//    [_pieProgressView setLineColorStart:_mainColor end:[UIColor clearColor]];
//    [_pieProgressView showPercentWithFont:font andOffsetY:0.0];
    _pieProgressView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
//    [_pieProgressView startAnimating];
    
    // bottom gradient
    _bottomGradient.image = [self bottomGradientImage];
    
    // interface hidden
    [self setInterfaceHidden:_interfaceHidden animated:NO];
    
    // text
    _textLabel.text = _itemModel.text;
    _textLabel.font = [UIFont fontWithName:_fontName size:_fontSize];
    
    [self redrawTitle];
    
    // pinch gesture
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchHandler:)];
//    [pinchGesture setDelegate: self];
    [_imageView addGestureRecognizer: pinchGesture];
    
    // double tap handler
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapHandler:)];
    [doubleTapGesture setNumberOfTapsRequired: 2];
    [doubleTapGesture setNumberOfTouchesRequired:1];
    [_imageView addGestureRecognizer: doubleTapGesture];

    [self buildView];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.imageView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    self.interfaceOrientation = toInterfaceOrientation;
    
    [self redrawTitle];
    
    [self recalculateScale];
    [self resetScaleAnimated:NO];
}

- (void) viewWillAppear:(BOOL)animated {
    self.interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    [self redrawTitle];
}

- (void) viewDidAppear:(BOOL)animated {
    if (_viewIsPresented == NO) {
        self.viewIsPresented = YES;
        [self performSelector:@selector(presentAfterDelay) withObject:nil afterDelay:0.1];
    }
}

- (void) presentAfterDelay {
    if (_storeImage == nil) return;
    
    [self updatePlaceholderImage];
    
    [self recalculateScale];
    [self resetScaleAnimated:NO];
}

- (void) viewDidDisappear:(BOOL)animated {
    self.viewIsPresented = NO;
    [self updatePlaceholderImage];
}

#pragma mark - Build view

- (void) buildView {
    // set slide to image view
    if (_lazyLoad) {
        if (_storeImage) {
            [self setupImage: _storeImage];
        }
    } else {
        UIImage *image = [UIImage imageWithContentsOfFile: _itemModel.imagePath];
        if (image) {
            self.storeImage = image;
            self.storeImageSize = image.size;
            
            [self setupImage:image];
        }
    }
}

- (void) restrictScaleByFrame {
    [self recalculateScale];
    [self resetScaleAnimated:NO];
}

- (void) setupImage: (UIImage *) image {
    // bind image
    [_imageView setImage: image];
    [_placeholderImageView setImage: image];
    
    // update image frame
    CGRect frame = _imageView.frame;
    frame.size = image.size;
    [_imageView setFrame:frame];
    
    // calculate scale
    if (_viewIsPresented) {
        [self presentAfterDelay];
    }
//    [self recalculateScale];
//    [self resetScaleAnimated:NO];
}

- (void) recalculateScale {
    if (!_storeImage) return;
    
    // image size
    CGFloat imageWidth = _storeImageSize.width;
    CGFloat imageHeight = _storeImageSize.height;
    if (imageWidth == 0.0 || imageHeight == 0.0) return;
    
    // calc scale
    CGFloat scale1 = _scrollView.frame.size.width / _storeImageSize.width;
    CGFloat scale2 = _scrollView.frame.size.height / _storeImageSize.height;
    CGFloat minScale = MIN(scale1, scale2);
    CGFloat maxScale = DMPhotoGalleryItemViewController_MaxScale;
    if (minScale > DMPhotoGalleryItemViewController_MaxScale) {
        maxScale = minScale;
    }
    
    _minScale = minScale;
    _maxScale = maxScale;
}

- (void) resetScaleAnimated: (BOOL) animated {
    _renderScale = _minScale;
    
    [self setMaketToScale:_renderScale animated:animated];
}

#pragma mark - Redraw title

- (void) redrawTitle {
    if (!_textLabel.text) return;
    
    // BOOL isPad = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) ? YES : NO;
    BOOL isLandscape = (UIInterfaceOrientationIsLandscape(_interfaceOrientation)) ? YES : NO;
    
    CGSize screenBoundSize = [UIScreen mainScreen].bounds.size;
    CGFloat screenWidth  = (isLandscape) ? screenBoundSize.height : screenBoundSize.width;
    CGFloat screenHeight = (isLandscape) ? screenBoundSize.width : screenBoundSize.height;
    // CGRect viewFrame = self.view.bounds;
    
    if (_lastRenderedWidth == screenWidth) {
        return;
    }
    self.lastRenderedWidth = screenWidth;
    
    // vars title
    CGFloat textWidth = screenWidth - 40.0;
    
    NSMutableDictionary *textAttr = [NSMutableDictionary dictionaryWithCapacity:1];
    [textAttr setObject:_textLabel.font forKey:NSFontAttributeName];
    
    NSString *text = _textLabel.text;
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:text attributes:textAttr];
    
    CGSize maxSize = CGSizeMake(textWidth, CGFLOAT_MAX);
    CGRect rect = [attrString boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    CGRect labelFrame = CGRectMake(20.0, 0.0, rect.size.width, rect.size.height);
    labelFrame.origin.y = screenHeight - rect.size.height - 64.0;
    
    _textLabel.frame = labelFrame;
    
    // shadow
    CGRect shadowFrame = CGRectMake(0.0, 0.0, screenWidth, rect.size.height + 100.0);
    shadowFrame.origin.y = screenHeight - 44.0 - shadowFrame.size.height;
    _bottomGradient.frame = shadowFrame;
}

#pragma mark - Interface status

- (void) setInterfaceHidden: (BOOL) hidden animated: (BOOL) animated {
    self.interfaceHidden = hidden;
    
    if (![self isViewLoaded]) return;
    
    float alpha = (hidden) ? 0.0 : 1.0;
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{

            _textLabel.alpha = alpha;
            _bottomGradient.alpha = alpha;
            
        } completion:nil];
    } else {
        
        _textLabel.alpha = alpha;
        _bottomGradient.alpha = alpha;

    }
}

- (void) updatePlaceholderImage {
    _placeholderImageView.hidden = _viewIsPresented;
    _scrollView.hidden = !_viewIsPresented;
}

#pragma mark - Zoom methods

- (void) doubleTapHandler:(UITapGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateEnded) return;
    
    CGPoint startPos = [sender locationInView: _imageView];
    _zoomRelationPos.x = startPos.x / _imageView.frame.size.width;
    _zoomRelationPos.y = startPos.y / _imageView.frame.size.height;
    
    CGFloat zoomScale = _minScale;
    if (_renderScale == _minScale) {
        zoomScale = _maxScale;
    }
    
    [self setMaketToScale:zoomScale animated:YES];
}

- (void) pinchHandler:(UIPinchGestureRecognizer *)sender {
    //NSLog(@"Pinch scale: %f,\tvelocity: %f", sender.scale, sender.velocity);
    
    static CGFloat zoomScale;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            
            CGPoint startPos = [sender locationInView: _imageView];
            _zoomRelationPos.x = startPos.x / _imageView.frame.size.width;
            _zoomRelationPos.y = startPos.y / _imageView.frame.size.height;
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            float scale = sender.scale;
            float newScale = [self scaleByPinchScale: scale];
            [self changeZoom: newScale];
            
            zoomScale = newScale;
            
            break;
        }
        case UIGestureRecognizerStateEnded: {
//            float scale = recognizer.scale;
//            float newScale = [self scaleByPinchScale: scale];
//            
//            float velocity = recognizer.velocity;
//            BOOL buttonVisible = YES;
//            if (newScale >= _maxScale - 0.1) {
//                if (velocity <= 0.0) {
//                    newScale = _minScale;
//                } else {
//                    newScale = _maxScale;
//                    buttonVisible = NO;
//                }
//            } else {
//                if (velocity >= 0.0) {
//                    newScale = _maxScale;
//                    buttonVisible = NO;
//                } else {
//                    newScale = _minScale;
//                }
//            }
            
            [self setMaketToScale:zoomScale animated:NO];
            
            break;
        }
        default:
            break;
    }
}

- (float) scaleByPinchScale: (float) scale {
    // NSLog(@"sc: %f", scale);
    // float deltaScale = _maxScale - _minScale;
    float newScale = 1.0;
    if (scale > 1.0) {
        newScale = _renderScale * scale;
    } else {
        newScale = _renderScale * scale;
    }
    
    //float newScale = _renderScale + (scale - 1.0) * deltaScale;
    
//    float newScale = _renderScale + (scale - 1.0);

    if (newScale < _minScale) {
        newScale = _minScale;
    }
    if (newScale > _maxScale) {
        newScale = _maxScale;
    }
    
    return newScale;
}

- (void) setMaketToScale: (float) scale animated: (BOOL) animated {
    if (scale < _minScale) scale = _minScale;
    if (scale > _maxScale) scale = _maxScale;
    
    // background image
    //    UIInterfaceOrientation orientation = renderOrienation;
    NSTimeInterval duration = 0.3;
    
    if (animated) {
        [UIView animateWithDuration:duration animations:^{
            
            // change zooming
            [self changeZoom: scale];
        } completion:^(BOOL finished) {
            [self resizeMaketToScale: scale];
        }];
    } else {
        
        // change zooming
        [self changeZoom: scale];
        
        [self resizeMaketToScale: scale];
    }
}

- (void) changeZoom: (float) scale {
    // UIInterfaceOrientation orientation = renderOrienation;
    // CGSize screenSize = [[UIDevice currentDevice] screenSizeForOrientation: orientation];
    CGSize screenSize = _scrollView.bounds.size;
    // BOOL isLandscape = (UIInterfaceOrientationIsLandscape(orientation)) ? YES : NO;
    // BOOL isPortrait = !isLandscape;
    CGSize imageSize = _storeImageSize;
    
    CGSize scrollContentSize = [self scaleSize:imageSize toScale:scale];
    float contentWidth  = scrollContentSize.width;
    float contentHeight = scrollContentSize.height;
    float scaleProportion = scale / _renderScale;
    
    // transform content view
    CGAffineTransform t = CGAffineTransformMakeScale(scaleProportion, scaleProportion);
    [_imageView setTransform: t];
    
    // scroll settings
    CGPoint scrollOffset = CGPointZero;
    CGSize scrollSize;
    CGPoint contentCenter = CGPointZero;
    if (contentWidth > screenSize.width) {
        scrollSize.width = contentWidth;
        contentCenter.x = roundf(scrollSize.width / 2.0);
        scrollOffset.x = roundf(contentWidth * _zoomRelationPos.x - screenSize.width / 2.0);
    } else {
        scrollSize.width = screenSize.width;
        contentCenter.x = roundf(scrollSize.width / 2.0);
    }
    if (contentHeight > screenSize.height) {
        scrollSize.height = contentHeight;
        contentCenter.y = roundf(scrollSize.height / 2.0);
        scrollOffset.y = roundf(contentHeight * _zoomRelationPos.y - screenSize.height / 2.0);
    } else {
        scrollSize.height = screenSize.height;
        contentCenter.y = roundf(scrollSize.height / 2.0);
    }
    //    if (isPortrait) {
    //        float deltaScale = _maxScale - _minScale;
    //        float percent = (scale - _minScale) / deltaScale;
    //
    //        scrollOffset.x = -10.0 * percent + (scrollSize.width  - _scrollView.frame.size.width) / 2.0;
    //        scrollOffset.y = (scrollSize.height - _scrollView.frame.size.height) / 2.0;
    //    }
    
    // check scroll offset
    float maxOffsetX = scrollSize.width  - screenSize.width;
    float maxOffsetY = scrollSize.height - screenSize.height;
    if (scrollOffset.x < 0.0) scrollOffset.x = 0.0;
    if (maxOffsetX > 0 && scrollOffset.x > maxOffsetX) scrollOffset.x = maxOffsetX;
    if (scrollOffset.y < 0.0) scrollOffset.y = 0.0;
    if (maxOffsetY > 0 && scrollOffset.y > maxOffsetY) scrollOffset.y = maxOffsetY;
    
    [_scrollView setContentSize: scrollSize];
    [_scrollView setContentOffset: scrollOffset animated: NO];
    [_imageView setCenter:contentCenter];
}

- (CGSize) scaleSize: (CGSize) size toScale: (float) scale {
    
    size.width  = roundf(scale * size.width);
    size.height = roundf(scale * size.height);
    
    return size;
}

- (void) resizeMaketToScale: (float) scale {
    // background image
    // UIInterfaceOrientation orientation = renderOrienation;
    // BOOL isLandscape = (UIInterfaceOrientationIsLandscape(orientation)) ? YES : NO;
    // BOOL isPortrait = !isLandscape;
    // CGSize screenSize = [[UIDevice currentDevice] screenSizeForOrientation: orientation];
    CGSize screenSize = _scrollView.bounds.size;
    // identity matrix
    CGAffineTransform t = CGAffineTransformIdentity;
    // scale proportion
    // float scaleProportion = scale / _renderScale;
    
    // render scale
    _renderScale = scale;
    
    // content size
    CGRect scrollContentRect = CGRectZero;
    scrollContentRect.size = [self scaleSize:_storeImageSize toScale:scale];
    [_imageView setTransform: t];
    [_imageView setFrame: scrollContentRect];
    
    // scroll settings
    BOOL scrollEnabled = YES;
    CGSize scrollSize;
    CGPoint scrollOffset = CGPointZero;
    if (scrollContentRect.size.width > screenSize.width) {
        scrollSize.width = scrollContentRect.size.width;
        scrollOffset.x = roundf(scrollContentRect.size.width * _zoomRelationPos.x - (screenSize.width / 2.0));
    } else {
        scrollSize.width = screenSize.width;
        scrollContentRect.origin.x = roundf((screenSize.width - scrollContentRect.size.width) / 2.0);
    }
    if (scrollContentRect.size.height > screenSize.height) {
        scrollSize.height = scrollContentRect.size.height;
        scrollOffset.y = roundf(scrollContentRect.size.height * _zoomRelationPos.y - (screenSize.height / 2.0));
    } else {
        scrollSize.height = screenSize.height;
        scrollContentRect.origin.y = roundf((screenSize.height - scrollContentRect.size.height) / 2.0);
    }
    //    if (isPortrait) {
    //        float deltaScale = _maxScale - _minScale;
    //        float percent = (scale - _minScale) / deltaScale;
    //
    //        scrollOffset.x = -10.0 * percent + (scrollSize.width  - _scrollView.frame.size.width) / 2.0;
    //        scrollOffset.y = (scrollSize.height - _scrollView.frame.size.height) / 2.0;
    //
    //        scrollEnabled = NO;
    //    }
    
    // check scroll offset
    float maxOffsetX = scrollSize.width  - screenSize.width;
    float maxOffsetY = scrollSize.height - screenSize.height;
    if (scrollOffset.x < 0.0) scrollOffset.x = 0.0;
    if (maxOffsetX > 0 && scrollOffset.x > maxOffsetX) scrollOffset.x = maxOffsetX;
    if (scrollOffset.y < 0.0) scrollOffset.y = 0.0;
    if (maxOffsetY > 0 && scrollOffset.y > maxOffsetY) scrollOffset.y = maxOffsetY;
    
    [_scrollView setContentSize:scrollSize];
    [_scrollView setContentOffset:scrollOffset animated:NO];
    [_scrollView setScrollEnabled: scrollEnabled];
    
    [_imageView setFrame: scrollContentRect];
    
    // scroll settings
    //    CGSize scrollSize = (isLandscape) ? CGSizeMake(480.0 + 2.0 * offsetLeft, 320.0) : screenSize;
    //    scrollSize.width  = scale * scrollSize.width;
    //    scrollSize.height = scale * scrollSize.height;
    //    [_scrollView setContentSize: scrollSize];
    //    [_scrollView setScrollEnabled: isLandscape];
}

@end
