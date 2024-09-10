import SwiftUI

struct GunSpecSettingView: View {
    
    @Environment(Model.self) var model
    @State var singleShootMode = false
    @State var firingSpeed: Float = 1
    @State var totalBullet: Float = 7
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Spacer()
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 100) {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()

                    model3D(name: "Handgun_toy", scale: 0.6, rotationAngle: 1.5, depth: -240)
                    {
                        self.model.gunType = .toy
                    }.opacity(self.model.gunType == .toy ? 1 : 0.5)
                   
                    model3D(name: "pepsi_gun", scale: 0.8, rotationAngle: -Double.pi/2, depth: -190)
                    {
                        self.model.gunType = .pepsiGun
                    }.scaleEffect(CGSize(width: 0.6, height: 0.6)).opacity(self.model.gunType == .pepsiGun ? 1 : 0.5)
                    Spacer()

                    model3D(name: "pink_gun", scale: 1, rotationAngle: Double.pi, depth: 140)
                    {
                        self.model.gunType = .pinkGun
                    }.scaleEffect(CGSize(width: 0.8, height: 0.8))
                        .opacity(self.model.gunType == .pinkGun ? 1 : 0.5)
                    Spacer()
                    
                    model3D(name: "basketball_gun", scale: 0.8, rotationAngle: Double.pi/2, depth: 0)
                    {
                        self.model.gunType = .basketballGun
                    }.scaleEffect(CGSize(width: 0.8, height: 0.8))
                        .opacity(self.model.gunType == .basketballGun ? 1 : 0.5)
                
                    model3D(name: "Tracers_Gun_Overwatch", scale: 1, rotationAngle: Double.pi/2, depth: -160)
                    {
                        self.model.gunType = .tracersGun
                    }.scaleEffect(CGSize(width: 0.4, height: 0.4))
                        .opacity(self.model.gunType == .tracersGun ? 1 : 0.5)
                    
                    model3D(name: "dart_gun", scale: 0.8, rotationAngle: Double.pi/2, depth: -300)
                    {
                        self.model.gunType = .dartGun
                    }.scaleEffect(CGSize(width: 0.5, height: 0.5))
                        .opacity(self.model.gunType == .dartGun ? 1 : 0.5)
                    
                    model3D(name: "Portal_Gun", scale: 1, rotationAngle: Double.pi/2, depth: -500)
                    {
                        self.model.gunType = .portalGun
                    }.scaleEffect(CGSize(width: 0.5, height: 0.5))
                        .opacity(self.model.gunType == .portalGun ? 1 : 0.5)
                    
                    model3D(name: "Stylized_Old_Gun", scale: 0.8, rotationAngle: Double.pi, depth: -70)
                    {
                        self.model.gunType = .stylizedOldGun
                    }.opacity(self.model.gunType == .stylizedOldGun ? 1 : 0.5)
                    
                    model3D(name: "crossbow", scale: 1, rotationAngle: 0, depth: -50, bundle: .main)
                    {
                        self.model.gunType = .crossbow
                    }.scaleEffect(CGSize(width: 1, height: 1))
                    .opacity(self.model.gunType == .crossbow ? 1 : 0.5)
                }
            }

            Spacer()
            
            Toggle("Single Fire Mode", isOn: $singleShootMode).onChange(of: singleShootMode) {
                model.singleShootMode = singleShootMode
            }.frame(width: 400, height: 30)
            
            Spacer()
            
            Text("Total bullet count: \(totalBullet, specifier: "%.2f")")
            Slider(
                value: $totalBullet,
                in: 7...200,
                step: 1
            )
            .frame(width: 400, height: 30)
            .onChange(of: totalBullet) { oldValue, newValue in
                model.totalBullet = Int(totalBullet)
            }
            
            Spacer()
            
            
            Text("Firing Speed: \(firingSpeed, specifier: "%.2f")")
            Slider(
                value: $firingSpeed,
                in: 1...10,
                step: 1
            )
            .frame(width: 400, height: 30)
            .onChange(of: firingSpeed) { oldValue, newValue in
                model.shootSpeed = Int(firingSpeed)
            }
            
            Spacer()
            Spacer()
        }
    }
    

}

#Preview {
    GunSpecSettingView().frame(width: 1200, height: 1600).environment(Model())
}
