import AVFoundation
import Photos

final class CameraService: NSObject {
    enum CameraError: LocalizedError {
        case noCamera
        case cannotAddInput
        case cannotAddOutput
        case captureDataUnavailable
        case photoLibraryDenied

        var errorDescription: String? {
            switch self {
            case .noCamera:
                "No available rear camera was found."
            case .cannotAddInput:
                "The camera input could not be added."
            case .cannotAddOutput:
                "The photo output could not be added."
            case .captureDataUnavailable:
                "The captured photo data was unavailable."
            case .photoLibraryDenied:
                "Photo library permission is required to save photos."
            }
        }
    }

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    private var isConfigured = false

    func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func configure() async throws {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    try self.configureSessionIfNeeded()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func start() {
        sessionQueue.async {
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping (Result<Void, Error>) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off

        let delegate = PhotoCaptureDelegate { [weak self] result in
            self?.photoCaptureDelegate = nil
            completion(result)
        }

        photoCaptureDelegate = delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    private func configureSessionIfNeeded() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        defer {
            session.commitConfiguration()
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCamera
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality

        isConfigured = true
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<Void, Error>) -> Void

    init(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            completion(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            completion(.failure(CameraService.CameraError.captureDataUnavailable))
            return
        }

        savePhotoData(data)
    }

    private func savePhotoData(_ data: Data) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                self.completion(.failure(CameraService.CameraError.photoLibraryDenied))
                return
            }

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            } completionHandler: { _, error in
                if let error {
                    self.completion(.failure(error))
                } else {
                    self.completion(.success(()))
                }
            }
        }
    }
}
