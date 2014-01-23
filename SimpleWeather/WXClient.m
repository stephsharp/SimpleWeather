//
//  WXClient.m
//  SimpleWeather
//
//  Created by Stephanie Sharp on 22/01/2014.
//  Copyright (c) 2014 RU Advertising. All rights reserved.
//

#import "WXClient.h"
#import "WXCondition.h"
#import "WXDailyForecast.h"

@interface WXClient ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation WXClient

- (id)init
{
    if (self = [super init])
    {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

// -fetchJSONFromURL: creates an object for other methods and objects to use;
// this behavior is sometimes called the factory pattern.
- (RACSignal *)fetchJSONFromURL:(NSURL *)url
{
    NSLog(@"Fetching: %@",url.absoluteString);

    // Returns the signal. This will not execute until this signal is subscribed to.
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                // Creates an NSURLSessionDataTask (also new to iOS 7) to fetch data from the URL
                NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (! error)
                    {
                        NSError *jsonError = nil;
                        id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                        if (! jsonError)
                        {
                            // When JSON data exists and there are no errors, send the subscriber the JSON serialized as either an array or dictionary
                            [subscriber sendNext:json];
                        }
                        else
                        {
                            // If there is an error, notify the subscriber
                            [subscriber sendError:jsonError];
                        }
                    }
                    else
                    {
                        // If there is an error, notify the subscriber
                        [subscriber sendError:error];
                    }

                    // Whether the request passed or failed, let the subscriber know that the request has completed
                    [subscriber sendCompleted];
                }];

                // Starts the the network request once someone subscribes to the signal
                [dataTask resume];

                // Creates and returns an RACDisposable object which handles any cleanup when the signal is destroyed
                return [RACDisposable disposableWithBlock:^{
                    [dataTask cancel];
                }];
            }]
            doError:^(NSError *error) {
                // Adds a “side effect” to log any errors that occur. Side effects don’t subscribe to the signal; rather, they return the signal to which they’re attached for method chaining. You’re simply adding a side effect that logs on error.
                NSLog(@"%@",error);
            }];
}

@end
