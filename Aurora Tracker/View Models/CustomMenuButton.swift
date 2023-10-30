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
    @Binding var text: String

    var body: some View {
        VStack {
            Text(text)
                .font(.title2)
                .font(buttonFont)
        }
        .padding()
        .foregroundColor(.blue)
        .cornerRadius(14.0)
    }
}

struct EventsButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomMenuButton(text: .constant("Text"))
    }
}
