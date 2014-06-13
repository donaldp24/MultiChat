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
        
        // decode message
        
        self.messageUid = [aDecoder decodeObjectForKey:kMessageUidKey];
        
        self.type = [[aDecoder decodeObjectForKey:kTypeKey] intValue];
        
        self.isRead = NO;
        
        // sender, receiver
        self.senderUid = [aDecoder decodeObjectForKey:kMessageSenderUidKey];
        self.receiverUid = [aDecoder decodeObjectForKey:kMessageReceiverUidKey];
        
        // passer, target
        self.passerUid = [aDecoder decodeObjectForKey:kMessagePasserUidKey];
        self.targetUid = [aDecoder decodeObjectForKey:kMessageTargetUidKey];
        
        if (self.type == MAMessageTypeMessage)
        {
            // message for messaging
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
                    self.jsmessage.text = @".... ";
                    self.jsmessage.speech = [aDecoder decodeObjectForKey:kMessageSpeechKey];
                    break;
                default:
                    break;
            }
            self.jsmessage.sender = [aDecoder decodeObjectForKey:kMessageSenderKey];
            self.jsmessage.timestamp = [aDecoder decodeObjectForKey:kMessageTimestampKey];
        }
        else if (self.type == MAMessageTypeAvatar)
        {
            // message for avatar
            self.avatar = [UIImage imageWithData:[aDecoder decodeObjectForKey:kMessageAvatarKey]];
        }
        else if (self.type == MAMessageTypeConnectionInfo)
        {
            // message for connection info
            self.connectedPeers = [[NSMutableArray alloc] init];
        }
        else
            return nil;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    //uid
    [aCoder encodeObject:self.messageUid forKey:kMessageUidKey];
    
    // type
    [aCoder encodeObject:[NSNumber numberWithInt:self.type] forKey:kTypeKey];
    
    // encode sender Uid and receiver Uid
    [aCoder encodeObject:self.senderUid forKey:kMessageSenderUidKey];
    [aCoder encodeObject:self.receiverUid forKey:kMessageReceiverUidKey];
    
    // passer, target
    [aCoder encodeObject:self.passerUid forKey:kMessagePasserUidKey];
    [aCoder encodeObject:self.targetUid forKey:kMessageTargetUidKey];
    
    
    if (self.type == MAMessageTypeMessage)
    {
        [aCoder encodeObject:[NSNumber numberWithInt:self.jsmessage.messageType] forKey:kMessageTypeKey];
        [aCoder encodeObject:[NSNumber numberWithInt:self.jsmessage.messageStyle] forKey:kMessageStyleKey];
        [aCoder encodeObject:[NSNumber numberWithInt:self.jsmessage.mediaType] forKey:kMessageMediaTypeKey];
        
        switch (self.jsmessage.mediaType) {
            case JSBubbleMediaTypeText:
                [aCoder encodeObject:self.jsmessage.text forKey:kMessageTextKey];
                break;
            case JSBubbleMediaTypeImage:
                [aCoder encodeObject:UIImagePNGRepresentation(self.jsmessage.image) forKey:kMessageImageKey];
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
    }
    else if (self.type == MAMessageTypeAvatar)
    {
        // message for avatar
        [aCoder encodeObject:UIImagePNGRepresentation(self.avatar) forKey:kMessageAvatarKey];
    }
    else if (self.type == MAMessageTypeConnectionInfo)
    {
        // message for connection info
        [aCoder encodeObject:self.connectedPeers forKey:kMessageConnectionInfoKey];
    }
}


@end
