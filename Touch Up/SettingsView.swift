//
//  SettingsView.swift
//  Touch Up
//
//  Created by Sebastian Hueber on 03.02.23.
//

import SwiftUI
import TouchUpCore

struct SettingsView: View {
    
    @ObservedObject var model: TouchUp
    
    var welcomeBanner: some View {
        Group {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to Touch Up 🐑")
                    .font(.largeTitle)
                Text("Touch Up converts USB HID data from any Windows certified touchscreen to mouse events.\nInjecting mouse events requires access to accessibility APIs. You can allow this by clicking the button below.")
            }
            
            HStack {
                Spacer()
                Button {
                    model.grantAccessibilityAccess()
                } label: {
                    
                    Text("Grant Accessibility Access")
                }
                .buttonStyle(BorderedButtonStyle())
            }
        }
    }
    
    var top: some View {
        Group {
            Toggle(model.uiLabels(for: \TouchUp.isPublishingMouseEventsEnabled).title, isOn: $model.isPublishingMouseEventsEnabled)
            
            let id_: Binding<UInt> = Binding {return (model.connectedTouchscreen?.id) ?? 0}
            set: { value in
                model.connectedTouchscreen = model.connectedScreens.first(where:{$0.id == value})
                model.rememeberCues()
            }

            Picker(model.uiLabels(for: \TouchUp.connectedTouchscreen).title, selection: id_) {
                ForEach(model.connectedScreens) {
                    Text($0.name).tag($0.id)
                }
            }
        }
    }
    
    
    var gestureSettings: some View {
        Group {
            
            let mode_ = Binding {
                model.isClickOnLiftEnabled ? 2 : (model.isScrollingWithOneFingerEnabled ? 0 : 1)
            } set: { value in
                model.isScrollingWithOneFingerEnabled = value == 0
                model.isClickOnLiftEnabled = value == 2
            }
            
            Picker(
                selection: mode_,
                label: SettingsExplanationLabel(
                    labels: ("On Finger Drag", "Specify which action should occur when dragging one finger on the touch screen.")
                )
            ) {
                Text("Scroll").tag(0)
                Text("Move Cursor").tag(1)
                Text("Point and Click").tag(2)
            }

            
            Toggle(isOn: $model.isSecondaryClickEnabled) {
                SettingsExplanationLabel(labels: model.uiLabels(for: \TouchUp.isSecondaryClickEnabled))
            }
            
            Toggle(isOn: $model.isMagnificationEnabled) {
                SettingsExplanationLabel(labels: model.uiLabels(for: \TouchUp.isMagnificationEnabled))
            }
            
            Toggle(isOn: $model.isClickWindowToFrontEnabled) {
                SettingsExplanationLabel(labels: model.uiLabels(for: \TouchUp.isClickWindowToFrontEnabled))
            }
        }
    }
    
    
    var parameterSettings: some View {
        Group {
            Slider(value: $model.holdDuration, in: 0.0...0.16, step: 0.02){
                SettingsExplanationLabel(labels: model.uiLabels(for: \TouchUp.holdDuration))
            }
            
            Slider(value: $model.doubleClickDistance, in: 0...8, step: 1) {
                SettingsExplanationLabel(labels: model.uiLabels(for: \TouchUp.doubleClickDistance))
            }
        }
    }
    
    
    var troubleshootingSettings: some View {
        Group {
            let errorResistance_ = Binding {Double(model.errorResistance)} set: {
                model.errorResistance = NSInteger(Int($0)) }
            
            Slider(value: errorResistance_ , in: 0...10, step: 1) {
                SettingsExplanationLabel(labels: model.uiLabels(for: \TouchUp.errorResistance))
            }
            
            Toggle(isOn: $model.ignoreOriginTouches) {
                SettingsExplanationLabel(labels: model.uiLabels(for: \TouchUp.ignoreOriginTouches))
            }
            
            Button(action: {
                (NSApp.delegate as? AppDelegate)?.showDebugOverlay()
            }, label: {
                HStack {
                    Text("Open Fullscreen Test Environment")
                    Spacer()
                    Image(nsImage: NSImage(named: NSImage.shareTemplateName) ?? NSImage())
                                .renderingMode(.template)
                }
                
            })
            .foregroundColor(.accentColor)
            .buttonStyle(PlainButtonStyle())
            
        }
    }
    
    @ViewBuilder
    var githubLink: some View {
        if #available(macOS 11.0, *) {
            Link(destination: URL(string: "https://github.com/shueber/Touch-Up")!) {
                Label("GitHub", systemImage: "link")
                    .foregroundColor(.accentColor)
            }
        } else {
            Button(action: {
                if let url = URL(string: "https://github.com/shueber/Touch-Up") {
                    NSWorkspace.shared.open(url)
                }
            }, label: {
                Text("GitHub")
                    .foregroundColor(.accentColor)
            })
            .buttonStyle(BorderlessButtonStyle())
        }
    }
    
    var footer: some View {
        HStack {
            Spacer()
            VStack {
                if let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Touch Up v\(versionString)")
                        .font(.title)
                }

                Text("Made with 🐑 in Aachen")
                    .font(.footnote)
                
                githubLink

            }
            .padding(.vertical)
            Spacer()
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        
    }
    
    var container: some View {
        return List {
            
            LegacySection {
                welcomeBanner
            }
            
            LegacySection {
                top
            }
            
            LegacySection(title: "Gestures") {
                gestureSettings
            }
            
            LegacySection(title: "Parameters") {
                parameterSettings
            }
            
            LegacySection(title: "Troubleshooting") {
                troubleshootingSettings
            }
            
            footer
            
        }
        .toggleStyle(SwitchToggleStyle())
    }
    
    
    
    var body: some View {
        container
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 350,  maxHeight: .infinity)
        
    }
}


struct LegacySection<Content: View>: View {
    var title: String? = nil
    var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal, 12)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.secondary)
                    .shadow(radius: 1)
                    
                    
                
                VStack(alignment: .leading, spacing: 16, content: content)
                    .padding(12)
            }
            
        }
        .padding(.bottom)
    }
}


struct SettingsExplanationLabel: View {
    
    let labels: (title:String, description:String)
    
    var body: some View {
        VStack(alignment:.leading, spacing: 4) {
            Text(labels.title)
            Text(labels.description)
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(model: TouchUp())
    }
}
