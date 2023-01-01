//
//  UserData.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import Foundation
import Network
import SwiftUI
import Particle_SDK

@MainActor
final class SharedCloud: ObservableObject {
    @Published var userAuthenticated: Bool = ParticleCloud.sharedInstance().isAuthenticated
    @Published private(set) var networkConnected = true
    @AppStorage("savedDeviceID") private var savedDeviceID: String?
    
    var weatherStation: WeatherStation? {
        willSet {
            objectWillChange.send()
            savedDeviceID = newValue?.deviceID
        }
    }
    
    enum CloudError: Error, LocalizedError {
        case loginError, cannotGetDevices, noSavedDevice
        
        var errorDescription: String? {
            switch self {
            case .loginError:
                return "Can't login to Particle Cloud. Please check your credentials and try again!"
            case .cannotGetDevices:
                return "An unexpected error occurred while getting the list of your devices. Please try again."
            case .noSavedDevice:
                return "It's great to see you in here! Please select your station to continue."
            }
        }
    }
    
    private let queue = DispatchQueue(label: "Monitor")
    
    init() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.networkConnected = true
            }
            if path.status == .unsatisfied {
                self.networkConnected = false
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    func logIn(username: String, password: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            ParticleCloud.sharedInstance().login(withUser: username, password: password) { error in
                if let _ = error {
                    continuation.resume(throwing: CloudError.loginError)
                }else {
                    self.userAuthenticated = true
                    continuation.resume()
                }
            }
        }
    }
    
    func logOut() {
        ParticleCloud.sharedInstance().logout()
        weatherStation = nil
        savedDeviceID = nil
        userAuthenticated = false
    }
    
    func initializeStationFromSavedDevice() async throws {
        guard let savedDeviceID = savedDeviceID else {
            throw CloudError.noSavedDevice
        }
        
        self.weatherStation = try await WeatherStation(deviceID: savedDeviceID)
    }
    
    func isDeviceSavedDevice(deviceID: String) -> Bool {
        return savedDeviceID == deviceID
    }
    
    func getUserDevices() async throws -> [ParticleDevice] {
        return try await withCheckedThrowingContinuation { continuation in
            ParticleCloud.sharedInstance().getDevices { devices, error in
                if let devices = devices {
                    continuation.resume(returning: devices)
                }else {
                    continuation.resume(throwing: CloudError.cannotGetDevices)
                }
            }
        }
    }
}
