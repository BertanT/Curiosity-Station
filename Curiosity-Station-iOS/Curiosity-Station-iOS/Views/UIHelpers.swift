//
//  UIHelpers.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

// Predefining gradients used throughout the Playground to make code cleaner
public extension Gradient {
    // Some hand dandy predefined gradients
    static var tealGradient = Gradient(colors: [UIColor.systemTeal, UIColor.systemGreen].map { Color($0) })
    static var indigoGradient = Gradient(colors: [UIColor.systemIndigo, UIColor.systemTeal].map { Color($0) })
    static var orangeGradient = Gradient(colors: [UIColor.systemOrange, UIColor.systemPink].map { Color($0) })
    static var purpleGradient = Gradient(colors: [Color(UIColor.systemPurple), Color(UIColor.systemPink)])
    static var redGradient = Gradient(colors: [UIColor.systemRed, UIColor.systemPink].map { Color($0) })
}

// A view modifier that enables views to have gradient fills, and adds some shadow too!
fileprivate struct GradientBackground: ViewModifier {
    let gradient: Gradient
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    let glowRadius: CGFloat
    public func body(content: Content) -> some View {
        content
            .overlay(LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint))
            .mask(content)
            .glow(radius: glowRadius)
    }
}

fileprivate struct GradientField: ViewModifier {
    var gradient: Gradient
    var systemImage: String
    var font: Font
    func body(content: Content) -> some View {
        VStack {
            HStack {
                content
                    .font(font)
                    .shadow(radius: 10)
                Image(systemName: systemImage)
                    .font(font)
                    .gradientBackground(gradient: gradient, glowRadius: 0)
            }
            Capsule()
                .frame(height: 4)
                .gradientBackground(gradient: gradient, glowRadius: 0)
        }.shadow(radius: 10)
    }
}

// Turning custom view modifiers to extension functions for them to be used like built-in modifier
// Example: ".myModifier()" instead of ".modifier(MyModifier())"
public extension View {
    func gradientBackground(gradient: Gradient, startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing, glowRadius: CGFloat = 10) -> some View {
        self.modifier(GradientBackground(gradient: gradient, startPoint: startPoint, endPoint: endPoint, glowRadius: glowRadius))
    }
    
    // I love this! this is the colorful glow that I wrote about in the essay
    // Inspired by the album artwork glow on Apple Music!
    func glow(radius: CGFloat = 10) -> some View {
        ZStack {
            // Don't add an overlay if the radius is set to 0, it can look weird
            if radius != 0 {
                self.overlay(self.blur(radius: radius))
            }
            self
        }
    }
}

public extension TextField {
    func gradientField(gradient: Gradient, systemImage: String, font: Font = .title2) -> some View {
        self.modifier(GradientField(gradient: gradient, systemImage: systemImage, font: font))
    }
}

public extension SecureField {
    func gradientField(gradient: Gradient, systemImage: String, font: Font = .title2) -> some View {
        self.modifier(GradientField(gradient: gradient, systemImage: systemImage, font: font))
    }
}

// The animated gradient button used all throughout the playground.
// Using ButtonStyle for cleaner code
public struct GradientButtonStyle: ButtonStyle {
    private let gradient: Gradient
    private let disabled: Bool
    
    public init(gradient: Gradient, disabled: Bool = false) {
        self.gradient = gradient
        self.disabled = disabled
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
        // Show gradient only if the button is enabled.
        // Decrease the glow/shadow radius as the button is pressed
            .gradientBackground(gradient: disabled ? Gradient(colors: [.gray]) : gradient, glowRadius: disabled ? 0 : (configuration.isPressed ? 0 : 15))
        // Scale down the button as it is pressed
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
        // A cool bouncing spring animation!
            .animation(.spring(), value: 0.4)
    }
}

struct WDGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
            configuration.content
        }
        .background(Color("WDGroupBoxBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
        .shadow(color: Color("shadowColor"), radius: 5)
    }
}

