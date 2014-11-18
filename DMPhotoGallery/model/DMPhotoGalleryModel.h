//
//  DMPhotoGalleryModel.h
//  DMPhotoGallery
//
//  Created by Dima Avvakumov on 15.03.12.
//  Copyright (c) 2012 Dima Avvakumov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMPhotoGalleryModel : NSObject

@property (strong, nonatomic) NSString *text;

@property (strong, nonatomic) NSString *imagePath;
@property (strong, nonatomic) NSURL *imageURL;

@property (strong, nonatomic) NSString *previewPath;
@property (strong, nonatomic) NSURL *previewURL;

@end
