//
//  peegAppDelegate.m
//  peeg
//

#import "peegAppDelegate.h"
#import "peegViewController.h"

@implementation peegAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    if (self.window == nil) {
        self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    }
    if (self.viewController == nil) {
        self.viewController = [[[peegViewController alloc] init] autorelease];
    }

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
