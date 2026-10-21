//
//  TextExtension.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 10/9/26.
//

import SwiftUI

extension Text {
    func appInputPromptStyle() -> Text {
        self
            .font(.appBody)
            .foregroundStyle(AppColors.textSecondary)
    }
}
