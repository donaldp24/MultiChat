//
//  MAViewController.m
//  MultiChat
//
//  Created by Donald Pae on 5/21/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAViewController.h"
#import "MAAppDelegate.h"
#import "MAGlobalData.h"

static CGFloat textFieldsLowerPos = 237.0;



@interface MAViewController () {
    UIResponder *currentResponder;
}

@property (strong, nonatomic) MAAppDelegate *appDelegate;

@property (weak, nonatomic) IBOutlet UIImageView *imgBg;
@property (strong, nonatomic) UIView *loginGroup;

@property (strong, nonatomic) UITextField *usernameTextField;
@property (strong, nonatomic) UIButton *submitButton;

@property (strong, nonatomic) MASConstraint *loginGroupTopConstraint;

@end

@implementation MAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // title
    self.navigationItem.hidesBackButton = YES;
    
    [self initializeTextFields];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
    [self.view addGestureRecognizer:tap];
    
    self.appDelegate = (MAAppDelegate *)[[UIApplication sharedApplication] delegate];
    

    if ([[MAGlobalData sharedData] isSetName])
    {
        [self.appDelegate.mpcHandler start:[[MAGlobalData sharedData] getName]];
        [self performSegueWithIdentifier:@"gointo" sender:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //self.navigationController.navigationBarHidden = YES;
    
    self.navigationItem.title = @"MultiChat";
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:197/255.0 green:0/255.0 blue:27/255.0 alpha:1.0]];
}

- (void) initializeTextFields {
    
    _usernameTextField = [self loginTextFieldForIcon:@"login-username" placeholder:@"NAME"];
    _usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _usernameTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    _usernameTextField.text = [[MAGlobalData sharedData] getName];
    
    _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _submitButton.backgroundColor = [UIColor colorWithRed:221/255.0 green:35/255.0 blue:45/255.0 alpha:1.0];
    
    _submitButton.tintColor = [UIColor whiteColor];
    _submitButton.layer.cornerRadius = 5.0;
    [_submitButton setTitle:@"Enter" forState:UIControlStateNormal];
    [_submitButton addTarget:self action:@selector(onLogin:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _loginGroup = [UIView new];
    _loginGroup.backgroundColor = [UIColor clearColor];
    

    [_loginGroup addSubview:_usernameTextField];

    [_loginGroup addSubview:_submitButton];

    [self.view addSubview:_loginGroup];
    
    
    [_usernameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@42.0);
        make.width.equalTo(@260.0);
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
    }];
    
    
    [_submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(_usernameTextField);
        make.left.equalTo(_usernameTextField);
        make.top.equalTo(_usernameTextField.mas_bottom).with.offset(15.0);
        make.bottom.equalTo(@0);
    }];
    
    [_loginGroup mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(@0);
        _loginGroupTopConstraint = make.top.equalTo(@(textFieldsLowerPos));
    }];
    
    
}

- (IBAction)onLogin:(id)sender {
    if (currentResponder) {
        [currentResponder resignFirstResponder];
    }
    
    [[MAGlobalData sharedData] setName:[_usernameTextField text]];
    
    [self.appDelegate.mpcHandler start:[_usernameTextField text]];
    
    [self performSegueWithIdentifier:@"gointo" sender:self];
}

- (UITextField *)loginTextFieldForIcon:(NSString *)filename placeholder:(NSString *)placeholder {
    
    //Gray background view
    UIView *grayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 45.0, 42.0)];
    grayView.backgroundColor = [UIColor colorWithRed:0.67 green:0.70 blue:0.77 alpha:1.0];
    
    //Path & Mask so we only make rounded corners on right side
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:grayView.bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerBottomLeft)
                                                         cornerRadii:CGSizeMake(5.0, 5.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = grayView.bounds;
    maskLayer.path = maskPath.CGPath;
    grayView.layer.mask = maskLayer;
    
    //Add icon image
    UIImageView *passwordIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:filename]];
    [grayView addSubview:passwordIcon];
    
    [passwordIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(@0);
        make.centerY.equalTo(@0);
    }];
    
    //Finally make the textField
    UITextField *textField = [[UITextField alloc] init];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.font = [UIFont systemFontOfSize:14.0];
    textField.textColor = [UIColor blackColor];
    textField.backgroundColor = [UIColor whiteColor];
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.leftView = grayView;
    textField.placeholder = placeholder;
    textField.delegate = self;
    
    return textField;
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
    /*
     if (textField == _usernameTextField && preFilledUsername) {
     preFilledUsername = NO;
     textField.text = @"";
     }
     */
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    currentResponder = nil;
}


- (void) reset
{
    /*
     if(self.currentAccount && loginState == LoginStateLoggingIn){
     _usernameTextField.text = self.currentAccount.user.name;
     preFilledUsername = YES;
     } else {
     _usernameTextField.text = @"";
     preFilledUsername = NO;
     }
     */
}

#pragma mark Keyboard Methods

- (void)keyboardShowing:(NSNotification *)note
{
    NSNumber *duration = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    //CGRect endFrame = ((NSValue *)note.userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;
    _loginGroupTopConstraint.with.offset(80.0);
    
    
    [UIView animateWithDuration:duration.floatValue animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardHiding:(NSNotification *)note
{
    NSNumber *duration = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    
    _loginGroupTopConstraint.with.offset(textFieldsLowerPos);
    
    [UIView animateWithDuration:duration.floatValue animations:^{
        [self.view layoutIfNeeded];
    }];
    
}

@end
