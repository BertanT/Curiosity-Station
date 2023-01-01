//
//  LoginScreen.swift
//  Curiosity-Station-iOS
//
//  Created by Bertan on 1.05.2021.
//

import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject private var sharedCloud: SharedCloud
    @State private var userName = ""
    @State private var password = ""
    @State private var progressViewActive = false
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            NavigationLink(destination: WeatherScreen().environmentObject(sharedCloud), isActive: $sharedCloud.userAuthenticated ) { EmptyView() }
            Text("Welcome to Curiosity Station! Please sign in with your Particle IoT Account.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            Image("welcome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 350)
                .padding()
            Spacer()
            TextField("e-mail address", text: $userName)
                .gradientField(gradient: .indigoGradient, systemImage: "person.circle")
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding([.horizontal, .bottom])
            SecureField("password", text: $password)
                .gradientField(gradient: .indigoGradient, systemImage: "key")
                .padding(.horizontal)
                .onSubmit(logIn)
            Button(action: logIn) {
                HStack {
                    Text("Sign In")
                    Image(systemName: "checkmark.circle")
                }
            }
            .buttonStyle(GradientButtonStyle(gradient: .tealGradient, disabled: progressViewActive || userName == "" || password == ""))
            .disabled(progressViewActive || userName == "" || password == "")
            .padding()
            .navigationBarItems(leading: progressViewActive ? AnyView(ProgressView()) : AnyView(EmptyView()))
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Can't Sign In :("), message: Text("Please check your credentials and try again."), dismissButton: .default(Text("Close")))
            }
            //            TODO: ADD PROPER LINK!
            Link("Learn More About the Project", destination: URL(string: "https://particle.io")!)
            Spacer()
        }
        .navigationTitle("Good to See You!")
        .onChange(of: sharedCloud.networkConnected) { _ in
            clearCredentials()
        }
    }
    
    private func logIn() {
        progressViewActive = true
        Task(priority: .userInitiated) {
            do {
                try await sharedCloud.logIn(username: userName, password: password)
            }catch {
                showingAlert.toggle()
            }
            clearCredentials()
            progressViewActive = false
        }
    }
    
    
    private func clearCredentials() {
        userName = ""
        password = ""
    }
}


struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
