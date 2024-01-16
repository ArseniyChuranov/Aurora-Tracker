//
//  MainMenu.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 3/18/23.
//

import SwiftUI
import MapKit
import UserNotifications
import Network

struct MainMenu: View {
    
    @Binding var auroraList: [IndividualAuroraSpot]
    @EnvironmentObject var provider: AuroraProvider
    @EnvironmentObject var eventModel: EventModel
    
    @State private var error: AuroraError?
    @State private var hasError = false
    
    @State private var infoList: [String] = ["0", "1"]
    
    @State private var isSheetPresented = false
    @State private var isFetchinAurora = false
    @State private var connectionAvaliable = false
    
    @State private var textForButton = "Update Forecast"
    @State private var forecastInfo = "Current Forecast Info"
    
    @State private var fistAuroraFetched = false
    
    var body: some View {
        
        GeometryReader { geometry in
            // make sure that at least once aurora is updated.
                
                NavigationStack {
                    
                    VStack {
                        NavigationLink(destination:
                                        AuroraMapViewLink(forecastTime: $infoList[0],
                                                        observationTime: $infoList[1])) {
                            ZStack {
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color(red: 0.05, green: 0.05, blue: 1.0, opacity: 0.5))
                                    .frame(maxWidth: geometry.size.width * 0.9, maxHeight: 200)
                                
                                HStack {
                                    Spacer()
                                        .frame(width: geometry.size.width - geometry.size.width * 0.9)
                                    
                                    Text("See Map")
                                    
                                    Spacer()
                                    
                                    Image(systemName: "globe")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 50)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 10)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                        .frame(width: geometry.size.width - geometry.size.width * 0.9)
                                }
                                .padding()
                            }
                            .foregroundColor(.white)
                        }
                        
                        Button {
                            if !isSheetPresented {
                                isSheetPresented = true
                            }
                            
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color(red: 0.05, green: 0.05, blue: 1.0, opacity: 0.5))
                                    .frame(maxWidth: geometry.size.width * 0.9, maxHeight: 100)
                                
                                HStack {
                                    Spacer()
                                        .frame(width: geometry.size.width - geometry.size.width * 0.9)
                                    
                                    Text(forecastInfo)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "info.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 50)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                        .frame(width: geometry.size.width - geometry.size.width * 0.9)
                                }
                                .padding()
                            }
                            .foregroundColor(.white)
                        }
                
                        // forecast update button.
                        Button {
                            Task {
                                if !isFetchinAurora {
                                    textForButton = "Updating..."
                                    await fetchAurora()
                                    textForButton = "Update Forecast"
                                }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color(red: 0.05, green: 0.05, blue: 1.0, opacity: 0.5))
                                    .frame(maxWidth: geometry.size.width * 0.9, maxHeight: 100)
                                
                                HStack {
                                    Spacer()
                                        .frame(width: geometry.size.width - geometry.size.width * 0.9)
                                    
                                    Text(textForButton)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.clockwise.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 50)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                        .frame(width: geometry.size.width - geometry.size.width * 0.9)
                                }
                                .padding()
                            }
                            .foregroundColor(.white)

                        }
                        
                        Text("Note: Internet connection is required to observe latest Aurora Forecast.")
                            .italic()
                            .padding()
                    }
                    .sheet(isPresented: $isSheetPresented) {
                        // input info about current aurora.
                        VStack {
                            Text("Forecast Time")
                            Text(provider.aurora.forecastTime)
                                .font(.title2)
                            Text("Observation Time")
                            Text(provider.aurora.observationTime)
                                .font(.title2)
                        }
                        .presentationDetents([.medium])
                        .padding()
                    }
            }
            .task {
                
                if !fistAuroraFetched {
                    await fetchAurora()
                    fistAuroraFetched = true
                }
                
                // should work on startup
                
                // if no internet?
                
                // await fetchAurora()
            }
        }
    }
}


extension MainMenu {
    
    func fetchAurora() async {
        do {
            
//            Actual Data from Database online
            
            // textForButton = "loading"
            
            print("starting aurora")
            
            isFetchinAurora = true
            try await provider.fetchAurora()
            
            print("Aurora done")
            
//             Sample Data
            
//     
//            let downloader = TestDownloader()
//            let client = AuroraClient(downloader: downloader)
//            let aurora = try await client.aurora
            
            
            // not used // newList = aurora.coordinates

            
        } catch {
            self.error = error as? AuroraError ?? .unexpectedError(error: error)
            self.hasError = true
        }
        
        isFetchinAurora = false
        // textForButton = "Get new data!"
    }
    
}

/*

 struct MainMenu_Previews: PreviewProvider {
 // doesn't work
 static var auroraPreview = IndividualAuroraSpot.preview
 
 static var previews: some View {
     MainMenu(auroraList: .constant(auroraPreview))
         .environmentObject(EventModel())
         .environmentObject(AuroraProvider(client: AuroraClient(downloader: TestDownloader())))
         // .environment(\.colorScheme, .dark)
    }
 }


 */

/*
 
 import SwiftUI
 import MapKit
 import UserNotifications

 struct MainMenu: View {
     
     @Binding var auroraList: [IndividualAuroraSpot]
     @EnvironmentObject var provider: AuroraProvider
     @EnvironmentObject var eventModel: EventModel
     
     @State private var error: AuroraError?
     @State private var hasError = false
     
     @State private var infoList: [String] = ["0", "1"]
     
     @State private var isSheetPresented = false
     @State private var isFetchinAurora = false
     
     @State private var textForButton = "Get new data!"
     
     var body: some View {
         
         
         // Create a sample data set to test rectangle functions and overlays, make colors simple.
         
         /*
          
          Create a menu view, with a button that will navigate to the map.
          
          Button {
              
              //  simple button to fetch new aurora. play with labels
              
              
              Task {
                  if !isFetchinAurora {
                      await fetchAurora()
                      
                      infoList[0] = provider.aurora.forecastTime
                      infoList[1] = provider.aurora.observationTime
                  }
              }
              
          } label: {
              Text(textForButton)
          }
          
          */
         
         VStack {
             NavigationView {
                 VStack {
                     
                     List {
                         NavigationLink(destination:
                                         SheetAuroraInfo(forecastTime: $infoList[0],
                                                         observationTime: $infoList[1])) {
                             MainMenuButton()
                                 .foregroundColor(.white)
                             
                             
                         }
                         NavigationLink(destination: EventsList()) {
                             EventsButton()
                         }
                     }
                     
                     
                     /*
                     NavigationLink(destination: EventsList()) {
                         EventsButton()
                     }
                     */
                     
                     Button {
                         
                         //  simple button to fetch new aurora. play with labels
                         
                         
                         Task {
                             if !isFetchinAurora {
                                 await fetchAurora()
                                 
                                 infoList[0] = provider.aurora.forecastTime
                                 infoList[1] = provider.aurora.observationTime
                             }
                         }
                         
                     } label: {
                         Text(textForButton)
                     }
                 }
                 .toolbar {
                     ToolbarItem(placement: .navigationBarTrailing) {
                         Button (action: {
                             isSheetPresented = true
                         }) {
                             Image(systemName: "info.circle")
                         }
                     }
                 }
                 .sheet(isPresented: $isSheetPresented) {
                     // input info about current aurora.
                     
                     // when used, map creates double layers of tiles, fix that.
                     VStack {
                         Text("Forecast Time")
                         Text(provider.aurora.forecastTime)
                             .font(.title2)
                         Text("Observation Time")
                         Text(provider.aurora.observationTime)
                             .font(.title2)
                     }
                     .presentationDetents([.medium])
                     .padding()
                 }
             }
             
             
             /*
              
              .onSubmit {
                  
          }
              
              */
         }
         .task {
             
             await fetchAurora()
             // This async function calls for actual data, disable if needed to work with sample data.
             // Last updates sample data will be written to aurora.json file in documents directory.
             
             /*
              
              To ensure accurate data representation in future, figure a system that will fetch data once in a while
              
              Create an appropriate time based on device settings, fetch data, and return some kind of notification
              
              as well as create a notification center that will ensure notifications are set up the way customer wants
              
              */
             
 //            await fetchAurora()
             
             //
             
             // infoList[0] = provider.aurora.forecastTime
             // infoList[1] = provider.aurora.observationTime
  
         }
     }
 }


 extension MainMenu {
     
     func fetchAurora() async {
         do {
             
 //            Actual Data from Database online
             
             textForButton = "loading"
             
             isFetchinAurora = true
             try await provider.fetchAurora()
             
 //             Sample Data
             
 //
 //            let downloader = TestDownloader()
 //            let client = AuroraClient(downloader: downloader)
 //            let aurora = try await client.aurora
             
             
             // not used // newList = aurora.coordinates

             
         } catch {
             self.error = error as? AuroraError ?? .unexpectedError(error: error)
             self.hasError = true
         }
         
         isFetchinAurora = false
         textForButton = "Get new data!"
     }
 }



  struct MainMenu_Previews: PreviewProvider {
  // doesn't work
  static var auroraPreview = IndividualAuroraSpot.preview
  
  static var previews: some View {
      MainMenu(auroraList: .constant(auroraPreview))
          .environmentObject(EventModel())
          .environmentObject(AuroraProvider(client: AuroraClient(downloader: TestDownloader())))
          // .environment(\.colorScheme, .dark)
     }
  }

 
 */


// NOTIFICATION ASYNC

/*
 
 Plan for notifications: Each day update data closer to evening time / if storm will happen.
 Then send it at usually evening time, 2-3 hours before evening in that particular location
 
 */

/*
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {success, error in
    if success {
        print("Permission granted")
        permissionNotificationGranted = true
    } else if let error = error {
        print(error.localizedDescription)
    }
}
*/
/*
func requestNotificationAuthorization() async {
    do {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        print("notification is here")
        
        let notification = UNMutableNotificationContent()
        notification.title = "This is a test title"
        notification.body = "This should work for me"
        notification.sound = UNNotificationSound.default
        
        // this is what triggers notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
        
        // request? read into it
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: trigger)
        
        // request the request // wording is top
        
        await returnNotification(notification: request)
        print("cycle complete")
        
        
    } catch {
        print(error.localizedDescription)
    }
}

await requestNotificationAuthorization()

func returnNotification(notification: UNNotificationRequest) async {
    print("notification was sent to work")
    do {
        try await UNUserNotificationCenter.current().add(notification)
        print("notification should be dispatched")
    } catch {
        print(error.localizedDescription)
    }
}
 
 */

/*
if permissionNotificationGranted {
    
    let notification = UNMutableNotificationContent()
    notification.title = "This is a test title"
    notification.body = "This should work for me"
    notification.sound = UNNotificationSound.default
    
    // this is what triggers notification
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    
    // request? read into it
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: trigger)
    
    // request the request // wording is top
    
    await returnNotification(notification: request)
}
*/
