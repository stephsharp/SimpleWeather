//
//  WXDailyForecast.m
//  SimpleWeather
//
//  Created by Stephanie Sharp on 22/01/2014.
//  Copyright (c) 2014 RU Advertising. All rights reserved.
//

#import "WXDailyForecast.h"

@implementation WXDailyForecast

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    // Get WXCondition‘s map and create a mutable copy of it
    NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];

    // Change the max and min key maps to what you’ll need for the daily forecast
    paths[@"tempHigh"] = @"temp.max";
    paths[@"tempLow"] = @"temp.min";

    // Return the new mapping
    return paths;
}

@end
