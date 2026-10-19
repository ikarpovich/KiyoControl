//
//  UVCControl.swift
//  KiyoControl
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

protocol Selector {
    func raw() -> Int
}

public class UVCControl {
    let interface: USBInterfacePointer
    let uvcSize: Int
    let uvcSelector: Int
    let uvcUnit: Int
    let uvcInterface: Int

    public var isCapable: Bool = false

    init(_ interface: USBInterfacePointer, _ uvcSize: Int, _ uvcSelector: Selector,
         _ uvcUnit: Int, _ uvcInterface: Int) {
        self.interface = interface
        self.uvcSize = uvcSize
        self.uvcSelector = uvcSelector.raw()
        self.uvcUnit = uvcUnit
        self.uvcInterface = uvcInterface
    }

    func getDataFor(type: UVCRequestCodes, length: Int) -> Int {
        let requestType = USBmakebmRequestType(direction: kUSBIn, type: kUSBClass, recipient: kUSBInterface)

        do {
            return try performRequest(type: type,
                                      length: length,
                                      requestType: requestType)
        } catch {
            // Should not return 0, but working on improving this
            return 0
        }
    }

    func setData(value: Int, length: Int) -> Bool {
        let requestType = USBmakebmRequestType(direction: kUSBOut, type: kUSBClass, recipient: kUSBInterface)

        do {
            _ = try performRequest(type: UVCRequestCodes.setCurrent,
                                   length: length,
                                   requestType: requestType,
                                   value: value)
            return true
        } catch {
            return false
        }
    }

    /// Sends an arbitrary UVC SET_CUR payload. Some vendor extension units
    /// use structured payloads that cannot be represented by the integer
    /// controls above.
    func setData(bytes: [UInt8]) -> Bool {
        guard uvcUnit >= 0,
              !bytes.isEmpty,
              bytes.count <= Int(UInt16.max) else {
            return false
        }

        let requestType = USBmakebmRequestType(direction: kUSBOut, type: kUSBClass, recipient: kUSBInterface)
        var payload = bytes
        return payload.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return false
            }

            var request = IOUSBDevRequest(bmRequestType: requestType,
                                          bRequest: UVCRequestCodes.setCurrent.rawValue,
                                          wValue: UInt16(uvcSelector << 8),
                                          wIndex: UInt16(uvcUnit << 8) | UInt16(uvcInterface),
                                          wLength: UInt16(payload.count),
                                          pData: baseAddress,
                                          wLenDone: 0)
            do {
                try submit(&request)
                return true
            } catch {
                return false
            }
        }
    }

    func updateIsCapable() {
        isCapable = getDataFor(type: UVCRequestCodes.getInfo, length: 1) != 0
    }

    private func performRequest(type: UVCRequestCodes,
                                length: Int,
                                requestType: UInt8,
                                value: Int = 0) throws -> Int {
        guard uvcUnit >= 0 else {
            throw UVCError.invalidUnitId
        }

        var value = value

        try withUnsafeMutablePointer(to: &value, { value in
            var request = IOUSBDevRequest(bmRequestType: requestType,
                                          bRequest: UInt8(type.rawValue),
                                          wValue: UInt16(uvcSelector<<8),
                                          wIndex: UInt16(uvcUnit<<8) | UInt16(uvcInterface),
                                          wLength: UInt16(length),
                                          pData: value,
                                          wLenDone: 0)
            try submit(&request)
        })
        return value
    }

    private func submit(_ request: inout IOUSBDevRequest) throws {
        if #available(macOS 12.0, *) {
            guard interface.pointee.pointee.ControlRequest(interface, 0, &request) == kIOReturnSuccess else {
                throw UVCError.requestError
            }
            return
        }

        guard interface.pointee.pointee.USBInterfaceOpenSeize(interface) == kIOReturnSuccess else {
            throw UVCError.requestError
        }
        defer { _ = interface.pointee.pointee.USBInterfaceClose(interface) }

        guard interface.pointee.pointee.ControlRequest(interface, 0, &request) == kIOReturnSuccess else {
            throw UVCError.requestError
        }
    }

    private func USBmakebmRequestType(direction: Int, type: Int, recipient: Int) -> UInt8 {
        return UInt8((direction & kUSBRqDirnMask) << kUSBRqDirnShift) |
            UInt8((type & kUSBRqTypeMask) << kUSBRqTypeShift)|UInt8(recipient & kUSBRqRecipientMask)

    }
}
