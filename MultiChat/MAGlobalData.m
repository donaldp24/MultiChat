//
//  MAGlobalData.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAGlobalData.h"
#import "MAUIManager.h"

#define kUidKey         @"uid"
#define kUserNameKey    @"username"
#define kDeviceTokenKey @"devicetoken"
#define kAvatarImageNameKey @"avatar"

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
        
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        _uid = [NSString stringWithFormat:@"%@", (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid))];
        _uid = [_uid substringToIndex:13];
        
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
        
        NSString *avatarName = [userDefault objectForKey:kAvatarImageNameKey];
        if (avatarName != nil && ![avatarName isEqualToString:@""])
        {
            _avatarImageFileName = [NSString stringWithFormat:@"%@", avatarName];
        }
        else
        {
            _avatarImageFileName = @"default_avatar.png";
        }
        [self getAvatarImage];
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

- (void)setAvatarImage:(UIImage *)image
{
    _avatarImage = image;
    
    NSData *data = UIImagePNGRepresentation(image);
    
    NSString *fileName = [NSString stringWithFormat:@"%d.png", (int)[[NSDate date] timeIntervalSince1970]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *filePath = [cacheDirectory stringByAppendingPathComponent:fileName];
    
    // Save to file
    NSError *err = nil;
    [data writeToFile:filePath options:NSDataWritingAtomic error:&err];
    
    // set file name
    self.avatarImageFileName = fileName;
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", _avatarImageFileName] forKey:kAvatarImageNameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)getAvatarImage
{
    NSString *filePath = nil;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    filePath = [cacheDirectory stringByAppendingPathComponent:_avatarImageFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath] == NO)
        filePath = nil;
    
    UIImage *imgFile = nil;
    if (filePath != nil)
        imgFile = [UIImage imageWithContentsOfFile:filePath];
    if (imgFile == nil)
    {
        imgFile = [UIImage imageNamed:[[MAUIManager sharedUIManager] getDefaultAvatarImageName]];
        _avatarImageFileName = [[MAUIManager sharedUIManager] getDefaultAvatarImageName];
    }
    imgFile = [UIImage imageWithCGImage:[imgFile CGImage] scale:[UIScreen mainScreen].scale orientation:[imgFile imageOrientation]];
    _avatarImage = imgFile;
}


@end
