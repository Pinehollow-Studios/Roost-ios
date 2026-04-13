import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class ResumeSnapshotStore {
    private(set) var snapshotImage: UIImage?
    var isShowingSnapshot = false

    @ObservationIgnored
    private var hideTask: Task<Void, Never>?

    func captureCurrentWindow() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) else {
            return
        }

        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        snapshotImage = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }

    func showForResume() {
        guard snapshotImage != nil else { return }

        hideTask?.cancel()
        isShowingSnapshot = true

        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                isShowingSnapshot = false
            }
        }
    }

    func clear() {
        hideTask?.cancel()
        hideTask = nil
        snapshotImage = nil
        isShowingSnapshot = false
    }
}
