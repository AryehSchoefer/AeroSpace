import AppKit
import Common

struct TabCandidate: Equatable {
    let id: UInt32
    let title: String
    let rect: CGRect?
}

/// Tab labels are live window titles, while hidden tab frames go stale after relayout,
/// so the title decides and the frame only breaks ties.
func matchHiddenTabIds(
    tabTitles: [String],
    visibleTitle: String,
    visibleRect: CGRect?,
    candidates: [TabCandidate],
    stickyIds: Set<UInt32>,
) -> Set<UInt32> {
    var remainingTitles = tabTitles
    if let index = remainingTitles.firstIndex(of: visibleTitle) {
        remainingTitles.remove(at: index)
    }
    func score(_ candidate: TabCandidate) -> Int {
        (stickyIds.contains(candidate.id) ? 2 : 0) + (visibleRect != nil && candidate.rect == visibleRect ? 1 : 0)
    }
    var pool = candidates.sorted { score($0) != score($1) ? score($0) > score($1) : $0.id < $1.id }
    var result: Set<UInt32> = []
    for title in remainingTitles {
        if let index = pool.firstIndex(where: { $0.title == title }) {
            result.insert(pool.remove(at: index).id)
        }
    }
    return result
}
