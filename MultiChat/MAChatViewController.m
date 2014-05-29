//
//  MAChatViewController.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAChatViewController.h"
#import "MAAppDelegate.h"
#import "MAMessage.h"
#import "LCVoice.h"

@interface MAChatViewController () <JSMessagesViewDelegate, JSMessagesViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) MAAppDelegate *appDelegate;
@property (strong, nonatomic) IBOutlet UILabel *lblStatus;


@property (strong, nonatomic) NSMutableArray *messageArray;
@property (nonatomic,strong) UIImage *willSendImage;
@property (strong, nonatomic) NSMutableArray *timestamps;

@property(nonatomic,retain) LCVoice * voice;


@end

@implementation MAChatViewController

@synthesize messageArray;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // initilaize voice recorder
    // Init LCVoice
    self.voice = [[LCVoice alloc] init];

    
    // set mpc handler
    self.appDelegate = (MAAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.appDelegate.mpcHandler setDelegate:self];
    
    
    self.delegate = self;
    self.dataSource = self;
    
    self.messageArray = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    
    
    self.lblStatus = [[UILabel alloc] init];
    [self.lblStatus setFrame:CGRectMake(0, 20 + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, 30)];
    
    [self.lblStatus setBackgroundColor:[UIColor whiteColor]];
    
    [self.lblStatus setTextAlignment:NSTextAlignmentCenter];
    
    [self.lblStatus setTextColor:[UIColor lightGrayColor]];
    
    //[self.lblStatus setFont:[UIFont systemFontOfSize:13.0]];
    [self.view addSubview:self.lblStatus];
    //[self.lblStatus setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    
    [self refreshStatus];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.receiverPeerID == nil)
        self.navigationItem.title = @"Everyone";
    else
        self.navigationItem.title = [NSString stringWithFormat:@"%@", [self.receiverPeerID displayName]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:197/255.0 green:0/255.0 blue:27/255.0 alpha:1.0]];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        
        [self.appDelegate.mpcHandler setDelegate:nil];
    }
    [super viewWillDisappear:animated];
}



#pragma mark - MAMPCHandlerDelegate

- (void)peerStateChanged:(NSDictionary *)userInfo
{
    [self performSelectorOnMainThread:@selector(refreshStatus) withObject:nil waitUntilDone:NO];
}

- (void)peerDataReceived:(MAMessage *)message;
{
    [self performSelectorOnMainThread:@selector(dataReceived:) withObject:message waitUntilDone:NO];
}


- (void)dataReceived:(id)data
{
    [JSMessageSoundEffect playMessageReceivedSound];
    
    [self.messageArray addObject:data];
    
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

#pragma mark - refresh status

- (void)refreshStatus
{
    NSUInteger nCount = [self.appDelegate.mpcHandler numberOfConnectedPeers];
    if (nCount == 0)
    {
        self.lblStatus.text = @"You are the only one here";
    }
    else
    {
        self.lblStatus.text = [NSString stringWithFormat:@"%d people chatting", (int)nCount + 1];
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messageArray.count;
}

#pragma mark - Messages view delegate
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    
    [JSMessageSoundEffect playMessageSentSound];
    
    MAMessage *message = [self.appDelegate.mpcHandler sendMessageWithText:text];
    [self.messageArray addObject:message];
    
    [self finishSend];
}

- (void)cameraPressed:(id)sender{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.messageType;
    //return (indexPath.row % 2) ? JSBubbleMessageTypeIncoming : JSBubbleMessageTypeOutgoing;
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.messageStyle;
    //return JSBubbleMessageStyleFlat;
}

- (JSBubbleMediaType)messageMediaTypeForRowAtIndexPath:(NSIndexPath *)indexPath{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.mediaType;
    
//    if([[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Text"]){
//        return JSBubbleMediaTypeText;
//    }else if ([[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"]){
//        return JSBubbleMediaTypeImage;
//    }
    
//    return -1;
}

- (UIButton *)sendButton
{
    return [UIButton defaultSendButton];
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    /*
     JSMessagesViewTimestampPolicyAll = 0,
     JSMessagesViewTimestampPolicyAlternating,
     JSMessagesViewTimestampPolicyEveryThree,
     JSMessagesViewTimestampPolicyEveryFive,
     JSMessagesViewTimestampPolicyCustom
     */
    return JSMessagesViewTimestampPolicyEveryThree;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    /*
     JSMessagesViewAvatarPolicyIncomingOnly = 0,
     JSMessagesViewAvatarPolicyBoth,
     JSMessagesViewAvatarPolicyNone
     */
    //return JSMessagesViewAvatarPolicyBoth;
    return JSMessagesViewAvatarPolicyNone;
}

- (JSAvatarStyle)avatarStyle
{
    /*
     JSAvatarStyleCircle = 0,
     JSAvatarStyleSquare,
     JSAvatarStyleNone
     */
    return JSAvatarStyleCircle;
}

- (JSInputBarStyle)inputBarStyle
{
    /*
     JSInputBarStyleDefault,
     JSInputBarStyleFlat
     
     */
    return JSInputBarStyleFlat;
}

//  Optional delegate method
//  Required if using `JSMessagesViewTimestampPolicyCustom`
//
//  - (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
//

#pragma mark - Messages view data source
- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.text;
    
//    if([[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Text"]){
//        return [[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Text"];
//    }
//    return nil;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.timestamp;
//    return [self.timestamps objectAtIndex:indexPath.row];
}

- (NSString *)senderForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.sender;
}

- (UIImage *)avatarImageForIncomingMessage
{
    return [UIImage imageNamed:@"demo-avatar-jobs"];
}

- (UIImage *)avatarImageForOutgoingMessage
{
    return [UIImage imageNamed:@"demo-avatar-woz"];
}

- (id)dataForRowAtIndexPath:(NSIndexPath *)indexPath{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.image;
    
//    if([[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"]){
//        return [[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"];
//    }
//    return nil;
    
}

// recorded sound
- (id)voiceForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.speech;
}

#pragma UIImagePicker Delegate

#pragma mark - Image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    
    
    UIImage * image = [info objectForKey:UIImagePickerControllerEditedImage];
    UIImage * smallImg;
    if (image.size.width > 800) {
        smallImg = [self imageResize:image andResizeTo:CGSizeMake(480, 320)];
    } else {
        smallImg = image;
    }
    
    /*
    self.willSendImage = [info objectForKey:UIImagePickerControllerEditedImage];
    //[self.messageArray addObject:[NSDictionary dictionaryWithObject:self.willSendImage forKey:@"Image"]];
    //[self.timestamps addObject:[NSDate date]];
    JSMessage *message = [[JSMessage alloc] init];
    message.image = self.willSendImage;
    message.sender = [self.appDelegate.mpcHandler.peerID displayName];
    message.messageType = JSBubbleMessageTypeOutgoing;
    message.mediaType = JSBubbleMediaTypeImage;
    message.messageStyle = JSBubbleMessageStyleFlat;
    message.timestamp = [NSDate date];
    
    
    
    [self.messageArray addObject:message];
    
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
    
	*/
    
    
    [JSMessageSoundEffect playMessageSentSound];
    
    MAMessage *message = [self.appDelegate.mpcHandler sendMessageWithImage:smallImg];
    [self.messageArray addObject:message];
    
    [self finishSend];
    
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
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

//////////////////////////////////////////////////////////////
#pragma mark - Voice Record
- (void) recordStart:(id)sender
{
    NSString * name = [NSString stringWithFormat:@"%f.caf", [[NSDate date] timeIntervalSince1970]];
    
    [self.voice startRecordWithPath:[NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), name]];
    
}

- (void) recordEnd:(id)sender
{
    [self.voice stopRecordWithCompletionBlock:^{
        
        if (self.voice.recordTime > 0.0f) {
            /*
             UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"\nrecord finish ! \npath:%@ \nduration:%f",self.voice.recordPath,self.voice.recordTime] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
             [alert show];*/
            
            [JSMessageSoundEffect playMessageSentSound];
            
            
            // send recorded data to peer
            if([[NSFileManager defaultManager] fileExistsAtPath:self.voice.recordPath])
            {
                NSData *voicedata = [[NSFileManager defaultManager] contentsAtPath:self.voice.recordPath];
                
                MAMessage *message = [self.appDelegate.mpcHandler sendMessageWithSpeech:voicedata];
                [self.messageArray addObject:message];
                
                [self finishSend];
            }
            else
            {
                NSLog(@"File not exits");
            }
            
            
            [self.tableView reloadData];
            [self scrollToBottomAnimated:YES];
        }
        
    }];
}

- (void) recordCancel:(id)sender
{
    [self.voice cancelled];
    
    //    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:@"取消了" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
    //    [alert show];
}


@end
