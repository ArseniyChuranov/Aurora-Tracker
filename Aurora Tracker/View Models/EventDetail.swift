//
//  EventDetail.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 4/1/23.
//

import SwiftUI

struct EventDetail: View {
    var event: Event
    
    var body: some View {
        VStack {
            Text(event.description)
                .padding(.top)
        }
    }
}

struct EventDetail_Previews: PreviewProvider {
    
    static var events = EventModel().events
    
    static var previews: some View {
        EventDetail(event: events[0])
    }
}
