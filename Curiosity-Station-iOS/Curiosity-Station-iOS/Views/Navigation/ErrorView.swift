//
//  DeviceErrorView.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

struct ErrorView: View {
    let errorTitle: String
    let errorDescription: String
    let customImage: Image?
    let buttonTitle: String
    let buttonAction: () -> Void
    
    init(errorTitle: String, errorDescription: String, customErrorImage: Image? = nil, buttonTitle: String = "Try Again!", buttonAction: @escaping () -> Void) {
        self.errorTitle = errorTitle
        self.errorDescription = errorDescription
        self.customImage = customErrorImage
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
    
    
    var body: some View {
        VStack {
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.medium)
                .padding(.bottom, 1)
            Text(errorDescription)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button(action: buttonAction) {
                Text(buttonTitle)
            }
            .buttonStyle(GradientButtonStyle(gradient: .indigoGradient))
            .padding(.top, 5)
            Spacer()
            if let image = customImage {
                image
                    .resizable()
                    .scaledToFit()
                    .padding()
                Spacer()
                Spacer()
            }else {
                Image("deviceError")
                    .resizable()
                    .scaledToFit()
            }
        }
        .padding(.top)
        .edgesIgnoringSafeArea(customImage == nil ? .bottom : [])
    }
}

struct DeviceErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(errorTitle: "Exaple Error!", errorDescription: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus non urna eu diam sollicitudin sagittis. Vivamus quis congue nibh, pharetra sagittis elit.", buttonTitle: "Fix Error!") { }
        ErrorView(errorTitle: "Exaple Error!", errorDescription: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus non urna eu diam sollicitudin sagittis. Vivamus quis congue nibh, pharetra sagittis elit.", customErrorImage: Image("noDevices")) { }
    }
}
