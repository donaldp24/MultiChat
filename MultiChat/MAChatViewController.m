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
#import "MAGlobalData.h"
#import "MAUIManager.h"
#import "LCVoiceHud.h"

@interface MAChatViewController () <JSMessagesViewDelegate, JSMessagesViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LCVoiceHudDelegate>

@property (strong, nonatomic) MAAppDelegate *appDelegate;
@property (strong, nonatomic) IBOutlet UILabel *lblStatus;


@property (strong, nonatomic) NSMutableArray *messageArray;
@property (nonatomic,strong) UIImage *willSendImage;
@property (strong, nonatomic) NSMutableArray *timestamps;

@property(nonatomic,strong) LCVoice * voice;


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
    [self.voice setDelegate:self];
    
    
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
    
    NSMutableArray *array = nil;
    [self.appDelegate.mpcHandler getMessages:self.receiverPeerUid array:&array isReading:YES];
    self.messageArray = [[NSMutableArray alloc] initWithArray:array];
    
    [self refreshStatus];
    
    
    // title
    self.navigationItem.hidesBackButton = YES;
    
    // back button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(backPressed:) forControlEvents:UIControlEventTouchUpInside]; //adding action
    [button setBackgroundImage:[UIImage imageNamed:@"backicon"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"backicon_hover"] forState:UIControlStateHighlighted];
    button.frame = CGRectMake(0 ,0,31,31);
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.receiverPeerUid == nil || [self.receiverPeerUid isEqualToString:@""])
        self.navigationItem.title = @"Everyone";
    else
    {
        NSMutableArray *array = nil;
        [self.appDelegate.mpcHandler getPeers:&array];
        
        NSString *name = @"Not Connected";
        for (NSDictionary *dic in array)
        {
            
            if (dic != nil)
            {
                NSArray *values = [dic allValues];
                NSArray *keys = [dic allKeys];
                if (keys != nil && keys.count != 0)
                {
                    if ([self.receiverPeerUid isEqualToString:[keys objectAtIndex:0]])
                    {
                        if (values != nil && values.count != 0)
                            name = [values objectAtIndex:0];
                        break;
                    }
                }
            }
        }
        self.navigationItem.title = [NSString stringWithFormat:@"%@", name];
    }

    
    MAUIManager *uimanager = [MAUIManager sharedUIManager];
    
    self.navigationController.navigationBarHidden = NO;
    
    
    self.navigationController.navigationBar.barStyle = [uimanager navbarStyle];
    
    self.navigationController.navigationBar.tintColor = [uimanager navbarTintColor];
    self.navigationController.navigationBar.titleTextAttributes = [uimanager navbarTitleTextAttributes];
    
    self.navigationController.navigationBar.barTintColor = [uimanager navbarBarTintColor];
    
    // add bottom border
    CALayer *border = [CALayer layer];
    border.borderColor = [uimanager navbarBorderColor].CGColor;
    border.borderWidth = 1;
    CALayer *layer = self.navigationController.navigationBar.layer;
    border.frame = CGRectMake(0, layer.bounds.size.height, layer.bounds.size.width, 1);
    [layer addSublayer:border];
    
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

- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - MAMPCHandlerDelegate

- (void)peerStateChanged:(NSDictionary *)userInfo
{
    //[self performSelectorOnMainThread:@selector(refreshStatus) withObject:nil waitUntilDone:NO];
    [self refreshStatus];
}

- (void)peerDataReceived:(MAMessage *)message;
{
    //[self performSelectorOnMainThread:@selector(dataReceived:) withObject:message waitUntilDone:NO];
    [self dataReceived:message];
}


- (void)dataReceived:(id)data
{
    MAMessage *message = (MAMessage*)data;
    if (message.type != MAMessageTypeMessage)
        return;
    
    [JSMessageSoundEffect playMessageReceivedSound];
    
    
    BOOL isMine = NO;
    
    // if send for everyone
    if ([self.receiverPeerUid isEqualToString:kUidForEveryone])
    {
        if ([message.receiverUid isEqualToString:kUidForEveryone])
            isMine = YES;
    }
    else
    {
        // if send from target, and send for me
        if ([message.senderUid isEqualToString:self.receiverPeerUid] &&
            [message.receiverUid isEqualToString:[MAGlobalData sharedData].uid])
        {
            isMine = YES;
        }
    }
    
    if (isMine)
    {
        message.isRead = YES;
        
        [self.messageArray addObject:data];
        
        [self.tableView reloadData];
        [self scrollToBottomAnimated:YES];
    }
}

#pragma mark - refresh status

- (void)refreshStatus
{
    NSMutableArray *array = nil;
    [self.appDelegate.mpcHandler getPeers:&array];
    
    NSUInteger nCount = [array count];
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
    
    MAMessage *message = [self.appDelegate.mpcHandler sendMessageWithText:text recevierUid:self.receiverPeerUid];
    [self.messageArray addObject:message];
    
    [self finishSend];
}

- (void)cameraPressed:(id)sender{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Take Photo" otherButtonTitles:@"Choose Existing", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0 || buttonIndex == 1)
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        if (buttonIndex == 0)
        {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        else if (buttonIndex == 1)
        {
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [self presentViewController:picker animated:YES completion:nil];
    }
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
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"" forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"sendbutton"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"sendbutton_hover"] forState:UIControlStateHighlighted];
    return button;
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
    return JSMessagesViewAvatarPolicyBoth;
    //return JSMessagesViewAvatarPolicyNone;
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

- (UIImage *)avatarImageForIncomingMessageAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.messageArray.count)
        return [[MAUIManager sharedUIManager] getDefaultAvatar];
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    UIImage *img = [self.appDelegate.mpcHandler getAvatar:message.senderUid];
    if (img == nil)
        img = [[MAUIManager sharedUIManager] getDefaultAvatar];
    return img;
}

- (UIImage *)avatarImageForOutgoingMessageAtIndexPath:(NSIndexPath *)indexPath
{
    return [MAGlobalData sharedData].avatarImage;
}

- (id)imageForRowAtIndexPath:(NSIndexPath *)indexPath{
    MAMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.jsmessage.image;
    
//    if([[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"]){
//        return [[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"];
//    }
//    return nil;
    
}

// recorded sound
- (id)speechForRowAtIndexPath:(NSIndexPath *)indexPath
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
    //if (image.size.width > 800) {
        smallImg = [self imageResize:image andResizeTo:CGSizeMake(50, 50)];
    //} else {
    //    smallImg = image;
    //}
    
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
    
    MAMessage *message = [self.appDelegate.mpcHandler sendMessageWithImage:smallImg receiverUid:self.receiverPeerUid];
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
#pragma mark - Stop Button Tap
- (void) tapStopButton
{
    [self recordEnd:nil];
}

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
            
            [JSMessageSoundEffect playMessageSentSound];
            
            
            // send recorded data to peer
            if([[NSFileManager defaultManager] fileExistsAtPath:self.voice.recordPath])
            {
                NSData *voicedata = [[NSFileManager defaultManager] contentsAtPath:self.voice.recordPath];
                
                MAMessage *message = [self.appDelegate.mpcHandler sendMessageWithSpeech:voicedata receiverUid:self.receiverPeerUid];
                [self.messageArray addObject:message];
                
                //[self finishSend];
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
