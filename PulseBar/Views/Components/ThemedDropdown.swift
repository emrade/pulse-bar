//
//  ThemedDropdown.swift
//  PulseBar
//
//  Created by Emmanuel Fache on 13/08/2025.
//

import SwiftUI

struct ThemedDropdown<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let displayName: (T) -> String
    let onSelectionChanged: (T) -> Void
    
    @State private var isExpanded = false
    @State private var isHovered = false
    
    init(
        title: String,
        selection: Binding<T>,
        options: [T],
        displayName: @escaping (T) -> String,
        onSelectionChanged: @escaping (T) -> Void
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.displayName = displayName
        self.onSelectionChanged = onSelectionChanged
    }
    
    var body: some View {
        ZStack {
            // Dropdown button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(displayName(selection))
                        .themedSurfaceText()
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .themedSurfaceVariantText()
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.themedSurfaceVariant)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    isHovered || isExpanded ? Color.themedAccent.opacity(0.6) : Color.themedOutline.opacity(0.5),
                                    lineWidth: 0.5
                                )
                        )
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }
            
            // Dropdown menu overlay
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            selection = option
                            onSelectionChanged(option)
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isExpanded = false
                            }
                        }) {
                            HStack {
                                Text(displayName(option))
                                    .themedSurfaceText()
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if option == selection {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.themedAccent)
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Rectangle()
                                    .fill(option == selection ? Color.themedAccent.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.themedSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.themedOutline.opacity(0.8), lineWidth: 0.5)
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .offset(y: 20) // Position below the button
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .top)),
                    removal: .opacity
                ))
                .zIndex(1000)
            }
        }
        // Close dropdown when clicking outside
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if isExpanded {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded = false
                        }
                    }
                }
        )
    }
}


#Preview {
    enum TestOption: String, CaseIterable {
        case option1 = "Option 1"
        case option2 = "Option 2"
        case option3 = "Option 3"
    }
    
    @Previewable @State var selectedOption = TestOption.option1
    
    return ThemedDropdown(
        title: "Test",
        selection: $selectedOption,
        options: Array(TestOption.allCases),
        displayName: { $0.rawValue },
        onSelectionChanged: { _ in }
    )
    .frame(width: 200)
    .padding()
}