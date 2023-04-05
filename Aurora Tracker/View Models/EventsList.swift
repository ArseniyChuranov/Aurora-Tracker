//
//  FactsList.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 3/31/23.
//

import SwiftUI

struct EventsList: View {
    @EnvironmentObject var events: EventModel
    @State private var selectedEvent: Event?
    

    
    var body: some View {
        NavigationView {
            List {
                ForEach(EventModel().events) {event in
                    NavigationLink {
                        EventDetail(event: event)
                    } label: {
                        EventCell(event: event)
                    }
                    .tag(event)
                    
                }
                .listRowBackground(Color(red: 0.008235, green: 0.098039, blue: 0.301961))
            }
            .navigationTitle("Events")
        }
    }
}

struct EventsList_Previews: PreviewProvider {
    static var previews: some View {
        EventsList()
            .environmentObject(EventModel())
            .environment(\.colorScheme, .dark)
    }
}
