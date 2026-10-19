//
//  RazerKiyoProDeviceProperties.swift
//  UVC
//

import Foundation

private enum RazerKiyoProXU: Int, Selector {
    case setISP = 0x01

    func raw() -> Int {
        return rawValue
    }
}

/// Access to the Kiyo Pro's vendor ISP commands. Its extension unit is
/// discovered from the configuration descriptor rather than assuming a
/// firmware-specific unit ID.
public final class RazerKiyoProDeviceProperties {
    public let isAvailable: Bool

    private let ispControl: UVCControl?

    init(_ device: USBDevice) {
        guard RazerVendor.isKiyoPro(vendorID: device.vendorID, productID: device.productID),
              device.descriptor.interfaceID >= 0,
              let extensionUnit = device.descriptor.extensionUnits.first(where: {
                  $0.guid == RazerXUGuids.kiyoProISP && $0.unitID > 0
              }) else {
            self.isAvailable = false
            self.ispControl = nil
            return
        }

        self.isAvailable = true
        self.ispControl = UVCControl(device.interface,
                                     8,
                                     RazerKiyoProXU.setISP,
                                     extensionUnit.unitID,
                                     device.descriptor.interfaceID)
    }

    /// Applies the setting's complete ordered transaction, including any
    /// required FoV pre-command and the persistent save command.
    func apply(_ setting: RazerKiyoProSetting) -> Bool {
        guard let ispControl else {
            return false
        }

        for packet in setting.commandPackets where !ispControl.setData(bytes: packet) {
            // Later packets may depend on this write; in particular, do not
            // send the save command after an incomplete transaction.
            return false
        }
        return true
    }
}

// The wrapper and its UVCControl are held and used only by UVCDeviceActor
// after construction. UVCDeviceActor serializes all IOKit transfers.
extension RazerKiyoProDeviceProperties: @unchecked Sendable {}
