//
//  EventsButton.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 4/1/23.
//

import SwiftUI

struct CustomMenuButton: View {
    
    let mainFont = Font.title.lowercaseSmallCaps()
    let buttonFont = Font.system(.largeTitle, design: .serif, weight: .bold)
    var text: String

    var body: some View {
        ZStack {
            Color(.blue)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.4)
            
            VStack {
                Text(text)
                    .font(.title2)
                    .font(buttonFont)
            }
            //.border(Color.black)
            //.clipShape(Capsule(), style: FillStyle())
            //.cornerRadius(14.0)
            //.padding()
        }
        .clipShape(Capsule(style: .circular), style: FillStyle())
        .cornerRadius(1.0)
        .frame(width: 300, height: 35)
        .padding()
    }
}

struct EventsButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomMenuButton(text: "Text")
    }
}
