import SwiftUI

struct MetalSettingbuttonView: UIViewRepresentable {
    static let targetSize: CGSize = CGSize(width: 720/6, height: 720/6)

    typealias UIViewType = UIView

    @Environment(MetalViewModel.self) var viewModel

    func makeUIView(context: Context) -> UIView {
        let view = MetalLayerView(frame: CGRect(origin: .zero, size: MetalSettingbuttonView.targetSize))
        view.backgroundColor = .clear
        view.isOpaque = false

        if let layer = view.layer as? CAMetalLayer {
            layer.pixelFormat = .bgra8Unorm
            layer.frame = view.frame
            layer.drawableSize = view.bounds.size
            layer.isOpaque = false
            layer.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
            viewModel.setDrawTarget(metalLayer: layer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {

    }
}

class MetalLayerView: UIView {
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
}
