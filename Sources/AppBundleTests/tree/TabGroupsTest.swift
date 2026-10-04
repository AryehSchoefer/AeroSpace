@testable import AppBundle
import Common
import XCTest

final class TabGroupsTest: XCTestCase {
    private let frame = CGRect(x: 0, y: 39, width: 1800, height: 1130)
    private let otherFrame = CGRect(x: 900, y: 39, width: 900, height: 1130)

    func testMatchesHiddenTabsByTitle() {
        let result = matchHiddenTabIds(
            tabTitles: ["tmux attach", "logs", "tmux"],
            visibleTitle: "tmux",
            visibleRect: frame,
            candidates: [
                TabCandidate(id: 10, title: "tmux attach", rect: frame),
                TabCandidate(id: 11, title: "logs", rect: otherFrame), // stale frame is fine
                TabCandidate(id: 12, title: "unrelated", rect: frame),
            ],
            stickyIds: [],
        )
        assertEquals(result, [10, 11])
    }

    func testSingleTabMatchesNothing() {
        let result = matchHiddenTabIds(
            tabTitles: ["tmux"],
            visibleTitle: "tmux",
            visibleRect: frame,
            candidates: [TabCandidate(id: 10, title: "tmux", rect: frame)],
            stickyIds: [],
        )
        assertEquals(result, [])
    }

    func testDuplicateTitlesTakeOneCandidatePerTab() {
        let result = matchHiddenTabIds(
            tabTitles: ["tmux attach", "tmux attach", "tmux"],
            visibleTitle: "tmux",
            visibleRect: frame,
            candidates: [
                TabCandidate(id: 10, title: "tmux attach", rect: frame),
                TabCandidate(id: 11, title: "tmux attach", rect: frame),
                TabCandidate(id: 12, title: "tmux attach", rect: frame),
            ],
            stickyIds: [],
        )
        assertEquals(result, [10, 11])
    }

    func testFrameMatchBreaksTies() {
        let result = matchHiddenTabIds(
            tabTitles: ["a", "b"],
            visibleTitle: "b",
            visibleRect: frame,
            candidates: [
                TabCandidate(id: 10, title: "a", rect: otherFrame),
                TabCandidate(id: 11, title: "a", rect: frame),
            ],
            stickyIds: [],
        )
        assertEquals(result, [11])
    }

    func testStickyIdsWinOverFrameMatch() {
        let result = matchHiddenTabIds(
            tabTitles: ["a", "b"],
            visibleTitle: "b",
            visibleRect: frame,
            candidates: [
                TabCandidate(id: 10, title: "a", rect: otherFrame),
                TabCandidate(id: 11, title: "a", rect: frame),
            ],
            stickyIds: [10],
        )
        assertEquals(result, [10])
    }

    private func tile(_ visibleId: UInt32, _ tabIds: Set<UInt32>) -> TabTile { TabTile(visibleId: visibleId, tabIds: tabIds) }

    func testPlainWindowsUnchanged() {
        let result = reconcileTabGroups(
            [tile(1, [1]), tile(2, [2])],
            TabGroupScan(visibleIds: [1, 2], groups: [:]),
            aliveIds: [1, 2],
        )
        assertEquals(result, TabReconcileResult(outcomes: [.keep(tile(1, [1])), .keep(tile(2, [2]))], newGroups: []))
    }

    func testNewTabJoinsExistingTile() {
        let result = reconcileTabGroups(
            [tile(1, [1])],
            TabGroupScan(visibleIds: [2], groups: [2: [1, 2]]),
            aliveIds: [1, 2],
        )
        assertEquals(result.outcomes, [.keep(tile(2, [1, 2]))])
        assertEquals(result.newGroups, [])
    }

    func testSwitchTab() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2, 3])],
            TabGroupScan(visibleIds: [3], groups: [3: [1, 2, 3]]),
            aliveIds: [1, 2, 3],
        )
        assertEquals(result.outcomes, [.keep(tile(3, [1, 2, 3]))])
    }

    func testCloseVisibleTab() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2, 3])],
            TabGroupScan(visibleIds: [2], groups: [2: [2, 3]]),
            aliveIds: [2, 3],
        )
        assertEquals(result.outcomes, [.keep(tile(2, [2, 3]))])
    }

    func testLastSiblingClosedBecomesPlainWindow() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2])],
            TabGroupScan(visibleIds: [2], groups: [:]),
            aliveIds: [2],
        )
        assertEquals(result.outcomes, [.keep(tile(2, [2]))])
    }

    func testDragHiddenTabOut() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2, 3])],
            TabGroupScan(visibleIds: [1, 2], groups: [1: [1, 3]]),
            aliveIds: [1, 2, 3],
        )
        assertEquals(result.outcomes, [.keep(tile(1, [1, 3]))])
    }

    func testDragVisibleTabOut() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2, 3])],
            TabGroupScan(visibleIds: [1, 2], groups: [2: [2, 3]]),
            aliveIds: [1, 2, 3],
        )
        assertEquals(result.outcomes, [.keep(tile(2, [2, 3]))])
    }

    func testDragOutOfTwoTabGroupKeepsCurrentVisible() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2])],
            TabGroupScan(visibleIds: [1, 2], groups: [:]),
            aliveIds: [1, 2],
        )
        assertEquals(result.outcomes, [.keep(tile(1, [1]))])
    }

    func testMergeTwoTiles() {
        let result = reconcileTabGroups(
            [tile(1, [1]), tile(2, [2, 3])],
            TabGroupScan(visibleIds: [2], groups: [2: [1, 2, 3]]),
            aliveIds: [1, 2, 3],
        )
        assertEquals(result.outcomes, [.merged, .keep(tile(2, [1, 2, 3]))])
    }

    func testGroupOwnedByTileContainingVisibleId() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2]), tile(5, [5, 6])],
            TabGroupScan(visibleIds: [1, 5], groups: [1: [1, 2], 5: [5, 6]]),
            aliveIds: [1, 2, 5, 6],
        )
        assertEquals(result.outcomes, [.keep(tile(1, [1, 2])), .keep(tile(5, [5, 6]))])
    }

    func testTileWithNoVisibleIdsKeepsMembers() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2, 3])],
            TabGroupScan(visibleIds: [], groups: [:]),
            aliveIds: [1, 2, 3],
        )
        assertEquals(result.outcomes, [.keep(tile(1, [1, 2, 3]))])
    }

    func testDeadTile() {
        let result = reconcileTabGroups(
            [tile(1, [1, 2])],
            TabGroupScan(visibleIds: [], groups: [:]),
            aliveIds: [],
        )
        assertEquals(result.outcomes, [.dead])
    }

    func testUnownedGroupIsReportedAsNew() {
        let result = reconcileTabGroups(
            [tile(7, [7])],
            TabGroupScan(visibleIds: [1, 7], groups: [1: [1, 2]]),
            aliveIds: [1, 2, 7],
        )
        assertEquals(result, TabReconcileResult(outcomes: [.keep(tile(7, [7]))], newGroups: [tile(1, [1, 2])]))
    }
}
