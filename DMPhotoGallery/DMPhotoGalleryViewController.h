//
//  DMPhotoGalleryViewController.h
//  DMPhotoGallery
//
//  Created by Dima Avvakumov on 15.03.12.
//  Copyright (c) 2012 Dima Avvakumov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMPhotoGalleryModel.h"

//#import <ShareKit/SHKItem.h>
//#import <SHKFacebook.h>
//#import <SHKVkontakte.h>
//#import <SHKTwitter.h>
//#import <SHKMail.h>

@class DMPhotoGalleryViewController;
@protocol DMPhotoGalleryViewControllerDelegate <NSObject>

- (void) photoGalleryViewControllerWillClose: (DMPhotoGalleryViewController *) controller;

@end

@interface DMPhotoGalleryViewController : UIViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIActionSheetDelegate>

@property (weak, nonatomic) id <DMPhotoGalleryViewControllerDelegate> delegate;

@property (strong, nonatomic) UIColor *mainColor;
@property (strong, nonatomic) UIFont *font;

- (id) initWithItems: (NSArray *) items andDelegate: (id<DMPhotoGalleryViewControllerDelegate>) delegate;

- (void) setCurrentIndex: (NSInteger) currentIndex;

+ (void) setAppearenceMainColor: (UIColor *) mainColor;
+ (void) setAppearenceFont: (UIFont *) font;

@end
