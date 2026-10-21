//
//  Modifier.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 10/4/26.
//

import SwiftUI

struct PrimaryTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .foregroundStyle(AppColors.textPrimary)
    }
}

struct SecondaryTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .foregroundStyle(AppColors.textSecondary)
    }
}

struct EmphasizedTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appSemiboldBody)
            .foregroundStyle(AppColors.textPrimary)
    }
}

struct CaptionTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appCaption)
            .foregroundStyle(AppColors.textSecondary)
    }
}

struct TitleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appTitle)
            .foregroundStyle(AppColors.textPrimary)
    }
}

struct SectionTitleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appCaption)
            .foregroundStyle(AppColors.textSecondary)
    }
}

struct RowTitleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appSemiboldBody)
            .foregroundStyle(AppColors.textPrimary)
    }
}

struct EmptyStateTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appEmptyTitle)
            .foregroundStyle(AppColors.textPrimary)
    }
}

struct DetailTitleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appCaption)
            .foregroundStyle(AppColors.textSecondary)
    }
}

struct DetailValueTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .foregroundStyle(AppColors.textPrimary)
    }
}

struct DialogTitleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appHeadline)
            .foregroundStyle(AppColors.textPrimary)
    }
}

struct DialogMessageTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appSubheadline)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
    }
}

struct AppCardStyle: ViewModifier {
    private let cornerRadius: CGFloat
    private let opacity: Double

    init(cornerRadius: CGFloat = 12, opacity: Double = 1) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                AppColors.card.opacity(opacity),
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
    }
}

struct AppInputCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .primaryTextStyle()
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AppTaskCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AppTagPillStyle: ViewModifier {
    private let isSelected: Bool
    init(isSelected: Bool) {
        self.isSelected = isSelected
    }

    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .padding(12)
            .foregroundStyle(AppColors.textPrimary)
            .background(
                isSelected ? AppColors.selectedButton : AppColors.button,
                in: RoundedRectangle(cornerRadius: 12)
            )
    }
}

struct AppDisclosureCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                AppColors.card.opacity(0.4),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.textSecondary.opacity(0.4), lineWidth: 1)
            }
            .disclosureGroupStyle(CustomDisclosureStyle())
    }
}

struct AppPrimaryButtonStyle: ViewModifier {
    private let isDisabled: Bool

    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }

    func body(content: Content) -> some View {
        content
            .font(.appSemiboldBody)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                AppColors.button.opacity(isDisabled ? 0.4 : 1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .opacity(isDisabled ? 0.6 : 1)
    }
}

struct AppFilterButtonStyle: ViewModifier {
    private let isSelected: Bool

    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }

    func body(content: Content) -> some View {
        content
            .font(.appSemiboldBody)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(
                isSelected ? AppColors.selectedButton : AppColors.button,
                in: Capsule()
            )
            .overlay {
                if isSelected {
                    Capsule()
                        .stroke(AppColors.selectedStroke, lineWidth: 2)
                }
            }
    }
}

struct AppPickerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appSemiboldBody)
            .tint(AppColors.textPrimary)
            .padding()
            .background(
                AppColors.card,
                in: RoundedRectangle(cornerRadius: 8)
            )
    }
}

struct AppButtonImageStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .semibold))
            .tint(AppColors.textPrimary)
    }
}

struct NavigationIndicatorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
//            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 5)
            .foregroundStyle(AppColors.navigationIndicator)
            .font(.caption.weight(.semibold))
    }
}

struct AppListRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(AppColors.card)
            .listRowSeparatorTint(AppColors.separator)
    }
}

struct AppCardWithStrokeStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .primaryTextStyle()
            .background(
                AppColors.card,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.primary.opacity(0.45))
            }
    }
}

struct AppHomeViewSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.textSecondary.opacity(0.4), lineWidth: 1)
            }
    }
}

extension View {
    func primaryTextStyle() -> some View {
        modifier(PrimaryTextStyle())
    }

    func secondaryTextStyle() -> some View {
        modifier(SecondaryTextStyle())
    }

    func emphasizedTextStyle() -> some View {
        modifier(EmphasizedTextStyle())
    }

    func captionTextStyle() -> some View {
        modifier(CaptionTextStyle())
    }
    
    func titleTextStyle() -> some View {
        modifier(TitleTextStyle())
    }
    
    func sectionTitleTextStyle() -> some View {
        modifier(SectionTitleTextStyle())
    }

    func rowTitleTextStyle() -> some View {
        modifier(RowTitleTextStyle())
    }

    func emptyStateTextStyle() -> some View {
        modifier(EmptyStateTextStyle())
    }

    func detailTitleTextStyle() -> some View {
        modifier(DetailTitleTextStyle())
    }

    func detailValueTextStyle() -> some View {
        modifier(DetailValueTextStyle())
    }

    func dialogTitleTextStyle() -> some View {
        modifier(DialogTitleTextStyle())
    }

    func dialogMessageTextStyle() -> some View {
        modifier(DialogMessageTextStyle())
    }

    func appCard(cornerRadius: CGFloat = 12, opacity: Double = 1) -> some View {
        modifier(AppCardStyle(cornerRadius: cornerRadius, opacity: opacity))
    }

    func appInputCard() -> some View {
        modifier(AppInputCardStyle())
    }

    func appTaskCard() -> some View {
        modifier(AppTaskCardStyle())
    }

    func appTagPill(isSelected: Bool) -> some View {
        modifier(AppTagPillStyle(isSelected: isSelected))
    }

    func appDisclosureCard() -> some View {
        modifier(AppDisclosureCardStyle())
    }
    
    func appPrimaryButtonStyle(isDisabled: Bool = false) -> some View {
        modifier(AppPrimaryButtonStyle(isDisabled: isDisabled))
    }
    
    func appFilterButtonStyle(isSelected: Bool = false) -> some View {
        modifier(AppFilterButtonStyle(isSelected: isSelected))
    }
    
    func appPickerStyle() -> some View {
        modifier(AppPickerStyle())
    }
    
    func appButtonImageStyle() -> some View {
        modifier(AppButtonImageStyle())
    }
    
    func navigationIndicatorStyle() -> some View {
        modifier(NavigationIndicatorStyle())
    }
    
    func appListRowStyle() -> some View {
        modifier(AppListRowStyle())
    }
    
    func appCardWithStrokeStyle() -> some View {
        modifier(AppCardWithStrokeStyle())
    }
    
    func appHomeViewSectionStyle() -> some View {
        modifier(AppHomeViewSectionStyle())
    }
}
