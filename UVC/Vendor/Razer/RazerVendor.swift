//
//  RazerVendor.swift
//  UVC
//

import Foundation

public enum RazerVendor {
    public static let vendorID: UInt16 = 0x1532
    public static let kiyoProProductID: UInt16 = 0x0E05

    public static func isKiyoPro(vendorID: UInt16, productID: UInt16) -> Bool {
        return vendorID == Self.vendorID && productID == Self.kiyoProProductID
    }
}
