//
//  WXController.m
//  SimpleWeather
//
//  Created by Stephanie Sharp on 20/01/2014.
//  Copyright (c) 2014 RU Advertising. All rights reserved.
//

#import "WXController.h"
#import <LBBlurredImage/UIImageView+LBBlurredImage.h>

@interface WXController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *blurredImageView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat screenHeight;

@end

@implementation WXController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Get and store the screen height
    // Needed to display the weather data in a paged manner
    self.screenHeight = [UIScreen mainScreen].bounds.size.height;

    UIImage *background = [UIImage imageNamed:@"bg"];

    // Create a static image background and add it to the view
    self.backgroundImageView = [[UIImageView alloc] initWithImage:background];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];

    // Create a blurred background image using LBBlurredImage
    // Set the alpha to 0 initially so backgroundImageView is visible
    self.blurredImageView = [[UIImageView alloc] init];
    self.blurredImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.blurredImageView.alpha = 0;
    [self.blurredImageView setImageToBlur:background blurRadius:10 completionBlock:nil];
    [self.view addSubview:self.blurredImageView];

    // Create a tableview that will handle all the data presentation
    // WXController will be the delegate and data source, as well as the scroll view delegate
    // Note that pagingEnabled is set to YES
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.tableView.pagingEnabled = YES;
    [self.view addSubview:self.tableView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGRect bounds = self.view.bounds;

    self.backgroundImageView.frame = bounds;
    self.blurredImageView.frame = bounds;
    self.tableView.frame = bounds;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITableViewDataSource

// The table view has two sections, one for hourly forecasts and one for daily
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // TODO: Return count of forecast
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (! cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];

    // TODO: Setup the cell

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Determine cell height based on screen
    return 44;
}

@end
