//
//  EDMenuView.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 02/11/2024.
//

import SwiftUI

struct EDMenuView<Content: View>: View {
    @StateObject
    private var viewModel = EDMenuViewModel()

    @ViewBuilder
    var content: Content

    var body: some View {
        HStack(spacing: 0) {
            if #available(iOS 18.0, *) {
                ForEach(subviews: content) { subview in
                    subview
                }
            } else {
                content
            }
        }
        .environmentObject(viewModel)
        .padding(.bottom, 8)
        .background(Color.accentColor.opacity(0.2))
        .background {
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct EDMenuItemView: View {
    @EnvironmentObject
    var menuViewModel: EDMenuViewModel

    var text: String
    var selected: Bool {
        menuViewModel.selectedText == text
    }

    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .foregroundStyle(selected ? Color.black : .accentColor)
            .background(selected ? Color.accentColor : .clear)
            .contentShape(Rectangle())
            .onTapGesture {
                menuViewModel.select(text)
            }
            .onAppear {
                if menuViewModel.selectedText == nil {
                    menuViewModel.select(text)
                }
            }
    }

    init(_ text: String) {
        self.text = text
    }
}

class EDMenuViewModel: ObservableObject {
    @Published
    var selectedText: String?

    func select(_ text: String) {
        withAnimation {
            selectedText = text
        }
    }
}

#Preview {
    EDMenuView {
        EDMenuItemView("item1")
        EDMenuItemView("item3")
    }
}
