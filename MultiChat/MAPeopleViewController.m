//
//  MAPeopleViewController.m
//  MultiChat
//
//  Created by Donald Pae on 5/25/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "MAPeopleViewController.h"
#import "MAUIManager.h"
#import "MAAppDelegate.h"
#import "MAGlobalData.h"
#import "MAChatViewController.h"
#import "SVProgressHUD.h"

@interface MAPeopleViewController () {
    NSString *prevName;
    NSTimer *_timer;
    UIBarButtonItem *_refreshButton;
    int _degree;
}

@property (nonatomic, strong) IBOutlet UITableView *tblPeople;
@property (nonatomic, strong) NSMutableArray *peopleArray;
@property (strong, nonatomic) MAAppDelegate *appDelegate;

@end

@implementation MAPeopleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.peopleArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.appDelegate = (MAAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    prevName = [NSString stringWithFormat:@"%@", [MAGlobalData sharedData].uid];
    
    // This will remove extra separators from tableview
    //self.tblPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tblPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 20, 20, 20)];
    UILabel *indicateTextView = [[UILabel alloc] initWithFrame:CGRectMake(43, 16, 100, 25)];
    [indicateTextView setTextAlignment:NSTextAlignmentCenter];
    [indicateTextView setTextAlignment:NSTextAlignmentJustified];
    
    [indicateTextView setText:@"researching"];
    
    [self.tblPeople.tableFooterView addSubview:indicator];
    [self.tblPeople.tableFooterView addSubview:indicateTextView];
    [indicator setColor:[UIColor blackColor]];
    [indicator startAnimating];
    
    // title
    self.navigationItem.hidesBackButton = YES;
    
    
    // settings button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(settingsPressed:) forControlEvents:UIControlEventTouchUpInside]; //adding action
    [button setBackgroundImage:[UIImage imageNamed:@"settingsicon"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"settingsicon_hover"] forState:UIControlStateHighlighted];
    button.frame = CGRectMake(0 ,0,31,31);
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithCustomView:button];
   
    self.navigationItem.leftBarButtonItem = settingsButton;
    
    // refresh button
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(refreshPressed:) forControlEvents:UIControlEventTouchUpInside]; //adding action
    [button setBackgroundImage:[UIImage imageNamed:@"refreshicon"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"refreshicon_hover"] forState:UIControlStateHighlighted];
    
    button.frame = CGRectMake(0 ,0,31,31);
    _refreshButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    self.navigationItem.rightBarButtonItem = _refreshButton;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    MAUIManager *uimanager = [MAUIManager sharedUIManager];
    
    self.navigationController.navigationBarHidden = NO;
    
    self.navigationItem.title = [uimanager peopleTitle];
    
    self.navigationController.navigationBar.barStyle = [uimanager navbarStyle];
    
    self.navigationController.navigationBar.tintColor = [uimanager navbarTintColor];
    self.navigationController.navigationBar.titleTextAttributes = [uimanager navbarTitleTextAttributes];
    
    self.navigationController.navigationBar.barTintColor = [uimanager navbarBarTintColor];
    
    CALayer *border = [CALayer layer];
    border.borderColor = [uimanager navbarBorderColor].CGColor;
    border.borderWidth = 1;
    CALayer *layer = self.navigationController.navigationBar.layer;
    
    border.frame = CGRectMake(0, layer.frame.size.height, layer.bounds.size.width, 1);
    [layer addSublayer:border];
    
    
    self.appDelegate.mpcHandler.delegate = self;
    
    
    if ([self.appDelegate.mpcHandler isStarted])
    {
        /*
        if (![[MAGlobalData sharedData].uid isEqualToString:prevName])
        {
            [self.appDelegate.mpcHandler stop];
            [self.appDelegate.mpcHandler start:[MAGlobalData sharedData].uid];
            prevName = [NSString stringWithFormat:@"%@", [MAGlobalData sharedData].uid];
        }
         */
    }
    else
        [self.appDelegate.mpcHandler start:[MAGlobalData sharedData].uid];
    
    NSMutableArray *array = nil;
    [self.appDelegate.mpcHandler getPeers:&array];
    self.peopleArray = [[NSMutableArray alloc] initWithArray:array];
    
    [self.tblPeople reloadData];
    
    _degree = 0;
    //_timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(timerProc:) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_timer invalidate];
}

- (void)settingsPressed:(id)sender
{
    [self performSegueWithIdentifier:@"gosettings" sender:self];
}

- (void)refreshPressed:(id)sender
{
    [self.appDelegate.mpcHandler restart];
    
    [self.peopleArray removeAllObjects];
    
    [self.tblPeople reloadData];
    
    [SVProgressHUD showWithStatus:@"Refreshing..." maskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD dismissAfterDelay:3];
}

#pragma mark MAMPCHandler Delegate
- (void)peerStateChanged:(NSDictionary *)userInfo
{
    NSDictionary *dic = [[NSDictionary alloc] initWithDictionary:userInfo];
    [self performSelectorOnMainThread:@selector(peerStateChangedProc:) withObject:dic waitUntilDone:NO];
}

- (void)peerDataReceived:(MAMessage *)message
{
    [self.tblPeople reloadData];
}

- (void)peerStateChangedProc:(NSDictionary *)userInfo
{
    [self.peopleArray removeAllObjects];
    self.peopleArray = nil;
    
    NSMutableArray *peers;
    [self.appDelegate.mpcHandler getPeers:&peers];
    self.peopleArray = [[NSMutableArray alloc] initWithArray:peers];
    
    [self.tblPeople reloadData];
}

#pragma mark UITableView Data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.peopleArray count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (cell == nil)
        return cell;
    
    NSString *receiverUid = @"";
    
    UIImageView *imgAvatar = (UIImageView *)[cell viewWithTag:101];
    UILabel *lblName = (UILabel *)[cell viewWithTag:102];
    UILabel *lblCount = (UILabel *)[cell viewWithTag:103];
    UIView *viewBg = (UIView *)[cell viewWithTag:99];
    
    imgAvatar.layer.cornerRadius = imgAvatar.frame.size.height / 2;
    imgAvatar.layer.masksToBounds = YES;
    imgAvatar.layer.borderWidth = 0;
    //imgAvatar.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    //imgAvatar.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    
    if (indexPath.row == 0)
    {
        imgAvatar.image = [[MAUIManager sharedUIManager] getPeopleAvatar];
        lblName.text = @"Everyone";
        
        int count = [self.appDelegate.mpcHandler getUnreadMessageCount:@""];
        if (count != 0)
            lblCount.text = [NSString stringWithFormat:@"%d", count];
        else
            lblCount.text = @"";
    }
    else
    {
        UIImage *avatar = nil;
        if (indexPath.row <= [self.peopleArray count])
        {
            NSDictionary *dic = [self.peopleArray objectAtIndex:indexPath.row - 1];
            NSString *name = @"";
            int count = 0;
            if (dic != nil)
            {
                NSArray *values = [dic allValues];
                if (values != nil && values.count != 0)
                    name = [values objectAtIndex:0];
                NSArray *keys = [dic allKeys];
                if (keys != nil && keys.count != 0)
                {
                    receiverUid = [keys objectAtIndex:0];
                    count = [self.appDelegate.mpcHandler getUnreadMessageCount:receiverUid];
                    avatar = [self.appDelegate.mpcHandler getAvatar:receiverUid];
                }
            }
            
            if (avatar == nil)
                avatar = [[MAUIManager sharedUIManager] getDefaultAvatar];
            
            imgAvatar.image = avatar;
            lblName.text = [NSString stringWithFormat:@"%@", name];
            
            if (count != 0)
                lblCount.text = [NSString stringWithFormat:@"%d", count];
            else
                lblCount.text = @"";
        }
    }
    
    // background
    if (viewBg) {
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = viewBg.frame;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1.0] CGColor], nil];
        [viewBg.layer insertSublayer:gradient above:0];
        viewBg.tag = 199;
        
    }
    
    
    return cell;
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.appDelegate.mpcHandler setDelegate:nil];
    
    //[self performSegueWithIdentifier:@"gochat" sender:self];
    MAChatViewController *chatview = [self.storyboard instantiateViewControllerWithIdentifier:@"MAChatViewController"];
    
    NSString *uid = @"";
    if (indexPath.row == 0)
    {
        //
    }
    else
    {
        if (indexPath.row <= [self.peopleArray count])
        {
            NSDictionary *dic = [self.peopleArray objectAtIndex:indexPath.row - 1];
            
            if (dic != nil)
            {
                NSArray *keys = [dic allKeys];
                if (keys != nil && keys.count != 0)
                    uid = [keys objectAtIndex:0];
            }
        }
    }
    chatview.receiverPeerUid = uid;
    
    [self.navigationController pushViewController:chatview animated:YES];
}

- (void)timerProc:(NSTimer *)timer
{
    UIImage *img = [UIImage imageNamed:@"refreshicon"];
    img = rotate(img, _degree);
    _degree += 30;
    if (_degree > 360)
        _degree = _degree - 360;
    [_refreshButton setImage:img];
}

static inline double radians (double degrees) {return degrees * M_PI/180;}

UIImage* rotate(UIImage* src, int degree)
{
    UIGraphicsBeginImageContext(src.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
  /*

    CGContextRotateCTM (context, radians(degree));

    
    [src drawAtPoint:CGPointMake(0, 0)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
   */
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(context, src.size.width/2, src.size.height/2);
    
    //Rotate the image context
    CGContextRotateCTM(context, radians(degree));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(-src.size.width / 2, -src.size.height / 2,     src.size.width, src.size.height), src.CGImage);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
