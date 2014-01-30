//
//  WXController.m
//  SimpleWeather
//
//  Created by Stephanie Sharp on 20/01/2014.
//  Copyright (c) 2014 RU Advertising. All rights reserved.
//

#import "WXController.h"
#import <LBBlurredImage/UIImageView+LBBlurredImage.h>
#import "WXManager.h"

@interface WXController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *blurredImageView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat screenHeight;
@property (nonatomic, strong) NSDateFormatter *hourlyFormatter;
@property (nonatomic, strong) NSDateFormatter *dailyFormatter;

@end

@implementation WXController

// NSDateFormatter objects are expensive to initialize, but by placing
// them in the init method you’ll ensure they’re only initialized once.
- (id)init
{
    if (self = [super init])
    {
        _hourlyFormatter = [[NSDateFormatter alloc] init];
        _hourlyFormatter.dateFormat = @"h a";

        _dailyFormatter = [[NSDateFormatter alloc] init];
        _dailyFormatter.dateFormat = @"EEEE";
    }
    return self;
}

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

    // Set the header of your table to be the same size of your screen
    // This takes advantage of UITableView’s paging which will page the header and the daily and hourly forecast sections
    CGRect headerFrame = [UIScreen mainScreen].bounds;

    // Create an inset/padding variable so that all labels are evenly spaced and centered
    CGFloat inset = 20;

    // Create and initialize the height variables for your various views
    CGFloat temperatureHeight = 110;
    CGFloat hiloHeight = 40;
    CGFloat iconHeight = 30;

    // Create frames for your labels and icon view based on the constant and inset variables
    CGRect hiloFrame = CGRectMake(inset,
                                  headerFrame.size.height - hiloHeight,
                                  headerFrame.size.width - (2 * inset),
                                  hiloHeight);

    CGRect temperatureFrame = CGRectMake(inset,
                                         headerFrame.size.height - (temperatureHeight + hiloHeight),
                                         headerFrame.size.width - (2 * inset),
                                         temperatureHeight);

    CGRect iconFrame = CGRectMake(inset,
                                  temperatureFrame.origin.y - iconHeight,
                                  iconHeight,
                                  iconHeight);

    // Copy the icon frame, adjust it so the text has some room to expand, and move it to the right of the icon
    CGRect conditionsFrame = iconFrame;
    conditionsFrame.size.width = self.view.bounds.size.width - (((2 * inset) + iconHeight) + 10);
    conditionsFrame.origin.x = iconFrame.origin.x + (iconHeight + 10);

    // Set the current-conditions view as your table header
    UIView *header = [[UIView alloc] initWithFrame:headerFrame];
    header.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = header;

    // Build each required label to display weather data
    // bottom left
    UILabel *temperatureLabel = [[UILabel alloc] initWithFrame:temperatureFrame];
    temperatureLabel.backgroundColor = [UIColor clearColor];
    temperatureLabel.textColor = [UIColor whiteColor];
    temperatureLabel.text = @"0°";
    temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:120];
    [header addSubview:temperatureLabel];

    // bottom left
    UILabel *hiloLabel = [[UILabel alloc] initWithFrame:hiloFrame];
    hiloLabel.backgroundColor = [UIColor clearColor];
    hiloLabel.textColor = [UIColor whiteColor];
    hiloLabel.text = @"0° / 0°";
    hiloLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28];
    [header addSubview:hiloLabel];

    // top
    UILabel *cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 30)];
    cityLabel.backgroundColor = [UIColor clearColor];
    cityLabel.textColor = [UIColor whiteColor];
    cityLabel.text = @"Loading...";
    cityLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cityLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:cityLabel];

    UILabel *conditionsLabel = [[UILabel alloc] initWithFrame:conditionsFrame];
    conditionsLabel.backgroundColor = [UIColor clearColor];
    conditionsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    conditionsLabel.textColor = [UIColor whiteColor];
    [header addSubview:conditionsLabel];

    // Add an image view for a weather icon
    // bottom left
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:iconFrame];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    [header addSubview:iconView];

    // Observes the currentCondition key on the WXManager singleton
    [[RACObserve([WXManager sharedManager], currentCondition)
      // Delivers any changes on the main thread since you’re updating the UI
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(WXCondition *newCondition) {
         // Updates the text labels with weather data; you’re using newCondition for the text and not the singleton.
         // The subscriber parameter is guaranteed to be the new value.
         temperatureLabel.text = [NSString stringWithFormat:@"%.0f°",newCondition.temperature.floatValue];
         conditionsLabel.text = [newCondition.condition capitalizedString];
         cityLabel.text = [newCondition.locationName capitalizedString];

         // Uses the mapped image file name to create an image and sets it as the icon for the view
         iconView.image = [UIImage imageNamed:[newCondition imageName]];
     }];

    // This code binds high and low temperature values to the hiloLabel‘s text property.
    // The RAC(…) macro helps keep syntax clean. The returned value from the signal is assigned
    // to the text key of the hiloLabel object.
    RAC(hiloLabel, text) = [[RACSignal combineLatest:@[
                                // Observe the high and low temperatures of the currentCondition key.
                                // Combine the signals and use the latest values for both.
                                // The signal fires when either key changes.
                                RACObserve([WXManager sharedManager], currentCondition.tempHigh),
                                RACObserve([WXManager sharedManager], currentCondition.tempLow)]
                                // Reduce the values from your combined signals into a single value;
                                // note that the parameter order matches the order of your signals.
                                reduce:^(NSNumber *hi, NSNumber *low) {
                                    return [NSString  stringWithFormat:@"%.0f° / %.0f°",hi.floatValue,low.floatValue];
                                }]
                                // Again, since you’re working on the UI, deliver everything on the main thread.
                                deliverOn:RACScheduler.mainThreadScheduler];

    //The table isn’t reloading!
    // To fix this you need to add another ReactiveCocoa observable
    // on the hourly and daily forecast properties of the manager.
    [[RACObserve([WXManager sharedManager], hourlyForecast)
            deliverOn:RACScheduler.mainThreadScheduler]
        subscribeNext:^(NSArray *newForecast) {
            [self.tableView reloadData];
        }];

    [[RACObserve([WXManager sharedManager], dailyForecast)
            deliverOn:RACScheduler.mainThreadScheduler]
        subscribeNext:^(NSArray *newForecast) {
            [self.tableView reloadData];
        }];

    // Begin finding the current location of the device
    [[WXManager sharedManager] findCurrentLocation];
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
    // Note: You’re using table cells for headers here instead of the built-in section headers
    // which have sticky-scrolling behavior. The table view is set up with paging enabled and
    // sticky-scrolling behavior would look odd in this context.

    // The first section is for the hourly forecast. Use the six latest
    // hourly forecasts and add one more cell for the header.
    if (section == 0)
    {
        return MIN([[WXManager sharedManager].hourlyForecast count], 6) + 1;
    }

    // The next section is for daily forecasts. Use the six latest
    // daily forecasts and add one more cell for the header.
    return MIN([[WXManager sharedManager].dailyForecast count], 6) + 1;
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

    if (indexPath.section == 0)
    {
        // The first row of each section is the header cell
        if (indexPath.row == 0)
        {
            [self configureHeaderCell:cell title:@"Hourly Forecast"];
        }
        else
        {
            // Get the hourly weather and configure the cell using custom configure methods
            WXCondition *weather = [WXManager sharedManager].hourlyForecast[indexPath.row - 1];
            [self configureHourlyCell:cell weather:weather];
        }
    }
    else if (indexPath.section == 1)
    {
        // The first row of each section is the header cell
        if (indexPath.row == 0)
        {
            [self configureHeaderCell:cell title:@"Daily Forecast"];
        }
        else
        {
            // Get the daily weather and configure the cell using another custom configure method
            WXCondition *weather = [WXManager sharedManager].dailyForecast[indexPath.row - 1];
            [self configureDailyCell:cell weather:weather];
        }
    }

    return cell;
}

// Configures and adds text to the cell used as the section header.
// You’ll reuse this for daily and hourly forecast sections.
- (void)configureHeaderCell:(UITableViewCell *)cell title:(NSString *)title
{
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = @"";
    cell.imageView.image = nil;
}

// Formats the cell for an hourly forecast
- (void)configureHourlyCell:(UITableViewCell *)cell weather:(WXCondition *)weather
{
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = [self.hourlyFormatter stringFromDate:weather.date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f°",weather.temperature.floatValue];
    cell.imageView.image = [UIImage imageNamed:[weather imageName]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

// Formats the cell for a daily forecast
- (void)configureDailyCell:(UITableViewCell *)cell weather:(WXCondition *)weather
{
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = [self.dailyFormatter stringFromDate:weather.date];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f° / %.0f°",
                                    weather.tempHigh.floatValue,
                                    weather.tempLow.floatValue];
    cell.imageView.image = [UIImage imageNamed:[weather imageName]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Determine cell height based on screen
    return 44;
}

@end
