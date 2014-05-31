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
                self.jsmessage.text = [aDecoder decodeObjectForKey:kMessageTextKey];
                break;
            case JSBubbleMediaTypeImage:
                self.jsmessage.image = [UIImage imageWithData:[aDecoder decodeObjectForKey:kMessageImageKey]];
                break;
            case JSBubbleMediaTypeSpeech:
                self.jsmessage.text = @"....)))  ";
                self.jsmessage.speech = [aDecoder decodeObjectForKey:kMessageSpeechKey];
                break;
            default:
                break;
        }
        self.jsmessage.sender = [aDecoder decodeObjectForKey:kMessageSenderKey];
        self.jsmessage.timestamp = [aDecoder decodeObjectForKey:kMessageTimestampKey];
        
        // sender and receiver
        self.senderUid = [aDecoder decodeObjectForKey:kMessageSenderUidKey];
        self.receiverUid = [aDecoder decodeObjectForKey:kMessageReceiverUidKey];
        
        self.isInfo = [[aDecoder decodeObjectForKey:kMessageInfoKey] boolValue];
        
        self.isRead = NO;
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
            [aCoder encodeObject:self.jsmessage.text forKey:kMessageTextKey];
            break;
        case JSBubbleMediaTypeImage:
            [aCoder encodeObject:UIImageJPEGRepresentation(self.jsmessage.image, 75/100.0) forKey:kMessageImageKey];
            break;
        case JSBubbleMediaTypeSpeech:
            [aCoder encodeObject:self.jsmessage.text forKey:kMessageTextKey];
            [aCoder encodeObject:self.jsmessage.speech forKey:kMessageSpeechKey];
            break;
        default:
            break;
    }
    
    [aCoder encodeObject:self.jsmessage.sender forKey:kMessageSenderKey];
    [aCoder encodeObject:self.jsmessage.timestamp forKey:kMessageTimestampKey];
    
    
    // encode sender Uid and receiver Uid
    [aCoder encodeObject:self.senderUid forKey:kMessageSenderUidKey];
    [aCoder encodeObject:self.receiverUid forKey:kMessageReceiverUidKey];
    
    [aCoder encodeObject:[NSNumber numberWithBool:self.isInfo] forKey:kMessageInfoKey];
}


@end
