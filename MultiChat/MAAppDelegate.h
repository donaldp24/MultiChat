//
//  MAAppDelegate.h
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MAMPCHandler.h"

@interface MAAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) MAMPCHandler *mpcHandler;

@end
