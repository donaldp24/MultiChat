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

@interface MAPeopleViewController () {
    NSString *prevName;
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
    
    prevName = [NSString stringWithFormat:@"%@", [MAGlobalData sharedData].userName];
    
    // This will remove extra separators from tableview
    self.tblPeople.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // title
    self.navigationItem.hidesBackButton = YES;
    
    
    // settings button
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsicon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)];
    self.navigationItem.leftBarButtonItem = settingsButton;
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
    
    self.appDelegate.mpcHandler.delegate = self;
    if ([self.appDelegate.mpcHandler isStarted])
    {
        if (![[MAGlobalData sharedData].userName isEqualToString:prevName])
        {
            [self.appDelegate.mpcHandler stop];
            [self.appDelegate.mpcHandler start:[MAGlobalData sharedData].userName];
            prevName = [NSString stringWithFormat:@"%@", [MAGlobalData sharedData].userName];
        }
    }
    else
        [self.appDelegate.mpcHandler start:[MAGlobalData sharedData].userName];
    
    [self.tblPeople reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)settingsPressed:(id)sender
{
    [self performSegueWithIdentifier:@"gosettings" sender:self];
}


#pragma mark MAMPCHandler Delegate
- (void)peerStateChanged:(NSDictionary *)userInfo
{
    NSDictionary *dic = [[NSDictionary alloc] initWithDictionary:userInfo];
    [self performSelectorOnMainThread:@selector(peerStateChangedProc:) withObject:dic waitUntilDone:NO];
}

- (void)peerDataReceived:(MAMessage *)message
{
    //
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    }
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    if (indexPath.row == 0)
    {
        cell.textLabel.text = @"Everyone";
    }
    else
    {
        if (indexPath.row <= [self.peopleArray count])
        {
            MCPeerID *peerID = [self.peopleArray objectAtIndex:indexPath.row - 1];
            cell.textLabel.text = [NSString stringWithFormat:@"%@", [peerID displayName]];
        }
    }
    return cell;
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.appDelegate.mpcHandler setDelegate:nil];
    [self performSegueWithIdentifier:@"gochat" sender:self];
}

@end
