//
//  ContentView.swift
//  KiyoControl
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI
import AVFoundation
import UVC

struct ContentView: View {
    @Environment(DevicesManager.self) private var manager
    @Environment(UserSettings.self) private var settings

    // PreviewSession is owned by AppDelegate (NSStatusItem +
    // NSPopover lifetime) and injected via .environment(_:) on the
    // NSHostingController root view. Reading it via @Environment here
    // — instead of @State — keeps the AVCaptureSession instance
    // stable across popover open/close cycles. AppDelegate's
    // popoverWillShow / popoverDidClose hooks drive resume() /
    // suspend(), so ContentView no longer watches scenePhase.
    @Environment(PreviewSession.self) private var preview

    var body: some View {
        // Camera preview at the top of the popover, settings tabs
        // below. NSPopover sizes to the content's intrinsic size, so
        // each child carries its own .frame and the popover grows
        // to fit the sum of preview + tab content.
        VStack(spacing: 0) {
            cameraNameLabel()

            cameraPreview()
                .animation(nil, value: settings.hideCameraPreview)

            SettingsView()
        }
        // Drive PreviewSession from the selected-device identity. A
        // change to selectedDevice cancels the previous task body and
        // runs this one, so a rapid sequence of switches collapses
        // to "detach prior, attach latest" with the intermediate
        // attaches superseded.
        .task(id: manager.selectedDevice?.avDevice?.uniqueID) {
            if let device = manager.selectedDevice?.avDevice {
                await preview.attach(device: device,
                                     quality: settings.cameraPreviewQuality,
                                     hdrEnabled: selectedCameraHDREnabled)
            } else {
                await preview.detach()
            }
        }
        .onChange(of: selectedCameraHDREnabled) { _, enabled in
            reconfigurePreviewForHDR(enabled: enabled)
        }
        .onChange(of: selectedCameraHDRMode) { _, _ in
            guard selectedCameraHDREnabled else { return }
            reconfigurePreviewForHDR(enabled: true)
        }
        .frame(width: settings.cameraPreviewSize.getWidth())
        .fixedSize(horizontal: true, vertical: false)
    }

    private var selectedCameraHDREnabled: Bool {
        manager.selectedDevice?.controller?.kiyoProSettings?.hdrEnabled == true
    }

    private var selectedCameraHDRMode: KiyoProHDRMode? {
        manager.selectedDevice?.controller?.kiyoProSettings?.hdrMode
    }

    private func reconfigurePreviewForHDR(enabled: Bool) {
        guard let deviceID = manager.selectedDevice?.avDevice?.uniqueID else { return }
        Task {
            await preview.reconfigureHDR(deviceID: deviceID, enabled: enabled)
        }
    }

    @ViewBuilder
    private func cameraNameLabel() -> some View {
        // Reserve a header strip above the preview frame for the
        // currently selected camera's display name. Centered, secondary
        // text style so it reads as a caption rather than competing
        // with the controls below.
        Text(manager.selectedDevice?.name ?? "No Camera")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func cameraPreview() -> some View {
        if settings.hideCameraPreview {
            EmptyView()
        } else if manager.selectedDevice != nil {
            CameraPreview(layer: preview.previewLayer)
                .frame(
                    width: settings.cameraPreviewSize.getWidth(),
                    height: settings.cameraPreviewSize.getHeight()
                )
                .scaleEffect(CGSize(width: settings.mirrorPreview ? -1 : 1, height: 1))
        } else {
            Image("video.slash")
                .frame(
                    width: settings.cameraPreviewSize.getWidth(),
                    height: settings.cameraPreviewSize.getHeight()
                )
                .background(Color.gray)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(DevicesManager.shared)
            .environment(UserSettings.shared)
            .environment(ProfileManager.shared)
            .environment(PreviewSession())
    }
}
#endif
