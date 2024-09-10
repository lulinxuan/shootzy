import SwiftUI
import RealityKit

@main
struct GunShotApp: App {
    @State private var immersionState: ImmersionStyle = .mixed
    @State private var model = Model()
    @State var metalViewModel = MetalViewModel(colorPixelFormat: .bgra8Unorm)


    var body: some SwiftUI.Scene {
        ImmersiveSpace(id: "Gun") {
            HandSpace(trackingModel: TrackingModelContainer.trackingModel)
                .environment(model)
                .environment(metalViewModel)
        }
        .upperLimbVisibility(.hidden)
        .immersionStyle(selection: $immersionState, in: .mixed)
    }
}

@MainActor
enum TrackingModelContainer {
    private(set) static var trackingModel = TrackingModel()
}
