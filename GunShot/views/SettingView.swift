import SwiftUI

struct SettingView: View {
    
    @Environment(Model.self) var model
    let menuItems = SettingMenuItem.getMenuItems()
    @State private var selectedMenuItem: SettingMenuItem = SettingMenuItem.getMenuItems()[0]

    var body: some View {
        NavigationSplitView {
            List(menuItems) { item in
                Button(item.label) {
                    selectedMenuItem = item
                }.font(.system(size: 60))
                    .frame(width: 300, height: 600, alignment: .center)
                .background(selectedMenuItem.label == item.label ? .gray : .clear)    
            }
            Button("", image: ImageResource(name: "reset", bundle: Bundle.main)) {
                model.clearingToy = true
            }.font(.system(size: 80))
             .foregroundStyle(.blue)
            Spacer()

        } detail: {
            if selectedMenuItem.label == "Targets"{
                TargetSettingView()
                    .environment(model)
                    .navigationTitle("Add Targets")
                    .padding(30)
                    .hoverEffect()
            } else if selectedMenuItem.label == "Gun"{
                GunSpecSettingView()
                    .environment(model)
                    .navigationTitle("Customize Gun")
                    .padding(30)
                    .hoverEffect()
            }
            if self.model.resourceLoaded{
                    Button("Start!", image: ImageResource(name: "shooting", bundle: Bundle.main)) {
                        model.finishSetting = true
                    }.font(.system(size: 80))
                     .foregroundStyle(.red)
                Spacer()

            }else{
                ProgressView()
            }
            
            Spacer()
            Spacer()

        }.frame(width: 1600, height: 1600)
    }
}

#Preview {
    SettingView().environment(Model())
}
