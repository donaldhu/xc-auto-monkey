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

static CGFloat const NotificationCenterPanThreshold = 12; // It will pan at this point
static CGFloat const ControlCenterPanThreshold = 13; // It will pan at this point

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
    
    self.windowFrame = [self.app.windows elementBoundByIndex:0].frame;;
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Test methods

- (void)testMonkey
{
    while(true) {
        [NSThread sleepForTimeInterval:0.1];
        if (arc4random() % 2 == 0) {
            [self tap];
        } else {
            [self pan];
        }
    }
}

#pragma mark - Event methods

- (void)tap
{
    CGFloat x = arc4random() % (int)self.windowFrame.size.width;
    CGFloat y = arc4random() % (int)self.windowFrame.size.height;
    
    [[XCUIDeviceProxy sharedInstance] tapAtPoint:(CGPoint){x,y}];
}

- (void)pan
{
    CGFloat x = arc4random() % (int)self.windowFrame.size.width;
    CGFloat y = arc4random() % (int)self.windowFrame.size.height;
    CGFloat dx = arc4random() % (int)self.windowFrame.size.width;
    CGFloat dy = arc4random() % (int)self.windowFrame.size.height;

    CGFloat controlCenterThreshold = self.windowFrame.size.height - ControlCenterPanThreshold;
    while (y <= NotificationCenterPanThreshold || y >= controlCenterThreshold) {
        y = arc4random() % (int)self.windowFrame.size.height;
    }
    
    [[XCUIDeviceProxy sharedInstance] panFromPoint:(CGPoint){x,y} toPoint:(CGPoint){dx,dy} withDuration:0.3];
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
    XCSynthesizedEventRecord *eventRecords = ({
        XCSynthesizedEventRecord *eventRecords = [[XCSynthesizedEventRecord alloc] initWithName:@"" interfaceOrientation:0];
        
        XCPointerEventPath *pointerEventPath = [[XCPointerEventPath alloc] initForTouchAtPoint:point offset:0];
        [pointerEventPath liftUpAtOffset:0.01];
        
        [eventRecords addPointerEventPath:pointerEventPath];
        
        eventRecords;
    });
    
    void (^completion)(NSError *) = ^(NSError *error) {};
    
    [self.proxy _XCT_synthesizeEvent:eventRecords completion:completion];
}

- (void)panFromPoint:(CGPoint)point toPoint:(CGPoint)toPoint withDuration:(CGFloat)duration
{
    XCSynthesizedEventRecord *eventRecords = ({
        XCSynthesizedEventRecord *eventRecords = [[XCSynthesizedEventRecord alloc] initWithName:@"" interfaceOrientation:0];
        
        XCPointerEventPath *pointerEventPath = [[XCPointerEventPath alloc] initForTouchAtPoint:point offset:0];
        [pointerEventPath moveToPoint:toPoint atOffset:duration];
        [pointerEventPath liftUpAtOffset:duration + 0.01];
        
        [eventRecords addPointerEventPath:pointerEventPath];
        
        eventRecords;
    });
    
    void (^completion)(NSError *) = ^(NSError *error) {};
    
    [self.proxy _XCT_synthesizeEvent:eventRecords completion:completion];
}

@end
