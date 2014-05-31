//
//  MAGlobalData.h
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAGlobalData : NSObject

@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *avatarImageFileName;
@property (nonatomic, strong) UIImage *avatarImage;

+ (MAGlobalData *)sharedData;
- (void)setAvatarImage:(UIImage *)image;


@end
