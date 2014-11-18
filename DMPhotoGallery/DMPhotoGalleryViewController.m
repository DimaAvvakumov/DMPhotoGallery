//
//  GalleryViewController.m
//  HotelRMGC
//
//  Created by Dima Avvakumov on 15.03.12.
//  Copyright (c) 2012 avvakumov@east-media.ru. All rights reserved.
//

#import "DMPhotoGalleryViewController.h"
#import "DMPhotoGalleryPreviewView.h"
#import "DMPhotoGalleryItemViewController.h"

@interface DMPhotoGalleryViewController () <DMPhotoGalleryPreviewViewDelegate> {
    BOOL _isAppereanceProxy;
    
    int _currentIndex;
    
    BOOL _isIOS7AndMore;
}

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) IBOutlet UIView *mainScrollView;
@property (weak, nonatomic) IBOutlet DMPhotoGalleryPreviewView *previewView;

@property (strong, nonatomic) NSMutableDictionary *cachedControllers;
@property (strong, nonatomic) DMPhotoGalleryItemViewController *currentVC;

@property (strong, nonatomic) UIActionSheet *shareSheet;

@property (weak, nonatomic) IBOutlet UIView *navigationView;
@property (weak, nonatomic) IBOutlet UIImageView *gradientView;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

//@property (strong, nonatomic) UIActionSheet *shareSheet;

@property (assign, nonatomic) BOOL interfaceHidden;

- (void) prepareBeforeAfterViewControllers;

@end

@implementation DMPhotoGalleryViewController

- (id) initAppearence {
    self = [super init];
    if (self) {
        _isAppereanceProxy = YES;
        
        [self baseInit];
    }
    return self;
}

- (id) initWithItems:(NSArray *)items andDelegate:(id<DMPhotoGalleryViewControllerDelegate>)delegate {
    self = [super initWithNibName: @"DMPhotoGalleryViewController" bundle: nil];
    if (self) {
        [self baseInit];
                
        self.items = items;
        self.delegate = delegate;
        
        self.cachedControllers = [NSMutableDictionary dictionaryWithCapacity:3];
        
        _isIOS7AndMore = ([[[UIDevice currentDevice] systemVersion] integerValue] > 6) ? YES : NO;
        
        self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options: nil];
        [_pageViewController setDataSource: self];
        [_pageViewController setDelegate: self];
        [self addChildViewController:_pageViewController];
    }
    return self;
}

- (void) baseInit {
    _currentIndex = 0;
    
    self.interfaceHidden = YES;
    
    // init values
    self.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    self.mainColor = [UIColor whiteColor];
    
    // appearence
    if (!_isAppereanceProxy) {
        DMPhotoGalleryViewController *proxy = [DMPhotoGalleryViewController appearenceProxy];
        self.font = proxy.font;
        self.mainColor = proxy.mainColor;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([_items count] == 0) return;
    
    CGRect pageFrame = CGRectMake(0.0, 0.0, _mainScrollView.frame.size.width, _mainScrollView.frame.size.height);
    [_pageViewController.view setFrame: pageFrame];
//    for (UIGestureRecognizer *gR in pageViewController.view.gestureRecognizers) {
//        gR.delegate = self;
//    }
    [_mainScrollView addSubview: _pageViewController.view];
    
    // page view controller
    [self initPageViewControllerWithIndex: _currentIndex];
    
    // tap handler
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    [self.view addGestureRecognizer:gr];
    
    [self updateInterfaceAnimated:NO];
    
    [self updateStatusBarWithDuration:0.0];
    
    // preview view
    [_previewView setItems: _items];
    [_previewView setCurrentPage: _currentIndex];
    
    // top gradient
    _gradientView.image = [self topGradientImage];
    
    // buttons font
    [_closeButton setImage:[self createCloseImage] forState:UIControlStateNormal];
    [_shareButton setImage:[self createShareImage] forState:UIControlStateNormal];
    // _closeButton.titleLabel.font = [UIFont fontWithName:_fontName size:_fontSize];
    // _shareButton.titleLabel.font = [UIFont fontWithName:_fontName size:_fontSize];
}

- (void)viewDidUnload {
    [self setMainScrollView:nil];
    
//    if (ios5) {
//        for (UIGestureRecognizer *gR in pageViewController.view.gestureRecognizers) {
//            gR.delegate = nil;
//        }
//    }

    [self setPreviewView:nil];
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
    
    NSArray *viewControllers = _pageViewController.viewControllers;
    for (DMPhotoGalleryItemViewController *vc in viewControllers) {
        
        [self updateControllerFrame:vc];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    
    NSArray *viewControllers = _pageViewController.viewControllers;
    for (DMPhotoGalleryItemViewController *vc in viewControllers) {
        
        [self updateControllerFrame:vc];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (BOOL) shouldAutorotate {
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    _interfaceHidden = YES;
    [self updateInterfaceAnimated: YES];
    
    [_previewView redrawForOrientation:toInterfaceOrientation];
}

#pragma mark - Change status bar events

- (BOOL) prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation) preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void) updateStatusBarWithDuration: (NSTimeInterval) duration {
    if (_isIOS7AndMore) {
        if (duration > 0) {
            [UIView animateWithDuration:duration animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
        } else {
            [self setNeedsStatusBarAppearanceUpdate];
        }
    } else {
        BOOL hidden = [self prefersStatusBarHidden];
        UIStatusBarAnimation animation = [self preferredStatusBarUpdateAnimation];
        
        [[UIApplication sharedApplication] setStatusBarHidden: hidden withAnimation:animation];
    }
}

#pragma mark - Appearence

+ (DMPhotoGalleryViewController *) appearenceProxy {
    static DMPhotoGalleryViewController *sharedProxy = nil;
    if (sharedProxy == nil) {
        sharedProxy = [[DMPhotoGalleryViewController alloc] initAppearence];
    }
    return sharedProxy;
}

+ (void) setAppearenceFont:(UIFont *)font {
    [DMPhotoGalleryViewController appearenceProxy].font = font;
}

+ (void) setAppearenceMainColor:(UIColor *)mainColor {
    [DMPhotoGalleryViewController appearenceProxy].mainColor = mainColor;
}

#pragma mark - Tap handler

- (void)tapHandler:(UITapGestureRecognizer*)sender {
    self.interfaceHidden = !_interfaceHidden;
    
    [self updateInterfaceAnimated:YES];
}

- (void) updateInterfaceAnimated: (BOOL) animated {
    float alpha = (_interfaceHidden) ? 0.0 : 1.0;
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [_navigationView setAlpha: alpha];
            [_previewView setAlpha: alpha];
        } completion:nil];
    } else {
        [_navigationView setAlpha: alpha];
        [_previewView setAlpha: alpha];
    }
    
    for (NSString *cachedKey in _cachedControllers) {
        DMPhotoGalleryItemViewController *cntr = [_cachedControllers objectForKey:cachedKey];
        
        [cntr setInterfaceHidden:_interfaceHidden animated:animated];
    }
    
//    if (_afterViewController) {
//        [_afterViewController setInterfaceHidden:_interfaceHidden animated:animated];
//    }
//    if (_beforeViewController) {
//        [_beforeViewController setInterfaceHidden:_interfaceHidden animated:animated];
//    }
    
//    NSArray *controllers = _pageViewController.viewControllers;
//    if (controllers) {
//        for (DMPhotoGalleryItemViewController *cntr in controllers) {
//            [cntr setInterfaceHidden:_interfaceHidden animated:animated];
//        }
//    }
    
    if (self.shareSheet) {
        [_shareSheet dismissWithClickedButtonIndex:0 animated:YES];
    }
}

#pragma mark - page view controller

- (void) initPageViewControllerWithIndex: (NSUInteger) index {
    DMPhotoGalleryItemViewController *controller = [self viewControllerAtIndex: index];
//    
//    
//    DMPhotoGalleryModel *model = [_items objectAtIndex: index];
//    
//    DMPhotoGalleryItemViewController *controller = [[DMPhotoGalleryItemViewController alloc] initWithModel:model andLazyLoad:NO];
//    [controller setIndex:index];
//    if (_fontName) {
//        controller.fontName = _fontName;
//        controller.fontSize = _fontSize;
//    }
    NSArray *initControllers = [NSArray arrayWithObject: controller];
    [self setCurrentVC:controller];
    
    [_pageViewController setViewControllers: initControllers
                                  direction: UIPageViewControllerNavigationDirectionForward
                                   animated: NO
                                 completion: nil];
    
    _currentIndex = (int) index;
    
    [self prepareBeforeAfterViewControllers];
    
    [_previewView setCurrentPage: index];
}

- (DMPhotoGalleryItemViewController *) viewControllerAtIndex: (NSInteger) index {
    if (index < 0) return nil;
    if (index >= [_items count]) return nil;
    
    NSString *cacheKey = [NSString stringWithFormat:@"%d", (int)index];
    DMPhotoGalleryItemViewController *controller = [_cachedControllers objectForKey:cacheKey];
    if (controller) {
        // [self updateControllerFrame:controller];
        
        return controller;
    }
    
    DMPhotoGalleryModel *model = [_items objectAtIndex: index];
    
    controller = [[DMPhotoGalleryItemViewController alloc] initWithModel:model andLazyLoad:NO];
    [controller setIndex:index];
    controller.fontName = _font.fontName;
    controller.fontSize = _font.pointSize;
    controller.mainColor = _mainColor;
    // [self updateControllerFrame:controller];
    [controller setInterfaceHidden:_interfaceHidden animated:NO];
    
    [_cachedControllers setObject:controller forKey:cacheKey];
    
    return controller;
}

- (void) updateControllerFrame: (DMPhotoGalleryItemViewController *) controller {
//    return;
    
//    CGRect frame = self.view.bounds;
//    controller.view.frame = frame;
    
    [controller restrictScaleByFrame];
}

- (void) prepareBeforeAfterViewControllers {
    NSInteger nextIndex = _currentIndex + 1;
    NSInteger prevIndex = _currentIndex - 1;
    
    // next slide
    if (nextIndex < [_items count]) {
        [self viewControllerAtIndex:nextIndex];
        
//        DMPhotoGalleryModel *model = [_items objectAtIndex: nextIndex];
//        
//        DMPhotoGalleryItemViewController *cntr = [[DMPhotoGalleryItemViewController alloc] initWithModel:model andLazyLoad:YES];
//        [cntr setIndex:nextIndex];
//        if (_fontName) {
//            cntr.fontName = _fontName;
//            cntr.fontSize = _fontSize;
//        }
//        [cntr setInterfaceHidden:_interfaceHidden animated:NO];
//        self.afterViewController = cntr;
    }
//    else {
//        self.afterViewController = nil;
//    }
    
    // prev slide
//    NSInteger prevIndex = _currentIndex - 1;
    if (prevIndex >= 0) {
        [self viewControllerAtIndex:prevIndex];
//        DMPhotoGalleryModel *model = [_items objectAtIndex: prevIndex];
//        
//        DMPhotoGalleryItemViewController *cntr = [[DMPhotoGalleryItemViewController alloc] initWithModel:model andLazyLoad:YES];
//        [cntr setIndex:prevIndex];
//        if (_fontName) {
//            cntr.fontName = _fontName;
//            cntr.fontSize = _fontSize;
//        }
//        [cntr setInterfaceHidden:_interfaceHidden animated:NO];
//        self.beforeViewController = cntr;
    }
//    else {
//        self.beforeViewController = nil;
//    }
}

- (void) clearOldControllers {
    NSInteger nextIndex = _currentIndex + 1;
    NSInteger prevIndex = _currentIndex - 1;

    // clear old controllers
    NSArray *keys = [_cachedControllers allKeys];
    for (NSString *cacheKey in keys) {
        NSInteger index = [cacheKey integerValue];
        
        if (index < prevIndex || index > nextIndex) {
            [_cachedControllers removeObjectForKey:cacheKey];
        }
    }
}

#pragma mark - Current index

- (void) setCurrentIndex: (NSInteger) currentIndex {
    if (currentIndex < 0) return;
    if (currentIndex >= [_items count]) return;
    
    _currentIndex = (int) currentIndex;
}

- (IBAction)closeAction:(UIButton *)sender {
    [_delegate photoGalleryViewControllerWillClose:self];
}

#pragma mark - UIPageViewController data source

- (UIPageViewControllerSpineLocation) pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return UIPageViewControllerSpineLocationMin;
}

- (UIViewController *) pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
//    if (_beforeViewController == nil) return nil;
    
    DMPhotoGalleryItemViewController *cntr = [self viewControllerAtIndex:(_currentIndex-1)];
    
//    DMPhotoGalleryItemViewController *cntr = (DMPhotoGalleryItemViewController *) _beforeViewController;
    
    return cntr;
}

- (UIViewController *) pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
//    if (_afterViewController == nil) return nil;
    
//    DMPhotoGalleryItemViewController *cntr = (DMPhotoGalleryItemViewController *) _afterViewController;
    
    DMPhotoGalleryItemViewController *cntr = [self viewControllerAtIndex:(_currentIndex+1)];
    
    return cntr;

//    GalleryItemViewController *controller = (GalleryItemViewController *) viewController;
//    int index = [controller itemIndex] + 1;
//    
//    if (index >= [_slides count]) return nil;
//    
//    GalleryItemViewController *cntr = [[GalleryItemViewController alloc] initWithNibName:@"GalleryItemViewController" bundle: nil];
//    [cntr setLazyLoad: YES];
//    [cntr setItemInfo: [_slides objectAtIndex: index]];
//    //[cntr setDelegate: self];
//    
//    currentIndex = index;
//    
//    return cntr;
}

#pragma mark - UIPageViewController delegate

- (void) pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    if (finished && completed) {
        DMPhotoGalleryItemViewController *cntr = [pageViewController.viewControllers objectAtIndex: 0];
        _currentIndex = (int) cntr.index;
        
        [self setCurrentVC:cntr];
        
        [_previewView setCurrentPage: _currentIndex];
        
        [self clearOldControllers];
        [self prepareBeforeAfterViewControllers];
    }
}

#pragma mark GalleryPreviewViewDelegate

- (void) photoGalleryPreviewModel:(DMPhotoGalleryPreviewView *)view didTappedAtIndex:(NSUInteger)index {
    [self initPageViewControllerWithIndex:index];
}

#pragma mark - Draw methods

- (UIImage *) topGradientImage {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    UIColor *startColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    UIColor *endColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
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

- (UIImage *) createCloseImage {
    CGSize size = CGSizeMake(20.0, 20.0);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(context, 0.5, 0.5);
    CGContextAddLineToPoint(context, 19.5, 19.5);
    CGContextMoveToPoint(context, 19.5, 0.5);
    CGContextAddLineToPoint(context, 0.5, 20.0);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokePath(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *) createShareImage {
    CGSize size = CGSizeMake(22.0, 30.0);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(context, 8.5, 9.5);
    CGContextAddLineToPoint(context, 0.5, 9.5);
    CGContextAddLineToPoint(context, 0.5, 29.5);
    CGContextAddLineToPoint(context, 21.5, 29.5);
    CGContextAddLineToPoint(context, 21.5, 9.5);
    CGContextAddLineToPoint(context, 14.5, 9.5);
    
    CGContextMoveToPoint(context, 11.5, 20.5);
    CGContextAddLineToPoint(context, 11.5, 1.5);
    CGContextAddLineToPoint(context, 7.5, 5.5);
    
    CGContextMoveToPoint(context, 11.5, 1.5);
    CGContextAddLineToPoint(context, 15.5, 5.5);
    
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Share action

- (IBAction) sharedAction:(UIButton *) btn {
    if (_currentVC.imageView.image == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Фотография еще не загрузилась" message:@"" delegate:self cancelButtonTitle:@"Продолжить" otherButtonTitles:nil];
        alert.delegate = self;
        [alert show];

        return;
    }
    
    if (!self.shareSheet) {
        self.shareSheet = [[UIActionSheet alloc] initWithTitle:@"Поделиться:" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        [_shareSheet addButtonWithTitle:@"Twitter"];
        [_shareSheet addButtonWithTitle:@"Facebook"];
//        [_shareSheet addButtonWithTitle:@"Вконтакте"];
        [_shareSheet addButtonWithTitle:@"E-Mail"];
        [_shareSheet addButtonWithTitle:@"Сохранить на устройство"];
        _shareSheet.cancelButtonIndex = [_shareSheet addButtonWithTitle:@"Отмена"];
        [_shareSheet setContentMode:UIViewContentModeBottom];
    }
    
    [_shareSheet showFromRect:[[btn superview] convertRect:btn.frame toView:self.view] inView:self.view animated:YES];
}

//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex != actionSheet.cancelButtonIndex) {
//        // NSLog(@"%d", buttonIndex);
//        DMPhotoGalleryModel *model = [_items objectAtIndex:_currentIndex];
//        ShareItem *shareItem = [[ShareItem alloc] init];
//        shareItem.imagePath = model.imagePath;
//        shareItem.imageURL = model.imageURL;
//        shareItem.title = model.text;
//
//        switch (buttonIndex) {
//            case 0: {
//                
//                [[ShareManager defaultManager] shareTwitter:shareItem];
//                break;
//            }
//            case 1: {
//                [[ShareManager defaultManager] shareFacebook:shareItem];
//                break;
//            }
//            case 2: {
//                [[ShareManager defaultManager] shareEmail:shareItem];
//                break;
//            }
//            case 3: {
//                UIImageWriteToSavedPhotosAlbum(_currentVC.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//                break;
//            }
//            default:
//                break;
//        }
//    }
//}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo
{
    // Was there an error?
    if (error != NULL)
    {
		UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle: @"Произошла ошибка, попробуйте еще раз"];
        [alert addButtonWithTitle: @"Продолжить"];
        [alert show];
        return;
        // Show error message...
    }
    else  // No errors
    {
        UIAlertView *alert = [[UIAlertView alloc] init];
        [alert setTitle: @"Изображение сохранено"];
        [alert addButtonWithTitle: @"Продолжить"];
        [alert show];
        return;
		// Show message image successfully saved
    }
}

@end
