//
//  RazerKiyoProSetting.swift
//  UVC
//
//  Kiyo Pro ISP payloads are based on the public kiyoproctrls-mac utility.
//  The camera does not currently return these values through its GET result
//  request, so the UI tracks only values successfully applied this session.
//

import Foundation

public enum KiyoProAutofocusMode: String, CaseIterable, Hashable, Sendable {
    case responsive
    case passive

    public var title: String {
        switch self {
        case .responsive: return "Responsive"
        case .passive: return "Passive"
        }
    }
}

public enum KiyoProHDRMode: String, CaseIterable, Hashable, Sendable {
    case dark
    case bright

    public var title: String {
        switch self {
        case .dark: return "Dark"
        case .bright: return "Bright"
        }
    }
}

public enum KiyoProFieldOfView: String, CaseIterable, Hashable, Sendable {
    case wide
    case medium
    case narrow

    public var title: String {
        switch self {
        case .wide: return "Wide"
        case .medium: return "Medium"
        case .narrow: return "Narrow"
        }
    }
}

public enum RazerKiyoProSetting: Hashable, Sendable {
    case autofocusMode(KiyoProAutofocusMode)
    case hdrEnabled(Bool)
    case hdrMode(KiyoProHDRMode)
    case fieldOfView(KiyoProFieldOfView)

    /// SET_ISP payloads, followed by the camera's save command. Medium and
    /// Narrow FoV require a setup payload before their selection payload.
    public var commandPackets: [[UInt8]] {
        var packets: [[UInt8]] = []
        let command: [UInt8]

        switch self {
        case .autofocusMode(.responsive):
            command = [0xFF, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        case .autofocusMode(.passive):
            command = [0xFF, 0x06, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]
        case .hdrEnabled(false):
            command = [0xFF, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        case .hdrEnabled(true):
            command = [0xFF, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]
        case .hdrMode(.dark):
            command = [0xFF, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        case .hdrMode(.bright):
            command = [0xFF, 0x07, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]
        case .fieldOfView(.wide):
            command = [0xFF, 0x01, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00]
        case .fieldOfView(.medium):
            packets.append([0xFF, 0x01, 0x00, 0x03, 0x01, 0x00, 0x00, 0x00])
            command = [0xFF, 0x01, 0x01, 0x03, 0x01, 0x00, 0x00, 0x00]
        case .fieldOfView(.narrow):
            packets.append([0xFF, 0x01, 0x00, 0x03, 0x02, 0x00, 0x00, 0x00])
            command = [0xFF, 0x01, 0x01, 0x03, 0x02, 0x00, 0x00, 0x00]
        }

        packets.append(command)
        packets.append([0xC0, 0x03, 0xA8, 0x00, 0x00, 0x00, 0x00, 0x00])
        return packets
    }
}
