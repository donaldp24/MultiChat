//
//  MAViewController.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MASettingsViewController.h"
#import "MAAppDelegate.h"
#import "MAGlobalData.h"
#import "MAUIManager.h"

static CGFloat textFieldsLowerPos = 237.0;



@interface MASettingsViewController () {
    UIResponder *currentResponder;
}

@property (strong, nonatomic) MAAppDelegate *appDelegate;

@property (weak, nonatomic) IBOutlet UIImageView *imgBg;
@property (strong, nonatomic) IBOutlet UIButton *avatar;
@property (strong, nonatomic) IBOutlet UIImageView *imgAvatar;

@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;

@property (strong, nonatomic) IBOutlet UIImageView *imgBg1;
@property (strong, nonatomic) IBOutlet UIImageView *imgBg2;

@end

@implementation MASettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
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
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
    [self.view addGestureRecognizer:tap];
    
    
    
    self.appDelegate = (MAAppDelegate *)[[UIApplication sharedApplication] delegate];

    
    self.imgAvatar.layer.cornerRadius = self.imgAvatar.frame.size.height / 2;
    self.imgAvatar.layer.masksToBounds = YES;
    self.imgAvatar.layer.borderWidth = 0;
    
    NSString *filePath = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    filePath = [cacheDirectory stringByAppendingPathComponent:[MAGlobalData sharedData].avatarImageFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath] == NO)
        filePath = nil;
    
    if (filePath != nil)
        self.imgAvatar.image = [MAGlobalData sharedData].avatarImage;
    else
        self.imgAvatar.image = [UIImage imageNamed:@"login_avatar"];
    
    
    //self.usernameTextField.layer.cornerRadius = 3.0;
    //self.usernameTextField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    //self.usernameTextField.layer.borderWidth = 1.0;
    self.usernameTextField.text = [[MAGlobalData sharedData] userName];
    
    //UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    //[self.usernameTextField setLeftViewMode:UITextFieldViewModeAlways];
    //[self.usernameTextField setLeftView:spacerView];


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    MAUIManager *uimanager = [MAUIManager sharedUIManager];
    
    self.navigationController.navigationBarHidden = NO;
    
    self.navigationItem.title = [uimanager settingsTitle];
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShowing:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHiding:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
    
}
- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [[MAGlobalData sharedData] setUserName:[_usernameTextField text]];
    [self.appDelegate.mpcHandler sendAvatar:[MAGlobalData sharedData].avatarImage receiverUid:kUidForEveryone];
}

- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onAvatar:(id)sender {
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





# pragma mark Gesture selector
- (void)backgroundTap:(UITapGestureRecognizer *)backgroundTap {
    if(currentResponder){
        [currentResponder resignFirstResponder];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentResponder = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    currentResponder = nil;
}


#pragma mark Keyboard Methods

- (void)keyboardShowing:(NSNotification *)note
{
    /*
    NSNumber *duration = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    _loginGroupTopConstraint.with.offset(80.0);
    
    
    [UIView animateWithDuration:duration.floatValue animations:^{
        [self.view layoutIfNeeded];
    }];
     */
}

- (void)keyboardHiding:(NSNotification *)note
{
    /*
    NSNumber *duration = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    
    _loginGroupTopConstraint.with.offset(textFieldsLowerPos);
    
    [UIView animateWithDuration:duration.floatValue animations:^{
        [self.view layoutIfNeeded];
    }];
    */
}

#pragma UIImagePicker Delegate

#pragma mark - Image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    
    
    UIImage * image = [info objectForKey:UIImagePickerControllerEditedImage];
    UIImage * smallImg;
    smallImg = [self imageResize:image andResizeTo:CGSizeMake(100, 100)];
    
    [self.imgAvatar setImage:smallImg];
    [[MAGlobalData sharedData] setAvatarImage:smallImg];
    
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

- (IBAction)onTellFriend:(id)sender
{
    NSString *string = @"Check out Cycro ! Download it now from http://cycro.me/dl";
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[string]
                                      applicationActivities:nil];
    //activityViewController.excludedActivityTypes = @[UIActivityTypePrint, ];
    
    [self.navigationController presentViewController:activityViewController
                                       animated:YES
                                     completion:^{
                                         // ...
                                     }];
}



@end
