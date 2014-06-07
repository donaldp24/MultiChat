//
//  MACommonMethods.h
//  MultiChat
//
//  Created by Donald Pae on 6/6/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>


#define DATETIME_FORMAT @"yyyy-MM-dd HH:mm:ss"


@interface MACommonMethods : NSObject

+ (NSDate *)str2date:(NSString *)dateString withFormat:(NSString *)formatString;
+ (NSString *)date2str:(NSDate *)convertDate withFormat:(NSString *)formatString;
+ (UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize;

@end
