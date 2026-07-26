# Prof. Slim's Lecture 8 Doubly Link List - Summer (VoD).mp4

- Course: Data Structures and Algorithms
- Drive file ID: `1UAOMdn0frz5H3L1ovyP1uwBEpow9JD1X`
- Type: lecture
- Video: https://drive.google.com/file/d/1UAOMdn0frz5H3L1ovyP1uwBEpow9JD1X/view?usp=drivesdk

## Transcript or detailed summary

Overview and Recap

The speaker introduces variations of the chain data structure following the previous discussion on single-ended, singly linked lists.

A comparison between linked lists and arrays highlights that linked lists are dynamic data structures where size does not need to be predefined.

The speaker reviews the time complexities of basic singly linked list operations:

Insert First: O(1) time complexity due to simple reference manipulation to attach a new node to the head.

Delete First: O(1) time complexity. This is an advantage over arrays, which require an O(n) shifting of elements when deleting the first entry.

Middle Deletion: Requires an O(n) search to locate the element, but the deletion itself is faster because it involves reference manipulation (bridging nodes) without any shifting.

Implementing a Stack Using a Linked List

The speaker discusses implementing a stack using a single-ended, singly linked list and explores two structural approaches:

Approach 1 (Optimal): Pushing is handled via insertFirst and popping via deleteFirst. Both operations yield an optimal time complexity of O(1).

Approach 2 (Suboptimal): Pushing via insertLast and popping via deleteLast requires traversing the entire list, resulting in an inefficient time complexity of O(n).

The speaker live-codes the optimal stack implementation (link stack or s) in Java using an underlying singly linked list (SSL).

The coded stack operations include:

isEmpty: Evaluates if the stack is empty by mapping directly to the underlying linked list's empty check.

push: Invokes insertFirst to add data. Unlike array-based stacks, there is no isFull method because the linked list grows dynamically.

pop: Invokes deleteFirst. The speaker fixes a data type mismatch during compilation to ensure the method extracts and returns the node's internal data rather than the node object itself.

size: Returns the total number of items. To achieve this, the speaker updates the underlying linked list class to track an internal tracking variable (number of items), incrementing it during insertion and decrementing it during deletion.

Motivation for Doubly Linked Lists

The speaker analyzes the performance limits of a double-ended, singly linked list (which maintains pointers to both the first and last nodes):

insertLast becomes efficient at O(1) time complexity using direct reference changes via a temporary node.

deleteLast remains trapped at O(n) time complexity. To update the last pointer cleanly, the structure must access the penultimate node. Because a singly linked list cannot move backward, it must traverse from the first node to the end to find it.

This limitation motivates the creation of a doubly linked list, where every node stores an explicit reference to both its next and previous neighbors. This allows backward traversal and enables O(1) efficiency for all boundary operations (insertFirst, insertLast, deleteFirst, and deleteLast).

Implementing a Double-Ended Doubly Linked List

The speaker demonstrates the Java code for a double-ended doubly linked list (ddll) using a custom node structure named link.

The link Node Class: Contains three instance variables: data (integer), next (link reference), and previous (link reference).

The ddll Class Architecture: Contains references to first, last, and an integer tracking number of items.

insertFirst(k) Implementation:

A new link (tmp) is instantiated with the data value k.

If the list is empty, both first and last pointers point directly to tmp.

If the list contains elements, tmp.next points to first, first.previous points to tmp, and the first pointer shifts to tmp. The speaker notes that missing the empty check will trigger a NullPointerException.

number of items increments by one.

insertLast(k) Implementation:

Designed as a mirror reflection of insertFirst. The speaker explains that conceptually, next updates to previous, and first updates to last.

If empty, first and last point to tmp. Otherwise, tmp.previous points to last, last.next points to tmp, and the last pointer updates to tmp.

deleteFirst() Implementation:

Captures the target node in a temporary variable.

If the list contains a single node (where first.next == null), both first and last are set to null.

For multi-node lists, first advances to first.next, and the new first node's previous pointer is nullified (first.previous = null) to disconnect the old link for the garbage collector. Failing to separate the single-node logic results in a NullPointerException.

number of items decrements by one and returns the deleted node.

deleteLast() Implementation:

Described as the exact mirror implementation of deleteFirst, swapping boundaries and direction pointers natively.

Forward and Backward Display Methods:

displayForward initializes a tracking pointer (current) at first and moves via current.next while printing data until it hits a null value.

displayBackward leverages the double-linked nature by initializing current at last and stepping backward using current.previous to print elements in reverse order.

Conclusion

The speaker notes that deleting an element matching a specific key is more complex, as it requires adjusting four separate pointers simultaneously; this operation will be handled in upcoming lab sessions.

The lecture concludes by previewing that the next class session will shift focus to tree data structures.
