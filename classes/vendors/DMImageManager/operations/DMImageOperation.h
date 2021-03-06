//
//  DMImageOperation.h
//  DMImageManager
//
//  Created by Dima Avvakumov on 29.07.13.
//  Copyright (c) 2012 Dima Avvakumov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

#import "DMImageCacheManager.h"

typedef void (^DMImageOperationCompetitionBlock)(UIImage *image);
typedef void (^DMImageOperationProgressBlock)(NSNumber *progress);
typedef void (^DMImageOperationFailureBlock)(NSError *error);
typedef UIImage * (^DMImageOperationProcessingBlock)(UIImage *image);

@interface DMImageOperation : NSOperation

@property (nonatomic, copy) DMImageOperationProgressBlock progressBlock;
@property (nonatomic, copy) DMImageOperationFailureBlock failureBlock;
@property (nonatomic, copy) DMImageOperationProcessingBlock processingBlock;

@property (assign, nonatomic) CGSize thumbSize;
@property (assign, nonatomic) BOOL cropThumb;

@property (assign, nonatomic) BOOL returnPostprocessingImage;

#pragma mark - Cache properties

@property (assign, nonatomic) BOOL cacheImage; // NO
@property (strong, nonatomic) NSString *cacheName; // @"default"
@property (strong, nonatomic) NSString *cacheSuffix; // nill

@property (strong, nonatomic) DMImageCacheManager *cacheManager;

- (id) initWithImagePath: (NSString *) imagePath identifer: (NSString *) identifier andBlock: (DMImageOperationCompetitionBlock) block;

- (NSString *) path;
- (NSString *) identifier;

- (BOOL) imageExist;

- (NSURL *) downloadURL;
- (void) setDownloadURL: (NSURL *) url;

+ (CGSize) resize: (CGSize) originalSize toSize: (CGSize) maxSize withCroping: (BOOL) cropImage;

@end
