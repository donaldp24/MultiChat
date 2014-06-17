//
//  JSBubbleView.m
//
//  Created by Jesse Squires on 2/12/13.
//  Copyright (c) 2013 Hexed Bits. All rights reserved.
//
//  http://www.hexedbits.com
//
//
//  Largely based on work by Sam Soffes
//  https://github.com/soffes
//
//  SSMessagesViewController
//  https://github.com/soffes/ssmessagesviewcontroller
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
//  associated documentation files (the "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
//  following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
//  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
//  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "JSBubbleView.h"
#import "JSMessageInputView.h"
#import "NSString+JSMessagesView.h"
#import "UIImage+JSMessagesView.h"

CGFloat const kJSAvatarSize = 50.0f;

#define kSenderTextHeight 14.0f

#define kMarginTop 3.0f
#define kMarginBottom 3.0f
#define kPaddingTop 6.0f
#define kPaddingBottom 6.0f
#define kBubblePaddingRight 35.0f

#define kImagePaddingTop 3.0f

#define kSpeakerBubbleWidth 45.0f
#define kSpeakerBubbleHeight 35.0f

@interface JSBubbleView()

- (void)setup;

+ (UIImage *)bubbleImageTypeIncomingWithStyle:(JSBubbleMessageStyle)aStyle;
+ (UIImage *)bubbleImageTypeOutgoingWithStyle:(JSBubbleMessageStyle)aStyle;

@end



@implementation JSBubbleView

@synthesize type;
@synthesize style;
@synthesize mediaType;
@synthesize text;
@synthesize data;
@synthesize speech;
@synthesize sender;
@synthesize selectedToShowCopyMenu;

#pragma mark - Setup
- (void)setup
{
    self.backgroundColor = [UIColor whiteColor];
    //self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.autoresizingMask = UIViewAutoresizingNone;
}

#pragma mark - Initialization
- (id)initWithFrame:(CGRect)rect
         bubbleType:(JSBubbleMessageType)bubleType
        bubbleStyle:(JSBubbleMessageStyle)bubbleStyle
          mediaType:(JSBubbleMediaType)bubbleMediaType
{
    self = [super initWithFrame:rect];
    if(self) {
        [self setup];
        self.type = bubleType;
        self.style = bubbleStyle;
        self.mediaType = bubbleMediaType;
    }
    return self;
}

- (void)dealloc
{
    self.text = nil;
}

#pragma mark - Setters
- (void)setType:(JSBubbleMessageType)newType
{
    type = newType;
    [self setNeedsDisplay];
}

- (void)setStyle:(JSBubbleMessageStyle)newStyle
{
    style = newStyle;
    [self setNeedsDisplay];
}

- (void)setMediaType:(JSBubbleMediaType)newMediaType{
    mediaType = newMediaType;
    [self setNeedsDisplay];
}

- (void)setText:(NSString *)newText
{
    text = newText;
    [self setNeedsDisplay];
}

- (void)setData:(id)newData{
    data = newData;
    [self setNeedsDisplay];
}

- (void)setSpeech:(id)newVoice{
    speech = newVoice;
    [self setNeedsDisplay];
}

- (void)setSender:(NSString *)newSender{
    sender = newSender;
    [self setNeedsDisplay];
}

- (void)setSelectedToShowCopyMenu:(BOOL)isSelected
{
    selectedToShowCopyMenu = isSelected;
    [self setNeedsDisplay];
}

#pragma mark - Drawing
- (CGRect)bubbleFrame
{
    CGRect rtFrame;
    if(self.mediaType == JSBubbleMediaTypeText){
        CGSize bubbleSize = [JSBubbleView bubbleSizeForText:self.text];
        rtFrame = CGRectMake(floorf(self.type == JSBubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                          floorf(kMarginTop),
                          floorf(bubbleSize.width),
                          floorf(bubbleSize.height));
    }else if (self.mediaType == JSBubbleMediaTypeImage){
        CGSize bubbleSize = [JSBubbleView imageSizeForImage:(UIImage *)self.data];
        rtFrame = CGRectMake(floorf(self.type == JSBubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 10.0f),
                          floorf(kMarginTop),
                          floorf(bubbleSize.width),
                          floorf(bubbleSize.height));
    }else if (self.mediaType == JSBubbleMediaTypeSpeech){
        CGSize bubbleSize = CGSizeMake(kSpeakerBubbleWidth, kSpeakerBubbleHeight); //[JSBubbleView bubbleSizeForText:self.text];
        rtFrame = CGRectMake(floorf(self.type == JSBubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                          floorf(kMarginTop),
                          floorf(bubbleSize.width),
                          floorf(bubbleSize.height));
    }else{
        NSLog(@"act对象消息");
        return CGRectMake(0, 0, 0, 0);
    }
    
    if (self.type == JSBubbleMessageTypeIncoming)
        rtFrame.origin.y += kSenderTextHeight;
    return rtFrame;
    
}

- (UIImage *)bubbleImage
{
    return [JSBubbleView bubbleImageForType:self.type style:self.style];
}

- (UIImage *)bubbleImageHighlighted
{
    switch (self.style) {
        case JSBubbleMessageStyleDefault:
        case JSBubbleMessageStyleDefaultGreen:
            return (self.type == JSBubbleMessageTypeIncoming) ? [UIImage bubbleDefaultIncomingSelected] : [UIImage bubbleDefaultOutgoingSelected];
            
        case JSBubbleMessageStyleSquare:
            return (self.type == JSBubbleMessageTypeIncoming) ? [UIImage bubbleSquareIncomingSelected] : [UIImage bubbleSquareOutgoingSelected];
        
      case JSBubbleMessageStyleFlat:
        return (self.type == JSBubbleMessageTypeIncoming) ? [UIImage bubbleFlatIncomingSelected] : [UIImage bubbleFlatOutgoingSelected];
        
        default:
            return nil;
    }
}

- (void)drawRect:(CGRect)frame
{
    [super drawRect:frame];
    
	UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    
    CGRect bubbleFrame = [self bubbleFrame];
    if (self.mediaType != JSBubbleMediaTypeImage)
        [image drawInRect:bubbleFrame];
    
    
    
    // draw sender name
    if (self.style == JSBubbleMessageStyleFlat && self.type == JSBubbleMessageTypeIncoming)
    {
        CGSize senderTextSize = [JSBubbleView senderTextSizeForText:self.sender];
        CGFloat textX = image.leftCapWidth - 3.0f + (self.type == JSBubbleMessageTypeOutgoing ? bubbleFrame.origin.x : 0.0f) - 10.0;
        
        CGRect textFrame = CGRectMake(textX,
                                      kMarginTop,
                                      senderTextSize.width,
                                      senderTextSize.height);
        
        
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
        {
            UIColor* textColor = [UIColor colorWithRed:176/255.0 green:176/255.0 blue:176/255.0 alpha:1.0];
            
            
            NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            [paragraphStyle setAlignment:NSTextAlignmentLeft];
            [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
            
            NSDictionary* attributes = @{NSFontAttributeName: [JSBubbleView senderFont],
                                         NSParagraphStyleAttributeName: paragraphStyle};
            
            // change the color attribute if we are flat
            if ([JSMessageInputView inputBarStyle] == JSInputBarStyleFlat)
            {
                NSMutableDictionary* dict = [attributes mutableCopy];
                [dict setObject:textColor forKey:NSForegroundColorAttributeName];
                attributes = [NSDictionary dictionaryWithDictionary:dict];
            }
            
            [self.sender drawInRect:textFrame
                   withAttributes:attributes];
        }
        else
        {
            [self.sender drawInRect:textFrame
                         withFont:[JSBubbleView senderFont]
                    lineBreakMode:NSLineBreakByWordWrapping
                        alignment:NSTextAlignmentLeft];
        }
        
    }
	

	if (self.mediaType == JSBubbleMediaTypeText)
	{
        CGSize textSize = [JSBubbleView textSizeForText:self.text];
        
        CGFloat textX = image.leftCapWidth - 3.0f + (self.type == JSBubbleMessageTypeOutgoing ? bubbleFrame.origin.x : 0.0f);
        
        CGRect textFrame = CGRectMake(textX,
                                      kPaddingTop + kMarginTop + (self.type == JSBubbleMessageTypeIncoming?kSenderTextHeight:0),
                                      textSize.width,
                                      textSize.height);
        
		// for flat outgoing messages change the text color to grey or white.  Otherwise leave them black.
		if (self.style == JSBubbleMessageStyleFlat && self.type == JSBubbleMessageTypeOutgoing)
		{
			UIColor* textColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0];
			if (self.selectedToShowCopyMenu)
				textColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0];
			
			if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
			{
				NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
				[paragraphStyle setAlignment:NSTextAlignmentLeft];
				[paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
				
				NSDictionary* attributes = @{NSFontAttributeName: [JSBubbleView font],
											 NSParagraphStyleAttributeName: paragraphStyle};
				
				// change the color attribute if we are flat
				if ([JSMessageInputView inputBarStyle] == JSInputBarStyleFlat)
				{
					NSMutableDictionary* dict = [attributes mutableCopy];
					[dict setObject:textColor forKey:NSForegroundColorAttributeName];
					attributes = [NSDictionary dictionaryWithDictionary:dict];
				}
				
				[self.text drawInRect:textFrame
					   withAttributes:attributes];
			}
			else
			{
				CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), textColor.CGColor);
				[self.text drawInRect:textFrame
							 withFont:[JSBubbleView font]
						lineBreakMode:NSLineBreakByWordWrapping
							alignment:NSTextAlignmentLeft];
				CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor blackColor].CGColor);
			}
		}
		else
		{
			if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
			{
                UIColor* textColor = [UIColor colorWithRed:119/255.0 green:119/255.0 blue:119/255.0 alpha:1.0];
                if (self.selectedToShowCopyMenu)
                    textColor = [UIColor colorWithRed:119/255.0 green:119/255.0 blue:119/255.0 alpha:1.0];
                
                
				NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
				[paragraphStyle setAlignment:NSTextAlignmentLeft];
				[paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
				
				NSDictionary* attributes = @{NSFontAttributeName: [JSBubbleView font],
											 NSParagraphStyleAttributeName: paragraphStyle};
				
                // change the color attribute if we are flat
				if ([JSMessageInputView inputBarStyle] == JSInputBarStyleFlat)
				{
					NSMutableDictionary* dict = [attributes mutableCopy];
					[dict setObject:textColor forKey:NSForegroundColorAttributeName];
					attributes = [NSDictionary dictionaryWithDictionary:dict];
				}
                
				[self.text drawInRect:textFrame
					   withAttributes:attributes];
			}
			else
			{
				[self.text drawInRect:textFrame
							 withFont:[JSBubbleView font]
						lineBreakMode:NSLineBreakByWordWrapping
							alignment:NSTextAlignmentLeft];
			}
		}
	}
	else if(self.mediaType == JSBubbleMediaTypeImage)	// media
	{
        UIImage *recivedImg = (UIImage *)self.data;
        
		if (recivedImg)
		{
            CGSize imageSize = [JSBubbleView imageSizeForImage:recivedImg];
            
            CGFloat imgX = image.leftCapWidth - 3.0f + (self.type == JSBubbleMessageTypeOutgoing ? bubbleFrame.origin.x : 0.0f);
            
            CGRect imageFrame = CGRectMake(imgX - 3.f,
                                          kPaddingTop + kImagePaddingTop + (self.type == JSBubbleMessageTypeIncoming?kSenderTextHeight:0),
                                          imageSize.width - kPaddingTop - kMarginTop,
                                          imageSize.height - kPaddingBottom + 2.f);
            
            
            if (self.style == JSBubbleMessageStyleFlat && self.type == JSBubbleMessageTypeOutgoing)
            {
                UIColor* textColor = [UIColor whiteColor];
                if (self.selectedToShowCopyMenu)
                    textColor = [UIColor lightTextColor];
            }
            [recivedImg drawInRect:imageFrame];
            
		}
	}
    else if(self.mediaType == JSBubbleMediaTypeSpeech)	// audio
	{
        UIImage *recivedImg = [UIImage imageNamed:@"speaker"];
        
		if (recivedImg)
		{
            CGSize imageSize = CGSizeMake(28, 28);
            
            CGFloat imgX = image.leftCapWidth - 3.0f + (self.type == JSBubbleMessageTypeOutgoing ? bubbleFrame.origin.x - 3.0f: 3.0f);
            
            CGRect imageFrame = CGRectMake(imgX - 3.f,
                                           kPaddingTop + (self.type == JSBubbleMessageTypeIncoming?kSenderTextHeight:0) + 3,
                                           imageSize.width,
                                           imageSize.height);
            
            
            if (self.style == JSBubbleMessageStyleFlat && self.type == JSBubbleMessageTypeOutgoing)
            {
                UIColor* textColor = [UIColor whiteColor];
                if (self.selectedToShowCopyMenu)
                    textColor = [UIColor lightTextColor];
            }
            [recivedImg drawInRect:imageFrame];
            
		}
	}
}

#pragma mark - Bubble view
+ (UIImage *)bubbleImageForType:(JSBubbleMessageType)aType style:(JSBubbleMessageStyle)aStyle
{
    switch (aType) {
        case JSBubbleMessageTypeIncoming:
            return [self bubbleImageTypeIncomingWithStyle:aStyle];
            
        case JSBubbleMessageTypeOutgoing:
            return [self bubbleImageTypeOutgoingWithStyle:aStyle];
            
        default:
            return nil;
    }
}

+ (UIImage *)bubbleImageTypeIncomingWithStyle:(JSBubbleMessageStyle)aStyle
{
    switch (aStyle) {
        case JSBubbleMessageStyleDefault:
            return [UIImage bubbleDefaultIncoming];
            
        case JSBubbleMessageStyleSquare:
            return [UIImage bubbleSquareIncoming];
            
        case JSBubbleMessageStyleDefaultGreen:
            return [UIImage bubbleDefaultIncomingGreen];
        
      case JSBubbleMessageStyleFlat:
        return [UIImage bubbleFlatIncoming];
        
        default:
            return nil;
    }
}

+ (UIImage *)bubbleImageTypeOutgoingWithStyle:(JSBubbleMessageStyle)aStyle
{
    switch (aStyle) {
        case JSBubbleMessageStyleDefault:
            return [UIImage bubbleDefaultOutgoing];
            
        case JSBubbleMessageStyleSquare:
            return [UIImage bubbleSquareOutgoing];
            
        case JSBubbleMessageStyleDefaultGreen:
            return [UIImage bubbleDefaultOutgoingGreen];
        
      case JSBubbleMessageStyleFlat:
        return [UIImage bubbleFlatOutgoing];
        
        default:
            return nil;
    }
}

+ (UIFont *)font
{
    return [UIFont systemFontOfSize:16.0f];
}

+ (UIFont *)senderFont
{
    return [UIFont systemFontOfSize:11.0f];
}

+ (CGSize)senderTextSizeForText:(NSString *)txt
{
    CGFloat width = [UIScreen mainScreen].applicationFrame.size.width * 0.75f;
    CGFloat height = MAX([JSBubbleView numberOfLinesForMessage:txt],
                         [txt numberOfLines]) * [JSMessageInputView textViewLineHeight];
    
    return [txt sizeWithFont:[JSBubbleView senderFont]
           constrainedToSize:CGSizeMake(width - kJSAvatarSize, height + kJSAvatarSize)
               lineBreakMode:NSLineBreakByTruncatingTail];
}

+ (CGSize)textSizeForText:(NSString *)txt
{
    CGFloat width = [UIScreen mainScreen].applicationFrame.size.width * 0.75f;
    CGFloat height = MAX([JSBubbleView numberOfLinesForMessage:txt],
                         [txt numberOfLines]) * [JSMessageInputView textViewLineHeight];
    
    return [txt sizeWithFont:[JSBubbleView font]
           constrainedToSize:CGSizeMake(width - kJSAvatarSize, height + kJSAvatarSize)
               lineBreakMode:NSLineBreakByWordWrapping];
}

+ (CGSize)bubbleSizeForText:(NSString *)txt
{
	CGSize textSize = [JSBubbleView textSizeForText:txt];
	return CGSizeMake(textSize.width + kBubblePaddingRight,
                      textSize.height + kPaddingTop + kPaddingBottom);
}

+ (CGSize)bubbleSizeForImage:(UIImage *)image{
    CGSize imageSize = [JSBubbleView imageSizeForImage:image];
	return CGSizeMake(imageSize.width,
                      imageSize.height);
}

+ (CGSize)imageSizeForImage:(UIImage *)image{
    CGFloat width = 100;//[UIScreen mainScreen].applicationFrame.size.width * 0.75f;
    CGFloat height = 100;//130.f;
    
    //return CGSizeMake(width - kJSAvatarSize, height + kJSAvatarSize);
    return CGSizeMake(width, height);

}

+ (CGFloat)cellHeightForText:(NSString *)txt type:(int)type
{
    if (type == JSBubbleMessageTypeIncoming)
        return [JSBubbleView bubbleSizeForText:txt].height + kMarginTop + kSenderTextHeight + kMarginBottom;
    else
        return [JSBubbleView bubbleSizeForText:txt].height + kMarginTop + kMarginBottom;
}

+ (CGFloat)cellHeightForImage:(UIImage *)image type:(int)type
{
    if (type == JSBubbleMessageTypeIncoming)
        return [JSBubbleView bubbleSizeForImage:image].height + kMarginTop + kImagePaddingTop + kSenderTextHeight + kMarginBottom;
    else
        return [JSBubbleView bubbleSizeForImage:image].height + kMarginTop + kImagePaddingTop + kMarginBottom;
}

+ (CGFloat)cellHeightForSpeech:(int)type
{
    if (type == JSBubbleMessageTypeIncoming)
        return kSpeakerBubbleHeight + kMarginTop + kSenderTextHeight + kMarginBottom;
    else
        return kSpeakerBubbleHeight + kMarginTop + kMarginBottom;
}

+ (int)maxCharactersPerLine
{
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 34 : 109;
}

+ (int)numberOfLinesForMessage:(NSString *)txt
{
    return (txt.length / [JSBubbleView maxCharactersPerLine]) + 1;
}

@end