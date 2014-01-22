//
//  WXCondition.m
//  SimpleWeather
//
//  Created by Stephanie Sharp on 22/01/2014.
//  Copyright (c) 2014 RU Advertising. All rights reserved.
//

#import "WXCondition.h"

@implementation WXCondition

+ (NSDictionary *)imageMap
{
    // Create a static NSDictionary since every instance of WXCondition will use the same data mapper
    static NSDictionary *_imageMap = nil;
    if (! _imageMap)
    {
        // Map the condition codes to an image file (e.g. “01d” to “weather-clear.png”)
        // All condition codes: http://bugs.openweathermap.org/projects/api/wiki/Weather_Condition_Codes
        _imageMap = @{
                      @"01d" : @"weather-clear",
                      @"02d" : @"weather-few",
                      @"03d" : @"weather-few",
                      @"04d" : @"weather-broken",
                      @"09d" : @"weather-shower",
                      @"10d" : @"weather-rain",
                      @"11d" : @"weather-tstorm",
                      @"13d" : @"weather-snow",
                      @"50d" : @"weather-mist",
                      @"01n" : @"weather-moon",
                      @"02n" : @"weather-few-night",
                      @"03n" : @"weather-few-night",
                      @"04n" : @"weather-broken",
                      @"09n" : @"weather-shower",
                      @"10n" : @"weather-rain-night",
                      @"11n" : @"weather-tstorm",
                      @"13n" : @"weather-snow",
                      @"50n" : @"weather-mist",
                      };
    }
    return _imageMap;
}

// Declare the public message to get an image file name
- (NSString *)imageName
{
    return [WXCondition imageMap][self.icon];
}

#pragma mark - MTLJSONSerializing protocol methods

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    // The dictionary key is WXCondition‘s property name,
    // while the dictionary value is the keypath from the JSON.
    return @{
             @"date": @"dt",
             @"locationName": @"name",
             @"humidity": @"main.humidity",
             @"temperature": @"main.temp",
             @"tempHigh": @"main.temp_max",
             @"tempLow": @"main.temp_min",
             @"sunrise": @"sys.sunrise",
             @"sunset": @"sys.sunset",
             @"conditionDescription": @"weather.description",
             @"condition": @"weather.main",
             @"icon": @"weather.icon",
             @"windBearing": @"wind.deg",
             @"windSpeed": @"wind.speed"
             };
}

#pragma mark - Mantle transformers

// To create a transformer for a specific property, you add a class method
// that begins with the property name and ends with JSONTransformer.
+ (NSValueTransformer *)dateJSONTransformer
{
    // Return a MTLValueTransformer using blocks to transform values to and from Objective-C properties
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
                    return [NSDate dateWithTimeIntervalSince1970:str.floatValue];
                }
                reverseBlock:^(NSDate *date) {
                    return [NSString stringWithFormat:@"%f",[date timeIntervalSince1970]];
                }];
}

// Reuse dateJSONTransformer for sunrise and sunset
+ (NSValueTransformer *)sunriseJSONTransformer
{
    return [self dateJSONTransformer];
}

+ (NSValueTransformer *)sunsetJSONTransformer
{
    return [self dateJSONTransformer];
}

// The weather key is a JSON array, but we're only concerned about a single weather condition
+ (NSValueTransformer *)conditionDescriptionJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSArray *values) {
                    return [values firstObject];
                }
                reverseBlock:^(NSString *str) {
                    return @[str];
                }];
}

+ (NSValueTransformer *)conditionJSONTransformer
{
    return [self conditionDescriptionJSONTransformer];
}

+ (NSValueTransformer *)iconJSONTransformer
{
    return [self conditionDescriptionJSONTransformer];
}

// OpenWeatherAPI uses meters-per-second for wind speed, convert this to miles-per-hour
#define MPS_TO_MPH 2.23694f

+ (NSValueTransformer *)windSpeedJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSNumber *num) {
                    return @(num.floatValue*MPS_TO_MPH);
                }
                reverseBlock:^(NSNumber *speed) {
                    return @(speed.floatValue/MPS_TO_MPH);
                }];
}

@end
