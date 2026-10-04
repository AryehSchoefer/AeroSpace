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
}
