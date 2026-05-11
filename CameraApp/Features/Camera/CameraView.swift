import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        GeometryReader { geometry in
            let screenSize = UIScreen.main.bounds.size
            let previewWidth = screenSize.width
            let shutterSize: CGFloat = 54
            let shutterBottomInset: CGFloat = 4
            let previewButtonGap: CGFloat = 20
            let screenHeight = screenSize.height
            let shutterCenterY = screenHeight - shutterBottomInset - shutterSize / 2
            let maxPreviewHeight = shutterCenterY - shutterSize / 2 - previewButtonGap
            let previewHeight = min(previewWidth * 4 / 3, maxPreviewHeight)

            ZStack(alignment: .top) {
                previewArea
                    .frame(width: previewWidth, height: previewHeight)
                    .clipped()

                shutterButton
                    .position(x: previewWidth / 2, y: shutterCenterY)
            }
            .frame(width: previewWidth, height: screenHeight, alignment: .top)
            .background(Color.black.ignoresSafeArea())
        }
        .ignoresSafeArea(edges: [.top, .bottom])
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

    private var shutterButton: some View {
        Button {
            viewModel.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 54, height: 54)
                Circle()
                    .fill(.white)
                    .frame(width: 42, height: 42)
            }
        }
        .disabled(!viewModel.canCapturePhoto)
        .opacity(viewModel.canCapturePhoto ? 1 : 0.45)
        .accessibilityLabel("Capture photo")
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
