//
//  DMPhotoGalleryPreviewView.h
//  DMPhotoGallery
//
//  Created by Dima Avvakumov on 15.03.12.
//  Copyright (c) 2012 Dima Avvakumov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMPhotoGalleryModel.h"

@class DMPhotoGalleryPreviewView;
@protocol DMPhotoGalleryPreviewViewDelegate <NSObject>

- (void) photoGalleryPreviewModel: (DMPhotoGalleryPreviewView *) view didTappedAtIndex: (NSUInteger) index;

@end

@interface DMPhotoGalleryPreviewView : UIView

@property (weak, nonatomic) IBOutlet id<DMPhotoGalleryPreviewViewDelegate> delegate;

- (void) setItems: (NSArray *) items;

- (void) setCurrentPage: (NSUInteger) page;

- (void) redrawForOrientation: (UIInterfaceOrientation) orientation;

@end
