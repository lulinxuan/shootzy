import SwiftUI
import RealityKitContent
import RealityKit

struct TargetSettingView: View {
    
    @Environment(Model.self) var model

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("Add toys:").font(.system(size: 60))
            Text("Item will be placed at your left hand's index finger tip")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 60) {
                    model3D(name: "ToyRocket", scale: 1)
                    {
                        self.model.addingToy = .Rocket
                    }
                    model3D(name: "Pepsi_Cans", scale: 1)
                    {
                        self.model.addingToy = .Pepsi
                    }
                    model3D(name: "cube", scale: 0.7){
                        if self.model.boxStatus == .Ready{
                            self.model.boxStatus = .Adding
                        }
                    }
                    model3D(name: "Baby_duck", scale: 0.8){
                        self.model.addingToy = .Duck
                    }
                    
                    model3D(name: "dart_board", scale: 1, rotationAngle: 0){
                        self.model.addingToy = .DartBoard
                        self.model.gunType = .dartGun
                    }
                    
                    model3D(name: "Basketball_Hoop_Panel", scale: 1, rotationAngle: 0, bundle: .main){
                        self.model.addingToy = .BasketballPanel
                        self.model.gunType = .basketballGun
                    }
                }
            }
            
            Spacer()
            Spacer()
        }
    }
}

func model3D(name: String, scale: CGFloat, rotationAngle: Double = 45, depth: CGFloat = 0, bundle: Bundle = realityKitContentBundle, action: @escaping () -> Void) -> some View {
    return Model3D(named: name, bundle: bundle) { m in
        m.resizable()
         .scaledToFit()
         .rotation3DEffect(
             Rotation3D(
                 eulerAngles: .init(angles: [0, rotationAngle, 0], order: .xyz)
             )
         )
         .offset(z: depth)
         .frame(width: 500*scale, height: 500*scale)
         .hoverEffect()
         .onTapGesture(perform: action)
    } placeholder: {
        ProgressView()
    }
}

#Preview {
    TargetSettingView().environment(Model())
}
