//
//  ChartViewExtension.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 10/11/26.
//

import SwiftUI
import Charts

extension View {
    func chartText(title: String? = nil, text: String? = nil) -> some View {
        self
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let frameAnchor = chartProxy.plotFrame {
                        let frame = geometry[frameAnchor]
                        
                        VStack {
                            if let title {
                                Text(title)
                                    .primaryTextStyle()
                            }
                            if let text {
                                Text(text)
                                    .primaryTextStyle()
                            }
                        }
                        .position(
                            x: frame.midX,
                            y: frame.midY
                        )
                    }
                }
            }
    }
}
