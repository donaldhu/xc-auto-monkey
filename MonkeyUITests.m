//
//  MonkeyUITests.m
//  MonkeyUITests
//
//  Created by Donald Hu on 10/1/16.
//  Copyright © 2016 Donald Hu. All rights reserved.
//

#import <XCTest/XCTest.h>

#pragma mark - Configuration

static NSTimeInterval const XCMonkeyEventDelay = 0.1;  // In seconds

// Test pass conditions
// Set the value to 0 if you do not want to use the pass condition
// The monkey test will pass if ANY of the conditions are met

static NSUInteger const XCMonkeyEventsCount = 100000;
static NSTimeInterval const XCMonkeyDuration = 60 * 60 * 5; // In seconds

// Weights control the probability of the monkey performing an action
// A heigher weights results in a higher probability

static NSUInteger const XCMonkeyEventWeightTap = 500;
static NSUInteger const XCMonkeyEventWeightPan = 50;
static NSUInteger const XCMonkeyEventWeightPinchIn = 50;
static NSUInteger const XCMonkeyEventWeightBackgroundAndForeground = 1;

#pragma mark - Constants

typedef NS_ENUM(NSUInteger, XCMonkeyEventType) {
    XCMonkeyEventTypeTap        = 0,
    XCMonkeyEventTypePan        = 1,
    XCMonkeyEventTypePinchIn    = 2,
    XCMonkeyEventTypeHome       = 3
};

static NSUInteger const XCMonkeyEventTypeCount = 4;

static CGFloat XCMonkeyEventTapDuration = 0.01;
static CGFloat XCMonkeyEventPanDuration = 0.3;
static CGFloat XCMonkeyEventPinchDuration = 0.3;
static CGFloat XCMonkeyEventHomePreHomeWaitDuration = 0.5;
static CGFloat XCMonkeyEventHomePreLaunchWaitDuration = 0.5;
static CGFloat XCMonkeyEventHomePostLaunchWaitDuration = 0.5;

typedef struct {
    CGFloat notificationCenterPanThreshold;
    CGFloat controlCenterPanThreshold;
} XCMonkeyDeviceMetrics;

static XCMonkeyDeviceMetrics const XCMonkeyPhone6DeviceMetrics = {
    .notificationCenterPanThreshold     = 12,
    .controlCenterPanThreshold          = 13
};

static XCMonkeyDeviceMetrics const XCMonkeyPhone6PlusDeviceMetrics = {
    .notificationCenterPanThreshold     = 41,
    .controlCenterPanThreshold          = 34
};

#pragma mark - Custom class headers

@class XCTestDriver, XCTestManager, XCSynthesizedEventRecord, XCPointerEventPath;

@interface MonkeyUITests : XCTestCase
@property (nonatomic) XCUIApplication *app;
@property (nonatomic) CGRect windowFrame;
@property (nonatomic) CGRect nonControlCenterFrame;
@property (nonatomic) XCTestManager *proxy;
@property (nonatomic) XCMonkeyDeviceMetrics metrics;
@property (nonatomic) NSUInteger eventCount;
@property (nonatomic) NSTimeInterval endEpochTime;
@end

#pragma mark - Private class headers

@interface XCTestDriver : NSObject
+ (instancetype)sharedTestDriver;
- (XCTestManager *)managerProxy;
@end

@interface XCTRunnerDaemonSession : NSObject
+ (instancetype)sharedSession;
- (XCTestManager *)daemonProxy;
@end

@interface XCTestManager : NSObject
- (void)_XCT_synthesizeEvent:(XCSynthesizedEventRecord *)arg1 completion:(void (^)(NSError *))arg2;
- (void)_XCT_launchApplicationWithBundleID:(NSString *)arg1 arguments:(NSArray *)arg2 environment:(NSDictionary *)arg3 completion:(void (^)(NSError *))arg4;
@end

@interface XCSynthesizedEventRecord : NSObject
- (id)initWithName:(NSString *)arg1 interfaceOrientation:(long long)arg2;
- (void)addPointerEventPath:(XCPointerEventPath *)arg1;
@end

@interface XCUIApplication()
@property (nonatomic) NSString *bundleID;
@end

@interface XCPointerEventPath : NSObject
- (id)initForTouchAtPoint:(struct CGPoint)arg1 offset:(double)arg2;
- (void)liftUpAtOffset:(double)arg1;
- (void)moveToPoint:(struct CGPoint)arg1 atOffset:(double)arg2;
@end

#pragma mark - Monkey implementation

@implementation MonkeyUITests

static NSUInteger maxWeight;
static NSUInteger weights[] = {XCMonkeyEventWeightTap, XCMonkeyEventWeightPan, XCMonkeyEventWeightPinchIn, XCMonkeyEventWeightBackgroundAndForeground};
static NSUInteger events[] = {XCMonkeyEventTypeTap, XCMonkeyEventTypePan, XCMonkeyEventTypePinchIn, XCMonkeyEventTypeHome};

- (void)setUp
{
    [super setUp];
    
    self.continueAfterFailure = YES;

    self.app = [[XCUIApplication alloc] init];
    [self.app launch];
    
    if ([[XCTestDriver sharedTestDriver] respondsToSelector:@selector(managerProxy)]) {
        self.proxy = [XCTestDriver sharedTestDriver].managerProxy;
    }
    else {
        self.proxy = [XCTRunnerDaemonSession sharedSession].daemonProxy;
    }
    
    self.windowFrame = [self.app.windows elementBoundByIndex:0].frame;
    [self seedEventWeights];
    
    self.metrics = (self.windowFrame.size.height == 667) ? XCMonkeyPhone6DeviceMetrics : XCMonkeyPhone6PlusDeviceMetrics;
    
    self.nonControlCenterFrame = CGRectMake(0,
                                            self.metrics.notificationCenterPanThreshold + 1,
                                            self.windowFrame.size.width,
                                            self.windowFrame.size.height - self.metrics.notificationCenterPanThreshold - self.metrics.controlCenterPanThreshold - 2);
    
    self.endEpochTime = [[NSDate date] timeIntervalSince1970] + XCMonkeyDuration;
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Monkey test

- (void)testMonkey
{
    BOOL isRunning = true;
    while(isRunning) {
        [NSThread sleepForTimeInterval:XCMonkeyEventDelay];
        NSUInteger randomNumber = arc4random() % maxWeight;
        for (NSUInteger eventIndex = 0; eventIndex < XCMonkeyEventTypeCount; eventIndex++) {
            if (randomNumber < weights[eventIndex]) {
                [self performEventWithEventType:events[eventIndex]];
                break;
            }
        }

        self.eventCount++;
        
        isRunning = ![self didPassMonkeyTest];
    }
}

- (BOOL)didPassMonkeyTest
{
    BOOL eventCountPassed = XCMonkeyEventsCount != 0 && self.eventCount >= XCMonkeyEventsCount;
    BOOL durationPassed = XCMonkeyDuration != 0 && self.endEpochTime <= [[NSDate date] timeIntervalSince1970];

    return eventCountPassed || durationPassed;
}

#pragma mark - Helper functions for randomness

- (void)seedEventWeights
{
    NSUInteger weightSum = 0;
    for (NSUInteger eventIndex = 0; eventIndex < XCMonkeyEventTypeCount; eventIndex++) {
        weightSum += weights[eventIndex];
        weights[eventIndex] = weightSum;
    }
    
    maxWeight = weights[XCMonkeyEventTypeCount - 1];
}

static CGFloat randomFloatWithUpperBound(CGFloat upper)
{
    return (CGFloat)arc4random() / UINT32_MAX * upper;
}

static CGPoint randomPointInFrame(CGRect frame)
{
    return CGPointMake(frame.origin.x + randomFloatWithUpperBound(frame.size.width),
                       frame.origin.y + randomFloatWithUpperBound(frame.size.height));
}

#pragma mark - Helper methods for events

- (void)performEventWithEventType:(XCMonkeyEventType)type
{
    switch (type) {
        case XCMonkeyEventTypeTap:
            [self tap];
            break;
        case XCMonkeyEventTypePan:
            [self pan];
            break;
        case XCMonkeyEventTypePinchIn:
            [self pinchIn];
            break;
        case XCMonkeyEventTypeHome:
            [self home];
            break;
    }
}

- (void)tap
{
    [self tapAtPoint:randomPointInFrame(self.windowFrame)];
}

- (void)pan
{
    [self panFromPoint:randomPointInFrame(self.nonControlCenterFrame)
               toPoint:randomPointInFrame(self.nonControlCenterFrame)
          withDuration:XCMonkeyEventPanDuration];
}

- (void)pinchIn
{
    CGPoint point1 = randomPointInFrame(self.nonControlCenterFrame);
    CGPoint point2 = randomPointInFrame(self.nonControlCenterFrame);
    CGPoint midpoint = CGPointMake((point1.x + point2.x) / 2,
                                   (point1.y + point2.y) / 2);
    
    XCSynthesizedEventRecord *eventRecord = ({
        XCPointerEventPath *pointerEventPath1 = [[XCPointerEventPath alloc] initForTouchAtPoint:point1 offset:0];
        [pointerEventPath1 moveToPoint:midpoint atOffset:XCMonkeyEventPinchDuration];
        [pointerEventPath1 liftUpAtOffset:XCMonkeyEventPinchDuration + XCMonkeyEventTapDuration];
        
        XCPointerEventPath *pointerEventPath2 = [[XCPointerEventPath alloc] initForTouchAtPoint:point2 offset:0];
        [pointerEventPath2 moveToPoint:midpoint atOffset:XCMonkeyEventPinchDuration];
        [pointerEventPath2 liftUpAtOffset:XCMonkeyEventPinchDuration + XCMonkeyEventTapDuration];
        
        XCSynthesizedEventRecord *eventRecord = [[XCSynthesizedEventRecord alloc] initWithName:nil interfaceOrientation:0];
        [eventRecord addPointerEventPath:pointerEventPath1];
        [eventRecord addPointerEventPath:pointerEventPath2];
        eventRecord;
    });
    
    void (^completion)(NSError *) = ^(NSError *error) {};
    
    [self.proxy _XCT_synthesizeEvent:eventRecord completion:completion];
}

- (void)home
{
    [NSThread sleepForTimeInterval:XCMonkeyEventHomePreHomeWaitDuration];
    [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
    
    [NSThread sleepForTimeInterval:XCMonkeyEventHomePreLaunchWaitDuration];
    [self.proxy _XCT_launchApplicationWithBundleID:self.app.bundleID
                                         arguments:@[]
                                       environment:@{}
                                        completion:^(NSError *error) {}];
    [NSThread sleepForTimeInterval:XCMonkeyEventHomePostLaunchWaitDuration];
}

#pragma mark - Helper methods for interacting with proxy

- (void)tapAtPoint:(CGPoint)point
{
    XCSynthesizedEventRecord *eventRecord = ({
        XCPointerEventPath *pointerEventPath = [[XCPointerEventPath alloc] initForTouchAtPoint:point offset:0];
        [pointerEventPath liftUpAtOffset:XCMonkeyEventTapDuration];
        
        XCSynthesizedEventRecord *eventRecord = [[XCSynthesizedEventRecord alloc] initWithName:nil interfaceOrientation:0];
        [eventRecord addPointerEventPath:pointerEventPath];
        eventRecord;
    });
    
    void (^completion)(NSError *) = ^(NSError *error) {};
    
    [self.proxy _XCT_synthesizeEvent:eventRecord completion:completion];
}

- (void)panFromPoint:(CGPoint)point toPoint:(CGPoint)toPoint withDuration:(CGFloat)duration
{
    XCSynthesizedEventRecord *eventRecord = ({
        XCPointerEventPath *pointerEventPath = [[XCPointerEventPath alloc] initForTouchAtPoint:point offset:0];
        [pointerEventPath moveToPoint:toPoint atOffset:duration];
        [pointerEventPath liftUpAtOffset:duration + XCMonkeyEventTapDuration];
        
        XCSynthesizedEventRecord *eventRecord = [[XCSynthesizedEventRecord alloc] initWithName:nil interfaceOrientation:0];
        [eventRecord addPointerEventPath:pointerEventPath];
        eventRecord;
    });
    
    void (^completion)(NSError *) = ^(NSError *error) {};
    
    [self.proxy _XCT_synthesizeEvent:eventRecord completion:completion];
}

@end
