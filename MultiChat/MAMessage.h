//
//  MAMessage.h
//  MultiChat
//
//  Created by Donald Pae on 5/26/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSMessage.h"

// keys for NSCoding
#define kMessageUidKey              @"messageuid"
#define kMessageTypeKey             @"messagetype"
#define kMessageMediaTypeKey       @"mediatype"
#define kMessageStyleKey            @"messagestyle"
#define kMessageTextKey          @"text"
#define kMessageImageKey          @"image"
#define kMessageSpeechKey          @"speech" 
#define kMessageSenderKey           @"sender"
#define kMessageTimestampKey        @"timestamp"

#define kTypeKey                        @"type"

#define kMessageSenderUidKey           @"senderUid"
#define kMessageReceiverUidKey           @"receiverUid"

#define kMessagePasserUidKey             @"passerUid"
#define kMessageTargetUidKey            @"targetUid"

#define kMessageAvatarKey               @"avatar"
#define kMessageConnectionInfoKey       @"conninfo"


typedef enum {
    MAMessageTypeMessage = 0,
    MAMessageTypeAvatar,
    MAMessageTypeConnectionInfo
}MAMessageType;

@interface MAMessage : NSObject <NSCoding>


/**
 * message identifier
 */
@property (nonatomic, strong) NSString *messageUid;

/**
 *
 */
@property (nonatomic) MAMessageType type;

/**
 *
 */
@property (nonatomic, strong) JSMessage *jsmessage;

/**
 * uid of message sender
 *  set when message creating
 */
@property (nonatomic, strong) NSString *senderUid;
/**
 * uid of message receiver
 *   set when message creating
 */
@property (nonatomic, strong) NSString *receiverUid;

/**
 * uid of message passer
 *  set when message passing
 */
@property (nonatomic, strong) NSString *passerUid;

/**
 * uid of message target
 *  set when message passing
 */
@property (nonatomic, strong) NSString *targetUid;

/**
 * connected Peers
 */
@property (nonatomic, strong) NSMutableArray *connectedPeers;

/**
 * avatar image
 */
@property (nonatomic, strong) UIImage *avatar;


@property (nonatomic) BOOL isRead;


- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
