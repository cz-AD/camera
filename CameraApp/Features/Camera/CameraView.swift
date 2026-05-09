import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .idle, .requestingPermission:
                ProgressView()
                    .tint(.white)
            case .authorized:
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()
            case .denied:
                permissionDeniedView
            case .failed(let message):
                errorView(message)
            }

            VStack {
                Spacer()
                controls
            }
            .padding(.bottom, 10)
        }
        .task {
            await viewModel.prepareCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }

    private var controls: some View {
        HStack {
            Spacer()

            Button {
                viewModel.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.18))
                        .frame(width: 66, height: 66)
                    Circle()
                        .stroke(.white.opacity(0.95), lineWidth: 3)
                        .frame(width: 58, height: 58)
                    Circle()
                        .fill(.white)
                        .frame(width: 46, height: 46)
                }
            }
            .disabled(!viewModel.canCapturePhoto)
            .opacity(viewModel.canCapturePhoto ? 1 : 0.45)
            .accessibilityLabel("Capture photo")

            Spacer()
        }
        .overlay(alignment: .top) {
            if let message = viewModel.statusMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.55), in: Capsule())
                    .offset(y: -54)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 12) {
            Text("Camera access is disabled")
                .font(.title3.weight(.semibold))
            Text("Enable camera access in Settings to use the preview and capture photos.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("Camera unavailable")
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding()
    }
}

#Preview {
    CameraView()
}
