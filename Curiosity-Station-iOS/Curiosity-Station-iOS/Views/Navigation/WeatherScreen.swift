//
//  MonitorScreen.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

struct WeatherScreen: View {
    
    @EnvironmentObject private var sharedCloud: SharedCloud
    
    @State private var rainbowSignalingEnabled = false
    
    @State private var viewMode: ViewMode = .loading
    @State private var showingDeviceSelectionSheet = false
    @State private var toolbarProgressViewActive = false
    
    @State private var warningMessage: String?
    @State private var errorViewTitle = ""
    @State private var errorViewDescription = ""
    @State private var errorViewButtonTitle = ""
    @State private var errorViewButtonAction: () -> Void = { }
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var weatherDataPresent: Bool {
        return sharedCloud.weatherStation?.latestMeasurements != nil
    }
    
    enum ViewMode { case loading, weather, error }
    
    var body: some View {
        VStack {
            if let message = warningMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(Color(UIColor.systemOrange))
                    Text(message)
                        .font(.footnote)
                }
                .fixedSize(horizontal: false, vertical: true)
                .onTapGesture(perform: {withAnimation{warningMessage = nil}})
            }
            switch viewMode {
            case .loading:
                ProgressView("Weather data coming right up!")
            case .weather:
                if let weatherData = sharedCloud.weatherStation?.latestMeasurements {
                    WeatherMonitor(data: weatherData)
                }
            case .error:
                ErrorView(errorTitle: errorViewTitle, errorDescription: errorViewDescription, buttonTitle: errorViewButtonTitle, buttonAction: errorViewButtonAction)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Your Station")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if toolbarProgressViewActive {
                    ProgressView()
                }else {
                    EmptyView()
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { refreshData() }) {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                    .buttonStyle(GradientButtonStyle(gradient: .indigoGradient, disabled: viewMode == .loading || toolbarProgressViewActive))
                    .disabled(viewMode == .loading || toolbarProgressViewActive)
                    Menu {
                        VStack {
                            Button(action: {
                                showingDeviceSelectionSheet.toggle()
                            } ) {
                                Label("Change Station", systemImage: "antenna.radiowaves.left.and.right")
                            }
                            Button(action: toggleRainbowSignal) {
                                if rainbowSignalingEnabled {
                                    Label("Stop Signaling", systemImage: "lightbulb.slash")
                                }else {
                                    Label("Rainbow Signal!", systemImage: "lightbulb")
                                }
                            }
                            Button(action: {
                                sharedCloud.logOut()
                            }) {
                                Label("Log Out", systemImage: "lock")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .gradientBackground(gradient: (viewMode == .loading || toolbarProgressViewActive) ? Gradient(colors: [.gray]) : .indigoGradient)
                        
                    }
                    .disabled(viewMode == .loading || toolbarProgressViewActive)
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Something Went Wrong"), message: Text(alertMessage), dismissButton: .default(Text("Close")))
        }
        
        .sheet(isPresented: $showingDeviceSelectionSheet) {
            DeviceSelectionSheet(onSuccessfulSelection: { refreshData(enableAutoRefresh: true) })
                .environmentObject(sharedCloud)
        }
        
        .onAppear(perform: {
            refreshData(enableAutoRefresh: true)
        })
        
        .onChange(of: sharedCloud.networkConnected) { connected in
            if connected {
                refreshData()
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshData(enableAutoRefresh: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            sharedCloud.weatherStation?.disableAutoRefresh()
        }
    }
    
    func showAlert(message: String) {
        alertMessage = message
        showingAlert.toggle()
    }
    
    func setView(mode: ViewMode) {
        withAnimation {
            warningMessage = nil
            viewMode = mode
        }
    }
    
    func setProgressIndicator(loading: Bool) {
        if loading {
            if weatherDataPresent {
                withAnimation { toolbarProgressViewActive = true }
            }else{
                setView(mode: .loading)
            }
        }else {
            withAnimation { toolbarProgressViewActive = false }
        }
    }
    
    func showErrorView(errorTitle: String, errorDescription: String, buttonTitle: String = "Try Again!", buttonAction: @escaping () -> Void) {
        self.errorViewTitle = errorTitle
        self.errorViewDescription = errorDescription
        self.errorViewButtonTitle = buttonTitle
        self.errorViewButtonAction = buttonAction
        setView(mode: .error)
    }
    
    func handleError(error: Error) {
        if case SharedCloud.CloudError.noSavedDevice = error {
            showErrorView(errorTitle: "Welcome to Curiosity Station!", errorDescription: error.localizedDescription, buttonTitle: "Select Station!", buttonAction: { showingDeviceSelectionSheet.toggle() })
        }else if case WeatherStation.DeviceError.deviceOffline = error {
            if weatherDataPresent {
                warningMessage = "Your station went offline! Showing old data."
            }else {
                showErrorView(errorTitle: "Station Offline", errorDescription: error.localizedDescription, buttonAction: { refreshData(enableAutoRefresh: true) })
            }
        }else if case WeatherStation.DeviceError.hardwareFailure = error {
            if weatherDataPresent {
                showAlert(message: error.localizedDescription)
                warningMessage = ":( Your station reported hardware failure. Showing old data"
            }else {
                showErrorView(errorTitle: ":( Hardware Failure!", errorDescription: error.localizedDescription, buttonAction: { refreshData(enableAutoRefresh: true) })
            }
        }else if case WeatherStation.DeviceError.invalidConfiguration = error {
            if weatherDataPresent {
                warningMessage = "Your station has invalid configuration, please check the firmware! Showing old data."
            }else{
                showErrorView(errorTitle: "Invalid Configuration", errorDescription: error.localizedDescription, buttonAction: { refreshData(enableAutoRefresh: true) })
            }
        }
        else if case WeatherStation.DeviceError.invalidData = error {
            if weatherDataPresent {
                warningMessage = "Invalid data received from your station, please check the firmware! Showing old data."
            }else{
                showErrorView(errorTitle: "Invalid Weather Data", errorDescription: error.localizedDescription, buttonAction: { refreshData(enableAutoRefresh: true) })
            }
        }else if case WeatherStation.DeviceError.cannotEnableAutoRefresh = error {
            if weatherDataPresent {
                warningMessage = "There was an error while enabling auto refresh. Trying again in 10 seconds!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    warningMessage = nil
                    refreshData(enableAutoRefresh: true)
                }
            }
        }else if case WeatherStation.DeviceError.cannotSetSignaling = error {
            showAlert(message: "An unexpected error occurred while sending the signaling command to your station. Please try again.")
        }else {
            if weatherDataPresent {
                warningMessage = "An unexpected error occurred while communicating with your station. Showing old data for now."
            }else {
                showErrorView(errorTitle: "Something Went Wrong", errorDescription: "An unexpected error occurred while communicating with your station. Please try again.", buttonAction: { refreshData(enableAutoRefresh: true) })
            }
        }
        
    }
    
    func refreshData(enableAutoRefresh: Bool = false) {
        setProgressIndicator(loading: true)
        Task(priority: .userInitiated) {
            if sharedCloud.weatherStation == nil {
                do {
                    try await sharedCloud.initializeStationFromSavedDevice()
                }catch {
                    handleError(error: error)
                    return
                }
            }
            do {
                try await sharedCloud.weatherStation?.refreshWeatherData()
            }catch {
                print(error)
            }
            setProgressIndicator(loading: false)
            setView(mode: .weather)
            if enableAutoRefresh {
                self.enableAutoRefresh()
            }
        }
    }
    
    func toggleRainbowSignal() {
        Task(priority: .userInitiated) {
            do {
                try await sharedCloud.weatherStation?.setRainbowSignal(enable: !rainbowSignalingEnabled)
            }catch {
                handleError(error: error)
                if case WeatherStation.DeviceError.cannotSetSignaling = error {
                    handleError(error: WeatherStation.DeviceError.cannotSetSignaling)
                }
                return
            }
            rainbowSignalingEnabled = !rainbowSignalingEnabled
            if !rainbowSignalingEnabled {
                Task(priority: .background) {
                    try? await Task.sleep(nanoseconds: 553_000_000_000)
                    do {
                        try await sharedCloud.weatherStation?.setRainbowSignal(enable: false)
                    }catch {
                        return
                    }
                    rainbowSignalingEnabled = false
                }
            }
        }
    }
    
    func enableAutoRefresh() {
        Task(priority: .userInitiated) {
            do {
                try await sharedCloud.weatherStation?.enableNewMeasurementTracking {
                    refreshData()
                }
            }catch{
                handleError(error: error)
            }
        }
    }
}

struct MonitorScreen_Previews: PreviewProvider {
    static var previews: some View {
        WeatherScreen()
    }
}
