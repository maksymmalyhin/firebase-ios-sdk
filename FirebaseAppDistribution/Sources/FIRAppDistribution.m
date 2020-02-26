// Copyright 2019 Google
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FIRAppDistribution.h"

#import <FirebaseCore/FIRAppInternal.h>
#import <FirebaseCore/FIRComponent.h>
#import <FirebaseCore/FIRComponentContainer.h>

#import <UIKit/UIKit.h>
#import <AppAuth/AppAuth.h>
#import <FIRAppDistribution.h>
#import <FIRAppDistributionAppDelegateInterceptor.h>
#import <GoogleUtilities/GULAppDelegateSwizzler.h>

/// Empty protocol to register with FirebaseCore's component system.
@protocol FIRAppDistributionInstanceProvider <NSObject>
@end

@interface FIRAppDistribution () <FIRLibrary, FIRAppDistributionInstanceProvider>
@end

@implementation FIRAppDistributionRelease
- (instancetype)init {
    self = [super init];
    
    return self;
}
@end

@implementation FIRAppDistribution

#pragma mark - Singleton Support

- (instancetype)initWithApp:(FIRApp *)app
                    appInfo:(NSDictionary *)appInfo {
    self = [super init];
    
    if (self) {
        self.safariHostingViewController = [[UIViewController alloc] init];
        
        // Save any properties here
        NSLog(@"APP DISTRIBUTION STARTED UP!");
        
        [GULAppDelegateSwizzler proxyOriginalDelegate];
        
        FIRAppDistributionAppDelegatorInterceptor *interceptor = [FIRAppDistributionAppDelegatorInterceptor sharedInstance];
        [GULAppDelegateSwizzler registerAppDelegateInterceptor:interceptor];
        
    }
    
    return self;
}

+ (void)load {
    [FIRApp registerInternalLibrary:(Class<FIRLibrary>)self
                           withName:@"firebase-appdistribution"
                        withVersion:@"0.0.0"]; //TODO: Get version from podspec
}

+ (NSArray<FIRComponent *> *)componentsToRegister {
    
    FIRComponentCreationBlock creationBlock =
    ^id _Nullable(FIRComponentContainer *container, BOOL *isCacheable) {
        if (!container.app.isDefaultApp) {
            NSLog(@"App Distribution must be used with the default Firebase app.");
            return nil;
        }
        
        *isCacheable = YES;
        
        return [[FIRAppDistribution alloc] initWithApp:container.app
                                               appInfo:NSBundle.mainBundle.infoDictionary];
    };
    
    FIRComponent *component =
    [FIRComponent componentWithProtocol:@protocol(FIRAppDistributionInstanceProvider)
                    instantiationTiming:FIRInstantiationTimingEagerInDefaultApp
                           dependencies:@[]
                          creationBlock:creationBlock];
    return @[ component ];
}

+ (instancetype)appDistribution {
    // The container will return the same instance since isCacheable is set
    
    FIRApp *defaultApp = [FIRApp defaultApp];  // Missing configure will be logged here.
    
    // Get the instance from the `FIRApp`'s container. This will create a new instance the
    // first time it is called, and since `isCacheable` is set in the component creation
    // block, it will return the existing instance on subsequent calls.
    id<FIRAppDistributionInstanceProvider> instance =
    FIR_COMPONENT(FIRAppDistributionInstanceProvider, defaultApp.container);
    
    // In the component creation block, we return an instance of `FIRAppDistribution`. Cast it and
    // return it.
    return (FIRAppDistribution *)instance;
}

- (void) signInWithCompletion:(FIRAppDistributionSignInCompletion)completion {
    
    NSURL *issuer = [NSURL URLWithString:@"https://accounts.google.com"];
    
    [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuer
                                                        completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                     NSError *_Nullable error) {
        
        if (!configuration) {
            NSLog(@"Error retrieving discovery document: %@",
                  [error localizedDescription]);
            return;
        }
        
        NSString *redirectUrl = [@"dev.firebase.appdistribution." stringByAppendingString:[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@":/launch"]];
        NSLog(@"%@", redirectUrl);
        
        // builds authentication request
        OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:@"319754533822-osu3v3hcci24umq6diathdm0dipds1fb.apps.googleusercontent.com"
                                                        scopes:@[OIDScopeOpenID,
                                                                 OIDScopeProfile]
                                                   redirectURL:[NSURL URLWithString:redirectUrl]
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:nil];
        
        // Create an empty window + viewController to host the Safari UI.
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.rootViewController = self.safariHostingViewController;
        
        // Place it at the highest level within the stack.
        window.windowLevel = +CGFLOAT_MAX;
        
        // Run it.
        [window makeKeyAndVisible];
        
        NSLog(@"Presenting view controller: %@", self.safariHostingViewController);
        
        // performs authentication request
        [FIRAppDistributionAppDelegatorInterceptor sharedInstance].currentAuthorizationFlow =
        [OIDAuthState authStateByPresentingAuthorizationRequest:request
                                       presentingViewController:self.safariHostingViewController
                                                       callback:^(OIDAuthState *_Nullable authState,
                                                                  NSError *_Nullable error) {
            
            NSLog(@"Completed the sign in process");
            
            self.authState = authState;
            self.authError = error;
            
            completion(error);
        }];
    }];
    
}

-(void) signOut {
    self.authState = nil;
}

-(BOOL) signedIn {
    return self.authState? YES: NO;
}

- (void)checkForUpdateWithCompletion:(FIRAppDistributionUpdateCheckCompletion)completion {
    
    if(self.signedIn) {
        NSLog(@"Got authorization tokens. Access token: %@",
              self.authState.lastTokenResponse.accessToken);
        FIRAppDistributionRelease *release = [[FIRAppDistributionRelease alloc]init];
        release.bundleShortVersion = @"1.0";
        release.bundleVersion = @"123";
        release.downloadUrl = [NSURL URLWithString:@""];
        completion(release, nil);
    } else {
        [self signInWithCompletion:^(NSError * _Nullable error) {
            NSLog(@"Got authorization tokens. Access token: %@",
                  self.authState.lastTokenResponse.accessToken);
            FIRAppDistributionRelease *release = [[FIRAppDistributionRelease alloc]init];
            release.bundleShortVersion = @"1.0";
            release.bundleVersion = @"123";
            release.downloadUrl = [NSURL URLWithString:@""];
            completion(release, nil);
        }];
    }
}
@end
