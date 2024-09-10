class FixedSizeQueue<T> {
    private var elements: [T?] = []
    private let maxSize: Int
    private var head: Int = 0
    private var tail: Int = 0
    
    init(maxSize: Int) {
        precondition(maxSize > 0, "Max size must be greater than 0")
        self.maxSize = maxSize
        elements = Array(repeating: nil, count: maxSize + 1)
    }

    func enqueue(_ element: T) {
        elements[tail] = element
        tail = (tail + 1) % elements.count

        // If the tail has caught up with the head, advance the head to maintain the fixed size
        if tail == head {
            head = (head + 1) % elements.count
        }
    }
    
    var values:[T] {
        return elements.compactMap { $0 }
    }
    
    func clear(){
        elements = Array(repeating: nil, count: maxSize + 1)
        head = 0
        tail = 0
    }
}
