//
//  ParticleSetupViewController.h
//  mobile-sdk-ios
//
//  Created by Ido Kleinman on 12/13/14.
//  Copyright (c) 2014-2015 Particle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParticleSetupStrings.h"
#import "ParticleSetupStringsExtensions.h"
#import "ParticleSetupMainController.h"


#define SPARK_SETUP_RESOURCE_BUNDLE_IDENTIFIER  @"io.spark.ParticleSetup"

#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define isiPhone4  ([[UIScreen mainScreen] bounds].size.height == 480) ? YES : NO
#define isiPhone5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0)

@interface ParticleSetupUIViewController : UIViewController

@property(nonatomic, strong) UIView *backgroundView; //image or solid color

- (BOOL)isValidEmail:(NSString *)checkString; // should be in NSString category
- (void)disableKeyboardMovesViewUp; // might not be needed when we remove all popups
- (void)trimTextFieldValue:(UITextField *)textfield;

- (void)replaceSetupStrings:(UIView *)target;
@end
