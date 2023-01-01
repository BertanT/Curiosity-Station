//
//  ParticleSetupUIButton.m
//  teacup-ios-app
//
//  Created by Ido on 1/16/15.
//  Copyright (c) 2015 particle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParticleSetupUIButton.h"
#import "ParticleSetupCustomization.h"

@implementation ParticleSetupUIButton

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addTarget:self action:@selector(didTouchButton:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(didUntouchButton:) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(didUntouchButton:) forControlEvents:UIControlEventTouchUpInside];


    }
    return self;
}

- (UIColor *)darkerColorForColor:(UIColor *)c // TODO: category for UIColor?
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.1, 0.0)
                               green:MAX(g - 0.1, 0.0)
                                blue:MAX(b - 0.1, 0.0)
                               alpha:a];
    return nil;
}


- (void)didTouchButton:(id)sender {
    if ([self.type isEqualToString:@"action"]) {
        UIColor *color = [ParticleSetupCustomization sharedInstance].elementBackgroundColor;
        self.backgroundColor = [self darkerColorForColor:color];
        self.layer.shadowOpacity = 0;

    }
    [self setNeedsDisplay];

}

- (void)didUntouchButton:(id)sender {
    if ([self.type isEqualToString:@"action"]) {
        self.backgroundColor = [ParticleSetupCustomization sharedInstance].elementBackgroundColor;
        self.layer.shadowOpacity = 0.3;

    }
    [self setNeedsDisplay];

}


- (void)setType:(NSString *)type {
    _type = type;

    if (([type isEqualToString:@"action"]) || ([type isEqualToString:@"primary"])) {
        UIFont *boldFont = [UIFont fontWithName:[ParticleSetupCustomization sharedInstance].boldTextFontName size:self.titleLabel.font.pointSize + [ParticleSetupCustomization sharedInstance].fontSizeOffset];
        self.titleLabel.font = boldFont;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [ParticleSetupCustomization sharedInstance].elementBackgroundColor;
        self.layer.cornerRadius = 3.0;
        [self setTitleColor:[ParticleSetupCustomization sharedInstance].elementTextColor forState:UIControlStateNormal];

        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 2;
        self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    }

    if ([type isEqualToString:@"link"]) {
        NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:[self titleForState:UIControlStateNormal]];
        [s addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0, [s length])];
        [UIView performWithoutAnimation:^{
            [self setAttributedTitle:s forState:UIControlStateNormal];
            [self layoutIfNeeded];
        }];

        self.titleLabel.textColor = [ParticleSetupCustomization sharedInstance].linkTextColor;
        [self setTitleColor:[ParticleSetupCustomization sharedInstance].linkTextColor forState:UIControlStateNormal];

        self.titleLabel.font = [UIFont fontWithName:[ParticleSetupCustomization sharedInstance].normalTextFontName size:self.titleLabel.font.pointSize + [ParticleSetupCustomization sharedInstance].fontSizeOffset];
        self.backgroundColor = [UIColor clearColor];
    }


    if ([type isEqualToString:@"secondary"]) {

        UIFont *boldFont = [UIFont fontWithName:[ParticleSetupCustomization sharedInstance].boldTextFontName size:self.titleLabel.font.pointSize + [ParticleSetupCustomization sharedInstance].fontSizeOffset];
        self.titleLabel.font = boldFont;
        [self setTitleColor:[ParticleSetupCustomization sharedInstance].normalTextColor forState:UIControlStateNormal];

        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderColor = [ParticleSetupCustomization sharedInstance].normalTextColor.CGColor;
        self.layer.backgroundColor = [UIColor clearColor].CGColor;
        self.layer.cornerRadius = 3.0;
        self.layer.borderWidth = 2.0;
    }

    [self setNeedsDisplay];
    [self layoutIfNeeded];
}

- (void)setTitle:(nullable NSString *)title forState:(UIControlState)state {
    [super setTitle:title forState:state];

    if (self.type != nil && [self.type isEqualToString:@"link"]) {
        NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:[self titleForState:UIControlStateNormal]];
        [s addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0, [s length])];
        [self setAttributedTitle:s forState:UIControlStateNormal];
    }
}


- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];

    if (enabled) {
        self.alpha = 1;
    } else {
        self.alpha = 0.5;
    }
    [self setNeedsDisplay];

}

@end
