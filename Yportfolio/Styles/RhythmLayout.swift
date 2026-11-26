import SwiftUI

/// Editorial gallery rhythm: two tall cards side by side, then one wide card,
/// repeated. A trailing single card becomes wide, so rows never end half-empty.
///
/// The pattern is deterministic (it depends only on the position), which keeps the
/// composition regular and calm, and lets each card adapt its content to its slot.
/// All cards live in one container, so sorting, pinning and deleting animate as
/// moves. With `singleColumn` (accessibility text sizes) every card is wide.
struct RhythmLayout: Layout {
    enum Slot { case tall, wide }

    var tallHeight: CGFloat
    var spacing: CGFloat = DS.Spacing.sm
    var singleColumn = false

    /// Slot of the card at `index` in a collection of `count` cards.
    static func slot(at index: Int, count: Int, singleColumn: Bool = false) -> Slot {
        guard !singleColumn else { return .wide }
        switch index % 3 {
        case 0:  return index == count - 1 ? .wide : .tall   // lone last card → wide
        case 1:  return .tall
        default: return .wide
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 360
        return CGSize(width: width, height: frames(width: width, subviews: subviews).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, frames(width: bounds.width, subviews: subviews).frames) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                          proposal: ProposedViewSize(frame.size))
        }
    }

    private func frames(width: CGFloat, subviews: Subviews) -> (frames: [CGRect], height: CGFloat) {
        let half = (width - spacing) / 2
        var frames: [CGRect] = []
        var y: CGFloat = 0
        var index = 0
        while index < subviews.count {
            if index > 0 { y += spacing }
            switch Self.slot(at: index, count: subviews.count, singleColumn: singleColumn) {
            case .tall:
                frames.append(CGRect(x: 0, y: y, width: half, height: tallHeight))
                frames.append(CGRect(x: half + spacing, y: y, width: half, height: tallHeight))
                y += tallHeight
                index += 2
            case .wide:
                let height = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil)).height
                frames.append(CGRect(x: 0, y: y, width: width, height: height))
                y += height
                index += 1
            }
        }
        return (frames, y)
    }
}
