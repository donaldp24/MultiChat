//
//  MAGlobalData.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAGlobalData.h"

#define kUserNameKey    @"username"
#define kDeviceTokenKey @"devicetoken"

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
    if (self) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        NSString *userName = [userDefault objectForKey:kUserNameKey];
        if (userName != nil && ![userName isEqualToString:@""])
        {
            _userName = [NSString stringWithFormat:@"%@", userName];
        }
        else
        {
            _userName = [NSString stringWithFormat:@"%@", [UIDevice currentDevice].name];
        }
        
        NSString *deviceToken = [userDefault objectForKey:kDeviceTokenKey];
        if (deviceToken != nil && ![deviceToken isEqualToString:@""])
        {
            _deviceToken = [NSString stringWithFormat:@"%@", deviceToken];
        }
        else
        {
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            _deviceToken = [NSString stringWithFormat:@"%@", (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid))];
        }
    }
    return self;
}

- (void)setUserName:(NSString *)userName
{
    _userName = userName;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", _userName] forKey:kUserNameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setDeviceToken:(NSString *)deviceToken
{
    _deviceToken = deviceToken;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", _deviceToken] forKey:kDeviceTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
