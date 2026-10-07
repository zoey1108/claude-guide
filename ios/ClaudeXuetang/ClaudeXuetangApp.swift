import SwiftUI

@main
struct ClaudeXuetangApp: App {
    var body: some Scene {
        WindowGroup {
            LessonWebView()
                .ignoresSafeArea()
                .background(Color("PaperColor", bundle: nil).ignoresSafeArea())
        }
    }
}
