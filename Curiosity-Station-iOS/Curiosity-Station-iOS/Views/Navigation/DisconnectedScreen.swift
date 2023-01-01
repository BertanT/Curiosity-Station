//
//  DisconnectedView.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

struct DisconnectedScreen: View {
    var message: String
    var body: some View {
        VStack {
            Spacer()
            Text("Network Disconnected")
                .font(.largeTitle)
                .bold()
            Text(self.message)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Image("networkError")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width - UIScreen.main.bounds.width / 10)
        }
    }
}

struct DisconnectedView_Previews: PreviewProvider {
    static var previews: some View {
        DisconnectedScreen(message: "Not connected")
    }
}
