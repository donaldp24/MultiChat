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
#import "MAPeerID.h"

#define kServiceType    @"ma-chat"
#define kInviteTimeout  10
#define kFoundPeerTimeout   10

#define kDiscoveryUidKey    @"uid"

@protocol MAMPCHandlerDelegate <NSObject>

- (void)peerStateChanged:(NSDictionary *)userInfo;
- (void)peerDataReceived:(MAMessage *)message;

@end

@interface MAMPCHandler : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>


@property (nonatomic, strong) id<MAMPCHandlerDelegate> delegate;

- (void)start:(NSString *)displayName;
- (void)stop;
- (BOOL)isStarted;
- (NSUInteger)numberOfConnectedPeers;
- (void)getPeers:(NSMutableArray **)peersArray;
- (MAMessage *)sendMessageWithText:(NSString *)text;
- (MAMessage *)sendMessageWithText:(NSString *)text peerID:(MAPeerID *)targetPeerID;


@end
