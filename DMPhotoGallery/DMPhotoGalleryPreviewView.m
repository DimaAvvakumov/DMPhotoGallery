//
//  GalleryPreviewView.m
//  vpk
//
//  Created by Dima Avvakumov on 21.05.13.
//  Copyright (c) 2013 avvakumov@east-media.ru. All rights reserved.
//

#import "DMPhotoGalleryPreviewView.h"
#import "StandardPaths.h"

#import "DMImageManager.h"

@interface DMPhotoGalleryPreviewView()

@property (assign, nonatomic) BOOL needReload;

@property (strong, nonatomic) UIView *containerView;

@property (assign, nonatomic) NSUInteger currentIndex;

@property (strong, nonatomic) NSArray *images;
@property (strong, nonatomic) NSArray *galleryItems;

@property (assign, nonatomic) float visibleAspect;

@property (assign, nonatomic) UIInterfaceOrientation renderOrientation;

@property (assign, nonatomic) BOOL isPhone;
@property (assign, nonatomic) BOOL isPad;
@property (assign, nonatomic) BOOL isPhone5;

@end

@implementation DMPhotoGalleryPreviewView

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
    self.needReload = YES;
    self.currentIndex = 0;
    self.visibleAspect = 0.0;
    
    UIUserInterfaceIdiom ideom = [[UIDevice currentDevice] userInterfaceIdiom];
    self.isPhone = (ideom == UIUserInterfaceIdiomPhone);
    self.isPad = (ideom != UIUserInterfaceIdiomPhone);
    if (_isPhone && [[UIScreen mainScreen] bounds].size.height == 568.0) {
        self.isPhone5 = YES;
    } else {
        self.isPhone5 = NO;
    }
    
    self.renderOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGRect containerFrame = CGRectZero;
    containerFrame.size = self.frame.size;

    // toolbar view
//    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: containerFrame];
//    [toolbar setBarStyle: UIBarStyleBlackTranslucent];
//    [self addSubview: toolbar];
    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    
    // container view
    self.containerView = [[UIView alloc] initWithFrame: containerFrame];
//    _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _containerView.backgroundColor = [UIColor clearColor];
    [self addSubview: _containerView];
}

- (void) setItems: (NSArray *) items {
    self.needReload = YES;
    
    self.galleryItems = items;
}

- (void) redrawForOrientation:(UIInterfaceOrientation)orientation {
    self.renderOrientation = orientation;
    
    self.needReload = YES;
    [self setNeedsDisplay];
}

- (void) redraw {
    if (_galleryItems == nil) return;
    
    float viewWidth;
    if (_isPad) {
        viewWidth = (UIInterfaceOrientationIsLandscape(_renderOrientation)) ? 1024.0 : 768.0;
    } else {
        float add = (_isPhone5) ? 88.0 : 0.0;
        viewWidth = (UIInterfaceOrientationIsLandscape(_renderOrientation)) ? (480.0 + add) : 320.0;
    }
    float padding = 20.0;
    float maxWidth = viewWidth - 2.0 * padding;
    float offset = 0.0;
    CGSize previewOneSize = CGSizeMake(20.0, 15.0);
    CGSize previewTwoSize = CGSizeMake(40.0, 30.0);
    
    // remove old images
    if (_images) {
        for (UIView *v in _images) {
            [v removeFromSuperview];
        }
    }
    
    NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity: [_galleryItems count]];
    NSUInteger maxVisibleCount = floorf(maxWidth / (previewOneSize.width + 2.0));
    self.visibleAspect = 1.0;
    if (maxVisibleCount < [_galleryItems count]) {
        self.visibleAspect = maxVisibleCount / (float) [_galleryItems count];
    }
    NSUInteger nextIndex = 0;
    for (int i = 0; i < [_galleryItems count]; i++) {
        if (_visibleAspect < 1.0) {
            NSUInteger index = i * _visibleAspect;
            if (nextIndex > index) continue;
        }
        
        DMPhotoGalleryModel *item = [_galleryItems objectAtIndex: i];
        
        UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hadleTap:)];
        
        CGRect imageFrame = CGRectMake(offset, 14.0, previewOneSize.width, previewOneSize.height);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame: imageFrame];
        [imageView setUserInteractionEnabled: YES];
        [imageView setTag:i];
        [imageView addGestureRecognizer:gr];
        [imageView setAlpha: 0.0];
        
        NSString *previewPath = item.previewPath;
        if (previewPath == nil) {
            NSURL *previewURL = item.previewURL;
            if (previewURL) {
                NSString *localPath = [previewURL.path stringByReplacingOccurrencesOfString:@"://" withString:@"_"];
                previewPath = [[NSFileManager defaultManager] pathForCacheFile:localPath];
            }
        }
        
        DMImageOperation *operation = [[DMImageOperation alloc] initWithImagePath:previewPath identifer:nil andBlock:^(UIImage *image) {
            
            [imageView setImage: image];
            [UIView animateWithDuration:0.3 animations:^{
                [imageView setAlpha: 1.0];
            }];
        }];
        operation.downloadURL = item.previewURL;
        operation.thumbSize = previewTwoSize;
        operation.cropThumb = YES;
        [[DMImageManager defaultManager] addOperation: operation];
        
        [_containerView addSubview: imageView];
        [images addObject: imageView];
        
        offset += previewOneSize.width + 2.0;
        nextIndex++;
    }
    
    self.images = images;
    
    // move container
    CGRect frame = _containerView.frame;
    frame.origin.x = roundf(padding + roundf((maxWidth - offset) / 2.0));
    frame.size.width = offset;
    [_containerView setFrame:frame];
    
    [self update];
}

- (void) update {
    CGSize previewOneSize = CGSizeMake(20.0, 15.0);
    CGSize previewTwoSize = CGSizeMake(40.0, 30.0);
    
    float offset = 0.0;
    for (int i = 0; i < [_images count]; i++) {
        UIImageView *imageView = [_images objectAtIndex: i];
        CGRect imageFrame;
        
        // cur page
        BOOL currentPage = NO;
        if (imageView.tag == _currentIndex) {
            currentPage = YES;
        }
        
        if (currentPage) {
            imageFrame = CGRectMake(offset - 10.0, 7.0, previewTwoSize.width, previewTwoSize.height);
            [_containerView bringSubviewToFront: imageView];
            [imageView setUserInteractionEnabled: NO];
        } else {
            imageFrame = CGRectMake(offset, 14.0, previewOneSize.width, previewOneSize.height);
            [imageView setUserInteractionEnabled: YES];
        }
        if (imageFrame.size.width != imageView.frame.size.width) {
            [UIView animateWithDuration:0.3 animations:^{
                [imageView setFrame: imageFrame];
            }];
        }
        
        offset += previewOneSize.width + 2.0;
    }
}

- (IBAction)hadleTap:(UITapGestureRecognizer*)sender {
    if (sender.state != UIGestureRecognizerStateEnded) return;
    
    NSUInteger index = sender.view.tag;
    
    [_delegate photoGalleryPreviewModel:self didTappedAtIndex:index];
}

- (void) setCurrentPage: (NSUInteger) page {
    if (page >= ([_galleryItems count] + 1)) return;
    
//    page = floorf(page * _visibleAspect);
//    if (page >= [_images count]) return;
    
    self.currentIndex = page;
    
    [self update];
}

- (void)drawRect:(CGRect)rect {
    if (_needReload) {
        [self redraw];
    }
}

@end
