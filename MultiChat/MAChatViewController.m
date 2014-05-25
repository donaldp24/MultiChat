//
//  MAChatViewController.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAChatViewController.h"
#import "MAAppDelegate.h"
#import "JSMessage.h"


@interface MAChatViewController () <JSMessagesViewDelegate, JSMessagesViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) MAAppDelegate *appDelegate;
@property (strong, nonatomic) IBOutlet UILabel *lblStatus;


@property (strong, nonatomic) NSMutableArray *messageArray;
@property (nonatomic,strong) UIImage *willSendImage;
@property (strong, nonatomic) NSMutableArray *timestamps;

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
    
    // title
    self.navigationItem.hidesBackButton = YES;
    
    
    // settings button
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsicon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)];
    self.navigationItem.leftBarButtonItem = settingsButton;
    
    
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
    
    
    [self refreshStatus:[NSNumber numberWithInteger:[self.appDelegate.mpcHandler.session connectedPeers].count]];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"MultiChat";
    
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

#pragma mark - MAMPCHandlerDelegate

- (void)peerStateChanged:(NSDictionary *)userInfo
{
    int nCount = (int)[[self.appDelegate.mpcHandler.session connectedPeers] count];
    [self performSelectorOnMainThread:@selector(refreshStatus:) withObject:[NSNumber numberWithInt:nCount] waitUntilDone:NO];
}

- (void)peerDataReceived:(NSDictionary *)dataInfo
{
    MCPeerID *peerID = [dataInfo objectForKey:@"peerID"];
    NSData *data = [dataInfo objectForKey:@"data"];
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    JSMessage *message = [[JSMessage alloc] init];
    message.sender = [peerID displayName];
    message.text = text;
    message.mediaType = JSBubbleMediaTypeText;
    message.messageStyle = JSBubbleMessageStyleFlat;
    message.messageType = JSBubbleMessageTypeIncoming;
    message.timestamp = [NSDate date];
    
    [self performSelectorOnMainThread:@selector(dataReceived:) withObject:message waitUntilDone:NO];
    //[self dataReceived:dataInfo];
}


- (void)dataReceived:(id)data
{
    [JSMessageSoundEffect playMessageReceivedSound];
    
    [self.messageArray addObject:data];
    
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

#pragma mark - refresh status

- (void)refreshStatus:(NSNumber *)count
{
    int nCount = [count intValue];
    if (nCount == 0)
    {
        self.lblStatus.text = @"You are the only one here";
    }
    else
    {
        self.lblStatus.text = [NSString stringWithFormat:@"%d people chatting", nCount + 1];
    }
}


- (IBAction)settingsPressed:(id)sender
{
    [self.appDelegate.mpcHandler stop];
    [self.navigationController popViewControllerAnimated:YES];
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
    
//    [self.messageArray addObject:[NSDictionary dictionaryWithObject:text forKey:@"Text"]];
//    [self.timestamps addObject:[NSDate date]];
//    if((self.messageArray.count - 1) % 2)
//        [JSMessageSoundEffect playMessageSentSound];
//    else
//        [JSMessageSoundEffect playMessageReceivedSound];
    
    JSMessage *message = [[JSMessage alloc] init];
    message.text = text;
    message.sender = [self.appDelegate.mpcHandler.peerID displayName];
    message.messageType = JSBubbleMessageTypeOutgoing;
    message.mediaType = JSBubbleMediaTypeText;
    message.messageStyle = JSBubbleMessageStyleFlat;
    message.timestamp = [NSDate date];
    
    [self.messageArray addObject:message];
    
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    if (![self.appDelegate.mpcHandler.session sendData:data
                                               toPeers:self.appDelegate.mpcHandler.session.connectedPeers
                                              withMode:MCSessionSendDataReliable
                                                 error:&error]) {
        NSLog(@"[Error] %@", error);
    }
    
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
    JSMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.messageType;
    //return (indexPath.row % 2) ? JSBubbleMessageTypeIncoming : JSBubbleMessageTypeOutgoing;
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.messageStyle;
    //return JSBubbleMessageStyleFlat;
}

- (JSBubbleMediaType)messageMediaTypeForRowAtIndexPath:(NSIndexPath *)indexPath{
    JSMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.mediaType;
    
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
    JSMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.text;
    
//    if([[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Text"]){
//        return [[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Text"];
//    }
//    return nil;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.timestamp;
//    return [self.timestamps objectAtIndex:indexPath.row];
}

- (NSString *)senderForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.sender;
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
    JSMessage *message = [self.messageArray objectAtIndex:indexPath.row];
    return message.image;
    
//    if([[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"]){
//        return [[self.messageArray objectAtIndex:indexPath.row] objectForKey:@"Image"];
//    }
//    return nil;
    
}

#pragma UIImagePicker Delegate

#pragma mark - Image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    
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
    
	
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}


@end
