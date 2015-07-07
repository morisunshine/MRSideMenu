//
//  IFTTTAnimatedScrollViewController.m
//  JazzHands
//
//  Created by Devin Foley on 9/27/13.
//  Copyright (c) 2013 IFTTT Inc. All rights reserved.
//

#import "IFTTTAnimatedScrollViewController.h"

static inline CGFloat IFTTTMaxContentOffsetXForScrollView(UIScrollView *scrollView)
{
    return scrollView.contentSize.width + scrollView.contentInset.right - CGRectGetWidth(scrollView.bounds);
}

@interface IFTTTAnimatedScrollViewController ()
{
    CGFloat contentOffsetX_;
    CADisplayLink *timer_;
}

@property (nonatomic, assign) BOOL isAtEnd;

@end

@implementation IFTTTAnimatedScrollViewController

- (id)init
{
    if ((self = [super init])) {
        _isAtEnd = NO;
        self.animator = [IFTTTAnimator new];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    contentOffsetX_ = self.scrollView.contentOffset.x;
//    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    timer_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollViewTimer)];
    [timer_ addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)scrollViewTimer
{
    NSInteger time = (NSInteger)self.scrollView.contentOffset.x;
    [self.animator animate:time];
    
    self.isAtEnd = (self.scrollView.contentOffset.x >= IFTTTMaxContentOffsetXForScrollView(self.scrollView));
    
    id delegate = self.delegate;
    
    if (self.isAtEnd && [delegate respondsToSelector:@selector(animatedScrollViewControllerDidScrollToEnd:)]) {
        [delegate animatedScrollViewControllerDidScrollToEnd:self];
    }
    
    contentOffsetX_ += 5;
    CGPoint contentOffset = self.scrollView.contentOffset;
    self.scrollView.contentOffset = CGPointMake(contentOffsetX_, contentOffset.y);
    if (self.scrollView.contentSize.width <= contentOffsetX_) {
        [timer_ invalidate];
        timer_ = nil;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    NSInteger time = (NSInteger)aScrollView.contentOffset.x;
    [self.animator animate:time];
    
    self.isAtEnd = (aScrollView.contentOffset.x >= IFTTTMaxContentOffsetXForScrollView(aScrollView));
    
    id delegate = self.delegate;

    if (self.isAtEnd && [delegate respondsToSelector:@selector(animatedScrollViewControllerDidScrollToEnd:)]) {
        [delegate animatedScrollViewControllerDidScrollToEnd:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    id delegate = self.delegate;
    
    if (self.isAtEnd && [delegate respondsToSelector:@selector(animatedScrollViewControllerDidEndDraggingAtEnd:)]) {
        [delegate animatedScrollViewControllerDidEndDraggingAtEnd:self];
    }
}

@end
