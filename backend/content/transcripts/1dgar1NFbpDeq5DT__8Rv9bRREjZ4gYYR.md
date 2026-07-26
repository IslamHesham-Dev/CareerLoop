# Prof. Slim's Lecture 8 Doubly LinkList - Live Lecture (VoD).mp4

- Course: Data Structures and Algorithms
- Drive file ID: `1dgar1NFbpDeq5DT__8Rv9bRREjZ4gYYR`
- Type: lecture
- Video: https://drive.google.com/file/d/1dgar1NFbpDeq5DT__8Rv9bRREjZ4gYYR/view?usp=drivesdk

## Transcript or detailed summary

Lecture Overview

This lecture focuses on implementing abstract data types (ADTs) using chain data structures, specifically analyzing the transitions from arrays to singly linked lists, and ultimately to doubly linked lists.

Disadvantages of Array-Based Data Structures

The speaker contrasts linked lists with arrays by identifying two main limitations of array-based data structures:

Static Size: Arrays are static data structures that require a fixed size. When an array becomes full, it must be doubled in size and all elements copied over, which is an expensive operation.

Operational Inefficiency: For arrays, executing insert first and delete first operations requires a time complexity of O(N) due to the necessity of shifting subsequent elements.

Simulating a Stack via Singly Linked Lists

The instructor demonstrates how to implement a stack using a single-ended singly linked list (SLL), outlining three variations:

Variation 1 (Insert Last / Delete Last): Elements are added to the end of the list. In a single-ended singly linked list, insert last requires traversing the entire list, resulting in a time complexity of O(N).

Variation 2 (Insert First / Delete First): Top elements are tracked at the beginning of the list. Both insert first (push) and delete first (pop) achieve an optimal time complexity of O(1).

Variation 3 (Random Insertion): Elements are inserted randomly with keys/pairs indicating their sequence order. Popping requires searching for the largest key, forcing an inefficient time complexity of O(N).

Motivation for Doubly Linked Lists

While a double-ended singly linked list can improve insert last to O(1) by maintaining a reference to the last node, delete last still takes O(N) because the program must traverse the list to find the second-to-last node.

To achieve O(1) performance across all structural operations—insert first, insert last, delete first, and delete last—the data structure must be upgraded to a double-ended doubly linked list (DDLL). By adding a previous pointer alongside the next pointer, the program can access the second-to-last node via last.previous in O(1) time.

Implementation Details for Doubly Linked Lists (DDLL)

Node Class Modification

The node class changes from holding two instance variables to holding three: the data integer, a reference to the next node, and a reference to the previous node.

Structural Methods

insertFirst(int k): Handles adding a node to the front. The instructor explicitly adds a conditional branch for empty lists to ensure both first and last references point to the new node. For non-empty lists, it links tmp.next to first, sets first.previous to tmp, and updates first to tmp.

insertLast(int k): Demonstrated as a perfect mirror of insertFirst, swapping first with last, and next with previous.

deleteFirst() and deleteLast(): These methods remove nodes from either end. The instructor highlights the danger of a NullPointerException if a single-element list (singleton) is not handled properly when resetting pointers. Pointers are safely set to null to facilitate Java's automatic garbage collection.

Recursive Searching on Chain Data Structures

The lecture concludes with an analysis of a recursive method to check if an element occurs in the list (occur).

Performing recursion directly on the list object structure requires generating heavy, deeply cloned sub-lists to preserve the original data, creating a highly inefficient, expensive polynomial algorithm.

Instead, the instructor implements an O(N) solution using a private recursive helper method (helperRack) that operates recursively on individual nodes rather than the list itself. This approach passes the node reference (c.next) forward until it hits a base case (c == null or c.data == k), avoiding expensive memory operations.
