//
//  MAUIManager.h
//  MultiChat
//
//  Created by Donald Pae on 5/25/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MAUIManager : NSObject

+ (MAUIManager *)sharedUIManager;

- (NSString *)appTitle;
- (NSInteger)navbarStyle;
- (UIColor *)navbarTintColor;
- (NSDictionary *)navbarTitleTextAttributes;
- (UIColor *)navbarBarTintColor;
- (UIColor *)navbarBorderColor;

- (NSString *)peopleTitle;
- (NSString *)settingsTitle;

- (UIImage *)getDefaultAvatar;
- (UIImage *)getPeopleAvatar;

- (NSString *)getDefaultAvatarImageName;

@end
