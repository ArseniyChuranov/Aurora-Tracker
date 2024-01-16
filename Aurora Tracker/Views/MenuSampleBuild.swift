//
//  MenuSampleBuild.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/13/24.
//

import SwiftUI

struct MenuSampleBuild: View {
    
    /*
     
     Simple plan:
     
     Make 4 elements:
        1. Big button that will lead to the map
        2. button underneath that will show info regarding the forecast. Will show the state after app will get the info.
        3. last button underneath that will manyally queue update. will be able to press only after async function is finished.
        4. info disclamer, stating that internet connection is required to see the latest forecast
     
     application will allow only 1 orientation, which is vertical.
     
     
     */
    
    @State private var isSheetPresented = false
    @State private var isFetchinAurora = false
    @State private var textForButton = "Update Forecast"
    
    @State private var bounds = UIScreen.main.bounds
    
    
    var body: some View {
        
        let width = bounds.width
        let height = bounds.height
        let cellWidth = width * 0.9
        
        NavigationStack {
            VStack {
                ZStack {
                    
                    
                    var centerMapSpacer = cellWidth - cellWidth * 0.5
                    var chevronSpacer = cellWidth - centerMapSpacer - width * 0.4
                    
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(red: 0.05, green: 0.05, blue: 1.0, opacity: 0.5))
                        .frame(maxWidth: cellWidth, maxHeight: 150)
                    
                    HStack {
                        
                        // figure in which direction spacer is working
                        
                        Spacer()
                            .frame(width: width - cellWidth)
                        
                        Text("See Map") // main text
                        
                        Spacer()
                            
                        
                        Image(systemName: "globe")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 50)
                            .foregroundColor(.black)
                            // .padding(.leading)
                        
                        //Spacer()
                        //    .frame(width: chevronSpacer)
                        
                        
                        Image(systemName: "chevron.right")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 10)
                            .foregroundColor(.white)
                        
                        Spacer()
                            .frame(width: width - cellWidth)
                    }
                    .padding(.leading)
                }
                .foregroundColor(.white)
                
                ZStack {
                    
                    var centerSpacer = cellWidth - cellWidth * 0.7
                    
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(red: 0.05, green: 0.05, blue: 1.0, opacity: 0.5))
                        .frame(maxWidth: cellWidth, maxHeight: 150)
                    
                    HStack {
                        
                        Spacer()
                            .frame(width: width - cellWidth)
                        
                        Text("Current Forecast Info")
                        Spacer()
                           
                        
                        Image(systemName: "info.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 50)
                            .foregroundColor(.black)
                        
                        Spacer()
                            .frame(width: width - cellWidth)
                    }
                    .padding()
                }
                .foregroundColor(.white)
                
                ZStack {
                    
                    var centerSpacer = cellWidth - cellWidth * 0.6
                    
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color(red: 0.05, green: 0.05, blue: 1.0, opacity: 0.5))
                        .frame(maxWidth: cellWidth, maxHeight: 150)
                    
                    HStack {
                        Spacer()
                            .frame(width: width - cellWidth)
                        
                        Text("Update Forecast")
                        
                        Spacer()
                        
                        Image(systemName: "arrow.clockwise.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 50)
                            .foregroundColor(.black)
                        
                        Spacer()
                            .frame(width: width - cellWidth)
                        
                       
                    }
                    .padding()
                }
                .foregroundColor(.white)
                
                Text("Note: Internet connection is required to observe latest Aurora Forecast.")
                    .italic()
                    .padding()
                
            }
            .sheet(isPresented: $isSheetPresented) {
                // input info about current aurora forecast.
                // maybe add more info? if avaliable? or strucure it? idk. maybe its good for now
                VStack {
                    Text("Forecast Time")
                    Text("sample text")
                        .font(.title2)
                    Text("Observation Time")
                    Text("another sample text")
                        .font(.title2)
                }
                .presentationDetents([.medium])
                .padding()
            }
        }
    }
    
}

#Preview {
    MenuSampleBuild()
}




/*
 
 // NavigationLink(destination: SheetAuroraInfo)
 
 MainMenuButton()
     .scaledToFill()
 
 
 Button (action: {
     isSheetPresented = true
 }) {
     Text("Info")
 }
 
 
 
 CustomMenuButton(text: "Updating")
 
 
 Button {
     // Make this button do 2 things, update aurora and show status.
     // loading/updating $ update A
     Task {
         if !isFetchinAurora {
             
             // maybe check for internet connection? and say "Cant update"
             
             // await fetchAurora()
             textForButton = "Updating..."
             // maybe have a 2 second "Forecast Updated!" ""
         }
     }
     
 } label: {
     Text(textForButton)
 }
 
 Text("Internet connection is required to observe latest Aurora Forecast.")
     .padding(.bottom)
 
 */
