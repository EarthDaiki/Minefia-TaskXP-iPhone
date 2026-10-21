//
//  CustomDisclosureStyle.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 10/4/26.
//

import SwiftUI

struct CustomDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label
                    
                    Image(systemName: "chevron.right")
                        .navigationIndicatorStyle()
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if configuration.isExpanded {
                configuration.content
            }
        }
        
        
    }
}
