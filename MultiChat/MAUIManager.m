//
//  MAUIManager.m
//  MultiChat
//
//  Created by Donald Pae on 5/25/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAUIManager.h"

static MAUIManager *_sharedUIManager = nil;

@interface MAUIManager ()


@end



@implementation MAUIManager

+ (MAUIManager *)sharedUIManager
{
    if (_sharedUIManager == nil)
        _sharedUIManager = [[MAUIManager alloc] init];
    return _sharedUIManager;
}

- (NSString *)appTitle
{
    return @"MultiChart";
}

- (NSInteger)navbarStyle
{
    return UIBarStyleBlackTranslucent;
}

- (UIColor *)navbarTintColor
{
    return [UIColor whiteColor];
}

- (NSDictionary *)navbarTitleTextAttributes
{
    return @{NSForegroundColorAttributeName:[UIColor whiteColor]};
}

- (UIColor *)navbarBarTintColor
{
    return [UIColor colorWithRed:197/255.0 green:0/255.0 blue:27/255.0 alpha:1.0];
}


- (NSString *)peopleTitle
{
    return @"Friends";
}

- (NSString *)settingsTitle
{
    return @"Settings";
}


///////////////////////////////////////////////////

- (UIImage *)getDefaultAvatar
{
    
    UIImage *imgFile = nil;
    
    imgFile = [UIImage imageNamed:@"default_avatar"];
    
    imgFile = [UIImage imageWithCGImage:[imgFile CGImage] scale:[UIScreen mainScreen].scale orientation:[imgFile imageOrientation]];
    
    return imgFile;
}

- (UIImage *)getPeopleAvatar
{
    UIImage *imgFile = nil;
    
    imgFile = [UIImage imageNamed:@"people_avatar"];
    
    imgFile = [UIImage imageWithCGImage:[imgFile CGImage] scale:[UIScreen mainScreen].scale orientation:[imgFile imageOrientation]];
    
    return imgFile;
}

- (NSString *)getDefaultAvatarImageName
{
    return @"default_avatar";
}

@end
