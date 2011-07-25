//
//  peegAppDelegate.h
//  peeg
//

#import <UIKit/UIKit.h>

@class peegViewController;

@interface peegAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    peegViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet peegViewController *viewController;

@end

