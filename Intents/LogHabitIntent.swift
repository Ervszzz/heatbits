import Foundation

// Siri / App Intents integration stubbed out.
// To re-enable: add AppIntents.framework under Build Phases → Link Binary With Libraries.

class HabitStoreProvider {
    static let shared = HabitStoreProvider()
    private init() {}

    private var _store: HabitStore?

    var store: HabitStore {
        if let s = _store { return s }
        let s = HabitStore()
        _store = s
        return s
    }

    func logHabit(named name: String) -> Bool {
        store.logHabit(named: name)
    }

    func configure(with store: HabitStore) {
        _store = store
    }
}
