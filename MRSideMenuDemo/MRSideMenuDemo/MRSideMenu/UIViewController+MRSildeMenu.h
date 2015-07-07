

#import <UIKit/UIKit.h>

@class MRSildeMenu;

@interface UIViewController (MRSildeMenu)

@property (strong, readonly, nonatomic) MRSildeMenu *sideMenuViewController;

// IB Action Helper methods

- (IBAction)presentLeftMenuViewController:(id)sender;

@end
