//
//  CaptureDevice.swift
//  KiyoControl
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import AVFoundation
import Observation
import UVC

@MainActor
@Observable
final class CaptureDevice: Hashable {
    nonisolated let name: String
    // AVCaptureDevice's `Sendable` conformance is not yet declared in
    // the AVFoundation overlay this project targets, but the instance
    // we hold is treated as opaque from Swift's side: we never mutate
    // it; we only forward to its `==`/`hashValue` for identity and
    // `uniqueID` for persistence. `nonisolated(unsafe)` is the
    // narrowest escape hatch that keeps the static `==` / `hash(into:)`
    // implementations accessible from Equatable/Hashable's nonisolated
    // requirements without lifting the entire CaptureDevice type off
    // @MainActor.
    @ObservationIgnored nonisolated(unsafe) let avDevice: AVCaptureDevice?
    @ObservationIgnored private let uvcDeviceLoader = UVCDeviceLoader()

    private(set) var uvcDevice: UVCDevice?
    private(set) var isLoadingControls = true
    var controller: DeviceController?

    init(avDevice: AVCaptureDevice) {
        self.avDevice = avDevice
        self.name = avDevice.localizedName

        let deviceBox = AVCaptureDeviceBox(device: avDevice)
        let loader = uvcDeviceLoader
        Task { @MainActor [weak self] in
            let uvcDevice = await loader.load(deviceBox).device
            guard let self else { return }

            self.uvcDevice = uvcDevice
            self.controller = DeviceController(properties: uvcDevice?.properties,
                                               razerKiyoPro: uvcDevice?.razerKiyoPro)
            self.isLoadingControls = false
        }
    }

    nonisolated static func == (lhs: CaptureDevice, rhs: CaptureDevice) -> Bool {
        return lhs.avDevice == rhs.avDevice
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(avDevice)
    }

    func isConfigurable() -> Bool {
        return uvcDevice != nil
    }

    func isDefaultDevice() -> Bool {
        return false
    }

    func readValuesFromDevice() {
        guard let controller = controller else {
            return
        }

        Task {
            controller.exposureTime.update()
            controller.whiteBalance.update()
            controller.focusAbsolute.update()
        }
    }

    func writeValuesToDevice() {
        guard let controller = controller else {
            return
        }

        Task {
            controller.writeValues()
        }
    }
}

// The AVCaptureDevice is only passed to UVCDevice during discovery. This
// box allows that one synchronous USB probe to run on a background actor
// instead of blocking SwiftUI's main actor while the device responds.
private struct AVCaptureDeviceBox: @unchecked Sendable {
    let device: AVCaptureDevice
}

// UVCDevice owns a raw IOKit interface pointer and is intentionally
// transferred as an opaque handle after discovery completes.
private struct UVCDeviceBox: @unchecked Sendable {
    let device: UVCDevice?
}

// Each camera gets its own loader actor, so its blocking UVC descriptor
// and control requests are serialized without delaying app launch or the
// preview session. If a camera never answers a control request, its
// settings remain unavailable while the live video can still start.
private actor UVCDeviceLoader {
    func load(_ device: AVCaptureDeviceBox) -> UVCDeviceBox {
        return UVCDeviceBox(device: try? UVCDevice(device: device.device))
    }
}
