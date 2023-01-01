//
//  Compass.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

struct Compass: View {
    let angle: Angle
    var body: some View {
        ZStack {
            Image("compassFace")
                .resizable()
                .shadow(color: Color("shadowColor"), radius: 5)
            Image("compassNeedle")
                .resizable()
                .rotationEffect(self.angle)
        }.scaledToFit()
    }
}

struct Compass_Previews: PreviewProvider {
    static var previews: some View {
        Compass(angle: Angle(degrees: 0))
            .padding()
    }
}
