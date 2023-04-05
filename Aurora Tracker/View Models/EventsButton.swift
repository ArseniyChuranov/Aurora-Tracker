//
//  EventsButton.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 4/1/23.
//

import SwiftUI

struct EventsButton: View {
    var body: some View {
        VStack {
            Text("Events")
                .font(.title2)
        }
        .padding()
        .foregroundColor(.blue)
    }
}

struct EventsButton_Previews: PreviewProvider {
    static var previews: some View {
        EventsButton()
    }
}
