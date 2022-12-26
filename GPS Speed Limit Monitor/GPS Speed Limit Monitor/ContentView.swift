//
//  ContentView.swift
//  GPS Speed Limit Monitor
//
//  Created by ian on 9/30/22.
//

import SwiftUI
import MapKit
import CoreLocation
import Foundation

struct ContentView: View {
    @StateObject var locationViewModel = LocationViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination:IncidentsView()) {
                    Text("Incidents")
                }
                Map(coordinateRegion: $locationViewModel.region, showsUserLocation: true)
                    .onAppear(perform: locationViewModel.requestPermission)
                Text(String(locationViewModel.currentSpeed))
            }
        }
        .environmentObject(locationViewModel)
    }
}

struct IncidentsView: View {
    @EnvironmentObject var locationViewModel: LocationViewModel
    
    var body: some View {
        VStack {
            Text("Incidents")
            ForEach(0 ..< locationViewModel.incidents.count) { incident in
                Text(String(locationViewModel.incidents[incident].speed))
                //Text(String(locationViewModel.incidents[incident].location))
            }
        }
    }
}

struct Incident {
    var location: CLLocationCoordinate2D
    var speed: Double
}

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Location permissions
    var authorizationStatus: CLAuthorizationStatus
    
    // Map region
    @Published var region: MKCoordinateRegion
    private var span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    
    // Speed
    @Published var currentSpeed: CLLocationSpeed
    @Published var incidentCount: Int
    private var sameIncident: Bool
    
    // previous time and location
    private var prevLocation: CLLocation
    private var maxSpeed = 0.0
    //private var prevTime = Date()
    
    @Published var incidents: [Incident] = []
    
    
    
    private let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        authorizationStatus = locationManager.authorizationStatus
        self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: span)
        self.currentSpeed = 0
        self.incidentCount = 0
        self.sameIncident = false
        self.prevLocation = CLLocation(latitude: 0, longitude: 0)
        
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.first?.coordinate
        region = MKCoordinateRegion(center: currentLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), span: span)
        currentSpeed = getSpeed(loc1: locations.first!.coordinate , loc2: prevLocation.coordinate)
        prevLocation = locations.first!
        
        if (currentSpeed > 30 && currentSpeed < 200) {
            sameIncident = true
            if (currentSpeed > maxSpeed) {
                maxSpeed = currentSpeed
            }
        } else {
            if (sameIncident) {
                let incident = Incident(location: prevLocation.coordinate, speed: maxSpeed)
                incidents.append(incident)
                print(incidents)
                sameIncident = false
                maxSpeed = 0
            }
        }
    }
    
    func getSpeed(loc1: CLLocationCoordinate2D, loc2: CLLocationCoordinate2D) -> Double {
        let lat1 = loc1.latitude
        let lon1 = loc1.longitude
        let lat2 = loc2.latitude
        let lon2 = loc2.longitude
        
        // Calculate distance between loc1 and loc2
        let p = 0.017453292519943295
        let a = 0.5 - cos((lat2 - lat1) * p)/2 +
                  cos(lat1 * p) * cos(lat2 * p) *
                  (1 - cos((lon2 - lon1) * p))/2
        let distance = 12742 * asin(sqrt(a))
        
        let milesDistance = distance * 0.6213711922
        print(milesDistance * 360)
        return milesDistance * 360
    }
    
}

struct ContentViewPreview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
