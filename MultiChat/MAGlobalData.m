//
//  MAGlobalData.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAGlobalData.h"

#define kUserNameKey    @"username"

static MAGlobalData *_sharedData;

@implementation MAGlobalData

+ (MAGlobalData *)sharedData {
    if (_sharedData == nil)
        _sharedData = [[MAGlobalData alloc] init];
    return _sharedData;
}

- (id)init
{
    self = [super init];
    return self;
}

- (BOOL)isSetName
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *userName = [userDefault objectForKey:kUserNameKey];
    if (userName != nil && ![userName isEqualToString:@""])
    {
        return YES;
    }
    return NO;
}

- (NSString *)getName
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *userName = [userDefault objectForKey:kUserNameKey];
    if (userName != nil && ![userName isEqualToString:@""])
    {
        return [NSString stringWithFormat:@"%@", userName];
    }
    return [NSString stringWithFormat:@"%@", [UIDevice currentDevice].name];
}

- (void)setName:(NSString *)name
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", name] forKey:kUserNameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
