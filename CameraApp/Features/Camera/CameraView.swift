import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    previewArea
                        .frame(maxWidth: .infinity)
                        .frame(
                            height: max(
                                geometry.size.height - geometry.safeAreaInsets.top - 96,
                                0
                            )
                        )
                        .padding(.top, geometry.safeAreaInsets.top)

                    controls
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .task {
            await viewModel.prepareCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }

    private var previewArea: some View {
        ZStack {
            Color.black

            switch viewModel.state {
            case .idle, .requestingPermission:
                ProgressView()
                    .tint(.white)
            case .authorized:
                CameraPreviewView(session: viewModel.session)
            case .denied:
                permissionDeniedView
            case .failed(let message):
                errorView(message)
            }
        }
        .clipped()
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
                        .frame(width: 62, height: 62)
                    Circle()
                        .stroke(.white.opacity(0.95), lineWidth: 3)
                        .frame(width: 54, height: 54)
                    Circle()
                        .fill(.white)
                        .frame(width: 42, height: 42)
                }
            }
            .disabled(!viewModel.canCapturePhoto)
            .opacity(viewModel.canCapturePhoto ? 1 : 0.45)
            .accessibilityLabel("Capture photo")

            Spacer()
        }
        .frame(height: 96)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .overlay(alignment: .top) {
            if let message = viewModel.statusMessage {
                Text(message)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.55), in: Capsule())
                    .offset(y: -42)
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
