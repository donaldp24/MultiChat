//
//  MAChatViewController.h
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MAMPCHandler.h"

#import "JSMessagesViewController.h"

@interface MAChatViewController : JSMessagesViewController <MAMPCHandlerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSString *receiverPeerUid;


@end
