//
//  WeatherLabel.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

struct WeatherLabel: View {
    let title: String
    let description: String?
    let systemImage: String
    let font: Font?
    let symbolColor: Color?
    
    private let formatter = MeasurementFormatter()
    
    init(title: String, description: String? = "", systemImage: String, font: Font = .title3, symbolColor: Color? = nil) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.font = font
        self.symbolColor = symbolColor
    }
    
    var body: some View {
        HStack {
            Label(title: {
                Text(self.title + ":")
                    .bold()
                    .font(self.font)
                    .allowsTightening(true)
                    .shadow(color: Color("shadowColor"), radius: 5)
            }, icon: {
                Image(systemName: self.systemImage)
                    .font(self.font)
                    .foregroundColor(self.symbolColor)
                    .frame(width: 20, height: 20)
                    .shadow(color: self.symbolColor ?? Color("shadowColor"), radius: 5)
            })
            Text(description ?? "Error :(")
                .font(font)
                .allowsTightening(true)
                .shadow(color: Color("shadowColor"), radius: 5)
        }
    }
}
struct WeatherLabel_Previews: PreviewProvider {
    static var previews: some View {
        WeatherLabel(title: "Rainfall", description: "4mm",systemImage: "cloud.rain", symbolColor: Color(UIColor.systemTeal))
    }
}
