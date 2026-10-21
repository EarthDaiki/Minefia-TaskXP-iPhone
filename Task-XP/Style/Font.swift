//
//  SwiftUIView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 10/4/26.
//

import SwiftUI

extension Font {
    static let appBody =
        Font.custom(
            "Poppins-Medium",
            size: 17,
            relativeTo: .body
        )

    static let appBoldBody =
        Font.custom(
            "Poppins-Bold",
            size: 17,
            relativeTo: .body
        )

    static let appCaption =
        Font.custom(
            "Poppins-Regular",
            size: 12,
            relativeTo: .caption
        )
    
    static let appSemiboldBody =
        Font.custom(
            "Poppins-SemiBold",
            size: 17,
            relativeTo: .body
        )

    static let appHeadline =
        Font.custom(
            "Poppins-SemiBold",
            size: 17,
            relativeTo: .headline
        )

    static let appSubheadline =
        Font.custom(
            "Poppins-Regular",
            size: 15,
            relativeTo: .subheadline
        )
    
    static let appTitle =
        Font.custom(
            "Poppins-Bold",
            size: 22,
            relativeTo: .title2
        )
    
    static let appEmptyTitle =
        Font.custom(
            "Poppins-SemiBold",
            size: 17,
            relativeTo: .headline
        )
}
