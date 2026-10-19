//
//  KiyoProProtocolTests.swift
//  KiyoControlTests
//

import XCTest
import UVC

final class KiyoProProtocolTests: XCTestCase {
    private let savePacket: [UInt8] = [0xC0, 0x03, 0xA8, 0x00, 0x00, 0x00, 0x00, 0x00]

    func testFieldOfViewMediumAndNarrowUseTheirSetupPackets() {
        XCTAssertEqual(RazerKiyoProSetting.fieldOfView(.medium).commandPackets, [
            [0xFF, 0x01, 0x00, 0x03, 0x01, 0x00, 0x00, 0x00],
            [0xFF, 0x01, 0x01, 0x03, 0x01, 0x00, 0x00, 0x00],
            savePacket
        ])
        XCTAssertEqual(RazerKiyoProSetting.fieldOfView(.narrow).commandPackets, [
            [0xFF, 0x01, 0x00, 0x03, 0x02, 0x00, 0x00, 0x00],
            [0xFF, 0x01, 0x01, 0x03, 0x02, 0x00, 0x00, 0x00],
            savePacket
        ])
    }

    func testWideFieldOfViewAndOtherSettingsAppendSavePacket() {
        let settings: [RazerKiyoProSetting] = [
            .fieldOfView(.wide),
            .autofocusMode(.responsive),
            .autofocusMode(.passive),
            .hdrEnabled(false),
            .hdrEnabled(true),
            .hdrMode(.dark),
            .hdrMode(.bright)
        ]

        for setting in settings {
            let packets = setting.commandPackets
            XCTAssertEqual(packets.last, savePacket)
            XCTAssertTrue(packets.allSatisfy { $0.count == 8 })
        }
    }

    func testAutofocusAndHDRCommandsMatchTheKiyoProPayloads() {
        XCTAssertEqual(RazerKiyoProSetting.autofocusMode(.responsive).commandPackets, [
            [0xFF, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
            savePacket
        ])
        XCTAssertEqual(RazerKiyoProSetting.autofocusMode(.passive).commandPackets, [
            [0xFF, 0x06, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00],
            savePacket
        ])
        XCTAssertEqual(RazerKiyoProSetting.hdrEnabled(false).commandPackets, [
            [0xFF, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
            savePacket
        ])
        XCTAssertEqual(RazerKiyoProSetting.hdrEnabled(true).commandPackets, [
            [0xFF, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00],
            savePacket
        ])
        XCTAssertEqual(RazerKiyoProSetting.hdrMode(.dark).commandPackets, [
            [0xFF, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
            savePacket
        ])
        XCTAssertEqual(RazerKiyoProSetting.hdrMode(.bright).commandPackets, [
            [0xFF, 0x07, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00],
            savePacket
        ])
    }

    func testWideFieldOfViewUsesItsSingleSelectionCommand() {
        XCTAssertEqual(RazerKiyoProSetting.fieldOfView(.wide).commandPackets, [
            [0xFF, 0x01, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00],
            savePacket
        ])
    }

    func testKiyoProDeviceAndExtensionUnitIdentifiers() {
        XCTAssertTrue(RazerVendor.isKiyoPro(vendorID: 0x1532, productID: 0x0E05))
        XCTAssertFalse(RazerVendor.isKiyoPro(vendorID: 0x1532, productID: 0x0001))
        XCTAssertFalse(RazerVendor.isKiyoPro(vendorID: 0x0001, productID: 0x0E05))
        XCTAssertEqual(RazerXUGuids.kiyoProISP.uuidString,
                       "23E49ED0-1178-4F31-AE52-D2FB8A8D3B48")
    }
}
