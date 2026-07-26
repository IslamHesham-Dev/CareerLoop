# Prof. Slim's Lecture 5 Queues - Live Lecture (VoD).mp4

- Course: Data Structures and Algorithms
- Drive file ID: `1IkCgAqo5MNbZTVhCEHUHwmGGeCy_Vznw`
- Type: lecture
- Video: https://drive.google.com/file/d/1IkCgAqo5MNbZTVhCEHUHwmGGeCy_Vznw/view?usp=drivesdk

## Transcript or detailed summary

Abstract Data Type and Concepts

Definition: A queue is an abstract data type that follows the First-In, First-Out (FIFO) principle, where the first element added is the first one to be served.

Key Differences from Stacks: Stacks operate on a Last-In, First-Out (LIFO) model and have only one accessible end (the top). In contrast, queues have two distinct ends: a front for removing elements and a rear for adding elements.

Terminology: Adding an element is called enqueue (performed at the rear), and removing an element is called dequeue (performed from the front).

Main Operations: The fundamental queue methods include enqueue, dequeue, isEmpty, isFull, size, and peek (viewing the front element without removal).

Real-world Applications: Queues are ideal for task serialization where fairness is required based on arrival order, such as customer lines, toll stations, and print servers managing incoming requests from multiple computers.

Accessing and Manipulating Elements

Accessing Middle Elements: While not the primary purpose of a queue, finding or deleting an n-th element from the front can be done without extra memory storage. By dequeuing and immediately enqueuing elements n-1 times, the target element is brought to the front to be removed. A subsequent loop is then used to restore the correct relative order of the remaining elements.

Reversing a Queue: Reversing a queue can be achieved cleanly by using a single temporary stack. Elements are dequeued from the queue and pushed into the stack, which inherently reverses their order due to its LIFO nature. The elements are then popped from the stack and enqueued back into the queue. Reversal can also be accomplished in place without an external data structure via a recursive method.

Queue Implementation Using Arrays

The Array Pointer Problem: A naive array implementation where elements are shifted forward upon every dequeue causes a highly inefficient time complexity of O(n) for dequeuing.

The Circular Array Solution: To achieve an efficient O(1) time complexity for both enqueue and dequeue, a structural approach using moving pointers is implemented.

Variables Needed: An array to store the data, maxSize to define capacity, a front pointer, a rear pointer, and a numberOfItems variable to easily track state changes.

Initialization: The constructor initializes front to 0, rear to -1, and numberOfItems to 0.

Wrapping Around (Modulo Arithmetic Concept): As elements are added and removed, the rear and front pointers advance independently and wrap around to the beginning (index 0) of the array once they reach maxSize - 1. This structural design allows empty slots at the beginning of the array to be reused continuously.

Ambiguity Without numberOfItems: Without a tracking variable like numberOfItems, identifying whether a queue is entirely empty or entirely full becomes highly ambiguous because the front and rear pointers can end up at identical coordinates under both conditions.

Queue Implementation Using Stacks

Two-Stack Setup: A queue can also be constructed by utilizing two independent instances of a stack (e.g., stack S and stack T).

Operational Trade-offs:

Enqueue: New items are pushed directly onto stack S, yielding an efficient time complexity of O(1).

Dequeue: Because the oldest item is buried at the very bottom of stack S, all elements must be popped from S and pushed into T to flip the order. The bottom element is then removed and returned, and the remaining elements in T are shuffled back into S. This results in an inefficient O(n) time complexity for dequeuing and viewing (peek) operations.
