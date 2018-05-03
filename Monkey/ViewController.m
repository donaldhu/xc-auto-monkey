//
//  ViewController.m
//  Monkey
//
//  Created by Donald Hu on 10/1/16.
//  Copyright © 2016 Donald Hu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic) NSMutableArray <UIView *> *tapViews;
@end

@implementation ViewController

#pragma mark - Lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tapViews = [NSMutableArray new];
    
    self.tapGestureRecognizer = ({
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] init];
        [gestureRecognizer addTarget:self action:@selector(didRecognizeTapGesture:)];
        gestureRecognizer;
    });
    
    self.panGestureRecognizer = ({
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        [gestureRecognizer addTarget:self action:@selector(didRecognizePanGesture:)];
        gestureRecognizer;
    });
    
    self.pinchGestureRecognizer = ({
        UIPinchGestureRecognizer *gestureRecognizer = [[UIPinchGestureRecognizer alloc] init];
        [gestureRecognizer addTarget:self action:@selector(didRecognizePinchGesture:)];
        gestureRecognizer;
    });
    
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
    [self.view addGestureRecognizer:self.pinchGestureRecognizer];
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

#pragma mark - UIGestureRecognizer selectors

- (void)didRecognizeTapGesture:(UITapGestureRecognizer *)gesture
{
    CGPoint tapPoint = [gesture locationInView:self.view];
    [self addViewAtPoint:tapPoint withColor:[UIColor orangeColor]];
}

- (void)didRecognizePanGesture:(UIPanGestureRecognizer *)gesture
{
    CGPoint tapPoint = [gesture locationInView:self.view];
    [self addViewAtPoint:tapPoint withColor:[UIColor blueColor]];
}

- (void)didRecognizePinchGesture:(UIPinchGestureRecognizer *)gesture
{
    CGPoint touchLocation0 = [gesture locationOfTouch:0 inView:self.view];
    CGPoint touchLocation1 = [gesture locationOfTouch:1 inView:self.view];
    
    [self addViewAtPoint:touchLocation0 withColor:[UIColor greenColor]];
    [self addViewAtPoint:touchLocation1 withColor:[UIColor greenColor]];
}

#pragma mark - Helper methods

- (void)addViewAtPoint:(CGPoint)point withColor:(UIColor *)color
{
    CGSize tapViewSize = (CGSize){10,10};
    
    CGPoint origin = (CGPoint){point.x - tapViewSize.width / 2, point.y - tapViewSize.height / 2};
    
    UIView *view = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(origin.x, origin.y, tapViewSize.width, tapViewSize.height)];
        view.userInteractionEnabled = NO;
        view.backgroundColor = color;
        view;
    });
    
    [self.tapViews addObject:view];
    [self.view addSubview:view];
}

#pragma mark - CADisplayLink selector

- (void)update
{
    UIView *view = [self.tapViews firstObject];
    
    if (view) {
        view.alpha = view.alpha - 0.01 * self.tapViews.count;
        if (view.alpha <= 0) {
            [view removeFromSuperview];
            [self.tapViews removeObjectAtIndex:0];
        }
    }
}

@end
