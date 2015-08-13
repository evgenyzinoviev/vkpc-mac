//
//  Statistics.m
//  VKPC
//
//  Created by Eugene on 11/12/14.
//  Copyright (c) 2014 Eugene Z. All rights reserved.
//

#import "Statistics.h"

@implementation Statistics {
    NSMutableData *responseData;
}

static BOOL initialized = NO;
static Statistics *instance;
static NSTimer *timer;

static const float kNormalTimeout = 3600 * 6;
static const float kAfterFailureTimeout = 1200;

+ (void)initialize {
    if (initialized) {
        return;
    }
    
    instance = [[Statistics alloc] init];
    
    long ts = GetTimestamp();
    long reported = [[NSUserDefaults standardUserDefaults] integerForKey:VKPCPreferencesStatisticReportedTimestamp];
    
//    NSLog(@"[Statistics initialize] ts=%ld, reported=%ld", ts, reported);
    
    if (reported == 0 || ts - reported >= kNormalTimeout) {
//        NSLog(@"[Statistics initalize] report now");
        [self report];
    } else {
        [self initializeTimerWithTimeout:kNormalTimeout - (ts - reported)];
    }
    
    initialized = YES;
}

//+ (void)timerCallback:(NSTimer *)timer {
//    long ts = GetTimestamp();
//    long reported = [[NSUserDefaults standardUserDefaults] integerForKey:VKPCPreferencesStatisticReportedTimestamp];
//    
//    NSLog(@"[Statistics timerCallback] ts=%ld, reported=%ld", ts, reported);
//    
//    if (ts - reported >= 3600 * 8) {
//        [self report];
//    } else {
//        [self initializeTimerWithTimeout:kNormalTimeout];
//    }
//}

+ (void)initializeTimerWithTimeout:(float)timeout {
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                     target:[Statistics class]
                                   selector:@selector(report)
                                   userInfo:nil
                                    repeats:NO];
}

+ (void)report {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[NSURL URLWithString:@"https://ch1p.com/vkpc/usage.php"]];
    NSString *postData = [NSString stringWithFormat:@"app_v=%@&osx_v=%@&uuid=%@", getAppVersion(), getOSXVersion(), getUUID()];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
 
    [instance mrProper];
    [[NSURLConnection alloc] initWithRequest:request delegate:instance];
}

+ (void)requestDone:(NSData *)data {
    NSError *error;
    NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error || !json) {
        NSLog(@"[Statistics requestDone] error while parsing json: %@", error);
        [self initializeTimerWithTimeout:kAfterFailureTimeout];
        return;
    }
    
    NSString *result = json[0];
    NSLog(@"[Statistics requestDone] result: %@", result);
    if ([result isEqualToString:@"ok"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:GetTimestamp()] forKey:VKPCPreferencesStatisticReportedTimestamp];
        [self initializeTimerWithTimeout:kNormalTimeout];
    } else {
        [self initializeTimerWithTimeout:kAfterFailureTimeout];
    }
}

+ (void)requestFailed:(NSError *)error {
    NSLog(@"[Statistics requestFailed] error: %@", [error description]);
    [self initializeTimerWithTimeout:kAfterFailureTimeout];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [Statistics requestFailed:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [Statistics requestDone:responseData];
}

- (void)mrProper {
    responseData = nil;
}

static NSString *getAppVersion() {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:kCFBundleVersion];
}

static NSString *getOSXVersion() {
    SInt32 major, minor, bugfix;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    Gestalt(gestaltSystemVersionBugFix, &bugfix);
    return [NSString stringWithFormat:@"%d.%d.%d", major, minor, bugfix];
}

static NSString *getUUID() {
    return [[NSUserDefaults standardUserDefaults] stringForKey:VKPCPreferencesUUID];
}

@end
