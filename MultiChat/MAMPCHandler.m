 //
//  MAMPCHandler.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAMPCHandler.h"

enum MPCHandlerState {
    MPCHandlerStateNone = -1,
    MPCHandlerStateBrowsing = 0,
    MPCHandlerStateAdvertising = 1
};

@interface MAMPCHandler() {
    NSTimer *_timer;
}

@property (nonatomic) BOOL isConnected;
@property (nonatomic) BOOL isReceivedInvite;
@property (nonatomic) int state;

@property (nonatomic, strong) NSMutableArray *foundPeers;


@end

@implementation MAMPCHandler

- (id)init{
    self = [super init];
    
    self.theLock = [[NSLock alloc] init];
    self.isConnected = NO;
    self.foundPeers = [[NSMutableArray alloc] init];
    self.isReceivedInvite = NO;
    self.state = MPCHandlerStateNone;
    
    return self;
}

- (void)initMembers {
    self.isConnected = NO;
    [self.foundPeers removeAllObjects];
    self.isReceivedInvite = NO;
}

- (void)start:(NSString *)displayName {
    
    [self.theLock lock];
    
    [self initMembers];
    
    [self setupPeerWithDisplayName:displayName];
    [self setupSession];
    //if ( [(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"])
    //{
        self.state = MPCHandlerStateBrowsing;
    
        [self startBrowser];
    //}
    //else
    //    [self advertiseSelf:YES];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(timerProc:) userInfo:nil repeats:YES];
    
    [self.theLock unlock];
}

- (void)stop {
    
    [self.theLock lock];
    
    self.delegate = nil;
    
    if (_timer != nil)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    self.state = MPCHandlerStateNone;
    [self stopBrowser];
    [self stopAdvertiser];
    [self.session disconnect];
    
    [self.theLock unlock];
}

- (void)setupPeerWithDisplayName:(NSString *)displayName {
    self.peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
}

- (void)setupSession {
    self.session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
}


- (void)startBrowser {
    [self setupSession];
    
    [self.foundPeers removeAllObjects];
    
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:kServiceType];
    self.browser.delegate = self;
    
    [self.browser startBrowsingForPeers];
}

- (void)stopBrowser {
    [self.foundPeers removeAllObjects];
    [self.browser stopBrowsingForPeers];
    self.browser.delegate = nil;
    self.browser = nil;
}

- (void)startAdvertiser {

    self.isReceivedInvite = NO;
    
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:kServiceType];
    self.advertiser.delegate = self;
    
    [self setupSession];
    [self.advertiser startAdvertisingPeer];
}

- (void)stopAdvertiser {
    self.isReceivedInvite = NO;
    [self.advertiser stopAdvertisingPeer];
    self.advertiser.delegate = nil;
    self.advertiser = nil;
}

#pragma mark - Session Delegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
    [self.theLock lock];
    
    
    NSDictionary *userInfo = @{ @"peerID": peerID,
                                @"state" : @(state) };
    
    NSLog(@"displayName : %@", [peerID displayName]);
    
    
    if ([self.session.connectedPeers count] == 0)
    {
        self.isConnected = NO;
        NSLog(@"connectedPeers : 0");
    }
    else
    {
        self.isConnected = YES;
        NSLog(@"connectedPeers : %d", [self.session.connectedPeers count]);
    }
    
    if (self.state == MPCHandlerStateBrowsing)
    {
        [self.foundPeers removeObject:peerID];
        NSLog(@"Peer is removed from foundPeers : %@", [peerID displayName]);
    }
    else if (self.state == MPCHandlerStateAdvertising)
    {
        self.isReceivedInvite = NO;
        NSLog(@"isReceivedInvite : NO");
    }
    
    [self.theLock unlock];
    
    if (self.delegate)
        [self.delegate peerStateChanged:userInfo];
    
    
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSDictionary *userInfo = @{ @"data": data,
                                @"peerID": peerID };
    
    NSLog(@"received data from : %@", [peerID displayName]);
    
    if (self.delegate)
        [self.delegate peerDataReceived:userInfo];
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}


#pragma mark - Advertiser Delegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    //
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    [self.theLock lock];
    
    
    if (_state == MPCHandlerStateBrowsing || _state == MPCHandlerStateNone || self.isReceivedInvite == YES)
    {
        invitationHandler(NO, nil);
        NSLog(@"state %d, => invite is rejected : %@", self.state, [peerID displayName]);
    }
    else
    {
        NSLog(@"invite accepted : %@", [peerID displayName]);
        self.isReceivedInvite = YES;
        invitationHandler(YES, self.session);
    }
    
    [self.theLock unlock];
}


#pragma mark - Browser Delegate
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    //
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    [self.theLock lock];
    
    if (self.state == MPCHandlerStateAdvertising || self.state == MPCHandlerStateNone) {
        self.state = self.state;
        NSLog(@"don't send invite requesting, state= %d, peer = %@", self.state, [peerID displayName]);
    }
    else
    {
        NSLog(@"send invite requesting, peer = %@", [peerID displayName]);
        [self.foundPeers addObject:peerID];
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:30];
    }
    
    [self.theLock unlock];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    //
}

- (void)timerProc:(NSTimer *)timer {
    
    [self.theLock lock];
    
    if (self.isConnected == YES || self.state == MPCHandlerStateNone)
    {
        self.isConnected = self.isConnected;
    }
    else
    {
        if (self.state == MPCHandlerStateBrowsing)
        {
            if ([self.foundPeers count] == 0)
            {
                [self stopBrowser];
                self.state = MPCHandlerStateAdvertising;
                [self startAdvertiser];
                
                NSLog(@"browsing to advertising");
            }
            else
            {
                NSLog(@"browsing: cannot transform to advertising: found peers : %d", [self.foundPeers count]);
            }
        }
        else if (self.state == MPCHandlerStateAdvertising)
        {
            if (self.isReceivedInvite == NO)
            {
                [self stopAdvertiser];
                self.state = MPCHandlerStateBrowsing;
                [self startBrowser];
                
                NSLog(@"advertising to browsing");
            }
            else
            {
                NSLog(@"advertisng: cannot transform to browsing: received invite");
            }
        }
    }
    
    [self.theLock unlock];
}

@end
