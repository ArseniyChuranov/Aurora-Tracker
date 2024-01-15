//
//  MainMenuButton.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 3/18/23.
//

import SwiftUI

struct MainMenuButton: View {
    var body: some View {
        VStack(alignment: .center) {
            // create a simple button, with some edges
            Text("See Map")
                .font(.title)
        }
        .padding()
        .foregroundColor(.blue)
    }
}

struct MainMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuButton()
            .background(.yellow)
            .previewLayout(.fixed(width: 400, height: 60))
    }
}
