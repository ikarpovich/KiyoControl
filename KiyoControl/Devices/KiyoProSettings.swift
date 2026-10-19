//
//  KiyoProSettings.swift
//  KiyoControl
//

import Foundation
import Observation
import UVC

@MainActor
@Observable
final class KiyoProSettings {
    @ObservationIgnored private let actor: UVCDeviceActor

    private(set) var autofocusMode: KiyoProAutofocusMode?
    private(set) var hdrEnabled: Bool?
    private(set) var hdrMode: KiyoProHDRMode?
    private(set) var fieldOfView: KiyoProFieldOfView?
    private(set) var isApplying = false
    private(set) var statusMessage: String?

    init(actor: UVCDeviceActor) {
        self.actor = actor
    }

    func selectAutofocusMode(_ mode: KiyoProAutofocusMode?) {
        guard let mode else { return }
        apply(.autofocusMode(mode))
    }

    func selectHDR(_ enabled: Bool?) {
        guard let enabled else { return }
        apply(.hdrEnabled(enabled))
    }

    func selectHDRMode(_ mode: KiyoProHDRMode?) {
        guard let mode else { return }
        apply(.hdrMode(mode))
    }

    func selectFieldOfView(_ fieldOfView: KiyoProFieldOfView?) {
        guard let fieldOfView else { return }
        apply(.fieldOfView(fieldOfView))
    }

    private func apply(_ setting: RazerKiyoProSetting) {
        guard !isApplying else { return }
        isApplying = true
        statusMessage = nil
        let actor = self.actor

        Task { @MainActor [weak self] in
            let succeeded = await actor.setKiyoProSetting(setting)
            guard let self else { return }

            if succeeded {
                switch setting {
                case .autofocusMode(let value):
                    self.autofocusMode = value
                case .hdrEnabled(let value):
                    self.hdrEnabled = value
                case .hdrMode(let value):
                    self.hdrMode = value
                case .fieldOfView(let value):
                    self.fieldOfView = value
                }
                self.statusMessage = "Setting saved to the camera."
            } else {
                self.statusMessage = "Could not apply the setting to the camera."
            }
            self.isApplying = false
        }
    }
}
