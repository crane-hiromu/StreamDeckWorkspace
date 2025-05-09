import StreamDeckPlugin

// MARK: - Action
struct HelloAction: Action {

    func keyDown(context: String, payload: KeyEvent) {
        print("Hello, Stream Deck!")
    }
}
