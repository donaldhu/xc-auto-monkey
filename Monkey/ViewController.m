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
@property (nonatomic) NSMutableArray <UIView *> *tapViews;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tapViews = [NSMutableArray new];
    
    self.tapGestureRecognizer = ({
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] init];
        gestureRecognizer.numberOfTapsRequired = 1;
        [gestureRecognizer addTarget:self action:@selector(didRecognizeTapGesture:)];
        
        gestureRecognizer;
    });
    
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)didRecognizeTapGesture:(UITapGestureRecognizer *)tapGesture
{
    CGSize tapViewSize = (CGSize){10,10};
    CGPoint tapPoint = [tapGesture locationInView:self.view];
    
    CGPoint origin = (CGPoint){tapPoint.x - tapViewSize.width / 2, tapPoint.y - tapViewSize.height / 2};
    
    UIView *tapView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(origin.x, origin.y, tapViewSize.width, tapViewSize.height)];
        view.userInteractionEnabled = NO;
        view.backgroundColor = [UIColor orangeColor];
        
        view;
    });
    
    [self.tapViews addObject:tapView];
    
    [self.view addSubview:tapView];
}

- (void)update
{
    UIView *view = [self.tapViews firstObject];
    
    if (view) {
        view.alpha = view.alpha - 0.09;
        if (view.alpha <= 0) {
            [view removeFromSuperview];
            [self.tapViews removeObjectAtIndex:0];
        }
    }
}

@end
