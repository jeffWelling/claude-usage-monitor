import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        Text(viewModel.menuBarText)
            .monospacedDigit()
    }
}
