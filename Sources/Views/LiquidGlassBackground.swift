import SwiftUI

/// Authentic Tahoe / Liquid Glass card styling:
/// Highly translucent backdrop with luminous specular rim lighting and soft ambient depth
struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Glass body - translucent acrylic wash that lets the underlying wallpaper vibrancy through
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    
                    // Subtle light dispersion gradient from top to bottom
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Tahoe luminous glass rim border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.40),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(LiquidGlassCard(cornerRadius: cornerRadius))
    }
}
