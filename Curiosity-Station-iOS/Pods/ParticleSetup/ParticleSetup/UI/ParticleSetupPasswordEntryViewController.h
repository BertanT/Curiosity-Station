//
//  ParticleSetupPasswordEntryViewController.h
//  teacup-ios-app
//
//  Created by Ido on 1/20/15.
//  Copyright (c) 2015 spark. All rights reserved.
//

#import "ParticleSetupUIViewController.h"

@interface ParticleSetupPasswordEntryViewController : ParticleSetupUIViewController
@property(nonatomic, strong) NSString *networkName;
@property(nonatomic, strong) NSString *deviceID;
@property(nonatomic, strong) NSNumber *channel;
@property(nonatomic, strong) NSNumber *security;
@property(nonatomic) BOOL needToClaimDevice;
@end
