//
//  MonkeyUITests.m
//  MonkeyUITests
//
//  Created by Donald Hu on 10/1/16.
//  Copyright © 2016 Donald Hu. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface MonkeyUITests : XCTestCase
@property (nonatomic) XCUIApplication *app;
@property (nonatomic) CGRect windowFrame;
@end

#pragma mark - Configuration

static CGFloat const XCMonkeyEventDelay = 0.1;

static NSUInteger const XCMonkeyEventWeightTap = 10;
static NSUInteger const XCMonkeyEventWeightPan = 10;

#pragma mark - Constants

typedef NS_ENUM(NSUInteger, XCMonkeyEventType) {
    XCMonkeyEventTypeTap = 0,
    XCMonkeyEventTypePan = 1
};

static CGFloat const NotificationCenterPanThreshold = 12; // It will pan at this point
static CGFloat const ControlCenterPanThreshold = 13; // It will pan at this point

static NSUInteger const XCMonkeyEventTypeCount = 2;

#pragma mark - Private class headers

@class XCTestDriver, XCTestManager, XCSynthesizedEventRecord, XCPointerEventPath;

@interface XCTestDriver : NSObject
+ (instancetype)sharedTestDriver;
- (XCTestManager *)managerProxy;
@end

@interface XCTestManager : NSObject
- (void)_XCT_synthesizeEvent:(XCSynthesizedEventRecord *)arg1 completion:(void (^)(NSError *))arg2;
@end

@interface XCSynthesizedEventRecord : NSObject
- (id)initWithName:(NSString *)arg1 interfaceOrientation:(long long)arg2;
- (void)addPointerEventPath:(XCPointerEventPath *)arg1;
@end

@interface XCPointerEventPath : NSObject
- (id)initForTouchAtPoint:(struct CGPoint)arg1 offset:(double)arg2;
- (void)liftUpAtOffset:(double)arg1;
- (void)moveToPoint:(struct CGPoint)arg1 atOffset:(double)arg2;
@end

#pragma mark - Custom class headers

@interface XCUIDeviceProxy : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic) XCTestManager *proxy;
- (void)tapAtPoint:(CGPoint)point;
- (void)panFromPoint:(CGPoint)point toPoint:(CGPoint)toPoint withDuration:(CGFloat)duration;
@end

@implementation MonkeyUITests

#pragma mark - Lifecycle methods

- (void)setUp
{
    [super setUp];
    
    self.continueAfterFailure = YES;

    self.app = [[XCUIApplication alloc] init];
    [self.app launch];
    
    [XCUIDeviceProxy sharedInstance].proxy = [XCTestDriver sharedTestDriver].managerProxy;
    
    self.windowFrame = [self.app.windows elementBoundByIndex:0].frame;
    [self seedEventWeights];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Test methods

static NSUInteger maxWeight;
static NSUInteger weights[] = {XCMonkeyEventWeightTap, XCMonkeyEventWeightPan};
static NSUInteger events[] = {XCMonkeyEventTypeTap, XCMonkeyEventTypePan};

- (void)seedEventWeights
{
    NSUInteger weightSum = 0;
    for (NSUInteger eventIndex = 0; eventIndex < XCMonkeyEventTypeCount; eventIndex++) {
        weightSum += weights[eventIndex];
        weights[eventIndex] = weightSum;
    }
    
    maxWeight = weights[XCMonkeyEventTypeCount - 1];
}

- (void)testMonkey
{
    while(true) {
        [NSThread sleepForTimeInterval:XCMonkeyEventDelay];
        NSUInteger randomNumber = arc4random() % maxWeight;
        for (NSUInteger eventIndex = 0; eventIndex < XCMonkeyEventTypeCount; eventIndex++) {
            if (randomNumber < weights[eventIndex]) {
                [self performEventWithEventType:events[eventIndex]];
            }
        }
    }
}

- (void)performEventWithEventType:(XCMonkeyEventType)type
{
    switch (type) {
        case XCMonkeyEventTypeTap:
            [self tap];
            break;
        case XCMonkeyEventTypePan:
            [self pan];
            break;
    }
}

#pragma mark - Event methods

static CGFloat randomFloatWithUpperBound(CGFloat upper)
{
    return (CGFloat)arc4random() / UINT32_MAX * upper;
}

static CGPoint randomPointInFrame(CGRect frame)
{
    return CGPointMake(frame.origin.x + randomFloatWithUpperBound(frame.size.width),
                       frame.origin.y + randomFloatWithUpperBound(frame.size.height));
}

- (void)tap
{
    [[XCUIDeviceProxy sharedInstance] tapAtPoint:randomPointInFrame(self.windowFrame)];
}

- (void)pan
{
    CGRect nonControlCenterFrame = CGRectMake(0,
                                              NotificationCenterPanThreshold + 1,
                                              self.windowFrame.size.width,
                                              self.windowFrame.size.height - NotificationCenterPanThreshold - ControlCenterPanThreshold - 2);
    
    [[XCUIDeviceProxy sharedInstance] panFromPoint:randomPointInFrame(nonControlCenterFrame)
                                           toPoint:randomPointInFrame(nonControlCenterFrame)
                                      withDuration:0.3];
}

@end

@implementation XCUIDeviceProxy

+ (instancetype)sharedInstance
{
    static XCUIDeviceProxy *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[XCUIDeviceProxy alloc] init];
    });
    return sharedInstance;
}

- (void)tapAtPoint:(CGPoint)point
{
    XCSynthesizedEventRecord *eventRecord = ({
        XCPointerEventPath *pointerEventPath = [[XCPointerEventPath alloc] initForTouchAtPoint:point offset:0];
        [pointerEventPath liftUpAtOffset:0.01];
        
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
        [pointerEventPath liftUpAtOffset:duration + 0.01];
        
        XCSynthesizedEventRecord *eventRecord = [[XCSynthesizedEventRecord alloc] initWithName:nil interfaceOrientation:0];
        [eventRecord addPointerEventPath:pointerEventPath];
        eventRecord;
    });
    
    void (^completion)(NSError *) = ^(NSError *error) {};
    
    [self.proxy _XCT_synthesizeEvent:eventRecord completion:completion];
}

@end
