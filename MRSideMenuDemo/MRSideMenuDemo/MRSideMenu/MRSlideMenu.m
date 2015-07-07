//

#import "MRSildeMenu.h"
#import "IFTTTJazzHands.h"
#import "UIViewController+MRSildeMenu.h"

#define APP_SCREEN_WIDTH            [UIScreen mainScreen].bounds.size.width
#define APP_SCREEN_HEIGHT           [UIScreen mainScreen].bounds.size.height

@interface MRSildeMenu ()
{
    BOOL animating_;
    IFTTTAnimator *animator_;
    CADisplayLink *displayLink_;
    UIImageView *captuImageView_;
    NSInteger time_;
    NSInteger gapx_;
    BOOL isShowLeftMenu_;
}

@property (strong, readwrite, nonatomic) UIImageView *backgroundImageView;
@property (assign, readwrite, nonatomic) CGPoint originalPoint;
@property (strong, readwrite, nonatomic) UIButton *contentButton;
@property (strong, readwrite, nonatomic) UIView *menuViewContainer;
@property (strong, readwrite, nonatomic) UIView *contentViewContainer;
@property (assign, readwrite, nonatomic) BOOL didNotifyDelegate;

@end

@implementation MRSildeMenu

#pragma mark -
#pragma mark Instance lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    animator_ = [IFTTTAnimator new];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.menuViewContainer];
    [self.view addSubview:self.contentViewContainer];
    self.view.multipleTouchEnabled = NO;
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    self.panGestureRecognizer.maximumNumberOfTouches = 1;
    self.panGestureRecognizer.delegate = self;
    self.panGestureRecognizer.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:self.panGestureRecognizer];

    self.menuViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;    
    self.contentViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (self.leftMenuViewController) {
        [self moveViewController:self.leftMenuViewController toView:self.menuViewContainer];
    }

    [self moveViewController:self.contentViewController toView:self.contentViewContainer];
    
    [self updateContentViewShadow];
    
    [self configureAnimation];
}

- (UIImageView *)backgroundImageView
{
    if (!_backgroundImageView) {
        _backgroundImageView.image = self.backgroundImage;
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return _backgroundImageView;
}

- (UIButton *)contentButton
{
    if (!_contentButton) {
        _contentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _contentButton.frame = CGRectNull;
        [_contentButton addTarget:self action:@selector(hideMenuViewController) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _contentButton;
}

- (UIView *)menuViewContainer
{
    if (!_menuViewContainer) {
        _menuViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        _menuViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return _menuViewContainer;
}

- (UIView *)contentViewContainer
{
    if (!_contentViewContainer) {
        _contentViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        _contentViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    return _contentViewContainer;
}

#pragma mark - Setters -

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    _backgroundImage = backgroundImage;
    if (self.backgroundImageView)
        self.backgroundImageView.image = backgroundImage;
}

#pragma mark - Public methods -

- (id)initWithContentViewController:(UIViewController *)contentViewController
             leftMenuViewController:(UIViewController *)leftMenuViewController 
            rightMenuViewController:(UIViewController *)rightMenuViewController
{
    self = [self init];
    
    if (self) {
        self.contentViewController = contentViewController;
        self.leftMenuViewController = leftMenuViewController;
    }
    return self;
}

- (void)presentLeftMenuViewController
{
    [self showLeftMenuViewController];
}

- (void)hideMenuViewController
{
    [self hideMenuViewControllerAnimated:YES];
}

- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated
{
    if (_contentViewController == contentViewController || animating_ == YES) {
        
        if (animating_ == YES) {
            
        } else {
            [self hideMenuViewControllerAnimated:YES];
        }
        
        return;
    }
    
    if (animated == YES) {
        [self addChildViewController:contentViewController];
        contentViewController.view.alpha = 0;
        contentViewController.view.frame = self.contentViewContainer.bounds;
        [self.contentViewContainer addSubview:contentViewController.view];
        animating_ = YES;
        [UIView animateWithDuration:0.35 animations:^{
            contentViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            animating_ = NO;
            [contentViewController didMoveToParentViewController:self];
            [self hideViewController:self.contentViewController];
            _contentViewController = contentViewController;
            [self hideMenuViewControllerAnimated:YES];
            [self updateContentViewShadow];
        }];
    } else {
        [self setContentViewController:contentViewController];
    }
    
    [self updateGesturesInViewController:contentViewController];
}

#pragma mark UIGestureRecognizer Delegate (Private)

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.interactivePopGestureRecognizerEnabled && [self.contentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)self.contentViewController;
        if (navigationController.viewControllers.count > 1) {
            return NO;
        }
    }
    
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint point = [touch locationInView:gestureRecognizer.view];
        if (point.x < 40 || (point.x > 238 &&  0 < CGRectGetMinX(self.contentViewContainer.frame))) {
            return YES;
        } else {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark Pan gesture recognizer (Private)

- (IBAction)panGestureRecognized:(UIPanGestureRecognizer *)sender
{
    self.contentViewContainer.layer.anchorPoint = CGPointMake(0, 0.5);
    
    if ((sender.state == UIGestureRecognizerStateBegan)) {
        captuImageView_ = [[UIImageView alloc] initWithFrame:self.view.bounds];
        captuImageView_.image = [self capture];
        [self.contentViewContainer addSubview:captuImageView_];
        self.contentViewController.view.hidden = YES;
        if (isShowLeftMenu_ == YES) {
            time_ = CGRectGetMinX(self.contentViewContainer.frame);
        } else {
            time_ = 0;
        }
    }
    
    if ((sender.state == UIGestureRecognizerStateChanged) &&
        [sender isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        CGPoint offset = [sender translationInView:self.view];
        time_ += offset.x;
        [sender setTranslation:CGPointZero inView:self.view];
        [animator_ animate:time_];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (isShowLeftMenu_ == NO) {
            if (50 < time_) {
                [self showLeftMenuViewController];
            } else {
                [self beginResetDisplayAnimation];
            }
        } else {
            if (time_ <= APP_SCREEN_WIDTH - 50) {
                [self beginResetDisplayAnimation];
            } else {
                [self showLeftMenuViewController];
            }
        }
    }
}

#pragma mark - Private Methods -

- (void)commonInit
{
    gapx_ = APP_SCREEN_WIDTH / 20;
    self.interactivePopGestureRecognizerEnabled = YES;
    self.contentViewShadowEnabled = NO;
    self.contentViewShadowColor = [UIColor blackColor];
    self.contentViewShadowOffset = CGSizeZero;
    self.contentViewShadowOpacity = 0.4f;
    self.contentViewShadowRadius = 8.0f;
}

- (void)moveViewController:(UIViewController *)viewController toView:(UIView *)view
{
    [self addChildViewController:viewController];
    viewController.view.frame = self.view.bounds;
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

- (void)showLeftMenuViewController
{
    isShowLeftMenu_ = YES;
    if (!self.leftMenuViewController) {
        return;
    }
    [self.leftMenuViewController beginAppearanceTransition:YES animated:YES];
    self.leftMenuViewController.view.hidden = NO;
    [self.view.window endEditing:YES];
    [self addContentButton];
    [self updateContentViewShadow];
    [self beginShowDisplayAnimation];
}

- (void)hideViewController:(UIViewController *)viewController
{
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

- (void)hideMenuViewControllerAnimated:(BOOL)animated
{
    UIViewController *visibleMenuViewController = self.leftMenuViewController;
    [visibleMenuViewController beginAppearanceTransition:NO animated:animated];
    if ([self.delegate conformsToProtocol:@protocol(MRSideMenuDelegate)] && [self.delegate respondsToSelector:@selector(sideMenu:willHideMenuViewController:)]) {
        [self.delegate sideMenu:self willHideMenuViewController:self.leftMenuViewController];
    }

    [self.contentButton removeFromSuperview];
    [self beginResetDisplayAnimation];
    [self statusBarNeedsAppearanceUpdate];
}

- (void)addContentButton
{
    if (self.contentButton.superview)
        return;
    
    self.contentButton.autoresizingMask = UIViewAutoresizingNone;
    self.contentButton.frame = self.contentViewContainer.bounds;
    self.contentButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentViewContainer addSubview:self.contentButton];
}

- (void)statusBarNeedsAppearanceUpdate
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [UIView animateWithDuration:0.3f animations:^{
            [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        }];
    }
}

- (void)updateContentViewShadow
{
    if (self.contentViewShadowEnabled) {
        CALayer *layer = self.contentViewContainer.layer;
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:layer.bounds];
        layer.shadowPath = path.CGPath;
        layer.shadowColor = self.contentViewShadowColor.CGColor;
        layer.shadowOffset = self.contentViewShadowOffset;
        layer.shadowOpacity = self.contentViewShadowOpacity;
        layer.shadowRadius = self.contentViewShadowRadius;
    }
}

- (void)configureAnimation
{
    NSInteger left = 238;
    CGRect frame = CGRectMake(left, 0, APP_SCREEN_WIDTH, APP_SCREEN_HEIGHT);
    IFTTTFrameAnimation *contentFrameAnimation = [IFTTTFrameAnimation animationWithView:self.contentViewContainer];
    [contentFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:0 andFrame:self.view.bounds]];
    [contentFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:left andFrame:frame]];
    [animator_ addAnimation:contentFrameAnimation];
    IFTTTAlphaAnimation *menuAlphaAnimation = [IFTTTAlphaAnimation animationWithView:self.menuViewContainer];
    [menuAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:0 andAlpha:0]];
    [menuAlphaAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:left andAlpha:1]];
    [animator_ addAnimation:menuAlphaAnimation];
    IFTTTScaleAnimation *contentScaleAnimation = [IFTTTScaleAnimation animationWithView:self.contentViewContainer];
    [contentScaleAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:0 andScale:1]];
    [contentScaleAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:left andScale:0.7]];
    [animator_ addAnimation:contentScaleAnimation];
    IFTTTScaleAnimation *menuScaleAnimation = [IFTTTScaleAnimation animationWithView:self.menuViewContainer];
    [menuScaleAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:0 andScale:0.7]];
    [menuScaleAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:left andScale:1]];
    [animator_ addAnimation:menuScaleAnimation];
    IFTTTFrameAnimation *menuFrameAnimation = [IFTTTFrameAnimation animationWithView:self.menuViewContainer];
    [menuFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:0 andFrame:CGRectMake(-60, 0, APP_SCREEN_WIDTH - 60, APP_SCREEN_HEIGHT)]];
    [menuFrameAnimation addKeyFrame:[IFTTTAnimationKeyFrame keyFrameWithTime:left andFrame:CGRectMake(0, 0, APP_SCREEN_WIDTH - 60, APP_SCREEN_HEIGHT)]];
    [animator_ addAnimation:menuFrameAnimation];
}

- (void)beginShowDisplayAnimation
{
    self.contentViewContainer.layer.anchorPoint = CGPointMake(0, 0.5);
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    if (!displayLink_) {
        displayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(showDisplayAnimation)];
        [displayLink_ addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)showDisplayAnimation
{
    if (APP_SCREEN_WIDTH <= time_) {
        time_ = APP_SCREEN_WIDTH;
        [captuImageView_ removeFromSuperview];
        self.contentViewController.view.hidden = NO;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [self stopDisplayLink];
        if ([self.delegate respondsToSelector:@selector(sideMenu:didShowMenuViewController:)]) {
            [self.delegate sideMenu:self didShowMenuViewController:self.leftMenuViewController];
        }
    }
    
    [animator_ animate:time_];
    
    time_ += gapx_;
}

- (void)beginResetDisplayAnimation
{
    isShowLeftMenu_ = NO;
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    if (!displayLink_) {
        displayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(resetDisplayAnimation)];
        [displayLink_ addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)resetDisplayAnimation
{
    if (time_ <= 0) {
        time_ = 0;
        [captuImageView_ removeFromSuperview];
        self.contentViewController.view.hidden = NO;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [self stopDisplayLink];
        if ([self.delegate respondsToSelector:@selector(sideMenu:didHideMenuViewController:)]) {
            [self.delegate sideMenu:self didHideMenuViewController:self.leftMenuViewController];
        }
    }
    
    [animator_ animate:time_];
    
    time_ -= gapx_;
}

- (void)stopDisplayLink
{
    [displayLink_ invalidate];
    displayLink_ = nil;
}

// get the current view screen shot
- (UIImage *)capture
{
    UIViewController *controller = self.contentViewController;
    
    UIGraphicsBeginImageContextWithOptions(controller.view.bounds.size, NO, [UIScreen mainScreen].scale);
    
    [controller.view drawViewHierarchyInRect:controller.view.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)updateGesturesInViewController:(UIViewController *)viewController
{
    UINavigationController *rootViewController = (UINavigationController *)self.contentViewController;
    UIViewController *firstViewController = [rootViewController.viewControllers firstObject];
    UIView *view = firstViewController.view;
    [self updateGesturesInView:view];
}

- (void)updateGesturesInView:(UIView *)view;
{
    if (view.subviews) {
        for (UIView *subView in view.subviews) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                UIScrollView *scrollView = (UIScrollView *)subView;
                [scrollView.panGestureRecognizer 
                 requireGestureRecognizerToFail:self.panGestureRecognizer];
            }
            
            [self updateGesturesInView:subView];
        }
    }
}

@end
