//
//  AdvancedView.swift
//  KiyoControl
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI
import UVC

struct AdvancedView: View {
    @Bindable var controller: DeviceController

    var body: some View {
        Form {
            Section("Camera") {
                if controller.powerLineFrequency.isCapable {
                    PowerLineView(controller: controller)
                }

                if controller.backlightCompensation.isCapable {
                    BacklightView(controller: controller)
                }
            }

            if controller.zoomAbsolute.isCapable
                || controller.panTiltAbsolute.isCapable
                || controller.rollAbsolute.isCapable {
                Section("Orientation") {
                    if controller.zoomAbsolute.isCapable {
                        ZoomView(controller: controller)
                    }

                    if controller.panTiltAbsolute.isCapable {
                        PanTiltView(controller: controller)
                    }

                    if controller.rollAbsolute.isCapable {
                        RollView(controller: controller)
                    }
                }
            }

            if controller.focusAbsolute.isCapable {
                Section("Focus") {
                    FocusView(controller: controller)
                }
            }

            if let kiyoPro = controller.kiyoProSettings {
                KiyoProSettingsSection(settings: kiyoPro)
            }
        }
        .formStyle(.grouped)
        .frame(maxHeight: 360)
    }
}

private struct KiyoProSettingsSection: View {
    @Bindable var settings: KiyoProSettings

    var body: some View {
        Section("Razer Kiyo Pro") {
            Picker("Autofocus Mode", selection: Binding(
                get: { settings.autofocusMode },
                set: { settings.selectAutofocusMode($0) }
            )) {
                Text("Not set").tag(nil as KiyoProAutofocusMode?)
                ForEach(KiyoProAutofocusMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(Optional(mode))
                }
            }
            .disabled(settings.isApplying)

            Picker("HDR", selection: Binding(
                get: { settings.hdrEnabled },
                set: { settings.selectHDR($0) }
            )) {
                Text("Not set").tag(nil as Bool?)
                Text("Off").tag(Optional(false))
                Text("On").tag(Optional(true))
            }
            .disabled(settings.isApplying)

            Picker("HDR Mode", selection: Binding(
                get: { settings.hdrMode },
                set: { settings.selectHDRMode($0) }
            )) {
                Text("Not set").tag(nil as KiyoProHDRMode?)
                ForEach(KiyoProHDRMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(Optional(mode))
                }
            }
            .disabled(settings.isApplying)

            Picker("Field of View", selection: Binding(
                get: { settings.fieldOfView },
                set: { settings.selectFieldOfView($0) }
            )) {
                Text("Not set").tag(nil as KiyoProFieldOfView?)
                ForEach(KiyoProFieldOfView.allCases, id: \.self) { fieldOfView in
                    Text(fieldOfView.title).tag(Optional(fieldOfView))
                }
            }
            .disabled(settings.isApplying)

            Text("The camera does not report these current values. Selections show settings applied in this session.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let statusMessage = settings.statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
