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


/**
 * uid for everyone
 */
#define kUidForEveryone @""


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

- (MAMessage *)sendAvatar:(UIImage *)avatar receiverUid:(NSString *)receiverUid;
- (MAMessage *)sendMessageWithText:(NSString *)text recevierUid:(NSString *)receiverUid;
- (MAMessage *)sendMessageWithImage:(UIImage *)image receiverUid:(NSString *)receiverUid;
- (MAMessage *)sendMessageWithSpeech:(NSData *)speech receiverUid:(NSString *)receiverUid;



- (UIImage *)getAvatar:(NSString *)uid;


@end
