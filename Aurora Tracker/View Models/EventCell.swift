//
//  FactsCell.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 3/31/23.
//

import SwiftUI

struct EventCell: View {
    var event: Event
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(red: 0.380392, green: 0.380392, blue: 0.380392, opacity: 0.5))
                    .frame(width: 62, height: 62)
                event.icon
                    .resizable()
                    .frame(width: 60, height: 60)
                    //.border(Color.gray, width: 3)
                    .cornerRadius(9)
                    //.cornerRadius(8)
            }
            VStack(alignment: .leading) {
                Text(event.name)
                    .font(.title2)
                Text(event.subtitle)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.552941, green: 0.552941, blue: 0.552941))
            }
        }
        .padding(.vertical, 4)
    }
}

struct FactsCell_Previews: PreviewProvider {
    static var events = EventModel().events
    
    static var previews: some View {
        EventCell(event: events[0])
            .previewLayout(.fixed(width: 300, height: 70))
    }
}
