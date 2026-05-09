import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Color.black.ignoresSafeArea()
                    .frame(height: 0)

                topBar
                    .frame(height: 116)
                    .padding(.top, geometry.safeAreaInsets.top)

                previewArea
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(alignment: .bottom) {
                        lensSelector
                            .padding(.bottom, 22)
                    }

                bottomControls
                    .frame(maxWidth: .infinity)
            }
            .background(Color.black.ignoresSafeArea())
        }
        .task {
            await viewModel.prepareCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    levelRow(label: "L")
                    levelRow(label: "R")
                }

                Spacer()

                HStack(spacing: 20) {
                    Text("Log")
                        .foregroundStyle(.white.opacity(0.22))
                    Text("照片")
                        .foregroundStyle(.white)
                    Text("视频")
                        .foregroundStyle(.white.opacity(0.38))
                }
                .font(.subheadline.weight(.semibold))

                Spacer()

                HStack(spacing: 16) {
                    Image(systemName: "bolt.slash")
                    Image(systemName: "circle.circle")
                    Image(systemName: "circle.grid.3x3.fill")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
            }

            Text("如何选择相机模式")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color(red: 1.0, green: 0.82, blue: 0.26), in: RoundedRectangle(cornerRadius: 9))
                .overlay(alignment: .top) {
                    Triangle()
                        .fill(Color(red: 1.0, green: 0.82, blue: 0.26))
                        .frame(width: 24, height: 12)
                        .offset(y: -10)
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func levelRow(label: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))

            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(index < 4 ? Color.green : index == 4 ? Color.orange : Color.white.opacity(0.22))
                    .frame(width: 7, height: 7)
            }
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

    private var lensSelector: some View {
        HStack(spacing: 12) {
            lensOption(title: "13", unit: "mm", isSelected: false)
            lensOption(title: "24    48", unit: "mm      mm", isSelected: true)
            lensOption(title: "120", unit: "mm", isSelected: false)
        }
    }

    private func lensOption(title: String, unit: String, isSelected: Bool) -> some View {
        VStack(spacing: 1) {
            Image(systemName: isSelected ? "rectangle.split.3x1.fill" : "rectangle.split.3x1")
                .font(.body)
            Text(title)
                .font(.headline.weight(.bold))
            Text(unit)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(isSelected ? Color.mint : .white.opacity(0.86))
        .frame(width: isSelected ? 100 : 68, height: 58)
        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 12) {
            toolRow
            shutterRow
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(Color.black)
    }

    private var toolRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                toolItem(icon: "arrow.triangle.2.circlepath", title: "前置")
                toolItem(icon: "viewfinder.circle", title: "对焦", marker: "A")
                toolItem(icon: "circle.lefthalf.filled", title: "白平衡", marker: "A")
                toolItem(icon: "textformat.size", title: "ISO", marker: "A")
                toolItem(icon: "camera.aperture", title: "快门", marker: "A")
                toolItem(icon: "plusminus.circle", title: "补偿")
                toolItem(icon: "gearshape", title: "设置")
            }
            .padding(.horizontal, 22)
        }
        .frame(height: 54)
    }

    private func toolItem(icon: String, title: String, marker: String? = nil) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))

                if let marker {
                    Text(marker)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.mint)
                        .offset(x: 7, y: 4)
                }
            }
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(width: 58)
    }

    private var shutterRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.95))
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.black.opacity(0.7))
                }

            Button {
                viewModel.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 5)
                        .frame(width: 72, height: 72)
                    Circle()
                        .fill(.white)
                        .frame(width: 56, height: 56)
                }
            }
            .disabled(!viewModel.canCapturePhoto)
            .opacity(viewModel.canCapturePhoto ? 1 : 0.45)
            .accessibilityLabel("Capture photo")

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.green, .yellow, .orange, .pink, .purple, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.9))
                        .padding(5)
                }
        }
        .padding(.horizontal, 34)
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

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
