//
//  SceneDelegate.m
//  NCE1
//

#import "SceneDelegate.h"
#import "FirstViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions
{
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.backgroundColor = [UIColor clearColor];

    FirstViewController *firstController = [[FirstViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:firstController];
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];
}

@end
