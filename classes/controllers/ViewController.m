//
//  ViewController.m
//  DMPhotoGallery
//
//  Created by Dmitry Avvakumov on 18.11.14.
//  Copyright (c) 2014 Dima Avvakumov. All rights reserved.
//

#import "ViewController.h"

#import "DMPhotoGalleryViewController.h"

@interface ViewController () <DMPhotoGalleryViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) showAction: (UIButton *) sender {

    // create array
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:10];
    
    // append first
    [items addObject:[self photoGalleryItemAtIndex:0]];
    [items addObject:[self photoGalleryItemAtIndex:1]];
    [items addObject:[self photoGalleryItemAtIndex:2]];
    [items addObject:[self photoGalleryItemAtIndex:3]];
    
    // create controller
    DMPhotoGalleryViewController *controller = [[DMPhotoGalleryViewController alloc] initWithItems:items andDelegate:self];
    
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Model generator

- (DMPhotoGalleryModel *) photoGalleryItemAtIndex: (NSInteger) index {
    
    NSString *imageUrlPath;
    
    switch (index) {
        case 1: {
            imageUrlPath = @"http://photos-f.ak.instagram.com/hphotos-ak-xpf1/10808438_830892580286829_451834347_n.jpg";
            break;
        }
        case 2: {
            imageUrlPath = @"http://photos-f.ak.instagram.com/hphotos-ak-xfa1/10808608_1499151127024933_49370053_n.jpg";
            break;
        }
        case 3: {
            imageUrlPath = @"http://photos-c.ak.instagram.com/hphotos-ak-xpa1/10808894_1566935730186642_548560476_n.jpg";
            break;
        }
        default: {
            imageUrlPath = @"http://photos-d.ak.instagram.com/hphotos-ak-xpa1/10809716_1626328397594555_1895726818_n.jpg";
            
            break;
        }
    }
    
    DMPhotoGalleryModel *model = [[DMPhotoGalleryModel alloc] init];
    model.imagePath = nil;
    model.imageURL = [NSURL URLWithString:imageUrlPath];
    model.previewPath = nil;
    model.previewURL = [NSURL URLWithString:imageUrlPath];
    
    return model;
}

#pragma mark - DMPhotoGalleryViewControllerDelegate

- (void) photoGalleryViewControllerWillClose:(DMPhotoGalleryViewController *)controller {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
