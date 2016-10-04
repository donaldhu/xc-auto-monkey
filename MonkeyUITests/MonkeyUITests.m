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

@protocol PrivateXCTestDriverProtocol <NSObject>
+ (id)sharedTestDriver;
- (id)managerProxy;
@end

@protocol PrivateXCTestManagerProtocol <NSObject>
- (void)_XCT_synthesizeEvent:(id)arg1 completion:(void (^)(NSError *))arg2;
@end

@protocol PrivateXCSynthesizedEventRecordProtocol <NSObject>
- (id)initWithName:(id)arg1 interfaceOrientation:(long long)arg2;
- (void)addPointerEventPath:(id)arg1;
@end

@protocol PrivateXCPointerEventPathProtocol <NSObject>
- (id)initForTouchAtPoint:(struct CGPoint)arg1 offset:(double)arg2;
- (void)liftUpAtOffset:(double)arg1;
- (void)moveToPoint:(struct CGPoint)arg1 atOffset:(double)arg2;
@end

@interface XCUIDeviceProxy : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic) id <PrivateXCTestManagerProtocol> proxy;
- (void)tapAtPoint:(CGPoint)point;
- (void)panFromPoint:(CGPoint)point toPoint:(CGPoint)toPoint withDuration:(CGFloat)duration;
@end

@implementation MonkeyUITests

- (void)setUp
{
    [super setUp];
    
    self.continueAfterFailure = YES;

    self.app = [[XCUIApplication alloc] init];
    [self.app launch];
    
    id proxy = ((id <PrivateXCTestDriverProtocol> )[NSClassFromString(@"XCTestDriver") sharedTestDriver]).managerProxy;
    [XCUIDeviceProxy sharedInstance].proxy = proxy;
    
    CGRect frame = [self.app.windows elementBoundByIndex:0].frame;
    self.windowFrame = frame;
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testExample
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
    id <PrivateXCSynthesizedEventRecordProtocol> eventRecords = ({
        id <PrivateXCSynthesizedEventRecordProtocol> eventRecords = [[NSClassFromString(@"XCSynthesizedEventRecord") alloc] initWithName:@"" interfaceOrientation:0];
        
        id <PrivateXCPointerEventPathProtocol> pointerEventPath = [[NSClassFromString(@"XCPointerEventPath") alloc] initForTouchAtPoint:point offset:0];
        [pointerEventPath liftUpAtOffset:0.01];
        
        [eventRecords addPointerEventPath:pointerEventPath];
        
        eventRecords;
    });
    
    void (^completion)(NSError *) = ^(NSError *error) {};
    
    [self.proxy _XCT_synthesizeEvent:eventRecords completion:completion];
}

- (void)panFromPoint:(CGPoint)point toPoint:(CGPoint)toPoint withDuration:(CGFloat)duration
{
    id <PrivateXCSynthesizedEventRecordProtocol> eventRecords = ({
        id <PrivateXCSynthesizedEventRecordProtocol> eventRecords = [[NSClassFromString(@"XCSynthesizedEventRecord") alloc] initWithName:@"" interfaceOrientation:0];
        
        id <PrivateXCPointerEventPathProtocol> pointerEventPath = [[NSClassFromString(@"XCPointerEventPath") alloc] initForTouchAtPoint:point offset:0];
        [pointerEventPath moveToPoint:toPoint atOffset:duration];
        [pointerEventPath liftUpAtOffset:duration + 0.01];
        
        [eventRecords addPointerEventPath:pointerEventPath];
        
        eventRecords;
    });
    
    void (^completion)(NSError *) = ^(NSError *error) {};
    
    [self.proxy _XCT_synthesizeEvent:eventRecords completion:completion];
}

@end
