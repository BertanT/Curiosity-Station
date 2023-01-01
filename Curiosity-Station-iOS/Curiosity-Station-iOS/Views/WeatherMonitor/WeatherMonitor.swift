//
//  MonitorView.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

// UI struct for presenting weather data to the user
struct WeatherMonitor: View {
    private var data: WeatherData
    private let measurementFormatter: MeasurementFormatter
    private let providedValueMeasurementFormatter: MeasurementFormatter
    private let roundedAltitude: Measurement<UnitLength>
    
    private let dateFormatter = DateFormatter()
    
    private let groupBoxWidth = UIScreen.main.bounds.width * 0.85
    private let screenHeight = UIScreen.main.bounds.height
    
    var usingMetric: Bool
    
    init(data: WeatherData) {
        self.data = data
        
        // Create a custom number formatter to allow only one decimal point and assign it to the measurementformatter
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        
        measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter = numberFormatter
        measurementFormatter.unitOptions = .naturalScale
        measurementFormatter.locale = NSLocale.autoupdatingCurrent
        
        providedValueMeasurementFormatter = MeasurementFormatter()
        providedValueMeasurementFormatter.numberFormatter = numberFormatter
        providedValueMeasurementFormatter.unitOptions = .providedUnit
        
        usingMetric = measurementFormatter.locale.usesMetricSystem
        
        let estimatedAltitudeValue = data.estimateAltitudeM.converted(to: usingMetric ? .meters : .feet).value
        let roundedAltitudeValue = Double((estimatedAltitudeValue / Double(50)).rounded()) * 50
        self.roundedAltitude = Measurement(value: roundedAltitudeValue, unit: usingMetric ? .meters : .feet)
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.locale = NSLocale.autoupdatingCurrent
        dateFormatter.doesRelativeDateFormatting = true
    }
    
    var body: some View {
        VStack {
            GroupBox {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        WeatherLabel(title: "Wind", systemImage: "wind", symbolColor: Color(UIColor.systemTeal))
                        Spacer()
                        Text("\(data.windDirectionCardinal.rawValue), \(measurementFormatter.string(for: data.windSpeedKMH) ?? "Error :(")")
                            .font(.title3)
                            .shadow(color: Color("shadowColor"), radius: 5)
                        Spacer()
                    }
                    Spacer()
                    Compass(angle: Angle(degrees: data.windDirectionDeg.value))
                }
                .frame(width: groupBoxWidth, height: screenHeight * 0.15)
                .padding(22)
            }
            .groupBoxStyle(WDGroupBoxStyle())
            .padding(.vertical)
            
            GroupBox {
                HStack {
                    VStack {
                        WeatherLabel(title: "Time Measured", systemImage: "clock", symbolColor: Color(UIColor.systemYellow))
                            .padding(.bottom, 7)
                        if let date = data.updateTime {
                            Text(date, formatter: dateFormatter)
                        }else {
                            Text("Error :(")
                                .font(.title3)
                                .shadow(color: Color("shadowColor"), radius: 5)
                        }
                    }
                    Spacer()
                    Divider()
                    Spacer()
                    VStack {
                        WeatherLabel(title: "Battery", systemImage: batterySymbolName(), symbolColor: batterySymbolColor())
                            .padding(.bottom, 7)
                        if let percentageStr = data.batteryPercentage.description {
                            Text("\(percentageStr)%")
                                .font(.title3)
                                .shadow(color: Color("shadowColor"), radius: 5)
                        }else {
                            Text("Error :(")
                                .font(.title3)
                                .shadow(color: Color("shadowColor"), radius: 5)
                        }
                    }
                }
                .frame(width: groupBoxWidth, height: screenHeight * 0.10)
                .padding(22)
            }
            .groupBoxStyle(WDGroupBoxStyle())
            .padding(.bottom)
            
            GroupBox {
                HStack {
                    VStack(alignment: .leading, spacing: 7) {
                        WeatherLabel(title: "Temperature", description: measurementFormatter.string(for: data.temperatureC), systemImage: "thermometer", symbolColor: .red)
                        WeatherLabel(title: "Light", description: ("\(data.lightIntensityPercentage.description)%"), systemImage: "lightbulb.fill", symbolColor: Color(UIColor.systemOrange))
                        WeatherLabel(title: "UV Index", description: data.uvIndex.description, systemImage: "sun.max.fill", symbolColor: Color(UIColor.systemYellow))
                        WeatherLabel(title: "Pressure", description: measurementFormatter.string(for: data.barometricPressureMB), systemImage: "arrow.down.forward.and.arrow.up.backward", symbolColor: Color(UIColor.systemGreen))
                        WeatherLabel(title: "Humidity", description:("\(data.relativeHumidity.description)%"), systemImage: "drop.fill", symbolColor: Color(UIColor.systemTeal))
                        WeatherLabel(title: "Rainfall", description: providedValueMeasurementFormatter.string(for: data.rainfallMM.converted(to: usingMetric ? .millimeters : .inches)), systemImage: "cloud.rain.fill", symbolColor: Color(UIColor.systemBlue))
                        WeatherLabel(title: "Estimated Altitude", description: providedValueMeasurementFormatter.string(for: roundedAltitude), systemImage: "photo", symbolColor: Color(UIColor.systemPink))
                    }
                    Spacer()
                }
                .frame(width: groupBoxWidth, height: screenHeight * 0.3)
                .padding(22)
            }
            .groupBoxStyle(WDGroupBoxStyle())
        }
    }
    
    func batterySymbolName() -> String {
        switch data.batteryPercentage {
        case 51...75:
            return "battery.75"
        case 26...50:
            return "battery.50"
        case 1...25:
            return "battery.25"
        case 0:
            return "battery.0"
        default:
            return "battery.100"
        }
    }
    
    func batterySymbolColor() -> Color {
        switch data.batteryPercentage {
        case 11...25:
            return .orange
        case 0...10:
            return .red
        default:
            return .green
        }
    }
}

// TODO: Fix previews

//struct MonitorView_Previews: PreviewProvider {
//    static var previews: some View {
//        MonitorView(data: previewWeatherData)
//            .preferredColorScheme(.light)
//        MonitorView(data: previewWeatherData)
//            .preferredColorScheme(.dark)
//    }
//}
