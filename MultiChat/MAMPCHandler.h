//
//  MAMPCHandler.h
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "MAMessage.h"

#define kServiceType    @"ma-chat"
#define kInviteTimeout  30
#define kFoundPeerTimeout   30

//#define kDiscoveryUidKey    @"uid"
#define kDiscoveryUsernameKey @"username"

@protocol MAMPCHandlerDelegate <NSObject>

- (void)peerStateChanged:(NSDictionary *)userInfo;
- (void)peerDataReceived:(MAMessage *)message;

@end

@interface MAMPCHandler : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>


@property (nonatomic, strong) id<MAMPCHandlerDelegate> delegate;

- (void)start:(NSString *)displayName;
- (void)stop;
- (void)restart;
- (BOOL)isStarted;
- (NSUInteger)numberOfConnectedPeers:(NSString *)uid;
- (void)getPeers:(NSMutableArray **)peersArray;
- (void)getMessages:(NSString *)uid array:(NSMutableArray **)messageArray isReading:(BOOL)isReading;
- (int)getUnreadMessageCount:(NSString *)uid;
//- (MAMessage *)sendMessageWithText:(NSString *)text;
- (MAMessage *)sendMessageWithText:(NSString *)text uid:(NSString *)targetUid;
//- (MAMessage *)sendMessageWithImage:(UIImage *)image;
- (MAMessage *)sendMessageWithImage:(UIImage *)image uid:(NSString *)targetUid;
//- (MAMessage *)sendMessageWithSpeech:(NSData *)speech;
- (MAMessage *)sendMessageWithSpeech:(NSData *)speech uid:(NSString *)targetUid;

- (MAMessage *)sendAvatar:(UIImage *)avatar uid:(NSString *)targetUid;

- (UIImage *)getAvatar:(NSString *)uid;


@end
