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
#define kMessageTypeKey             @"messagetype"
#define kMessageMediaTypeKey       @"mediatype"
#define kMessageStyleKey            @"messagestyle"
#define kMessageRawDataKey          @"rawdata"
#define kMessageSenderKey           @"sender"
#define kMessageTimestampKey        @"timestamp"

#define kMessageSenderUidKey           @"senderUid"
#define kMessageReceiverUidKey           @"receiverUid"

@interface MAMessage : NSObject <NSCoding>

@property (nonatomic, strong) JSMessage *jsmessage;
@property (nonatomic, strong) NSString *senderUid;
@property (nonatomic, strong) NSString *receiverUid;

- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end
