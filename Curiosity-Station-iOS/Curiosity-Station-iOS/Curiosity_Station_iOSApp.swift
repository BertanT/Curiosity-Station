//
//  Curiosity_Station_iOSApp.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

@main
struct Curiosity_Station_iOSApp: App {
    @ObservedObject private var sharedCloud = SharedCloud()
    
    var body: some Scene {
        WindowGroup {
            if !sharedCloud.networkConnected && sharedCloud.weatherStation?.latestMeasurements == nil {
                DisconnectedScreen(message: "An active network connection is needed in order to sign in; for now, here is a cute puppy.")
            }else {
                NavigationView {
                    LoginScreen()
                        .environmentObject(sharedCloud)
                }.navigationViewStyle(StackNavigationViewStyle())
            }
            
        }
    }
}
