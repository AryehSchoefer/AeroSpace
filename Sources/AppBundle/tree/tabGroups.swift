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

struct TabTile: Equatable {
    var visibleId: UInt32
    var tabIds: Set<UInt32>
}

struct TabGroupScan: Equatable {
    var visibleIds: Set<UInt32> = []
    var groups: [UInt32: Set<UInt32>] = [:]
}

enum TabTileOutcome: Equatable {
    case keep(TabTile)
    case merged
    case dead
}

struct TabReconcileResult: Equatable {
    var outcomes: [TabTileOutcome]
    var newGroups: [TabTile]
}

// Hidden tabs can't be observed directly, so ids leave a tile only on positive evidence:
// they are dead, they belong to another tile's group, or they are visible on their own (dragged out)
func reconcileTabGroups(_ tiles: [TabTile], _ scan: TabGroupScan, aliveIds: Set<UInt32>) -> TabReconcileResult {
    var tiles = tiles.map { TabTile(visibleId: $0.visibleId, tabIds: $0.tabIds.intersection(aliveIds)) }
    let hadAliveIds = tiles.map { !$0.tabIds.isEmpty }
    var newGroups: [TabTile] = []

    for visibleId in scan.groups.keys.sorted() {
        let members = scan.groups[visibleId].orDie()
        let owners = tiles.indices.filter { !tiles[$0].tabIds.isDisjoint(with: members) }
        let owner = owners.first(where: { tiles[$0].tabIds.contains(visibleId) })
            ?? owners.max(by: { tiles[$0].tabIds.intersection(members).count < tiles[$1].tabIds.intersection(members).count })
        guard let owner else {
            newGroups.append(TabTile(visibleId: visibleId, tabIds: members))
            continue
        }
        for other in owners where other != owner {
            tiles[other].tabIds.subtract(members)
        }
        tiles[owner].tabIds.formUnion(members)
        tiles[owner].visibleId = visibleId
    }

    let groupVisibleIds = Set(scan.groups.keys)
    for index in tiles.indices where !tiles[index].tabIds.isEmpty {
        let visible = tiles[index].tabIds.intersection(scan.visibleIds)
        let keep = visible.intersection(groupVisibleIds).min()
            ?? (visible.contains(tiles[index].visibleId) ? tiles[index].visibleId : visible.min())
        if let keep {
            tiles[index].tabIds.subtract(visible.subtracting([keep]))
            tiles[index].visibleId = keep
        } else if !tiles[index].tabIds.contains(tiles[index].visibleId) {
            tiles[index].visibleId = tiles[index].tabIds.min().orDie()
        }
    }

    let outcomes: [TabTileOutcome] = tiles.indices.map { index in
        switch (tiles[index].tabIds.isEmpty, hadAliveIds[index]) {
            case (false, _): .keep(tiles[index])
            case (true, true): .merged
            case (true, false): .dead
        }
    }
    return TabReconcileResult(outcomes: outcomes, newGroups: newGroups)
}
