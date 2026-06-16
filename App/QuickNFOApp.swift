import SwiftUI

@main
struct QuickNFOApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 14) {
                Text("QuickNFO")
                    .font(.system(size: 34, weight: .bold))
                Text("Pré-visualização de ficheiros .nfo no Finder")
                    .foregroundStyle(.secondary)
                Text("Mantém esta aplicação na pasta Aplicações. "
                     + "Seleciona um ficheiro .nfo no Finder e prime a barra de espaço "
                     + "para o ver, ou repara no ícone gerado.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding(.horizontal, 24)
            }
            .padding(36)
            .frame(width: 480, height: 260)
        }
        .windowResizability(.contentSize)
    }
}
