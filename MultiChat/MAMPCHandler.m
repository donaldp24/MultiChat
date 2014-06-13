 //
//  MAMPCHandler.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAMPCHandler.h"
#import "MAGlobalData.h"
#import "MACommonMethods.h"


@interface MAMPCHandler() {
    BOOL _isStarted;
    BOOL _isConnected;
    
    NSMutableArray *_connectingPeers;
    double _lastTime;
    int _interval;
    NSTimer *_timer;
}

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;

@property (nonatomic, strong) NSRecursiveLock *theLock;


// {array of MAMessage}
@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSMutableDictionary *avatars;

// { uid : username }
@property (nonatomic, strong) NSMutableDictionary *peers;

/**
 * store all messages received
 */
@property (nonatomic, strong) NSMutableArray *receivedMessages;

// {uid: [ connected array of { uid : username } ]}
@property (nonatomic, strong) NSMutableDictionary *connectionInfos;

@end

@implementation MAMPCHandler

- (id)init{
    self = [super init];
    
    self.theLock = [[NSRecursiveLock alloc] init];
    
    _isStarted = NO;
    _isConnected = NO;
    
    self.messages = [[NSMutableArray alloc] init];
    self.receivedMessages = [[NSMutableArray alloc] init];
    
    self.peers = [[NSMutableDictionary alloc] init];
    
    _connectingPeers = [[NSMutableArray alloc] init];
    
    self.avatars = [[NSMutableDictionary alloc] init];
    
    self.connectionInfos = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)setDelegate:(id<MAMPCHandlerDelegate>)delegate
{
    _delegate = delegate;
}


- (void)start:(NSString *)displayName {
    [self.theLock lock];
    
    _isConnected = NO;
    [_connectingPeers removeAllObjects];
    [self.connectionInfos removeAllObjects];
    
    [self setupPeerWithDisplayName:displayName];
    
    [self setupSession];
    [self startAdvertiser];
    [self startBrowser];

    NSLog(@"handler started");
    
    _isStarted = YES;
    
    _interval = 10;
    _lastTime = [[NSDate date] timeIntervalSince1970];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerProc:) userInfo:nil repeats:YES];
    
    [self.theLock unlock];
}

- (void)stop {

    [self.theLock lock];
    
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }

    [self stopBrowser];
    [self stopAdvertiser];
    
    [self.session disconnect];
    
    NSLog(@"handler stopped");
    
    _isStarted = NO;
    _isConnected = NO;
    
    [self.theLock unlock];
}


- (BOOL)isStarted {
    return _isStarted;
}

/**
 * geta all reachable peers  : array of {uid:username}
 */
- (void)getPeers:(NSMutableArray *__autoreleasing *)peersArray
{
    [self.theLock lock];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    if (self.session == nil || [self.session.connectedPeers count] <= 0)
    {
        *peersArray = array;
        [self.theLock unlock];
        return;
    }
    
    NSMutableArray *connectedPeerIDs = [[NSMutableArray alloc] init];
    
    // directly connected peers
    for (int i = 0; i < self.session.connectedPeers.count; i++) {
        MCPeerID *peerID = [self.session.connectedPeers objectAtIndex:i];
        [connectedPeerIDs addObject:[peerID displayName]];
    }
    
    // indirectly connected peers
    NSArray *values = [self.connectionInfos allValues];
    for (NSArray *dicArray in values) {
        for (NSDictionary *dic in dicArray) {
            NSString *peerIDDisplayName = [[dic allKeys] objectAtIndex:0];
            if (![connectedPeerIDs containsObject:peerIDDisplayName])
                [connectedPeerIDs addObject:peerIDDisplayName];
        }
    }
    
    // added {uid:userName} value to array
    for (NSString *key in connectedPeerIDs) {
        NSArray *keys = [self.peers allKeys];
        for (NSString *uid in keys)
        {
            NSString *userName = [self.peers objectForKey:uid];
            if ([uid isEqualToString:key])
            {
                NSDictionary *dic = @{uid:userName};
                [array addObject:dic];
                break;
            }
        }
    }
    
    *peersArray = array;
    [self.theLock unlock];
}

- (void)getMessages:(NSString *)uid array:(NSMutableArray **)messageArray isReading:(BOOL)isReading
{
    [self.theLock lock];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (MAMessage *message in self.messages) {
        
        if (uid == nil || [uid isEqualToString:kUidForEveryone])
        {
            if ((message.jsmessage.messageType == JSBubbleMessageTypeOutgoing && [message.receiverUid isEqualToString:kUidForEveryone]) ||
                (message.jsmessage.messageType == JSBubbleMessageTypeIncoming && [message.receiverUid isEqualToString:kUidForEveryone]))
            {
                if (message.isRead == NO)
                    message.isRead = isReading;
                [array addObject:message];
            }
        }
        else
        {
            if ((message.jsmessage.messageType == JSBubbleMessageTypeIncoming &&
                 [message.receiverUid isEqualToString:[self.peerID displayName]] &&
                 [message.senderUid isEqualToString:uid ]
                 )
                ||
                (message.jsmessage.messageType == JSBubbleMessageTypeOutgoing &&
                 [message.receiverUid isEqualToString:uid] &&
                 [message.senderUid isEqualToString:[self.peerID displayName]]))
            {
                if (message.isRead == NO)
                    message.isRead = isReading;
                [array addObject:message];
            }
        }
    }
    *messageArray = array;
    
    [self.theLock unlock];
}

/**
 * get unread message count for uid(sender)->receiver or all
 *
 */
- (int)getUnreadMessageCount:(NSString *)uid
{
    int count = 0;
    [self.theLock lock];

    for (MAMessage *message in self.messages) {
        
        if (uid == nil || [uid isEqualToString:kUidForEveryone])
        {
            if ((message.jsmessage.messageType == JSBubbleMessageTypeOutgoing && [message.receiverUid isEqualToString:kUidForEveryone]) ||
                (message.jsmessage.messageType == JSBubbleMessageTypeIncoming && [message.receiverUid isEqualToString:kUidForEveryone]))
            {
                if (message.isRead == NO)
                    count++;
            }
        }
        else
        {
            if ((message.jsmessage.messageType == JSBubbleMessageTypeIncoming &&
                 [message.receiverUid isEqualToString:[self.peerID displayName]] &&
                 [message.senderUid isEqualToString:uid ]
                 )
                ||
                (message.jsmessage.messageType == JSBubbleMessageTypeOutgoing &&
                 [message.receiverUid isEqualToString:uid] &&
                 [message.senderUid isEqualToString:[self.peerID displayName]]))
            {
                if (message.isRead == NO)
                    count++;
            }
        }
    }
    
    [self.theLock unlock];
    return count;
}

- (void)setupPeerWithDisplayName:(NSString *)displayName {
    self.peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
}

- (void)setupSession {
    self.session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
}


- (void)startBrowser {

    [self.theLock lock];
    
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:kServiceType];
    self.browser.delegate = self;
    
    [self.browser startBrowsingForPeers];
    
    NSLog(@"start browsing");
    
    [self.theLock unlock];
}

- (void)stopBrowser {
    [self.theLock lock];

    [self.browser stopBrowsingForPeers];
    self.browser.delegate = nil;
    self.browser = nil;
    
    NSLog(@"stop browsing");
    
    [self.theLock unlock];
}

- (void)startAdvertiser {
    
    [self.theLock lock];
    
    NSDictionary *discoveryInfo = @{kDiscoveryUsernameKey: [MAGlobalData sharedData].userName};
    
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:discoveryInfo serviceType:kServiceType];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
    
    //_isAdvertising = YES;
    
    NSLog(@"start advertising");
    
    [self.theLock unlock];
}

- (void)stopAdvertiser {
    [self.theLock lock];
    
    [self.advertiser stopAdvertisingPeer];
    self.advertiser.delegate = nil;
    self.advertiser = nil;
    
    //_isAdvertising = NO;
    
    //_isInvited = NO;
    
    NSLog(@"stop advertising");
    
    [self.theLock unlock];
}

- (NSUInteger)numberOfConnectedPeers:(NSString *)uid {
    NSUInteger count = 0;
    
    [self.theLock lock];
    
    if (self.session)
    {
        if ([uid isEqualToString:@""])
            count = [self.session.connectedPeers count];
        else
        {
            for (MCPeerID *peerID in self.session.connectedPeers) {
                if ([[peerID displayName] isEqualToString:uid])
                {
                    count = 1;
                    break;
                }
            }
        }
    }
    
    [self.theLock unlock];
    
    return count;
}

#pragma mark - Session Delegate
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
    
    [self.theLock lock];
    if (![session isEqual:self.session])
    {
        NSLog(@"not same session");
        [self.theLock unlock];
        return;
    }
    
    
    NSDictionary *userInfo = @{ @"peerID": peerID,
                                @"state" : @(state) };
    
    NSLog(@"didChangeState : %d, displayName : %@", (int)state, [peerID displayName]);
    
    if (self.session.connectedPeers.count != 0)
        _isConnected = YES;
    else
    {
        [self.connectionInfos removeAllObjects];
        _isConnected = NO;
    }

    
    if (state == MCSessionStateConnected)
    {
        [self sendAvatar:[MAGlobalData sharedData].avatarImage receiverUid:[peerID displayName]];
    }
    else if (state == MCSessionStateConnecting)
    {
        if (![_connectingPeers containsObject:peerID])
            [_connectingPeers addObject:peerID];
    }
    else
    {
        [_connectingPeers removeObject:peerID];
        
        
        NSString *displayName = [peerID displayName];
        int count = [self.connectionInfos count];
        [self.connectionInfos removeObjectForKey:[peerID displayName]];
        count = [self.connectionInfos count];
        count = count;
    }
    
    if (_isConnected)
        [self sendConnectionInfo];
    
    _lastTime = [[NSDate date] timeIntervalSince1970];

    [self.theLock unlock];

    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate)
            [self.delegate peerStateChanged:userInfo];
    });
    

}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
    NSLog(@"received data from : %@", [peerID displayName]);
    
    [self.theLock lock];
    
    MAMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    // if already received, ignore the message
    // if the message is sent from this node, ignore the messsage
    if ([self.receivedMessages containsObject:message.messageUid] ||
        [message.senderUid isEqualToString:[self.peerID displayName]])
    {
        [self.theLock unlock];
        return;
    }
    
    // add the message to processed messages
    [self.receivedMessages addObject:message.messageUid];
    
    if (message.type == MAMessageTypeMessage)
    {
        if ([message.receiverUid isEqualToString:[self.peerID displayName]] ||
            [message.receiverUid isEqualToString:kUidForEveryone])
        {
            message.jsmessage.messageType = JSBubbleMessageTypeIncoming;
            [self.messages addObject:message];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate)
                    [self.delegate peerDataReceived:message];
            });
        }
        
        // if receiver is not this node, then relay the message
        if (![message.receiverUid isEqualToString:[self.peerID displayName]])
        {
            // relay the message
            [self relayMessage:message];
        }
    }
    else if (message.type == MAMessageTypeAvatar)
    {
        if ([message.receiverUid isEqualToString:[self.peerID displayName]] ||
            [message.receiverUid isEqualToString:kUidForEveryone])
        {
            UIImage *image = message.avatar;
            [self.avatars setObject:image forKey:message.senderUid];
        }
        
        // if receiver is not this node, then relay it
        if (![message.receiverUid isEqualToString:[self.peerID displayName]])
            [self relayMessage:message];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate)
                [self.delegate peerDataReceived:message];
        });
        
        
    }
    else if (message.type == MAMessageTypeConnectionInfo)
    {
        NSMutableArray *array = [[NSMutableArray alloc] initWithArray:message.connectedPeers];
        [self.connectionInfos setObject:array forKey:[peerID displayName]];
        
        // connection info is not relayed
        //[self relayMessage:message];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate)
            {
                
                [self.delegate peerStateChanged:nil];
            }
        });
    }
    
    [self.theLock unlock];
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
    
    if (context)
    {
        NSString *userName = [[NSString alloc] initWithData:context encoding:NSUTF8StringEncoding];
        if (userName != nil && ![userName isEqualToString:@""])
        {
            NSLog(@"%@-%@", [peerID displayName], userName);
            [self.peers setObject:userName forKey:[peerID displayName]];
        }
    }
    
    if (![_connectingPeers containsObject:peerID] && ![self.session.connectedPeers containsObject:peerID] && [[self.peerID displayName] caseInsensitiveCompare:[peerID displayName]] == NSOrderedAscending)
    {
        //_lastInviteTime = [[NSDate date] timeIntervalSince1970];
        NSLog(@"invite accepted : %@", [peerID displayName]);
        //NSMutableDictionary *invitePeer = [[NSMutableDictionary alloc] init];
        //[invitePeer setObject:[NSNumber numberWithInt:_lastInviteTime] forKey:@"time"];
        //[invitePeer setObject:peerID forKey:@"peerID"];

        //[_invitingPeers addObject:invitePeer];
        invitationHandler(YES, self.session);
        //_isInvited = YES;
    }
    else
    {
        NSLog(@"invite rejected : %@", [peerID displayName]);
        invitationHandler(NO, nil);
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
    

    NSString *userName = [info objectForKey:kDiscoveryUsernameKey];
    if (userName != nil && ![userName isEqualToString:@""])
    {
        [self.peers setObject:userName forKey:[peerID displayName]];
        NSLog(@"%@-%@", [peerID displayName], userName);
    }

    //NSLog(@"found peer %@ ---, advertisingPeer %@", [peerID displayName], _advertisingPeer);
    
    //if ([[self.session connectedPeers] containsObject:peerID])
    //{
    //    NSLog(@"found peer %@, already connected", [peerID displayName]);
    //}
    //else
    //{
      //  if ([_advertisingPeer caseInsensitiveCompare:[peerID displayName]] == NSOrderedDescending)
        //{
    if ([self.peerID.displayName caseInsensitiveCompare:[peerID displayName]] == NSOrderedDescending)
    {
            NSLog(@"found peer %@, send invite requesting", [peerID displayName]);
            NSData *context = [[MAGlobalData sharedData].userName dataUsingEncoding:NSUTF8StringEncoding];
            
            //_lastFoundPeerTime = [[NSDate date] timeIntervalSince1970];
            [browser invitePeer:peerID toSession:self.session withContext:context timeout:kFoundPeerTimeout];
            //_advertisingPeer = [NSString stringWithFormat:@"%@", [peerID displayName] ];
    }
        //}
    //}

    
    [self.theLock unlock];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    //
}

- (void)timerProc:(NSTimer *)timer
{
    [self.theLock lock];
    // count timeout
    double curTime = [[NSDate date] timeIntervalSince1970];
    if (_isConnected == NO)
    {
        if (curTime - _lastTime >= _interval)
        {
            _lastTime = curTime;
            _interval = 15 + (arc4random() % 5);
            
            [self restart];
            
            _lastTime = [[NSDate date] timeIntervalSince1970];
        }
    }
    [self.theLock unlock];
}

- (void)restart
{
    [self.theLock lock];
    
    [_connectingPeers removeAllObjects];
    
    [self stopAdvertiser];
    [self stopBrowser];
    [self.session disconnect];
    
    // if open this code block, then app will crash soon.
    /*
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *_uid = [NSString stringWithFormat:@"%@", (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid))];
    _uid = [_uid substringToIndex:13];
    [MAGlobalData sharedData].uid = _uid;
    
    [self setupPeerWithDisplayName:_uid];
     */
    [self setupSession];
    [self startAdvertiser];
    [self startBrowser];
     [self.theLock unlock];
}

-(UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


- (MAMessage *)sendMessage:(MAMessage *)mamessage receiverUid:(NSString *)receiverUid
{
    [self.theLock lock];
    static int count = 0;
    count++;
    mamessage.messageUid = [NSString stringWithFormat:@"%@-%@-%@-%d", [self.peerID displayName], receiverUid, [MACommonMethods date2str:[NSDate date] withFormat:DATETIME_FORMAT], count];
    
    mamessage.isRead = YES;
    mamessage.senderUid = [self.peerID displayName];
    mamessage.receiverUid = receiverUid;
    mamessage.passerUid = mamessage.senderUid;
    
    
    if (mamessage.type == MAMessageTypeMessage)
    {
        // store send message
        dispatch_async(dispatch_get_main_queue(), ^{
                [self.messages addObject:mamessage];
        });
        
    }
    else if (mamessage.type == MAMessageTypeAvatar)
    {
        // avatar message
    }
    else if (mamessage.type == MAMessageTypeConnectionInfo)
    {
        // connection info
    }
    
    NSError *error = nil;
    
    if ([receiverUid isEqualToString:kUidForEveryone])
    {
        mamessage.targetUid = kUidForEveryone;
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mamessage];
        
        // send to all
        if (![self.session sendData:data
                            toPeers:self.session.connectedPeers
                           withMode:MCSessionSendDataReliable
                              error:&error]) {
            NSLog(@"[Error] %@", error);
        }
    }
    else
    {
        // send to a specified target
        BOOL isSend = NO;
        for (MCPeerID *peerID in self.session.connectedPeers) {
            
            // send to receiver
            if ([[peerID displayName] isEqualToString:receiverUid])
            {
                isSend = YES;
                
                mamessage.targetUid = receiverUid;
                
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mamessage];
                
                if (![self.session sendData:data
                                    toPeers:[[NSArray alloc] initWithObjects:peerID, nil]
                                   withMode:MCSessionSendDataReliable
                                      error:&error]) {
                    NSLog(@"[Error] %@", error);
                }
                break;
            }
        }
        
        if (!isSend) {
            // send to all
            for (MCPeerID *peerID in self.session.connectedPeers) {
                mamessage.targetUid = [peerID displayName];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mamessage];
                if (![self.session sendData:data
                                    toPeers:[[NSMutableArray alloc] initWithObjects:peerID, nil]
                                   withMode:MCSessionSendDataReliable
                                      error:&error]) {
                    NSLog(@"[Error] %@", error);
                }
            }
        }
    }
    
    [self.theLock unlock];
    
    return mamessage;
}

//////////////////////////////////////
- (MAMessage *)sendMessageWithText:(NSString *)text recevierUid:(NSString *)receiverUid
{
    [self.theLock lock];
    
    JSMessage *message = [[JSMessage alloc] init];
    message.text = text;
    message.sender = [MAGlobalData sharedData].userName;
    message.messageType = JSBubbleMessageTypeOutgoing;
    message.mediaType = JSBubbleMediaTypeText;
    message.messageStyle = JSBubbleMessageStyleFlat;
    message.timestamp = [NSDate date];
    
    MAMessage *mamessage = [[MAMessage alloc] init];
    mamessage.type = MAMessageTypeMessage;
    mamessage.jsmessage = message;

    
    [self sendMessage:mamessage receiverUid:receiverUid];
    
    [self.theLock unlock];
    
    return mamessage;
}

//////////////////////////////////////////////////////////////////////
- (MAMessage *)sendMessageWithImage:(UIImage *)image receiverUid:(NSString *)receiverUid
{
    [self.theLock lock];
    
    JSMessage *message = [[JSMessage alloc] init];
    message.image = image;
    message.sender = [MAGlobalData sharedData].userName;
    message.messageType = JSBubbleMessageTypeOutgoing;
    message.mediaType = JSBubbleMediaTypeImage;
    message.messageStyle = JSBubbleMessageStyleFlat;
    message.timestamp = [NSDate date];
    
    MAMessage *mamessage = [[MAMessage alloc] init];
    mamessage.type = MAMessageTypeMessage;
    mamessage.jsmessage = message;
    
    [self sendMessage:mamessage receiverUid:receiverUid];
    
    [self.theLock unlock];
    
    
    return mamessage;
}


//////////////////////////////////////////////////////////////////////
- (MAMessage *)sendMessageWithSpeech:(NSData *)speech receiverUid:(NSString *)receiverUid
{
    [self.theLock lock];
    
    JSMessage *message = [[JSMessage alloc] init];
    message.text = @"  ....";
    message.speech = speech;
    message.sender = [MAGlobalData sharedData].userName;
    message.messageType = JSBubbleMessageTypeOutgoing;
    message.mediaType = JSBubbleMediaTypeSpeech;
    message.messageStyle = JSBubbleMessageStyleFlat;
    message.timestamp = [NSDate date];
    
    MAMessage *mamessage = [[MAMessage alloc] init];
    mamessage.type = MAMessageTypeMessage;
    mamessage.jsmessage = message;
    
    [self sendMessage:mamessage receiverUid:receiverUid];
    
    [self.theLock unlock];
    
    
    return mamessage;
}

//////////////////////////////////////////////////////////////////////
- (MAMessage *)sendAvatar:(UIImage *)avatar receiverUid:(NSString *)receiverUid
{
    [self.theLock lock];
    
    
    MAMessage *mamessage = [[MAMessage alloc] init];
    mamessage.type = MAMessageTypeAvatar;
    mamessage.avatar = [MACommonMethods imageResize:avatar andResizeTo:CGSizeMake(30, 30)];
    
    [self sendMessage:mamessage receiverUid:receiverUid];
    
    [self.theLock unlock];
    
    
    return mamessage;
}

////////////////////////////////////////////////////////////////////////////
- (MAMessage *)sendConnectionInfo
{
    [self.theLock lock];
    
    MAMessage *message = [[MAMessage alloc] init];
    message.type = MAMessageTypeConnectionInfo;
    message.connectedPeers = [[NSMutableArray alloc] init];
    
    for (MCPeerID *peerID in self.session.connectedPeers) {
        NSString *displayName = [peerID displayName];
        NSString *userName = [self.peers objectForKey:displayName];
        if (userName == nil)
            userName = displayName;
        [message.connectedPeers addObject:@{displayName:userName}];
    }
    
    [self sendMessage:message receiverUid:kUidForEveryone];
    
    [self.theLock unlock];
    
    return message;
}

- (UIImage *)getAvatar:(NSString *)uid
{
    return [self.avatars objectForKey:uid];
}


///////////////////////////////////////////////////////////////
- (void)relayMessage:(MAMessage *)message
{
    NSString *passerUid = message.passerUid;
    message.passerUid = [self.peerID displayName];
    
    NSError *error = nil;
    
    if ([message.receiverUid isEqualToString:kUidForEveryone])
    {
        message.targetUid = kUidForEveryone;
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
        
        for (MCPeerID *peerID in self.session.connectedPeers) {
            
            // send to broadcast
            if (![[peerID displayName] isEqualToString:message.senderUid] &&
                ![passerUid isEqualToString:message.passerUid])
            {
                if (![self.session sendData:data
                                    toPeers:[[NSArray alloc] initWithObjects:peerID, nil]
                                   withMode:MCSessionSendDataReliable
                                      error:&error]) {
                    NSLog(@"[Error] %@", error);
                }
                break;
            }
        }
    }
    else
    {
        // send to a specified target
        BOOL isSend = NO;
        for (MCPeerID *peerID in self.session.connectedPeers) {
            
            // send to receiver
            if ([[peerID displayName] isEqualToString:message.receiverUid])
            {
                isSend = YES;
                
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
                
                if (![self.session sendData:data
                                    toPeers:[[NSArray alloc] initWithObjects:peerID, nil]
                                   withMode:MCSessionSendDataReliable
                                      error:&error]) {
                    NSLog(@"[Error] %@", error);
                }
                break;
            }
        }
        
        if (!isSend) {
            // send to all
            for (MCPeerID *peerID in self.session.connectedPeers) {
                
                // send to broadcast
                if (![[peerID displayName] isEqualToString:message.senderUid] &&
                    ![passerUid isEqualToString:message.passerUid])
                {
                    message.targetUid = [peerID displayName];
                    
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
                    
                    if (![self.session sendData:data
                                        toPeers:[[NSArray alloc] initWithObjects:peerID, nil]
                                       withMode:MCSessionSendDataReliable
                                          error:&error]) {
                        NSLog(@"[Error] %@", error);
                    }
                    break;
                }
            }
        }
    }
    
}

@end
