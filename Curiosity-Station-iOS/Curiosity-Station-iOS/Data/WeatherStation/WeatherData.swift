//
//  WeatherData.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import Foundation

struct WeatherData: Equatable {
    private(set) var updateTime: Date
    private(set) var batteryPercentage: Int
    private(set) var temperatureC: Measurement<UnitTemperature>
    private(set) var relativeHumidity: Int
    private(set) var barometricPressureMB: Measurement<UnitPressure>
    private(set) var estimateAltitudeM: Measurement<UnitLength>
    private(set) var uvIndex: Int
    private(set) var lightIntensityPercentage: Int
    private(set) var windSpeedKMH: Measurement<UnitSpeed>
    private(set) var windDirectionDeg: Measurement<UnitAngle>
    private(set) var windDirectionCardinal: CardinalDirection = .n
    private(set) var rainfallMM: Measurement<UnitLength>
    
    enum WeatherMeasurement: String, CaseIterable { case updateTimeEpoch, batteryPercentage, temperatureC, relativeHumidity, barometricPressureMB, estimateAltitudeM, uvIndex, lightPercentage, windSpeedKMH, windDirectionDeg, rainfallMM }
    
    enum DataError: Error { case incompleteData }
    
    init(dataDict: [WeatherMeasurement: NSNumber]) throws {
        guard
            let updateTimeEpoch = dataDict[.updateTimeEpoch],
            let batteryPercentage = dataDict[.batteryPercentage],
            let temperatureC = dataDict[.temperatureC],
            let relativeHumidity = dataDict[.relativeHumidity],
            let barometricPressureMB = dataDict[.barometricPressureMB],
            let estimateAltitudeM = dataDict[.estimateAltitudeM],
            let uvIndex = dataDict[.uvIndex],
            let lightPercentage = dataDict[.lightPercentage],
            let windSpeedKMH = dataDict[.windSpeedKMH],
            let windDirectionDeg = dataDict[.windDirectionDeg],
            let rainfallMM = dataDict[.rainfallMM]
        else {
            throw DataError.incompleteData
        }
        
        self.updateTime = Date(timeIntervalSince1970: updateTimeEpoch.doubleValue)
        self.batteryPercentage = batteryPercentage.intValue
        self.temperatureC = Measurement(value: temperatureC.doubleValue, unit: UnitTemperature.celsius)
        self.relativeHumidity = relativeHumidity.intValue
        self.barometricPressureMB = Measurement(value: barometricPressureMB.doubleValue, unit: UnitPressure.millibars)
        self.estimateAltitudeM = Measurement(value: estimateAltitudeM.doubleValue, unit: UnitLength.meters)
        self.uvIndex = uvIndex.intValue
        self.lightIntensityPercentage = lightPercentage.intValue
        self.windSpeedKMH = Measurement(value: windSpeedKMH.doubleValue, unit: UnitSpeed.kilometersPerHour)
        self.windDirectionDeg = Measurement(value: windDirectionDeg.doubleValue, unit: UnitAngle.degrees)
        self.windDirectionCardinal = try CardinalDirection(degrees: windDirectionDeg.doubleValue)
        self.rainfallMM = Measurement(value: rainfallMM.doubleValue, unit: UnitLength.millimeters)
    }
}
