//
//  DeviceSelectionSheet.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

struct DeviceSelectionSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var sharedCloud: SharedCloud
    
    @State private var devices = [ParticleDevice]()
    
    @State private var viewMode: ViewMode = .loading
    
    @State private var toolbarProgressViewActive = false
    
    @State private var errorViewTitle = ""
    @State private var errorViewDescription = ""
    @State private var errorViewButtonTitle = ""
    @State private var errorViewButtonAction: () -> Void = { }
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let onSuccessfulSelection: () -> Void
    
    private enum ViewMode { case list, loading, error }
    private enum ProgressAppearance { case fullScreen, toolbar }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack(alignment: .leading) {
                    switch self.viewMode {
                    case .list:
                        List {
                            ForEach(devices, id: \.self) { device in
                                Button(action: {
                                    deviceListItemAction(device: device)
                                }) {
                                    DeviceListItem(showCheckmark: sharedCloud.isDeviceSavedDevice(deviceID: device.id) , device: device)
                                        .listRowInsets(EdgeInsets())
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    case .loading:
                        ProgressView("Loading devices")
                        
                    case .error:
                        ErrorView(errorTitle: "Error Loading Devices", errorDescription: "Sorry, an unexpected error occurred while loading the list of your devices.", customErrorImage: Image("cannotLoadDevices")) {
                            
                        }
                    }
                    
                }
                .navigationBarTitle("Select Your Station")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if toolbarProgressViewActive {
                            ProgressView()
                        }else {
                            EmptyView()
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: getDevicesList) {
                            Image(systemName: "arrow.clockwise.circle")
                        }.buttonStyle(GradientButtonStyle(gradient: .indigoGradient))
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle")
                        }.buttonStyle(GradientButtonStyle(gradient: .redGradient))
                    }
                }
                .onAppear(perform: getDevicesList)
                .alert(isPresented: self.$showAlert) {
                    Alert(title: Text("Can't Set Device"), message: Text(alertMessage), dismissButton: .default(Text("Close")))
                }
            }
        }
    }
    
    private func setView(mode: ViewMode) {
        withAnimation {
            self.viewMode = mode
        }
    }
    
    func showErrorView(errorTitle: String, errorDescription: String, buttonTitle: String = "Try Again!", buttonAction: @escaping () -> Void) {
        self.errorViewTitle = errorTitle
        self.errorViewDescription = errorDescription
        self.errorViewButtonTitle = buttonTitle
        self.errorViewButtonAction = buttonAction
        setView(mode: .error)
    }
    
    func showAlert(message: String) {
        alertMessage = message
        showAlert.toggle()
    }
    
    private func handleError(error: Error) {
        if case SharedCloud.CloudError.cannotGetDevices = error {
            showErrorView(errorTitle: "Cannot Get Devices!", errorDescription: error.localizedDescription, buttonAction: getDevicesList)
        }else {
            showAlert(message: error.localizedDescription)
        }
    }
    
    private func getDevicesList() {
        setView(mode: .loading)
        Task(priority: .userInitiated) {
            do {
                devices = try await sharedCloud.getUserDevices()
                setView(mode: .list)
            }catch {
                handleError(error: error)
            }
        }
    }
    
    func deviceListItemAction(device: ParticleDevice) {
        if sharedCloud.isDeviceSavedDevice(deviceID: device.id) {
            presentationMode.wrappedValue.dismiss()
        }else {
            toolbarProgressViewActive = true
            sharedCloud.weatherStation?.disableAutoRefresh()
            Task(priority: .userInitiated) {
                do {
                    try await sharedCloud.weatherStation = WeatherStation(device: device)
                    toolbarProgressViewActive = false
                    presentationMode.wrappedValue.dismiss()
                    onSuccessfulSelection()
                }catch {
                    toolbarProgressViewActive = false
                    handleError(error: error)
                }
            }
        }
    }
}

fileprivate struct DeviceListItem: View {
    @Environment(\.colorScheme) private var colorScheme
    let showCheckmark: Bool
    let device: ParticleDevice
    var body: some View {
        HStack {
            Group {
                if device.connected {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.green)
                }else {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .foregroundStyle(.red)
                }
            }
            .symbolRenderingMode(.hierarchical)
            .font(.title)
            
            
            VStack(alignment: .leading) {
                Text(device.name ?? "Name Not Available :(")
                    .bold()
                    .font(.title3)
                    .foregroundColor(self.colorScheme == .light ? .black : .white)
                Text("\(device.connected ? "Online" : getLastHeardString())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .foregroundColor(self.colorScheme == .light ? .black : .white)
            }
            if self.showCheckmark {
                Spacer()
                Image(systemName: "checkmark")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
    }
    
    func getLastHeardString() -> String {
        if let date = device.lastHeard {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            return "Last Heard: \(formatter.string(from: date))"
        }
        return "Offline"
    }
}
