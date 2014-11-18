//
//  DMPhotoGalleryItemViewController.h
//  DMPhotoGallery
//
//  Created by Dima Avvakumov on 15.03.12.
//  Copyright (c) 2012 Dima Avvakumov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMPhotoGalleryModel.h"

@interface DMPhotoGalleryItemViewController : UIViewController

@property (assign, nonatomic) BOOL lazyLoad;
@property (assign, nonatomic) NSInteger index;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (id)initWithModel: (DMPhotoGalleryModel *) galleryItem andLazyLoad: (BOOL) lazyLoad;

- (void) setInterfaceHidden: (BOOL) hidden animated: (BOOL) animated;

- (void) restrictScaleByFrame;

@property (strong, nonatomic) UIColor *mainColor;
@property (strong, nonatomic) NSString *fontName;
@property (assign, nonatomic) CGFloat fontSize;

@end
