import AVFoundation
import Combine
import Foundation

@MainActor
final class CameraViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case requestingPermission
        case authorized
        case denied
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var statusMessage: String?

    private let cameraService = CameraService()

    var session: AVCaptureSession {
        cameraService.session
    }

    var canCapturePhoto: Bool {
        state == .authorized
    }

    func prepareCamera() async {
        state = .requestingPermission

        let isAuthorized = await cameraService.requestCameraPermission()
        guard isAuthorized else {
            state = .denied
            return
        }

        do {
            try await cameraService.configure()
            state = .authorized
            cameraService.start()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func stopCamera() {
        cameraService.stop()
    }

    func capturePhoto() {
        statusMessage = "Capturing..."

        cameraService.capturePhoto { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    self?.showTemporaryStatus("Saved to Photos")
                case .failure(let error):
                    self?.showTemporaryStatus(error.localizedDescription)
                }
            }
        }
    }

    private func showTemporaryStatus(_ message: String) {
        statusMessage = message

        Task {
            try? await Task.sleep(for: .seconds(2))
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }
}
