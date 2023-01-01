//
//  ParticleManualNetworkViewController.m
//  teacup-ios-app
//
//  Created by Ido on 2/22/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

#import "ParticleManualNetworkViewController.h"
#import "ParticleSetupUIElements.h"
#import "ParticleSetupCustomization.h"
#import "ParticleConnectingProgressViewController.h"
#import "ParticleSetupCommManager.h"
#import "ParticleSetupPasswordEntryViewController.h"
#import "ParticleSetupCustomization.h"

#ifdef ANALYTICS
#import <SEGAnalytics.h>
#endif

@interface ParticleManualNetworkViewController () <UITextFieldDelegate>
@property(weak, nonatomic) IBOutlet UIImageView *brandImageView;
@property(weak, nonatomic) IBOutlet UIImageView *brandBackgroundImageView;
@property(weak, nonatomic) IBOutlet UITextField *networkNameTextField;
@property(weak, nonatomic) IBOutlet UISwitch *networkRequiresPasswordSwitch;
@property(weak, nonatomic) IBOutlet UIImageView *wifiSymbolImageView;
@property(weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation ParticleManualNetworkViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return ([ParticleSetupCustomization sharedInstance].lightStatusAndNavBar) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // move to super viewdidload?
    self.brandImageView.image = [ParticleSetupCustomization sharedInstance].brandImage;
    self.brandImageView.backgroundColor = [UIColor clearColor];
    self.brandBackgroundImageView.backgroundColor = [ParticleSetupCustomization sharedInstance].brandImageBackgroundColor;
    self.brandBackgroundImageView.image = [ParticleSetupCustomization sharedInstance].brandImageBackgroundImage;


    UIColor *navBarButtonsColor = ([ParticleSetupCustomization sharedInstance].lightStatusAndNavBar) ? [UIColor whiteColor] : [UIColor blackColor];
    [self.backButton setTitleColor:navBarButtonsColor forState:UIControlStateNormal];


    // Trick to add an inset from the left of the text fields
    CGRect viewRect = CGRectMake(0, 0, 10, 32);
    UIView *emptyView = [[UIView alloc] initWithFrame:viewRect];

    self.networkNameTextField.leftView = emptyView;
    self.networkNameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.networkNameTextField.delegate = self;
    self.networkNameTextField.returnKeyType = UIReturnKeyJoin;
    self.networkNameTextField.font = [UIFont fontWithName:[ParticleSetupCustomization sharedInstance].normalTextFontName size:16.0];

    self.networkRequiresPasswordSwitch.onTintColor = [ParticleSetupCustomization sharedInstance].elementBackgroundColor;

    self.wifiSymbolImageView.image = [self.wifiSymbolImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.wifiSymbolImageView.tintColor = [ParticleSetupCustomization sharedInstance].normalTextColor;// elementBackgroundColor;;

    self.backButton.imageView.image = [self.backButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.backButton.imageView.tintColor = navBarButtonsColor;// elementBackgroundColor;;

}

- (void)viewWillAppear:(BOOL)animated {
#ifdef ANALYTICS
    [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_ManualNetworkEntryScreen"];
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.networkNameTextField becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"connect"]) {
        // Get reference to the destination view controller
        ParticleConnectingProgressViewController *vc = [segue destinationViewController];
        vc.networkName = self.networkNameTextField.text;
        vc.channel = @0; // unknown
        vc.security = @(ParticleSetupWifiSecurityTypeOpen);
        vc.password = @""; // non secure network
        vc.deviceID = self.deviceID; // propagate device ID
        vc.needToClaimDevice = self.needToClaimDevice;
    }
    if ([[segue identifier] isEqualToString:@"require_password"]) // prompt user for password
    {
        // Get reference to the destination view controller
        ParticleSetupPasswordEntryViewController *vc = [segue destinationViewController];
        vc.networkName = self.networkNameTextField.text;
        vc.channel = @0; // unknown
        vc.security = @(ParticleSetupWifiSecurityTypeWPA2_AES_PSK); // default
        vc.deviceID = self.deviceID; // propagate device ID
        vc.needToClaimDevice = self.needToClaimDevice;
    }
}


- (IBAction)connectButtonTapped:(id)sender {
    [self trimTextFieldValue:self.networkNameTextField];
    if (![self.networkNameTextField.text isEqualToString:@""]) {
        [self.view endEditing:YES];
        if (self.networkRequiresPasswordSwitch.isOn) {
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_SelectedSecuredNetwork"];
#endif
            [self performSegueWithIdentifier:@"require_password" sender:self];
        } else {
#ifdef ANALYTICS
            [[SEGAnalytics sharedAnalytics] track:@"DeviceSetup_SelectedOpenNetwork"];
#endif
            [self performSegueWithIdentifier:@"connect" sender:self];

        }
    }


}


- (IBAction)cancelButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.networkNameTextField) {
        [self connectButtonTapped:self];
    }

    return YES;
}

@end
