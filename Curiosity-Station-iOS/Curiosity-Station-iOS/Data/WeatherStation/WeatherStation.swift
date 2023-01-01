//
//  WeatherStation.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import Foundation
import Particle_SDK

final class WeatherStation {
    var latestMeasurements: WeatherData?
    var newMeasurementTrackingEnabled = false
    let deviceID: String
    
    private let device: ParticleDevice
    private var newMeasurementEventID: Any?
    
    private let compatibleFirmwareIDPrefix = "CuriosityStationBeta1"
    private let correctVariableNames = (WeatherData.WeatherMeasurement.allCases.map { $0.rawValue } + ["firmwareID", "hardwareFailure"]).sorted()
    
    enum DeviceError: Error, LocalizedError {
        case cannotConnectDevice, deviceOffline, invalidConfiguration, hardwareFailure, cannotGetVariable, invalidData, cannotEnableAutoRefresh, cannotSetSignaling, otherCloudCommunicationError
        var errorDescription: String? {
            switch self {
            case .deviceOffline:
                return "This device seems to be offline. Please try again after making sure it is powered on and connected."
            case .invalidConfiguration:
                return "It seems like this device is not running the Curiosity Station firmware. Please flash the latest firmware to your device and try again."
            case .hardwareFailure:
                return "Your station has unfortunately reported that one or more sensors onboard are not working properly. Please check the wiring and try again. If the issue persists, your sensors may be broken and may need replacing.\n\nTip: Connect your device to a serial monitor for easier debugging."
            case .cannotGetVariable:
                return "An unexpected error occurred while reading data from your station. Please try again"
            case .invalidData:
                return "The data received from your station seems to be invalid, please check firmware integrity and try again."
            case .cannotEnableAutoRefresh:
                return "Couldn't enable auto refresh due to an unexpected error. We'll try again the next time you open the app."
            case .cannotSetSignaling:
                return "Couldn't set rainbow signaling due to an unexpected error, please try again."
            default:
                return "An unexpected error occurred while communicating with your station. Please try again"
            }
        }
    }
    
    init(device: ParticleDevice) async throws {
        self.device = device
        self.deviceID = device.id
        try await checkDevice()
    }
    
    init(deviceID: String) async throws {
        self.device = try await withCheckedThrowingContinuation { continuation in
            ParticleCloud.sharedInstance().getDevice(deviceID) { device, _ in
                if let device = device {
                    continuation.resume(returning: device)
                }else {
                    continuation.resume(throwing: DeviceError.cannotConnectDevice)
                }
            }
        }
        
        self.deviceID = device.id
        try await checkDevice()
    }
    
    private func deviceCheckStepOne() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            device.refresh { error in
                if let _ = error {
                    continuation.resume(throwing: DeviceError.otherCloudCommunicationError)
                }else {
                    if self.device.connected {
                        if self.device.variables.keys.sorted() == self.correctVariableNames {
                            continuation.resume()
                        }else {
                            continuation.resume(throwing: DeviceError.invalidConfiguration)
                        }
                        
                    }else {
                        continuation.resume(throwing: DeviceError.deviceOffline)
                    }
                }
            }
        }
    }
    
    private func checkDevice() async throws {
        try await deviceCheckStepOne()
        let firmwareID = try await getCloudVariable(named: "firmwareID") as? NSString
        if !(firmwareID?.hasPrefix(compatibleFirmwareIDPrefix) ?? false) {
            throw DeviceError.invalidConfiguration
        }
        let hardwareFailureReported = try await getCloudVariable(named: "hardwareFailure") as? Bool
        if hardwareFailureReported == true {
            throw DeviceError.hardwareFailure
        }
    }
    
    func enableNewMeasurementTracking(onNewMeasurement: @escaping () -> Void) async throws {
        try await checkDevice()
        guard let eventID = device.subscribeToEvents(withPrefix: "newMeasurement", handler: { _, error in
            if error == nil {
                onNewMeasurement()
            }
        })else {
            throw DeviceError.cannotEnableAutoRefresh
        }
        newMeasurementEventID = eventID
        newMeasurementTrackingEnabled = true
    }
    
    func disableAutoRefresh() {
        if let eventId = newMeasurementEventID {
            ParticleCloud.sharedInstance().unsubscribeFromEvent(withID: eventId)
            newMeasurementEventID = nil
            newMeasurementTrackingEnabled = false
        }
    }
    
    private func setSignaling(enable: Bool) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            device.signal(enable) { error in
                if let _ = error {
                    continuation.resume(throwing: DeviceError.cannotSetSignaling)
                }else {
                    continuation.resume()
                }
            }
        }
    }
    
    func setRainbowSignal(enable: Bool) async throws {
        try await checkDevice()
        try await setSignaling(enable: enable)
    }
    
    private func getCloudVariable(named: String) async throws -> Any {
        try Task.checkCancellation()
        return try await withCheckedThrowingContinuation { continuation in
            device.getVariable(named) { data, error in
                if let data = data {
                    continuation.resume(returning: data)
                }else {
                    continuation.resume(throwing: DeviceError.cannotGetVariable)
                }
            }
        }
    }
    
    func refreshWeatherData() async throws {
        try await checkDevice()
        
        let newMeasurements = try await withThrowingTaskGroup(of: (WeatherData.WeatherMeasurement, NSNumber).self, returning: [WeatherData.WeatherMeasurement: NSNumber].self) { taskGroup in
            for measurement in WeatherData.WeatherMeasurement.allCases {
                taskGroup.addTask(priority: .high) {
                    guard let value = try await self.getCloudVariable(named: measurement.rawValue) as? NSNumber else {
                        throw DeviceError.invalidData
                    }
                    return (measurement, value)
                }
            }
            
            var outputMeasurements = [WeatherData.WeatherMeasurement: NSNumber]()
            
            for try await measurement in taskGroup {
                outputMeasurements[measurement.0] = measurement.1
            }
            
            return outputMeasurements
        }
        do {
            latestMeasurements = try WeatherData(dataDict: newMeasurements)
        }catch {
            throw DeviceError.invalidData
        }
    }
}
