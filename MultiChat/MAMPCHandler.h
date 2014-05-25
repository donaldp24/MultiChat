//
//  MAMPCHandler.h
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#define kServiceType    @"ma-chat"


@protocol MAMPCHandlerDelegate <NSObject>

- (void)peerStateChanged:(NSDictionary *)userInfo;
- (void)peerDataReceived:(NSDictionary *)dataInfo;

@end

@interface MAMPCHandler : NSObject <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) NSLock *theLock;

@property (nonatomic, strong) id<MAMPCHandlerDelegate> delegate;

- (void)start:(NSString *)displayName;
- (void)stop;


@end
