//
//  FlightsEnrouteView.swift
//  Enroute
//
//  Created by Eric Hou on 12/14/20.
//

import SwiftUI

struct FlightSearch {
    var destination: String
    var origin: String?
    var airline: String?
    var inTheAir: Bool = true
}

struct FlightsEnrouteView: View {
    @State var flightSearch: FlightSearch
    
    var body: some View {
        NavigationView {
            FlightList(flightSearch)
                .navigationBarItems(leading: simulation, trailing: filter)
        }
    }
    
    @State private var showFilter = false
    
    var filter: some View {
        Button("Filter") {
            showFilter = true
        }
        // Anytime we set the binding to true the sheet is brought up
        // When the sheet is clicked away the binding is set to false
        .sheet(isPresented: $showFilter) {
            // isPresented allows for a 'Done' Button on the sheet rather than just swiping down
            // Calling a binding to flightsearch causes it to perform a new flightsearch
            FilterFlights(flightSearch: $flightSearch, isPresented: $showFilter)
        }
    }
    
    // if no FlightAware credentials exist in Info.plist
    // then we simulate data from KSFO and KLAS (Las Vegas, NV)
    // the simulation time must match the times in the simulation data
    // so, to orient the UI, this simulation View shows the time we are simulating
    var simulation: some View {
        let isSimulating = Date.currentFlightTime.timeIntervalSince(Date()) < -1
        return Text(isSimulating ? DateFormatter.shortTime.string(from: Date.currentFlightTime) : "")
    }
}

struct FlightList: View {
    @ObservedObject var flightFetcher: FlightFetcher

    init(_ flightSearch: FlightSearch) {
        self.flightFetcher = FlightFetcher(flightSearch: flightSearch)
    }

    var flights: [FAFlight] { flightFetcher.latest }
    
    var body: some View {
        List {
            ForEach(flights, id: \.ident) { flight in
                FlightListEntry(flight: flight)
            }
        }
        .navigationBarTitle(title)
    }
    
    private var title: String {
        let title = "Flights"
        if let destination = flights.first?.destination {
            return title + " to \(destination)"
        } else {
            return title
        }
    }
}

struct FlightListEntry: View {
    @ObservedObject var allAirports = Airports.all
    @ObservedObject var allAirlines = Airlines.all
    
    var flight: FAFlight

    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
            Text(arrives).font(.caption)
            Text(origin).font(.caption)
        }
            .lineLimit(1)
    }
    
    var name: String {
        return "\(allAirlines[flight.airlineCode]?.friendlyName ?? "Unknown Airline") \(flight.number)"
    }

    var arrives: String {
        let time = DateFormatter.stringRelativeToToday(Date.currentFlightTime, from: flight.arrival)
        if flight.departure == nil {
            return "scheduled to arrive \(time) (not departed)"
        } else if flight.arrival < Date.currentFlightTime {
            return "arrived \(time)"
        } else {
            return "arrives \(time)"
        }
    }

    var origin: String {
        return "from " + (allAirports[flight.origin]?.friendlyName ?? "Unknown Airport")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FlightsEnrouteView(flightSearch: FlightSearch(destination: "KSFO"))
    }
}
