//
//  MAMessage.m
//  MultiChat
//
//  Created by Donald Pae on 5/26/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAMessage.h"

@implementation MAMessage

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        
        // decode js message
        self.jsmessage = [[JSMessage alloc] init];
        self.jsmessage.messageType = [[aDecoder decodeObjectForKey:kMessageTypeKey] intValue];
        self.jsmessage.messageStyle = [[aDecoder decodeObjectForKey:kMessageStyleKey] intValue];
        self.jsmessage.mediaType = [[aDecoder decodeObjectForKey:kMessageMediaTypeKey] intValue];
        switch (self.jsmessage.mediaType) {
            case JSBubbleMediaTypeText:
                self.jsmessage.text = [aDecoder decodeObjectForKey:kMessageRawDataKey];
                break;
            case JSBubbleMediaTypeImage:
                self.jsmessage.image = [aDecoder decodeObjectForKey:kMessageRawDataKey];
                break;
            case JSBubbleMediaTypeSpeech:
                self.jsmessage.speech = [aDecoder decodeObjectForKey:kMessageRawDataKey];
                break;
            default:
                break;
        }
        self.jsmessage.sender = [aDecoder decodeObjectForKey:kMessageSenderKey];
        self.jsmessage.timestamp = [aDecoder decodeObjectForKey:kMessageTimestampKey];
        
        // sender and receiver
        self.senderUid = [aDecoder decodeObjectForKey:kMessageSenderUidKey];
        self.receiverUid = [aDecoder decodeObjectForKey:kMessageReceiverUidKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    // encode js message
    [aCoder encodeObject:[NSNumber numberWithInt:self.jsmessage.messageType] forKey:kMessageTypeKey];
    [aCoder encodeObject:[NSNumber numberWithInt:self.jsmessage.messageStyle] forKey:kMessageStyleKey];
    [aCoder encodeObject:[NSNumber numberWithInt:self.jsmessage.mediaType] forKey:kMessageMediaTypeKey];
    
    switch (self.jsmessage.mediaType) {
        case JSBubbleMediaTypeText:
            [aCoder encodeObject:self.jsmessage.text forKey:kMessageRawDataKey];
            break;
        case JSBubbleMediaTypeImage:
            [aCoder encodeObject:self.jsmessage.image forKey:kMessageRawDataKey];
            break;
        case JSBubbleMediaTypeSpeech:
            [aCoder encodeObject:self.jsmessage.speech forKey:kMessageRawDataKey];
            break;
        default:
            break;
    }
    
    [aCoder encodeObject:self.jsmessage.sender forKey:kMessageSenderKey];
    [aCoder encodeObject:self.jsmessage.timestamp forKey:kMessageTimestampKey];
    
    
    // encode sender Uid and receiver Uid
    [aCoder encodeObject:self.senderUid forKey:kMessageSenderUidKey];
    [aCoder encodeObject:self.receiverUid forKey:kMessageReceiverUidKey];
}


@end
