//
//  JSMessage.h
//  MultiChat
//
//  Created by Donald Pae on 5/22/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    JSBubbleMessageTypeIncoming = 0,
    JSBubbleMessageTypeOutgoing
} JSBubbleMessageType;

typedef enum {
    JSBubbleMediaTypeText = 0,
    JSBubbleMediaTypeImage,
    JSBubbleMediaTypeSpeech
}JSBubbleMediaType;

typedef enum {
    JSBubbleMessageStyleDefault = 0,
    JSBubbleMessageStyleSquare,
    JSBubbleMessageStyleDefaultGreen,
    JSBubbleMessageStyleFlat
} JSBubbleMessageStyle;



@interface JSMessage : NSObject

@property (strong, nonatomic) NSString *sender;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSData *speech;
@property (nonatomic) JSBubbleMessageType messageType;
@property (nonatomic) JSBubbleMediaType mediaType;
@property (nonatomic) JSBubbleMessageStyle messageStyle;

@property (strong, nonatomic) NSDate *timestamp;

@end
