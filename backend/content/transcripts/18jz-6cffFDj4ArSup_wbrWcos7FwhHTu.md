# Prof. Slim's Lecture 7 LinkList - Summer (VoD).mp4

- Course: Data Structures and Algorithms
- Drive file ID: `18jz-6cffFDj4ArSup_wbrWcos7FwhHTu`
- Type: lecture
- Video: https://drive.google.com/file/d/18jz-6cffFDj4ArSup_wbrWcos7FwhHTu/view?usp=drivesdk

## Transcript or detailed summary

Introduction to Linked Lists

Background: The speaker notes that up to this point, abstract data types (like stacks and queues) were implemented using arrays.

Array Trade-offs: Arrays offer fast, O(1) element access by index. However, they are static data structures with a fixed size. Resizing requires creating a new array and copying all elements over, which is an expensive operation.

The Alternative: Linked lists provide a dynamic alternative where maximum capacity is limited only by available memory. This makes them highly suitable for implementing dynamic stacks and queues.

Structural Overview and Terminology

Nodes/Links: Instead of continuous indexed cells, a linked list consists of self-contained boxes called nodes or links.

Singly Linked List: Each node contains a data value and a single pointer pointing to the next node in the chain. The final node points to null to mark the end of the list.

Doubly Linked List: A variation where each node contains pointers to both the next node and the previous node.

List Configurations:

Single-ended singly linked list: Contains a reference only to the first node of the list.

Double-ended singly linked list: Contains references to both the first and last nodes, optimizing certain operations like queue insertions.

Circular linked list: The last node points back to the first node instead of pointing to null.

Implementation Details in Java

The Node Class: Implemented as a "self-referential" or recursive data type because one of its instance variables references its own class type (Node next). It includes a data variable, a next variable, and a constructor. A toString method is also added to override Java's default reference printing.

The SLL Class: The speaker demonstrates creating a single-ended singly linked list (SSL) class within the same file using standard default access modifiers. It tracks the list via a Node first instance variable.

Core Linked List Methods

isEmpty(): Checks if the first pointer equals null (O(1) complexity).

insertFirst(int k): Allocates a temporary new node, sets its next pointer to the current first node, and reassigns first to this new node. This features an efficient O(1) time complexity because it completely avoids array-style element shifting.

deleteFirst(): Removes and returns the head node by shifting the first pointer to first.next. This is also highly efficient at O(1) complexity. The unreferenced old node is automatically handled by Java's garbage collector.

display() (Iterative): Uses a temporary variable (current) initialized to first to safely loop through the chain and print elements until it hits null. Moving the actual first pointer during traversal must be avoided, as doing so permanently destroys the reference to the list.

insertLast(int k): Requires a traversal up to the last node (using current.next == null as the stop condition) before attaching the new node. In a single-ended list, this results in an O(n) time complexity. To achieve an O(1) runtime for this operation, a double-ended list structure tracking a last pointer is required.

Recursive Traversal and "Magic"

The Importance of Recursion: The instructor explains that mastering recursion on linked structures is essential for handling more advanced operations in the coming weeks without writing overly complex code.

Node-Level Recursion: Recursion should be performed on the list's nodes rather than the list structure itself to avoid destructive head deletions. This is achieved using a static helper method that accepts a node as a parameter.

Reversing Order via Call Stack: By utilizing the behavior of the system call stack, swapping the order of the print statement and the recursive method call seamlessly flips the output. Placing the recursive call before the print statement delays execution until null is reached, effectively printing the linked list in completely reverse order.
