# CareerLoop video transcript intake

This file maps 153 videos across 5 courses to source-grounded transcript context for the study agent.

## How to fill it

1. Open the linked recording and generate its transcript.
2. Replace `[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]` only inside that video's START and END markers.
3. Keep every heading, `video_id`, Drive link, and marker unchanged.
4. Use `[inaudible]` for unclear audio instead of guessing.
5. Leave unprocessed video placeholders unchanged; the importer skips them.

Only text between matching transcript markers is ingested. Metadata outside the markers is used for identification and review.

## Data Structures and Algorithms (DSA)

Lectures and tutorials covering the Data Structures and Algorithms course.

### Prof. Slim's Lecture 11 Hashtable - Summer (VoD).mp4

- `video_id`: `1IcXExdHzJQjHabg7bHOxCNGGVFWwPzJp`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1IcXExdHzJQjHabg7bHOxCNGGVFWwPzJp/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1IcXExdHzJQjHabg7bHOxCNGGVFWwPzJp -->

Course Motivation and Data Structure Comparison

Core Objective: The overall goal of the Data Structures and Algorithms course is to store data records and efficiently perform three main operations: insertion, deletion, and searching.

Unsorted Arrays: Insertion is fast (O(1)). However, searching requires a linear scan, and deletion requires both searching and shifting elements down, leading to a slow time complexity of O(n) for both operations.

Sorted Arrays: Searching is highly efficient (O(log n)) using binary search. However, insertion and deletion both require shifting elements to maintain the sorted order, resulting in an O(n) time complexity.

Linked Lists: This dynamic data structure allows fast insertion at the beginning (O(1)). Deletion is faster than in arrays because it uses reference manipulation instead of element shifting, but it still takes O(n) due to the need to sequentially search for the target.

Binary Search Trees (BST): Balanced search trees allow insertion, deletion, and searching to all be performed with a time complexity of O(log n).

The Goal of Hash Tables: Hash tables serve as an alternative designed to outperform trees by achieving a time complexity of O(1) for insertion, deletion, and searching.

Hash Table Foundations and Hash Functions

Direct Addressing Table Concept: If records are identified by a unique ID (such as a student ID), they can theoretically be mapped directly into a massive array where the ID matches the index. While this guarantees O(1) operations, it results in an enormous waste of memory due to thousands of empty cells.

Hash Functions: To make the storage array smaller and more efficient, a hash function is introduced. It takes a key and maps it to a valid index within a restricted range (from 0 to b-1, where b is the array size).

Desired Properties: A good hash function must be simple and quick to calculate, and it must distribute elements uniformly to minimize collisions.

Hash Function Techniques:

Digit Extraction: Isolating specific digits out of a key (e.g., using the last four digits of an ID).

Division/Remainder Method: Dividing the key by the array size (b) and using the remainder (x mod b) as the index.

String Hashing/Folding: Summing up the ASCII or Unicode values of individual characters in a string. To prevent anagrams from mapping to the same index, character values can be multiplied by their positional weight.

Mid-Square Method: Squaring the key and performing a division or remainder operation on the result to help avoid certain collisions.

Pseudorandom: Using a key as a seed for a random number generator so it consistently maps to the same index.

Collision Resolution Techniques

A collision occurs when a hash function maps two different keys to the same index. There are several ways to resolve this:

Linear Probing: If a target cell is occupied, the algorithm sequentially checks the next index (adding 1 repeatedly using a modulo operator to wrap around) until an empty cell is found.

Drawback: Linear probing causes "clustering," where large contiguous blocks of cells become full, potentially degrading operations back to a slow linear search (O(n)).

Deletion Issue: Simply nullifying a cell during deletion breaks the linear probe chain, making subsequent searches fail to find elements placed further down the cluster. To fix this, a secondary boolean array or flag table is used to mark cells as "deleted" rather than empty, allowing searches to continue past them and new insertions to overwrite them.

Quadratic Probing: Instead of looking at the immediate next cell, the algorithm jumps by increments of the square of the step number (index + 1², index + 2², index + 3², etc.). This avoids consecutive cell clustering but can still lead to a secondary form of clustering if keys map to the same starting index.

Rehashing / Double Hashing: This technique utilizes a sequence of different hash functions (h₁ to hₙ). If the first function results in a collision, the second function is applied to find an available spot, and so on.

Chained Hash Tables (Separate Chaining): The hash table is constructed as an array of linked chains (linked lists or balanced BSTs). When a collision occurs, the element is simply appended to the chain at that index, bypassing the need to look for alternative array cells.

Load Factors and Table Properties

Load Factor (λ): The load factor defines how full a table is allowed to get before it is adjusted. A load factor of 1 means 100% of the cells are full, which significantly causes clusters and slows down operations.

Optimal Efficiency: In languages like Java, the ideal load factor for balancing time and memory efficiency is approximately 0.7 (70% occupied, 30% free). This guarantees that search operations will hit an empty cell and terminate quickly when an element is not present.

Resizing and Mathematical Optimization: If a table exceeds its load factor, a "rehash" is triggered, which doubles the array size. To ensure a uniform distribution of data, the array size should ideally be a prime number, as dividing by prime numbers mathematically creates more even remainder distributions.

<!-- TRANSCRIPT END: 1IcXExdHzJQjHabg7bHOxCNGGVFWwPzJp -->

### Prof. Slim's Lecture 10 Trees II - Summer (VoD).mp4

- `video_id`: `1w0niezzcWNxxqaL_04n6rc-zPIx1FHh1`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1w0niezzcWNxxqaL_04n6rc-zPIx1FHh1/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1w0niezzcWNxxqaL_04n6rc-zPIx1FHh1 -->
Overview and Deletion in Binary Search Trees (BST)

Goal of Trees: The lecture begins by reviewing trees as chained data structures designed to improve search efficiency. Linked lists require O(n) time complexity in the worst-case scenario. In contrast, balanced binary search trees achieve an optimal search time complexity of O(log n).

Self-Balancing Trees: Maintaining a perfectly balanced topology can be an expensive operation, leading to specific classes of self-balancing trees. Java's predefined balancing trees are implemented as red-black trees.

Deletion Cases: The main focus shifts to how to delete a node from a BST without violating its structural property, distinguishing between three unique cases:

Case 1 (The node is a leaf): This is the simplest task. The algorithm searches for the node while keeping track of its parent, then nullifies the appropriate parent pointer. This operation runs in O(1) time complexity.

Case 2 (The node has only one child): The parent pointer of the deleted node is directly diverted to link with its single child. The disconnected node becomes garbage collected. This operation also runs in O(1) time complexity.

Case 3 (The node has two children): Deleting a node with two children leaves a "hole" that must be filled using one of two valid alternatives to preserve the BST property:

Alternative A: Go to the left subtree and locate the largest value (by traversing all the way to the rightmost node until hitting null). Replace the deleted node with this value.

Alternative B: Go to the right subtree and locate the smallest value (by traversing all the way to the leftmost node until hitting null). Replace the deleted node with this leftmost descendant.

Overall Deletion Complexity: Searching for the node to delete takes O(log n) time in a balanced tree. Because finding the replacement node in Case 3 requires looping through a subtree path, the entire deletion process maintains an overall time complexity of O(log n).

Tree Traversals

The lecture moves to the second major topic: different methods for traversing trees to display information or read expressions.

Pre-order Traversal:

Follows the format of visiting the Root, Left Subtree, then Right Subtree.

When performed on an expression tree, it produces an output in prefix notation.

In-order Traversal:

Follows the format of visiting the Left Subtree, Root, then Right Subtree.

When performed on an expression tree, it yields infix notation (though parenthetical brackets may be lost, altering operator precedence).

For any binary search tree, an in-order traversal always outputs values in sorted ascending order. Swapping the left and right operations yields a sorted descending order instead.

Post-order Traversal:

Follows the format of visiting the Left Subtree, Right Subtree, then Root.

When performed on an expression tree, it results in postfix notation.

Level-order Traversal:

Explores the tree level-by-level starting from level 0 (the root) and moving from left to right.

Recursive Implementation and Stack Tracing

Recursive Code: The speaker demonstrates Java implementations for the recursive traversals, utilizing a public void method that delegates to a private/static recursive helper function starting at the root node.

The Elegance of Recursion: The code highlights how a slight shift in placement changes the traversal completely. Placing the print statement before the left/right helper calls results in a pre-order traversal; placing it between them creates an in-order traversal; and placing it after both calls forms a post-order traversal.

Stack Tracing: The execution behavior is walked through line-by-line using a simulated call stack. The helper calls are pushed onto the stack, expanded into their constituent print and recursive steps, and popped sequentially.

Unique Tree Reconstruction

The final segment of the video covers whether a tree can be uniquely reconstructed from its traversal sequences.

Standard Binary Trees: A single pre-order, in-order, or post-order traversal sequence is completely insufficient to reconstruct a standard binary tree uniquely. To uniquely reconstruct a generic binary tree, at least two traversals are required: one must be the in-order traversal, and the second must be either the pre-order or post-order traversal. Combining only pre-order and post-order sequences is not enough.

Binary Search Trees (BST): Because a BST inherently enforces structural boundaries, a single pre-order traversal sequence or a single post-order traversal sequence is enough to rebuild the tree in a completely unique way. However, an in-order traversal alone is still not enough for a BST because many differently structured trees share the exact same sorted ascending sequence.
<!-- TRANSCRIPT END: 1w0niezzcWNxxqaL_04n6rc-zPIx1FHh1 -->

### Prof. Slim's Lecture 10 Trees II- Live (VoD).mp4

- `video_id`: `1QSabDDhvzk-wR0cOR_MO1WV1UAEuU6LB`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1QSabDDhvzk-wR0cOR_MO1WV1UAEuU6LB/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1QSabDDhvzk-wR0cOR_MO1WV1UAEuU6LB -->
Introduction to Trees and Applications

Advantages and Tradeoffs: Trees serve as a structured alternative to arrays and linked lists. If a data structure has only single sequential choices, it degrades into a singly linked list. Trees become essential when managing applications that branch into multiple alternatives.

Applications: Main applications include organizational structures like folder hierarchies, robot movement planning, and Artificial Intelligence game trees (such as chess or tic-tac-toe). Programs like Deep Blue look ahead through massive tree branches to maximize winning states.

Time Complexity: While operations on basic linked lists or unorganized trees can be expensive, organizing data into a Balanced Binary Search Tree (BST) cuts the time complexity of searching, inserting, and deleting down to O(log n).

Self-Balancing Trees: To prevent a tree from degrading into a linear linked list layout when heavily altered, systems like Java use "Red-Black Trees." These trees utilize edge rotation to balance themselves automatically during operations.

Binary Search Tree Deletion (Three Cases)

The speaker maps out a BST on the board to illustrate the three logic cases needed to delete a node while maintaining BST properties:

Case 1: Deleting a Leaf Node: This is a straightforward process. The tree is traversed down a single branch path (O(h) time complexity, where h is tree height) to locate the target node. Tracking the parent node is necessary so that the parent's respective left or right pointer can be set to null.

Case 2: Deleting a Node with One Child: This is also an inner node variation that is simple to resolve. The parent node pointer is updated to point directly past the deleted node to its single child using a single reference manipulation.

Case 3: Deleting a Node with Two Children: This is the most complex scenario because deleting the node directly splits the structure into a "forest". To preserve the tree topology, the deleted node must be replaced using one of two pointer approaches:

Predecessor Approach: Go to the left subtree and locate the largest value by traversing strictly down the right edges until hitting a null point. Swap that largest value into the target node being deleted.

Successor Approach: Go to the right subtree and locate the smallest value by traversing strictly down the left edges until a null point is reached. Swap that value into the deleted node's slot.

Tree Traversals and Expression Trees

The speaker defines "Expression Trees," where inner nodes are binary operators and leaves are numbers/values. Traversing these structures yields distinct mathematical notations:

Pre-order Traversal (Depth-First): Visits the Root, then the Left subtree, then the Right subtree. When applied to an expression tree, it produces prefix notation.

Post-order Traversal: Visits the Left subtree, then the Right subtree, and finishes at the Root. This produces postfix notation. The true root node is always the last element printed.

In-order Traversal: Visits the Left subtree, then the Root, then the Right subtree. This yields standard infix notation. Traversing a BST in-order will always return values sorted in ascending order.

Level-order Traversal (Breadth-First): Processes nodes level-by-level from top to bottom.

Code Implementation: Recursive vs. Iterative

Recursive Layout: Standard traversals take roughly three lines of code in a recursive helper method. The placement of the print statement relative to the left/right recursive calls dictates whether it is pre-order, in-order, or post-order.

Iterative Simulation (Rule of Thumb): If recursion is banned or unfeasible, a Stack data structure must be explicitly managed to mimic the implicit system call stack.

To perform an iterative pre-order traversal, you push the root to the stack. While looping through a non-empty stack, you pop a node, process/print its data, and then push its children. Crucially, you must push the right child first and the left child second so that the left child sits on top to be processed next, delaying the right branch tasks correctly.

Theoretical Concepts & Reverse Engineering

Reconstructing Trees Uniquely:

A BST can be uniquely reconstructed using only one pre-order or post-order traversal sequence because value properties explicitly dictate whether an element belongs on the left or right of a node. An in-order sequence alone cannot uniquely reconstruct a BST because it simply outputs a sorted list that fits multiple tree shapes.

A standard Binary Tree (non-search) requires at least two traversals to be reconstructed uniquely. Pairing a pre-order sequence with an in-order sequence works, whereas combining pre-order with post-order fails to guarantee uniqueness (demonstrated with a 2-node counter-example).

Checking for a Full Tree: Instead of checking every pointer manually, a full binary tree can be verified through binary number mathematical induction. By measuring the height or levels (h), the total node count must exactly equal 2^h - 1. If the actual node count deviates, the tree is not full.
<!-- TRANSCRIPT END: 1QSabDDhvzk-wR0cOR_MO1WV1UAEuU6LB -->

### Prof. Slim's Lecture 9 Trees I - Summer (VoD).mp4

- `video_id`: `1lUuaSyfnKBXH1pCaMlmOQHL5is_tfV23`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1lUuaSyfnKBXH1pCaMlmOQHL5is_tfV23/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1lUuaSyfnKBXH1pCaMlmOQHL5is_tfV23 -->
Introduction & Applications

Linked List Limitations: In previously studied chain data structures like linked lists (singly or doubly linked), even if the elements are sorted, searching requires sequential traversal. This results in a worst-case time complexity of O(n).

Motivation for Trees: The lecture introduces trees as a dynamic, non-linear dynamic structure aimed at achieving a more efficient search time complexity of O(log n)—similar to performing a binary search on an ordered array.

Real-World Application: A directory and file subdirectory system on a computer desktop serves as a practical example of a tree structure. Hierarchical organization (e.g., Curriculum → Department → Majors → Files) allows users to search and find specific files much faster than searching a flat, unorganized structure.

Tree Terminology

Nodes and Edges: A tree consists of nodes (which store the data) and edges (which connect the nodes).

Root: The top-most node in a tree structure.

Children and Parents: If a node originates from another node, it is referred to as a child node, and the originating node is its parent.

Leaves: Nodes that do not have any children.

Subtree: A smaller tree structure contained within a larger tree, rooted at a specific non-root node.

Binary Trees (BT)

Definition: A binary tree is a specific type of tree where every node can have a maximum fan-out (arity) of two children. These are designated as the left child and the right child.

Implementation Class: A basic binary tree node is self-referential. The Node class contains three variables: data, a reference to the left child, and a reference to the right child.

Tree Structure: A BinaryTree class itself is structurally defined and navigated starting entirely from a single instance variable: its root node. If the root is null, the tree is empty.

Binary Search Trees (BST)

The Ordering Property: Standard binary trees do not improve search times on their own because data lacks arrangement. A Binary Search Tree (BST) solves this by enforcing a strict recursive property:

All data values in the left subtree must be smaller than (or equal to) the root node's value.

All data values in the right subtree must be strictly larger than the root node's value.

Every individual subtree within the tree must also satisfy the rules of a binary search tree.

The Search Process: When searching for a key, it is compared against the current node. If it does not match, the system chooses one path. For instance, if the key is larger than the current node, the entire left subtree is neglected and eliminated from the search space in a single step.

Search Algorithms: The instructor outlines two ways to find a key:

Iterative Search: Uses a tracking pointer (current = root) inside a loop to navigate left or right until the key is found or null is hit.

Recursive Search: Uses a static helper method that accepts a node pointer and the key. It evaluates base cases (if the node is null, return false; if data matches, return true) and conditionally returns a recursive call on node.left or node.right.

Tree Balance and Worst-Case Performance

Balanced Trees: A tree is considered balanced when the total number of nodes in the left subtree is relatively equal to the number of nodes in the right subtree, and every underlying subtree is balanced as well. Complete and full balanced trees achieve the ideal O(log n) search performance.

Worst-Case Degeneration: If sorted data (either ascending or descending) is inserted sequentially without balancing, the BST degrades structurally into a linear, singly linked list shape. In this un-balanced scenario, search efficiency collapses back to O(n).

Insertion Strategies

Leaf Insertion: To insert an item without disrupting the existing tree topology, the algorithm acts like a search function. It steps down the tree until it hits a null position.

Parent Tracking: Because the moving pointer eventually hits null, an iterative implementation must maintain a trailing pointer reference to the parent node. Once the position is found, the parent's value is checked one last time to hook the new node to its left or right pointer.

Achieving Perfect Topology (The Median Method): To insert a pre-sorted collection of numbers while preventing linear degradation, you must find the median element of the collection and establish it as the root. You then recursively find and insert the medians of the remaining left and right split-subsets to build a perfectly balanced BST topology.

Next Steps

The lecture concludes by noting that while searching and insertion have been covered, future sessions will address the more complex operations of node deletion and different methods of tree traversal.
<!-- TRANSCRIPT END: 1lUuaSyfnKBXH1pCaMlmOQHL5is_tfV23 -->

### Prof. Slim's Lecture 8 Doubly Link List - Summer (VoD).mp4

- `video_id`: `1UAOMdn0frz5H3L1ovyP1uwBEpow9JD1X`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1UAOMdn0frz5H3L1ovyP1uwBEpow9JD1X/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1UAOMdn0frz5H3L1ovyP1uwBEpow9JD1X -->
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
<!-- TRANSCRIPT END: 1UAOMdn0frz5H3L1ovyP1uwBEpow9JD1X -->

### Prof. Slim's Lecture 8 Doubly LinkList - Live Lecture (VoD).mp4

- `video_id`: `1dgar1NFbpDeq5DT__8Rv9bRREjZ4gYYR`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1dgar1NFbpDeq5DT__8Rv9bRREjZ4gYYR/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1dgar1NFbpDeq5DT__8Rv9bRREjZ4gYYR -->
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
<!-- TRANSCRIPT END: 1dgar1NFbpDeq5DT__8Rv9bRREjZ4gYYR -->

### Prof. Slim's Lecture 7 LinkList - Live Lecture (VoD).mp4

- `video_id`: `1x7UL9RcJyTU-_j4FpE4xmp1-b3i84Bvo`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1x7UL9RcJyTU-_j4FpE4xmp1-b3i84Bvo/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1x7UL9RcJyTU-_j4FpE4xmp1-b3i84Bvo -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1x7UL9RcJyTU-_j4FpE4xmp1-b3i84Bvo -->

### Prof. Slim's Lecture 7 LinkList - Summer (VoD).mp4

- `video_id`: `18jz-6cffFDj4ArSup_wbrWcos7FwhHTu`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/18jz-6cffFDj4ArSup_wbrWcos7FwhHTu/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 18jz-6cffFDj4ArSup_wbrWcos7FwhHTu -->
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
<!-- TRANSCRIPT END: 18jz-6cffFDj4ArSup_wbrWcos7FwhHTu -->

### Prof. Slim's Lecture 6 Priority Queues - Live Lecture (VoD) (2).mp4

- `video_id`: `1-ijTpNOXQy7GQolY-xWzY6x92umrk91v`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1-ijTpNOXQy7GQolY-xWzY6x92umrk91v/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1-ijTpNOXQy7GQolY-xWzY6x92umrk91v -->
Introduction to Priority Queues

A priority queue is a specialized type of queue and the third abstract data type covered in the course.

Unlike standard queues that use a first-in, first-out (FIFO) approach, a priority queue processes elements based on their designated priorities rather than their insertion order.

Elements in a priority queue consist of a value (the object itself) and a key (its priority level).

Real-world examples include managing inventory with specific expiry dates or managing process execution hierarchies (e.g., handling a system shutdown task with top priority) within an operating system to prevent application starvation.

Operations and Sorting

The priority queue abstract data type relies primarily on two main methods: insert (which takes both an element and its corresponding key) and remove (which removes the item with the highest priority).

Secondary methods include checking if the queue is empty or full (isEmpty, isFull), finding the queue's size (size), and previewing the highest priority item (peekMin).

To compare keys effectively, the data must fulfill mathematical properties of a total order: reflexivity, anti-symmetry, and transitivity.

When dealing strictly with integers, the value itself can act as the key, making the dual-parameter insert obsolete and simplifying it to a single-parameter method.

A priority queue can be used as a tool to sort an array by inserting all items into the queue and sequentially removing them.

Array-Based Implementations and Time Complexities

Operation / Feature

Variant 1: Unsorted Array

insert Logic: Items are appended sequentially to the first available cell at the end of the array.

insert Complexity: O(1)

remove Logic: Requires searching the array to find the minimum value, then replacing it with the last element.

remove Complexity: O(N)

peekMin Complexity: O(N) (requires a full array scan)

Variant 2: Sorted Array (Descending Order)

insert Logic: Shifting is performed during insertion to maintain the array in descending order.

insert Complexity: O(N)

remove Logic: Automatically removes the item at the end of the array (number of items - 1).

remove Complexity: O(1)

peekMin Complexity: O(1)

Independent of the variant chosen, a priority-queue-based sorting algorithm yields a total time complexity of O(N²) due to the combination of O(1) and O(N) loop steps—matching the performance profiles of selection or insertion sorts.

Generic Implementations and the Comparable Interface

Implementing a generic priority queue using standard Java Object arrays fails because the relational comparison operators (such as >) are not natively defined inside the generic Object class, resulting in compile-time errors.

To fix this, a generic priority queue must be built using arrays of the Comparable interface rather than generic objects.

The Comparable interface is a built-in Java interface housing the abstract method compareTo(Object o).

Custom classes (such as a Person class) must formally implement the Comparable interface and override the compareTo method.

The overridden compareTo method must return an integer rather than a boolean: returning 0 if objects are equal, a positive integer if the invoked object is greater, and a negative integer if it is smaller.

Inside the overridden compareTo method, explicit type casting from the generic Object parameter to the specific class type is required to access the underlying attributes being compared (e.g., checking an age variable).
<!-- TRANSCRIPT END: 1-ijTpNOXQy7GQolY-xWzY6x92umrk91v -->

### Prof. Slim's Lecture 5 Queues - Live Lecture (VoD).mp4

- `video_id`: `1IkCgAqo5MNbZTVhCEHUHwmGGeCy_Vznw`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1IkCgAqo5MNbZTVhCEHUHwmGGeCy_Vznw/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1IkCgAqo5MNbZTVhCEHUHwmGGeCy_Vznw -->
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
<!-- TRANSCRIPT END: 1IkCgAqo5MNbZTVhCEHUHwmGGeCy_Vznw -->

### Prof. Slim's Live Lecture 4 Stacks of Object (VoD).mp4

- `video_id`: `1aqX0d84fpdDA9vH59g2NdxrTtePyWU7M`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1aqX0d84fpdDA9vH59g2NdxrTtePyWU7M/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1aqX0d84fpdDA9vH59g2NdxrTtePyWU7M -->
Expression Evaluation and Stack Applications

Goal of Generic Stacks: The core objective is to create a generic implementation of a stack that can be utilized across various computational applications.

Evaluating Expressions: A prominent application for stacks is in compilers and interpreters to evaluate arithmetic expressions efficiently.

Notation Formats: Expressions are normally written in infix notation (e.g., 2 + 6 * 3 - 8). Compilers or Java Virtual Machines (JVM) convert these into postfix notation (also known as Polish notation) to enable execution in a single traversal, achieving an O(n) time complexity.

Infix to Postfix Conversion (On Board): On paper or a whiteboard, an unbracketed infix expression is converted by first fully bracketing it according to operator precedence and left-to-right rules for equal precedence. Then, moving from the outermost brackets inward, the operator is placed after its respective operands. However, implementing this exact algorithm programmatically is expensive (O(n²) complexity) because it requires recursive parsing back and forth.

Programmatic Infix to Postfix Conversion: Programming languages use a stack-based algorithm that operates in O(n) time by reading left-to-right:

Operands are immediately added to the output string.

Operators are managed using a stack. If the stack is empty or the incoming operator has a higher precedence than the operator on top of the stack, it is pushed.

If the incoming operator has a lower or equal precedence, the stack is popped and displayed until an operator of lower precedence is uncovered or the stack empties; only then is the incoming operator pushed.

Evaluating Postfix Notation: Postfix expressions do not contain brackets; the layout order uniquely determines the execution priority. Operands are sequentially pushed into a stack. When a binary operator is encountered, two items are popped, computed, and the result is pushed back. For non-commutative operations like subtraction, the first element popped is subtracted from the second element popped.

Evolving from Strongly Typed Stacks to Stacks of Objects

The Problem with Specific Stacks: An integer-array stack works perfectly for integer tracking. Because characters and integers are compatible data types via ASCII/Unicode values, a primitive character can technically be stored in an integer stack (returning numerical values like 97 or 98). However, trying to push an actual String object or a custom class (like Student or Professor) into an integer stack causes a compilation error.

The Maintenance Nightmare: Systematically rewriting the stack class code line-by-line to handle individual custom classes (e.g., converting array types, parameters, and return types from int to String or Student) is highly inefficient. Copying and pasting code across different files duplicates any underlying errors, making code maintenance highly problematic.

The Object Class Solution: In Java, the predefined Object class acts as the root or parent class for all reference data types and objects. Changing the internal storage of the stack to an array of type Object creates a singular, reusable generic stack. This allows the user to push diverse classes—such as String variables or standard numerical arrays—into the same stack structure.

Type Casting and Memory Safety Rules

The Reference Type Limitation: When an item is retrieved from an Object stack via .pop(), Java strictly registers its reference type as an Object. This restricts functionality; for example, you cannot call .length() on a popped string element because the .length() method does not exist in the basic Object parent class.

Compile-Time vs. Runtime Behavior: To utilize class-specific methods, the developer must explicitly type-cast the object back to its proper form. The compiler checks syntax rules but does not track the actual execution data type inside the object. Consequently, assigning a generic object to an incorrect class type will compile successfully but will throw a ClassCastException at runtime.

Type Verification: Tools like Java's instanceof method can be strategically deployed to confirm an object's precise type prior to casting, ensuring type safety.

Autoboxing and Wrapper Classes

Primitive Variables: Stacks designed around the parent Object class cannot natively accept raw primitive variables (such as standard int, double, char, or boolean) because primitives are not objects.

Wrapper Classes: Java accommodates primitives using specific wrapper classes: Integer, Double, Character, and Boolean. Originally, developers had to manually construct these wrappers around values to push them into an object stack (e.g., new Integer(6)), which is known as inboxing.

Autoboxing and Auto-unboxing: Since Java version 1.5/1.6, the language automates this behavior.

When passing a primitive value like 3 or 'a' into an object-based .push() method, Java automatically packages it into its wrapper class.

While explicit type-casting remains a mandatory requirement during .pop() actions, Java can automatically retrieve the inner raw value from the wrapper (outboxing/unboxing) when assigning the target variable directly to a primitive type.
<!-- TRANSCRIPT END: 1aqX0d84fpdDA9vH59g2NdxrTtePyWU7M -->

### Prof. Slim's Lecture 3 Stacks - Live Lecture (VoD).mp4

- `video_id`: `11quFvhf6eoymRe9x_H-fatetkyP7ntI7`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/11quFvhf6eoymRe9x_H-fatetkyP7ntI7/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 11quFvhf6eoymRe9x_H-fatetkyP7ntI7 -->
Conceptual Overview: Abstract Data Types (ADTs) and Stacks

Abstract Data Types (ADTs): An ADT is a tool defined to store a collection of data. The abstract aspect means that the user focuses entirely on what operations the tool can perform rather than how those operations are internally implemented.

The Stack Concept: A stack is a Last-In, First-Out (LIFO) data type. It mimics real-world scenarios like a pile of assignments on a desk or a stack of plates in a buffet line, where the most recently added item is always processed first. Stacks are ideal for problems where a decision needs to be delayed.

Core Stack Operations

A standard abstract stack features one single end where operations are executed, providing the following operations:

Push: Inserts an element onto the top of the stack.

Pop: Deletes and retrieves the element currently at the top of the stack.

Peek (or Top): Looks at the top element of the stack without removing it.

Is Empty: Validates if the stack contains no elements.

Is Full: Validates if the stack has reached its maximum bounds.

Size: Returns the total number of items currently in the stack.

Programmatic Implementation in Java

The speaker demonstrates building a stack of integers from scratch using a static array data structure.

Attributes: The stack class requires three private instance variables: an integer array a to hold the data, a maxSize variable to establish the upper bound of the static array, and a top integer tracking the index of the top element.

Constructor: When an empty stack object is instantiated, it initializes the array to a size specified by a formal parameter, sets maxSize, and sets top to -1 to signify an empty state.

Push Execution: The index tracker top is pre-incremented, and the integer is assigned to that array index (a[++top] = k). It includes a safety condition checking if top == maxSize - 1 to prevent a runtime index-out-of-bounds error if the stack is already full.

Pop Execution: The top value is returned, and top is subsequently decremented using a post-decrement operations layout (return a[top--]).

Optimization Note: All primary methods within an ideal stack implementation are structured to execute with a highly efficient time complexity of O(1).

Information Hiding Constraint: Because attributes are strictly defined with the private access modifier, external classes utilizing the stack as a black box can only interface with it using public operational methods like push() and pop(), rather than directly manipulating indices.

Problem-Solving Applications

Bracket Balancing in Compilers

The Goal: Given an expression containing brackets, determine if the brackets open and close in a valid, balanced sequence.

Naive/Counter Approaches: Simply counting open and closed brackets fails in scenarios where they appear in the wrong order (e.g., )(). Using a tracking counter variable works but becomes messy once expressions grow complex and require evaluating multiple bracket types.

The Stack Solution: As the string expression is scanned linearly from left to right, every open bracket is pushed onto the stack. When a closed bracket is encountered, the algorithm pops the corresponding element off the stack. If a pop is called on an empty stack, or if the stack is not completely empty after the string traversal finishes, the expression is declared unbalanced. This achieves a linear time complexity of O(n).

Reversing a Text File or an External Stack

Reversing Text: Lines from a file can be sequentially read and pushed to a stack until reaching the End-of-File marker. Popping the entries prints them out in perfectly reversed order.

Reversing a Stack in Place (External Method): To reverse a target stack using only other stack instances as temporary containers, the contents of the initial stack are unpacked into a temporary stack (tmp1), then unpacked again into a second stack (tmp2), and finally popped back into the original stack. This three-loop sequential procedure manages reference manipulation successfully without changing pointer addresses directly.

Arithmetic Expression Evaluation

The speaker breaks down three mathematical notations: Infix (operators between operands), Postfix (operators after operands), and Prefix (operators before operands).

Calculators convert expressions from infix to postfix notation to eliminate priorities and brackets entirely, unlocking sequential parsing via a stack.

Evaluation Algorithm: Read the postfix symbols sequentially. If a number/operand is scanned, push it onto the stack. If an operator arrives, pop the top two values from the stack, execute the arithmetic operation, and push the resulting value back into the stack.

Non-Commutative Warning: For operations like subtraction or division, order matters; the first item popped is treated as the right-hand operand (denominator/subtrahend), and the second item popped functions as the left-hand operand.

Syntax Validation: This evaluation pipeline can also serve as a validator for postfix expressions. If the algorithm hits the end of parsing and the stack contains more than one final numerical value, it indicates that the input expression was malformed.
<!-- TRANSCRIPT END: 11quFvhf6eoymRe9x_H-fatetkyP7ntI7 -->

### Prof. Slim's LIve Lecture 2 Sorting (VoD).mp4

- `video_id`: `1Q7NwFV8p4nSd0KR23PK433nq5pj6mB8S`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Q7NwFV8p4nSd0KR23PK433nq5pj6mB8S/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Q7NwFV8p4nSd0KR23PK433nq5pj6mB8S -->
Lecture Overview

This video features a live classroom lecture for the course CSCN301. The speaker reviews fundamental array operations from the previous session before introducing and detailing three fundamental sorting algorithms.

Part 1: Recap of Array Operations

The session begins with a review of data collection storage using sorted and unsorted arrays, focusing on three basic operations: insertion, deletion, and searching.

Unsorted Arrays:

Insertion: Takes O(1) constant time complexity.

Searching: Requires a linear search with a worst-case time complexity of O(n) because the element may not exist, requiring a cell-by-cell traversal to the end.

Deletion: Requires searching for the item first, yielding a worst-case complexity of O(n).

Sorted Arrays:

Insertion: Becomes less efficient at O(n) because the correct position must be located to insert a key.

Deletion: Remains unimproved compared to unsorted arrays, operating at O(n).

Searching: Drastically improves to O(log n) via binary search. For example, 16 elements require only 4 checks, whereas a linear search with 32 elements could require up to 32 checks in the worst case.

Application Choice: Unsorted arrays are ideal for simple archiving where insertion efficiency is prioritized. Sorted arrays are preferred when an application relies heavily on database searching (e.g., finding specific student names or filtering by highest GPA).

Part 2: Introduction to Sorting Algorithms

Sorting is highlighted as one of the most thoroughly studied topics in computer science because it optimizes search operations.

The speaker notes that sophisticated sorting algorithms with superior time complexities—such as Merge Sort, Quicksort, Shell Sort, and Heap Sort—are bypassed in this session to focus on three simpler, straightforward options.

Part 3: Bubble Sort

Bubble Sort is described as a simple algorithm that repeatedly steps through a collection, comparing adjacent elements and swapping them if they are out of order.

Live Demonstration:

Five students are brought to the front of the classroom to model an unsorted array containing the values 12, 70, 1, 61, and 20.

Pass 1: Adjacent pairs are checked cell-by-cell. 12 and 70 are in order. 70 is greater than 1, so they swap. 70 is greater than 61, causing another swap. Finally, 70 is greater than 20, resulting in a final swap.

Pass Invariant: At the completion of the first pass, the largest element (70) is guaranteed to bubble into its permanent, correct position at the end of the array. Subsequent passes establish an invariant where the last i elements remain correctly positioned and sorted.

Complexity Analysis:

Worst-Case Scenario: Occurs when an array is completely reversed (descending order) and needs to be sorted in ascending order. For n elements, the total comparisons required follow the polynomial series (n-1) + (n-2) + ... + 1, which equates to n(n-1)/2 or an O(n²) complexity.

Naive Implementation Issues: A standard Bubble Sort will continue executing all n-1 passes even if the array becomes fully sorted early.

Code Implementation Optimization:

The structure relies on nested loops: an outer loop counting the passes up to a.length - 1, and an inner loop performing the adjacent comparisons.

Optimization 1: The inner loop's boundary can be adjusted from j < a.length - 1 to j < a.length - 1 - i to avoid redundantly checking elements that have already bubbled to the end.

Optimization 2 (The Flag Technique): By introducing a boolean flag or a counter variable c inside the outer loop and resetting it to 0 at each pass, the program can track swaps. If the inner loop finishes a pass with 0 swaps, an early return or break statement terminates execution. This optimizes the best-case time complexity to linear O(n) when handling an already sorted array.

Flaw: Bubble Sort is generally considered inefficient because it executes a high volume of expensive swap operations.

Part 4: Selection Sort

Selection Sort minimizes the overall number of swaps by traversing the array to select the single smallest element from the unsorted portion and swapping it into place.

Live Demonstration:

The algorithm scans the array while tracking the smallest value seen so far. Once the true minimum element is discovered at the end of the pass, it is swapped directly into index 0.

Pass Invariant: After the first pass, the absolute minimum element is locked into the first position. The next pass isolates the remaining unsorted sub-array to find the second-smallest element.

Complexity & Optimization Discussion:

The worst-case number of total swaps is significantly lower at O(n), or n-1 swaps.

The Sorted Array Trap: In a standard implementation, Selection Sort still runs at O(n²) time complexity even if the array is already perfectly sorted. It must continuously scan the unsorted sub-arrays to confirm the minimums.

The Student Proposal: A student suggests tracking how many times the smallest value so far variable shifts its index backwards during a pass. If it changes exactly n-1 times consecutively, it indicates the array is already sorted and can trigger an early exit to achieve O(n) best-case behavior.

Code Implementation Structure:

The implementation uses two variables inside the outer loop: one to store the smallest value s and another to retain its explicit index location. Tracking the index is vital so the outer loop knows exactly where to perform the single swap at the end of the pass.

The inner loop initialization is set to j = i + 1, enabling it to skip previously sorted positions at the beginning of the array.

Part 5: Insertion Sort

Insertion Sort mirrors how people naturally organize a hand of playing cards. Rather than executing rigid element-by-element swaps, it extracts an element, creates a temporary copy, and shifts sorted items to the right until it finds the correct position to insert the item.

Live Demonstration:

The first element (at index 0) is automatically assumed to be a sorted sub-array of one.

The algorithm copies the item at index 1 (12) and evaluates it against the sorted item (70). Because 70 is larger, it shifts to the right into index 1. 12 is then cleanly inserted into index 0.

This sequential shifting behavior replaces the traditional, multi-step swap operation entirely.

Inherent Performance Advantages:

Worst-Case Scenario: If an array is sorted in descending order, every single element must slide across the entire sorted sub-array, resulting in an O(n²) time complexity.

Best-Case Scenario: If the array is already sorted, the cloned element is immediately compared to the item directly to its left. When the algorithm detects that the left item is smaller, no shifting occurs, and the cloned value is placed right back into its spot.

Consequently, Insertion Sort requires only n-1 total comparisons and zero shifts on sorted data. This grants it an automatic O(n) best-case time complexity natively, without requiring any added flag variables or code optimizations.

Summary of Algorithm Complexities

The lecture concludes by noting that Insertion Sort is highly effective for data sets that are already sorted or nearly sorted, running up to 40% faster than Bubble Sort and Selection Sort in practical applications.
<!-- TRANSCRIPT END: 1Q7NwFV8p4nSd0KR23PK433nq5pj6mB8S -->

### Prof. Slim's Live Lecture 2 Sorting (VoD) (2).mp4

- `video_id`: `1Oy6xbldN66CoM18qoyGqWaO6DYnPpWM8`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Oy6xbldN66CoM18qoyGqWaO6DYnPpWM8/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Oy6xbldN66CoM18qoyGqWaO6DYnPpWM8 -->
Background and Context

Array Operations: A collection of data can be stored in sorted or unsorted arrays. The most fundamental operations are insertion, deletion, and searching.

Unsorted Arrays: Insertion is highly efficient at O(1). However, deletion and searching both require a linear search, resulting in a worst-case time complexity of O(n).

Sorted Arrays: In sorted arrays, insertion and deletion worsen to O(n) due to the need to shift or search for specific keys. However, searching improves dramatically to O(log n) using a binary search.

Importance of Sorting: Sorting makes searching significantly more efficient and is a foundational operation in databases, such as when looking up student records by specific criteria.

Bubble Sort

Mechanism: Bubble sort compares adjacent elements in pairs and swaps them if they are out of order. It repeatedly bubbles the largest elements to the end of the array across multiple passes.

Invariant: After the first pass, the largest element is guaranteed to be in its correct, final position. After k passes, the last k elements are correctly positioned.

Code Implementation Structure: It uses a nested loop structure. The outer loop counts the total number of passes (n-1 passes for n elements), while the inner loop compares adjacent elements and handles the swaps.

Code Refinement: The inner loop can be optimized by subtracting the outer loop counter variable (minus i) from the length boundary, preventing unnecessary comparisons with elements already locked into their correct positions.

Flag/Counter Optimization: By introducing a swap counter variable or a boolean flag inside the outer pass loop, the algorithm can track whether any swaps occurred. If the count remains zero during a pass, the array is already sorted, and the method can exit early via a return statement.

Complexity:

Worst Case: Occurs when the array is in descending order and must be sorted in ascending order. The total number of comparisons is calculated as n(n-1)/2, giving a polynomial time complexity of O(n²).

Best Case (Optimized): If the flag optimization is implemented and the array is already sorted, it only requires a single pass, dropping the time complexity to O(n).

Selection Sort

Mechanism: Conceived to minimize the high number of swaps performed by bubble sort. It traverses the array to select the minimum value in the unsorted portion and swaps it into its correct position starting from index zero.

Invariant: After the first pass, the smallest element is locked into index zero. Each subsequent pass places the next smallest element in its correct sequential position.

Code Implementation Structure: Requires tracking both the smallest value found so far and its specific index location to successfully execute the swap at the end of the inner loop. The inner loop starts at i + 1 to skip already sorted elements.

Complexity:

Worst Case: Requires nested iterations to continuously find the minimums, yielding an O(n²) time complexity. The maximum number of total swaps is n-1.

Best Case: Unlike optimized bubble sort, standard selection sort maintains a time complexity of O(n²) even if the array is already sorted, because it still scans the remaining unsorted spaces to verify the minimum. An optimization proposed by a student involves checking the number of times the minimum changes when scanning backwards.

Insertion Sort

Mechanism: Commonly used to sort playing cards, insertion sort skips the first element (treating it as a sorted sub-array of size one) and sequentially picks the next elements. It takes a clone or ghost copy of the element to be inserted, compares it backwards against the sorted sub-array, and shifts elements to the right until it finds the correct insertion slot.

Code Implementation Structure: An outer for loop advances from index one to the end of the array. An inner loop handles the shifting mechanism. Shifting (a[j + 1] = a[j]) continues as long as the inner loop index j is non-negative and the selected element is smaller than the current value at a[j]. No swaps are performed, only continuous data shifts.

Complexity:

Worst Case: When the array is sorted in exact descending order, every element must shift across the entire length of the sorted sub-array, resulting in an O(n²) time complexity.

Best Case: When the array is already sorted, the algorithm checks the sub-array element exactly once per pass, identifies that no shifting is required, and places it right back. This gives it a natural best-case time complexity of O(n) without needing any artificial optimizations or flags. This makes it highly efficient—roughly 40% faster than Bubble Sort and Selection Sort—for datasets that are already sorted or nearly sorted.
<!-- TRANSCRIPT END: 1Oy6xbldN66CoM18qoyGqWaO6DYnPpWM8 -->

### Prof. Slim's Lecture 3 Stacks (VoD).mp4

- `video_id`: `1Dp4gwALIG36r5hMgCY6ZQX_lEgMF_IB-`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Dp4gwALIG36r5hMgCY6ZQX_lEgMF_IB-/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Dp4gwALIG36r5hMgCY6ZQX_lEgMF_IB- -->
Core Concepts & Definitions

Abstract Data Types (ADTs): The video introduces the concept of an abstract data type, which focuses on the data type as a collection of data and its allowable set of operations. This perspective intentionally sets aside the underlying implementation details to simplify algorithm design and achieve better time and space complexity.

The Stack Data Type: A stack is a collection of data elements defined by a Last-In, First-Out (LIFO) behavior. It mimics real-world piles, such as a stack of candles, plates at a buffet, or educational assignments layered on a desk. Elements can only be added or removed by directly interacting with the top of the stack.

Primary Stack Operations

Push: Inserts or adds a new data element onto the top of the stack.

Pop: Removes the topmost element from the stack. It can also be modified to return the value of the removed element.

Top: Inspects or references the item sitting at the absolute top of the stack without actually removing it.

Is Empty: Returns a boolean value (true or false) checking whether the stack currently contains zero elements.

Is Full: Returns a boolean value checking whether the stack has reached its maximum allocated capacity.

Size: Returns the exact total number of elements currently stored within the stack.

Algorithmic Applications of Stacks

Bracket Balancing Verification: Compilers use stacks to verify if equations are well-bracketed. By traversing an algebraic expression precisely once from left to right, open brackets are pushed onto the stack. Whenever a closed bracket is encountered, an element is popped from the stack.

If the stack becomes empty at the exact end of parsing, the expression is valid.

If a pop is attempted on an empty stack, or if unpopped brackets remain at the end, the configuration is invalid. This implementation drops the time complexity from an inefficient O(n²) back-and-forth traversal down to O(n).

Text and Sentence Reversal: Stacks provide a straightforward technique for reversing text sequences. A sentence can be read from left to right, parsing individual words split by spaces and pushing them in order into the stack. Popping words one by one naturally outputs the sentence in reversed order.

Expression Evaluation: Calculators and execution engines process mathematical expressions natively using stacks. Parsing standard human-readable formulas (infix notation) creates highly complex, deep O(n²) scans to respect standard operator precedence rules. Stacks facilitate converting these standard expressions into postfix or prefix notations, dropping computation steps down to simple linear workloads.

Code Implementation Strategy

Array Implementation: Because arrays are static structures, a fixed maxSize variable must configure the stack instance initially.

The Top Variable: Tracking the top elements uses an index pointer variable named top, initialized to -1 to explicitly signify an empty stack state.

Internal Constraint Checks: Robust software architecture dictates wrapping standard operations around protective conditional flags. Attempting to execute a push sequence on a full stack triggers an explicit IndexOutOfBoundsException error if left unchecked; thus, explicit isFull() checking must act as a preliminary safeguard. Correspondingly, executing pop routines requires a safe isEmpty() flag check.

Time Complexity Bounds: When properly mapped out inside array logic, all primary baseline operations—namely push, pop, top, isEmpty, isFull, and size—run inside optimal, independent O(1) constant time constraints.

External Methods vs. Internal States: The speaker distinguishes between internal class behavior and external algorithmic tools. Declaring variables like the data array and capacity sizes as private encapsulates implementation logic away safely. External tasks—like a helper function to reverse an entire stack cleanly—are restricted to interacting strictly with public interface actions (push, pop, isEmpty) without manipulating underlying data storage layout arrays directly.
<!-- TRANSCRIPT END: 1Dp4gwALIG36r5hMgCY6ZQX_lEgMF_IB- -->

### Prof. Slim's Live Lecture 1 Introduction to Arrays (VoD).mp4

- `video_id`: `1o_gzWVis0x3TQCepRMMLCeA4KHtyP76U`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1o_gzWVis0x3TQCepRMMLCeA4KHtyP76U/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1o_gzWVis0x3TQCepRMMLCeA4KHtyP76U -->
Course Structure and Overview

Topic: Introduction to Data Structures and Algorithms.

Nature of the Course: A pure programming course taught dynamically with interactive and practical concepts. It incorporates a blend of abstract theories implemented directly in Java to resolve complex, real-life problems.

Weekly Schedule: Includes weekly lectures, tutorials, and laboratory sessions. Weekly lab assignments are handled in randomized groups. All materials are posted online via a Content Management System (CMS) platform.

Tentative Grading Criteria:

Lab Assignments: 10%

Quizzes: 20% (Best of three quizzes)

Midterm Exam: 25%

Final Exam: 45%

Target Audience: Students are encouraged to use the first two weeks to review concepts taught in their second semester, especially for Computer Science majors who need to brush up on implementing things independently.

Overview of Core Concepts

Problem-Solving & Data Collection: Focuses on discovering efficient methods to solve complex problems and handle big data collections. Stacks, queues, lists, and sets are highlighted as implementation tools.

Static vs. Dynamic Data Structures:

Static: Structures like arrays require fixed sizes determined ahead of time. This can result in wasted space if the size is too large or severe inefficiencies if a bigger size must be created and fully populated cell-by-cell.

Dynamic: Structures like lists, vectors, linked lists, and binary trees offer dynamic sizing where size doesn't present an issue.

Primary Operations: Crucial data management concepts feature three essential actions: insertion, deletion, and searching.

Detailed Breakdown of Arrays

Classes and Objects in Java: The instructor provided an interactive live coding segment mapping out a Person class to demonstrate attributes, constructors, instantiation (new keyword), explicit parameters (this keyword), and overriding default memory references using toString methods.

Unsorted Arrays:

Characteristics: They function as indexed data structures allowing random cell access with a time complexity of O(1). Unpopulated integer array cells default to zero. In Java, the array length is a final constant variable that cannot be dynamically increased or decreased.

Insertion: Operates at a constant time complexity of O(1). Defensive programming or size checks are essential to avoid throwing an IndexOutOfBoundsException when attempting to write data beyond full capacity. Developers must track data using an active tracker variable (numberOfItems) rather than checking for default zeros since zero itself can be a valid input.

Deletion: Requires a linear time complexity of O(n) because the system must first linearly search for the targeted element before executing a loop to shift subsequent items up cell-by-cell. Nullifying empty cells does not save memory because integer allocations rigidly hold 32 bits regardless of values. All placement cases (middle, front, end) converge as O(n) worst-case variations depending on the total balance of search checks vs. sequential index shifting.

Searching: Linear search strategies inspect values from the first cell onwards, producing an O(n) complexity because missing or end-positioned values require traversing the full array.

Sorted Arrays:

Characteristics: Collection elements are strictly organized numerically, alphabetically, or lexicographically based on specific object attributes.

Insertion & Deletion: Both operations take O(n) linear time complexity. When inserting an element, the system must search for the correct sorted location, shift remaining items down or up to open a gap, overwrite the target index, and increment the tracker.

Binary Search: Outperforms linear search styles by operating at a logarithmic complexity (O(log n)). It splits an alphabetically or numerically sorted list in half repeatedly, evaluates the median value against the target, discards the obsolete side, and focuses recursively on the remaining segment until the item is isolated. Doubling the size of the array expands the search path by only a single incremental check (2^3 = 8 elements implies 3 checks, 2^4 = 16 elements implies 4 checks, and 2^5 = 32 elements implies 5 checks).
<!-- TRANSCRIPT END: 1o_gzWVis0x3TQCepRMMLCeA4KHtyP76U -->

### Prof. Slim's Lecture Classes & Objects II (VoD) (2).mp4

- `video_id`: `19jFBYMPgpCx6jXVJbbDDiGKdpOZx4qsW`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/19jFBYMPgpCx6jXVJbbDDiGKdpOZx4qsW/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 19jFBYMPgpCx6jXVJbbDDiGKdpOZx4qsW -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 19jFBYMPgpCx6jXVJbbDDiGKdpOZx4qsW -->

### Prof. Slim's Lecture Classes & Objects II (VoD).mp4

- `video_id`: `1JEfv1AxbyLPWatKaM1HdjDrUOFSK82H_`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1JEfv1AxbyLPWatKaM1HdjDrUOFSK82H_/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1JEfv1AxbyLPWatKaM1HdjDrUOFSK82H_ -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1JEfv1AxbyLPWatKaM1HdjDrUOFSK82H_ -->

### Prof. Slim's Lecture Classes & Objects I (VoD).mp4

- `video_id`: `13Kf8v4MWkfABJF8v9hDO7mfnWGFPdNQl`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/13Kf8v4MWkfABJF8v9hDO7mfnWGFPdNQl/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 13Kf8v4MWkfABJF8v9hDO7mfnWGFPdNQl -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 13Kf8v4MWkfABJF8v9hDO7mfnWGFPdNQl -->

### Prof. Slim's Lecture Arrays (VoD).mp4

- `video_id`: `1nsncV9aJNjDVyzXrqH7Cyz1v13uRkwvj`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1nsncV9aJNjDVyzXrqH7Cyz1v13uRkwvj/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1nsncV9aJNjDVyzXrqH7Cyz1v13uRkwvj -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1nsncV9aJNjDVyzXrqH7Cyz1v13uRkwvj -->

### Tutorial 11 Version 1 Hashtable (VoD).mp4

- `video_id`: `15N3O9ZzsJo7JYhgkCBGwSviDc2060_Rl`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/15N3O9ZzsJo7JYhgkCBGwSviDc2060_Rl/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 15N3O9ZzsJo7JYhgkCBGwSviDc2060_Rl -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 15N3O9ZzsJo7JYhgkCBGwSviDc2060_Rl -->

### Tutorial 11 Version 2 Hashtable (VoD).mp4

- `video_id`: `1fqL65ntD0MtL19G7RWUM3TAPvX-fJ4a5`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1fqL65ntD0MtL19G7RWUM3TAPvX-fJ4a5/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1fqL65ntD0MtL19G7RWUM3TAPvX-fJ4a5 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1fqL65ntD0MtL19G7RWUM3TAPvX-fJ4a5 -->

### Tutorial 10 Version 1 Trees II (VoD).mp4

- `video_id`: `1ljCr_v4j8fQKLaGuLlQI_lCa75WToTgs`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1ljCr_v4j8fQKLaGuLlQI_lCa75WToTgs/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1ljCr_v4j8fQKLaGuLlQI_lCa75WToTgs -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1ljCr_v4j8fQKLaGuLlQI_lCa75WToTgs -->

### Tutorial 10 Version 2 Trees II (VoD).mp4

- `video_id`: `1N-iELMPCtSTXIPK7y_PKJz53bPI4yZnJ`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1N-iELMPCtSTXIPK7y_PKJz53bPI4yZnJ/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1N-iELMPCtSTXIPK7y_PKJz53bPI4yZnJ -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1N-iELMPCtSTXIPK7y_PKJz53bPI4yZnJ -->

### Tutorial 9 Version 1 Trees I (VoD).mp4

- `video_id`: `1LII3v77SGvjrrRgd6LuqB9ykH7kpVLxB`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1LII3v77SGvjrrRgd6LuqB9ykH7kpVLxB/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1LII3v77SGvjrrRgd6LuqB9ykH7kpVLxB -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1LII3v77SGvjrrRgd6LuqB9ykH7kpVLxB -->

### Tutorial 8 Version 1 Doubly Link List (VoD).mp4

- `video_id`: `1uJat9ouF9oNzSvPWyfe3XxN4eZ_hJa-y`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1uJat9ouF9oNzSvPWyfe3XxN4eZ_hJa-y/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1uJat9ouF9oNzSvPWyfe3XxN4eZ_hJa-y -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1uJat9ouF9oNzSvPWyfe3XxN4eZ_hJa-y -->

### Tutorial 8 Version 2 Doubly Link List (VoD).mp4

- `video_id`: `1OU55FmkZ1C5A5NaFcOOwIyXH15-hdTYF`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1OU55FmkZ1C5A5NaFcOOwIyXH15-hdTYF/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1OU55FmkZ1C5A5NaFcOOwIyXH15-hdTYF -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1OU55FmkZ1C5A5NaFcOOwIyXH15-hdTYF -->

### Tutorial 8 Version 3 Doubly Link List (VoD).mp4

- `video_id`: `1Z5nK10vWYRNxdWczGaaqS0F7KKts8jCU`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Z5nK10vWYRNxdWczGaaqS0F7KKts8jCU/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Z5nK10vWYRNxdWczGaaqS0F7KKts8jCU -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Z5nK10vWYRNxdWczGaaqS0F7KKts8jCU -->

### Tutorial 7 Version 1 Link List (VoD).mp4

- `video_id`: `1XYl1jg0FB-a_DRLlujs_ypK_aDdVoDtH`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1XYl1jg0FB-a_DRLlujs_ypK_aDdVoDtH/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1XYl1jg0FB-a_DRLlujs_ypK_aDdVoDtH -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1XYl1jg0FB-a_DRLlujs_ypK_aDdVoDtH -->

### Tutorial 7 Version 3 Link List (VoD).mp4

- `video_id`: `1G2pFgdMBEczzVvSy8rUhjoPCuZaYWH9Q`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1G2pFgdMBEczzVvSy8rUhjoPCuZaYWH9Q/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1G2pFgdMBEczzVvSy8rUhjoPCuZaYWH9Q -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1G2pFgdMBEczzVvSy8rUhjoPCuZaYWH9Q -->

### Tutorial 7 Version 2 Link List (VoD).mp4

- `video_id`: `1ur82dxvxKHUdFJJXcYPuf4zw31iEFtpC`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1ur82dxvxKHUdFJJXcYPuf4zw31iEFtpC/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1ur82dxvxKHUdFJJXcYPuf4zw31iEFtpC -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1ur82dxvxKHUdFJJXcYPuf4zw31iEFtpC -->

### Tutorial 7 Version 2 Link List (VoD) (2).mp4

- `video_id`: `1D-or064ZaFy1vBCMlaDmwEPk5L9gvX55`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1D-or064ZaFy1vBCMlaDmwEPk5L9gvX55/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1D-or064ZaFy1vBCMlaDmwEPk5L9gvX55 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1D-or064ZaFy1vBCMlaDmwEPk5L9gvX55 -->

### Tutorial 6 Version 2 Priority Queues (VoD).mp4

- `video_id`: `1Nlo4lP00WK1HTOdBd5Yuiny_sogwYSTE`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Nlo4lP00WK1HTOdBd5Yuiny_sogwYSTE/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Nlo4lP00WK1HTOdBd5Yuiny_sogwYSTE -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Nlo4lP00WK1HTOdBd5Yuiny_sogwYSTE -->

### Tutorial 6 Version 1 Priority Queues (VoD).mp4

- `video_id`: `17I3828pmuoVh8ksf_Z3qySseNmy1OG8Z`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/17I3828pmuoVh8ksf_Z3qySseNmy1OG8Z/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 17I3828pmuoVh8ksf_Z3qySseNmy1OG8Z -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 17I3828pmuoVh8ksf_Z3qySseNmy1OG8Z -->

### Tutorial 5 Version 1 Queues (VoD).mp4

- `video_id`: `15Yetkxq-_Qx-Hzoibl_hu6xa_r3Scdts`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/15Yetkxq-_Qx-Hzoibl_hu6xa_r3Scdts/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 15Yetkxq-_Qx-Hzoibl_hu6xa_r3Scdts -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 15Yetkxq-_Qx-Hzoibl_hu6xa_r3Scdts -->

### Tutorial 5 Version 2 Queues (VoD).mp4

- `video_id`: `1ifnsYhBSSn4KH5A00jgRz6cALsjWbbpo`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1ifnsYhBSSn4KH5A00jgRz6cALsjWbbpo/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1ifnsYhBSSn4KH5A00jgRz6cALsjWbbpo -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1ifnsYhBSSn4KH5A00jgRz6cALsjWbbpo -->

### Tutorial 5 Version 3 Queues (VoD).mp4

- `video_id`: `1V-N0pSyOKTXnZ_uftAkWmTc8db774pAj`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1V-N0pSyOKTXnZ_uftAkWmTc8db774pAj/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1V-N0pSyOKTXnZ_uftAkWmTc8db774pAj -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1V-N0pSyOKTXnZ_uftAkWmTc8db774pAj -->

### Tutorial 4 Version 1 Stacks of Objects (VoD).mp4

- `video_id`: `11z1-ytKD-6-Olz3JoI_BBE-JX0Cf-VLc`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/11z1-ytKD-6-Olz3JoI_BBE-JX0Cf-VLc/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 11z1-ytKD-6-Olz3JoI_BBE-JX0Cf-VLc -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 11z1-ytKD-6-Olz3JoI_BBE-JX0Cf-VLc -->

### Tutorial 4 Version 2 Stacks of Objects (VoD).mp4

- `video_id`: `1ipczjETMB38JZzDXIy_N1Iw47Cw1cKFZ`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1ipczjETMB38JZzDXIy_N1Iw47Cw1cKFZ/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1ipczjETMB38JZzDXIy_N1Iw47Cw1cKFZ -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1ipczjETMB38JZzDXIy_N1Iw47Cw1cKFZ -->

### Tutorial 4 Version 3 Stacks of Objects (VoD).mp4

- `video_id`: `1y2WNNo7z_Diqprmz1RX5iLodtm7YrD2M`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1y2WNNo7z_Diqprmz1RX5iLodtm7YrD2M/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1y2WNNo7z_Diqprmz1RX5iLodtm7YrD2M -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1y2WNNo7z_Diqprmz1RX5iLodtm7YrD2M -->

### Tutorial 3 Version 2 Stacks (VoD).mp4

- `video_id`: `157T4SRPN1m6eZ9aa7cYpjHQbk_t-h8hY`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/157T4SRPN1m6eZ9aa7cYpjHQbk_t-h8hY/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 157T4SRPN1m6eZ9aa7cYpjHQbk_t-h8hY -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 157T4SRPN1m6eZ9aa7cYpjHQbk_t-h8hY -->

### Tutorial 3 Version 1 Stacks (VoD).mp4

- `video_id`: `10KenPeBjbu_kwXTRaRg6Lsbaq_CwC5tO`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/10KenPeBjbu_kwXTRaRg6Lsbaq_CwC5tO/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 10KenPeBjbu_kwXTRaRg6Lsbaq_CwC5tO -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 10KenPeBjbu_kwXTRaRg6Lsbaq_CwC5tO -->

### Tutorial 3 Version 3 Stacks (VoD).mp4

- `video_id`: `1ChwTp3Ov4QODA7yBJJ30q2fp07zRzlIJ`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1ChwTp3Ov4QODA7yBJJ30q2fp07zRzlIJ/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1ChwTp3Ov4QODA7yBJJ30q2fp07zRzlIJ -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1ChwTp3Ov4QODA7yBJJ30q2fp07zRzlIJ -->

### Tutorial 2 Version 1 Sorting (VoD).mp4

- `video_id`: `1Itlbp2CmTKgGw8qMS8QW-xIMUzFN7fT4`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Itlbp2CmTKgGw8qMS8QW-xIMUzFN7fT4/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Itlbp2CmTKgGw8qMS8QW-xIMUzFN7fT4 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Itlbp2CmTKgGw8qMS8QW-xIMUzFN7fT4 -->

### Tutorial 2 Version 2 Sorting (VoD).mp4

- `video_id`: `15yYOPEwoYa_nSpgwEw9y6XO9pjnRyYwk`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/15yYOPEwoYa_nSpgwEw9y6XO9pjnRyYwk/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 15yYOPEwoYa_nSpgwEw9y6XO9pjnRyYwk -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 15yYOPEwoYa_nSpgwEw9y6XO9pjnRyYwk -->

### Tutorial 1 Version 2 Introduction to Arrays (VoD).mp4

- `video_id`: `1L2GUlbX5KtksPsTRtHKiVuI3ntwSsM_v`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1L2GUlbX5KtksPsTRtHKiVuI3ntwSsM_v/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1L2GUlbX5KtksPsTRtHKiVuI3ntwSsM_v -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1L2GUlbX5KtksPsTRtHKiVuI3ntwSsM_v -->

### Tutorial 2 Version 3 Sorting (VoD).mp4

- `video_id`: `19al802VSYsu59Hqnxq5Kc9e7C77OlkXh`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/19al802VSYsu59Hqnxq5Kc9e7C77OlkXh/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 19al802VSYsu59Hqnxq5Kc9e7C77OlkXh -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 19al802VSYsu59Hqnxq5Kc9e7C77OlkXh -->

### Tutorial 1 Version 1 Introduction to Arrays (VoD).mp4

- `video_id`: `1N4Mcng07wlm8Tfg-4ZiLJngQAvaoIUA1`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1N4Mcng07wlm8Tfg-4ZiLJngQAvaoIUA1/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1N4Mcng07wlm8Tfg-4ZiLJngQAvaoIUA1 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1N4Mcng07wlm8Tfg-4ZiLJngQAvaoIUA1 -->

### Tutorial 1 Version 3 Introduction to Arrays (VoD).mp4

- `video_id`: `1YUsKvTL5s9b7UbnjrXpzuGkxD7Plr8Ba`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1YUsKvTL5s9b7UbnjrXpzuGkxD7Plr8Ba/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1YUsKvTL5s9b7UbnjrXpzuGkxD7Plr8Ba -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1YUsKvTL5s9b7UbnjrXpzuGkxD7Plr8Ba -->

### Tutorial Classes & Objects II (VoD).mp4

- `video_id`: `1b-j1Io79e5nxtkN-TakWn2cteCmmNxZ_`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1b-j1Io79e5nxtkN-TakWn2cteCmmNxZ_/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1b-j1Io79e5nxtkN-TakWn2cteCmmNxZ_ -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1b-j1Io79e5nxtkN-TakWn2cteCmmNxZ_ -->

### Tutorial Classes & Objects II (VoD) (2).mp4

- `video_id`: `1FipC7o24eUuQWQ7wVlWNLxbKg1ug97at`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1FipC7o24eUuQWQ7wVlWNLxbKg1ug97at/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1FipC7o24eUuQWQ7wVlWNLxbKg1ug97at -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1FipC7o24eUuQWQ7wVlWNLxbKg1ug97at -->

### Tutorial Arrays (VoD).mp4

- `video_id`: `1tGZLIRd7TMWcSXCbQ-fKFdgMtoUrYBIu`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1tGZLIRd7TMWcSXCbQ-fKFdgMtoUrYBIu/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1tGZLIRd7TMWcSXCbQ-fKFdgMtoUrYBIu -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1tGZLIRd7TMWcSXCbQ-fKFdgMtoUrYBIu -->

### Tutorial Classes & Objects I (VoD).mp4

- `video_id`: `1fS1L0Fo2agzoQG9m1hkSyvAB_kV1Lp1E`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1fS1L0Fo2agzoQG9m1hkSyvAB_kV1Lp1E/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1fS1L0Fo2agzoQG9m1hkSyvAB_kV1Lp1E -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1fS1L0Fo2agzoQG9m1hkSyvAB_kV1Lp1E -->

## Programming 2 (P2)

Lecture recordings for the Programming 2 course.

### =GUI (Live lecture) (VoD).mp4

- `video_id`: `1IxkwGSbC5vhxj5rmVTeh3VWWTAnl9wis`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1IxkwGSbC5vhxj5rmVTeh3VWWTAnl9wis/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1IxkwGSbC5vhxj5rmVTeh3VWWTAnl9wis -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1IxkwGSbC5vhxj5rmVTeh3VWWTAnl9wis -->

### GUI 1 (VoD).mp4

- `video_id`: `13C-w5Q7TkZ6afrdyV6AGWLjTrRv1N6_C`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/13C-w5Q7TkZ6afrdyV6AGWLjTrRv1N6_C/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 13C-w5Q7TkZ6afrdyV6AGWLjTrRv1N6_C -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 13C-w5Q7TkZ6afrdyV6AGWLjTrRv1N6_C -->

### Listeners (VoD).mp4

- `video_id`: `18EmdDlPrzJ_tOZF9LFc69q0uLRrlALwY`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/18EmdDlPrzJ_tOZF9LFc69q0uLRrlALwY/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 18EmdDlPrzJ_tOZF9LFc69q0uLRrlALwY -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 18EmdDlPrzJ_tOZF9LFc69q0uLRrlALwY -->

### Exceptions (Live lecture) (VoD).mp4

- `video_id`: `1iPGdRPgerzklyQtAYSYRNTvG7GfHJ7dx`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1iPGdRPgerzklyQtAYSYRNTvG7GfHJ7dx/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1iPGdRPgerzklyQtAYSYRNTvG7GfHJ7dx -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1iPGdRPgerzklyQtAYSYRNTvG7GfHJ7dx -->

### Game description video (VoD).mp4

- `video_id`: `1rroLZ-VJQOIf1vlsG0E2N_YTvalaewvV`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1rroLZ-VJQOIf1vlsG0E2N_YTvalaewvV/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1rroLZ-VJQOIf1vlsG0E2N_YTvalaewvV -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1rroLZ-VJQOIf1vlsG0E2N_YTvalaewvV -->

### GUI 2 (VoD).mp4

- `video_id`: `1LEHZyxEPr4mtTcITuG_H3eJBCCleoaEr`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1LEHZyxEPr4mtTcITuG_H3eJBCCleoaEr/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1LEHZyxEPr4mtTcITuG_H3eJBCCleoaEr -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1LEHZyxEPr4mtTcITuG_H3eJBCCleoaEr -->

### Encapsulation (Live lecture) (VoD).mp4

- `video_id`: `1pmarKRoEHlKJJ6ay1_qVhtWwYPXO07zC`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1pmarKRoEHlKJJ6ay1_qVhtWwYPXO07zC/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1pmarKRoEHlKJJ6ay1_qVhtWwYPXO07zC -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1pmarKRoEHlKJJ6ay1_qVhtWwYPXO07zC -->

### Lecture 4 (Interfaces -- live lecture) (VoD).mp4

- `video_id`: `1BqPccsKN9W9rmLsF20iObLZgFoYD_7Lq`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1BqPccsKN9W9rmLsF20iObLZgFoYD_7Lq/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1BqPccsKN9W9rmLsF20iObLZgFoYD_7Lq -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1BqPccsKN9W9rmLsF20iObLZgFoYD_7Lq -->

### Inheritance (Live lecture) (VoD).mp4

- `video_id`: `1n8ZISaAqYdf3uLs-VDRWEZUOTk1joNC3`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1n8ZISaAqYdf3uLs-VDRWEZUOTk1joNC3/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1n8ZISaAqYdf3uLs-VDRWEZUOTk1joNC3 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1n8ZISaAqYdf3uLs-VDRWEZUOTk1joNC3 -->

### Lecture 3 (Abstraction and Polymorphism -- live lecture) (VoD).mp4

- `video_id`: `1UMjKHw309XRt5NNoXYSc3G7GLQX8jCBk`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1UMjKHw309XRt5NNoXYSc3G7GLQX8jCBk/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1UMjKHw309XRt5NNoXYSc3G7GLQX8jCBk -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1UMjKHw309XRt5NNoXYSc3G7GLQX8jCBk -->

## Computer Organization (CO)

Lecture and tutorial recordings for the Computer Organization course.

### Lecture 4 Recording (VoD).mp4

- `video_id`: `1B7w5A6wgRYMYeIyejAxHgBpJfGadb5o4`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1B7w5A6wgRYMYeIyejAxHgBpJfGadb5o4/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1B7w5A6wgRYMYeIyejAxHgBpJfGadb5o4 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1B7w5A6wgRYMYeIyejAxHgBpJfGadb5o4 -->

### Tutorial Part  (VoD) (2).mp4

- `video_id`: `17NqruMCsug3Ke4awfAOtEmgfHIxCMlGv`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/17NqruMCsug3Ke4awfAOtEmgfHIxCMlGv/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 17NqruMCsug3Ke4awfAOtEmgfHIxCMlGv -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 17NqruMCsug3Ke4awfAOtEmgfHIxCMlGv -->

### Higher Order Functions - Recording Part 1 (VoD).mp4

- `video_id`: `1TJr1hpWioZ7BHbBA44TBWeYzq056dMTu`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1TJr1hpWioZ7BHbBA44TBWeYzq056dMTu/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1TJr1hpWioZ7BHbBA44TBWeYzq056dMTu -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1TJr1hpWioZ7BHbBA44TBWeYzq056dMTu -->

### Higher Order functions VoD (VoD).mp4

- `video_id`: `1X5hR5HxvKGGIwFmhfGVm2yfhdo4w5D_3`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1X5hR5HxvKGGIwFmhfGVm2yfhdo4w5D_3/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1X5hR5HxvKGGIwFmhfGVm2yfhdo4w5D_3 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1X5hR5HxvKGGIwFmhfGVm2yfhdo4w5D_3 -->

### 8 - Types Tutorial (VoD).mp4

- `video_id`: `1x6rH-4oVmqFddl496m179DY2m1ae5IaK`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1x6rH-4oVmqFddl496m179DY2m1ae5IaK/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1x6rH-4oVmqFddl496m179DY2m1ae5IaK -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1x6rH-4oVmqFddl496m179DY2m1ae5IaK -->

### Types Tutorial (VoD).mp4

- `video_id`: `1yJt0OgxBe4rP4BUYdVLSdlqhiyOK4e8T`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1yJt0OgxBe4rP4BUYdVLSdlqhiyOK4e8T/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1yJt0OgxBe4rP4BUYdVLSdlqhiyOK4e8T -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1yJt0OgxBe4rP4BUYdVLSdlqhiyOK4e8T -->

### Types Recording (VoD).mp4

- `video_id`: `1oWWkjQZ9nnMk7Rj_3q1fw2zj2I6AhZY2`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1oWWkjQZ9nnMk7Rj_3q1fw2zj2I6AhZY2/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1oWWkjQZ9nnMk7Rj_3q1fw2zj2I6AhZY2 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1oWWkjQZ9nnMk7Rj_3q1fw2zj2I6AhZY2 -->

### Extra Practice Recording 2 (VoD).mp4

- `video_id`: `1EiprxWlsnZUv2a8pgH8XZKqimwHitp5R`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1EiprxWlsnZUv2a8pgH8XZKqimwHitp5R/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1EiprxWlsnZUv2a8pgH8XZKqimwHitp5R -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1EiprxWlsnZUv2a8pgH8XZKqimwHitp5R -->

### Extra Practice Recording 1 (VoD).mp4

- `video_id`: `1Kn_GjLknGGoKRIJI8HJcdCNc8x91B261`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Kn_GjLknGGoKRIJI8HJcdCNc8x91B261/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Kn_GjLknGGoKRIJI8HJcdCNc8x91B261 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Kn_GjLknGGoKRIJI8HJcdCNc8x91B261 -->

### Tutorial 12 (video) (VoD).mp4

- `video_id`: `1sSlbvc4qwB7f7JIXQchO50_n_pPG1tVi`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1sSlbvc4qwB7f7JIXQchO50_n_pPG1tVi/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1sSlbvc4qwB7f7JIXQchO50_n_pPG1tVi -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1sSlbvc4qwB7f7JIXQchO50_n_pPG1tVi -->

### Tutorial 11 (video) (VoD).mp4

- `video_id`: `1Uvv_6SjjGssGGkQtwCijICZwoPHrq80A`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Uvv_6SjjGssGGkQtwCijICZwoPHrq80A/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Uvv_6SjjGssGGkQtwCijICZwoPHrq80A -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Uvv_6SjjGssGGkQtwCijICZwoPHrq80A -->

### C Recording 2 (VoD).mp4

- `video_id`: `1Nxf-6RNNASWJxVyhGXsXcXwdU8TGT-kf`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Nxf-6RNNASWJxVyhGXsXcXwdU8TGT-kf/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Nxf-6RNNASWJxVyhGXsXcXwdU8TGT-kf -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Nxf-6RNNASWJxVyhGXsXcXwdU8TGT-kf -->

### C Recording 1 (VoD).mp4

- `video_id`: `1fdGQchq78Ftj-Tbej1-IB3zLElHaMo1q`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1fdGQchq78Ftj-Tbej1-IB3zLElHaMo1q/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1fdGQchq78Ftj-Tbej1-IB3zLElHaMo1q -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1fdGQchq78Ftj-Tbej1-IB3zLElHaMo1q -->

### Higher Order Functions - Recording Part 2 (VoD).mp4

- `video_id`: `18ESlRRd7-anTb2ur-khGFkPMWrpXSKxT`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/18ESlRRd7-anTb2ur-khGFkPMWrpXSKxT/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 18ESlRRd7-anTb2ur-khGFkPMWrpXSKxT -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 18ESlRRd7-anTb2ur-khGFkPMWrpXSKxT -->

### Haskell L1 Part1 Recording (VoD).mp4

- `video_id`: `11ToGbZ1rvB6yg5EoYw-tLxDTOplohZ2O`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/11ToGbZ1rvB6yg5EoYw-tLxDTOplohZ2O/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 11ToGbZ1rvB6yg5EoYw-tLxDTOplohZ2O -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 11ToGbZ1rvB6yg5EoYw-tLxDTOplohZ2O -->

### Lists Recording (VoD).mp4

- `video_id`: `1oo0LD8ThMCSx6JE75OE7JGL5-Xn3eclL`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1oo0LD8ThMCSx6JE75OE7JGL5-Xn3eclL/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1oo0LD8ThMCSx6JE75OE7JGL5-Xn3eclL -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1oo0LD8ThMCSx6JE75OE7JGL5-Xn3eclL -->

### Why Prolog  (VoD).mp4

- `video_id`: `1HXM__SxcgxjidtrGMMwm9sM7vMLRIjEH`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1HXM__SxcgxjidtrGMMwm9sM7vMLRIjEH/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1HXM__SxcgxjidtrGMMwm9sM7vMLRIjEH -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1HXM__SxcgxjidtrGMMwm9sM7vMLRIjEH -->

### CLPFD Part - Recording (VoD).mp4

- `video_id`: `14APLvaNCQzEtXedgpmPdFQnaRsBg89yy`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/14APLvaNCQzEtXedgpmPdFQnaRsBg89yy/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 14APLvaNCQzEtXedgpmPdFQnaRsBg89yy -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 14APLvaNCQzEtXedgpmPdFQnaRsBg89yy -->

### Tutorial 7 Recording (VoD).mp4

- `video_id`: `1RXIQfS83uW3sqEN6TI7RhM09yY6vLAP-`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1RXIQfS83uW3sqEN6TI7RhM09yY6vLAP-/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1RXIQfS83uW3sqEN6TI7RhM09yY6vLAP- -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1RXIQfS83uW3sqEN6TI7RhM09yY6vLAP- -->

### Tutorial Part  (VoD).mp4

- `video_id`: `18yRyIBHQ3qsvsx6nSrvRgkm0gD10FYNy`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/18yRyIBHQ3qsvsx6nSrvRgkm0gD10FYNy/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 18yRyIBHQ3qsvsx6nSrvRgkm0gD10FYNy -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 18yRyIBHQ3qsvsx6nSrvRgkm0gD10FYNy -->

### Extra Practice Recording (VoD).mp4

- `video_id`: `1HnCI7vsFjKrcEV2kLepMDdjZN08zeKAb`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1HnCI7vsFjKrcEV2kLepMDdjZN08zeKAb/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1HnCI7vsFjKrcEV2kLepMDdjZN08zeKAb -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1HnCI7vsFjKrcEV2kLepMDdjZN08zeKAb -->

### Lecture Recording Part 1 (VoD).mp4

- `video_id`: `1EvmNTpOrq08TjcJVGyau3Xy16u1nTPVw`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1EvmNTpOrq08TjcJVGyau3Xy16u1nTPVw/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1EvmNTpOrq08TjcJVGyau3Xy16u1nTPVw -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1EvmNTpOrq08TjcJVGyau3Xy16u1nTPVw -->

### Lecture Recording Part 2 (VoD).mp4

- `video_id`: `1A9nsMH-pueC1ctPX45TK0BvsN4SNP0lt`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1A9nsMH-pueC1ctPX45TK0BvsN4SNP0lt/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1A9nsMH-pueC1ctPX45TK0BvsN4SNP0lt -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1A9nsMH-pueC1ctPX45TK0BvsN4SNP0lt -->

### Tutorial 5 recording (VoD).mp4

- `video_id`: `1mJKLU3kaRXpzxRJRvnS2rA6GuiRdc_h3`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1mJKLU3kaRXpzxRJRvnS2rA6GuiRdc_h3/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1mJKLU3kaRXpzxRJRvnS2rA6GuiRdc_h3 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1mJKLU3kaRXpzxRJRvnS2rA6GuiRdc_h3 -->

### Tutorial 4 Recording (VoD).mp4

- `video_id`: `1jt1rtcdi5IGI9cQIJQGIq3FShpZZ08GO`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1jt1rtcdi5IGI9cQIJQGIq3FShpZZ08GO/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1jt1rtcdi5IGI9cQIJQGIq3FShpZZ08GO -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1jt1rtcdi5IGI9cQIJQGIq3FShpZZ08GO -->

### Tutorial 2+3 (video) (VoD).mp4

- `video_id`: `16_AyDn-WS0FMEyw8_1kDBf9C11w9ka5c`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/16_AyDn-WS0FMEyw8_1kDBf9C11w9ka5c/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 16_AyDn-WS0FMEyw8_1kDBf9C11w9ka5c -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 16_AyDn-WS0FMEyw8_1kDBf9C11w9ka5c -->

### Lecture 1-a (VoD).mp4

- `video_id`: `1_Pf5aSqDw5iLJjoeWy6mb30ugdSeQOL0`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1_Pf5aSqDw5iLJjoeWy6mb30ugdSeQOL0/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1_Pf5aSqDw5iLJjoeWy6mb30ugdSeQOL0 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1_Pf5aSqDw5iLJjoeWy6mb30ugdSeQOL0 -->

### Lecture 1b (VoD).mp4

- `video_id`: `12qhg3X68sooGdCDaCpPz6fvUhelvRSpO`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/12qhg3X68sooGdCDaCpPz6fvUhelvRSpO/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 12qhg3X68sooGdCDaCpPz6fvUhelvRSpO -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 12qhg3X68sooGdCDaCpPz6fvUhelvRSpO -->

### Lecture 3 Recording (VoD).mp4

- `video_id`: `1Hyca5oXMYhPjvr8N3K19AwxnuAG4CQtl`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Hyca5oXMYhPjvr8N3K19AwxnuAG4CQtl/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Hyca5oXMYhPjvr8N3K19AwxnuAG4CQtl -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Hyca5oXMYhPjvr8N3K19AwxnuAG4CQtl -->

## Digital Logic Design (DLD)

Mixed lecture and tutorial recordings for Digital Logic Design.

### Lecture 11- Video [Ghantous] (VoD).mp4

- `video_id`: `1g2mPRmvnyxSDCSdx_2GWBkUWHYYcfKm5`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1g2mPRmvnyxSDCSdx_2GWBkUWHYYcfKm5/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1g2mPRmvnyxSDCSdx_2GWBkUWHYYcfKm5 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1g2mPRmvnyxSDCSdx_2GWBkUWHYYcfKm5 -->

### Video - Tutorial CPU 2 (VoD).mp4

- `video_id`: `1YV8PU7UGtZwPE_w4U9C97tNfHpnv7a8F`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1YV8PU7UGtZwPE_w4U9C97tNfHpnv7a8F/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1YV8PU7UGtZwPE_w4U9C97tNfHpnv7a8F -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1YV8PU7UGtZwPE_w4U9C97tNfHpnv7a8F -->

### Lecture 10 - Video [Ghantous] (VoD).mp4

- `video_id`: `19udiXeclCcsytNvdhE6wG9lRh-Js0cLW`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/19udiXeclCcsytNvdhE6wG9lRh-Js0cLW/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 19udiXeclCcsytNvdhE6wG9lRh-Js0cLW -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 19udiXeclCcsytNvdhE6wG9lRh-Js0cLW -->

### CPU 1 Recording (Dr. Nada) (VoD).mp4

- `video_id`: `1Fz__3CbLJiLXbeV7jy85SJnQJSgJbio5`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Fz__3CbLJiLXbeV7jy85SJnQJSgJbio5/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Fz__3CbLJiLXbeV7jy85SJnQJSgJbio5 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Fz__3CbLJiLXbeV7jy85SJnQJSgJbio5 -->

### CPU 2 recording (Dr. Nada) (VoD).mp4

- `video_id`: `1q48icZwuEka2TXcgOiDFEr4FEFhwVMis`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1q48icZwuEka2TXcgOiDFEr4FEFhwVMis/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1q48icZwuEka2TXcgOiDFEr4FEFhwVMis -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1q48icZwuEka2TXcgOiDFEr4FEFhwVMis -->

### Video - Tutorial CPU 1 (VoD).mp4

- `video_id`: `17sXe9g4IKO8cGyx4FHm49iJyzjFP73_U`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/17sXe9g4IKO8cGyx4FHm49iJyzjFP73_U/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 17sXe9g4IKO8cGyx4FHm49iJyzjFP73_U -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 17sXe9g4IKO8cGyx4FHm49iJyzjFP73_U -->

### Lecture 9 - Video [Ghantous] (VoD).mp4

- `video_id`: `1BqfxJvebtZ2JURHFC1mirBJ5tDxqiEPH`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1BqfxJvebtZ2JURHFC1mirBJ5tDxqiEPH/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1BqfxJvebtZ2JURHFC1mirBJ5tDxqiEPH -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1BqfxJvebtZ2JURHFC1mirBJ5tDxqiEPH -->

### Video - Tutorial 9 (VoD).mp4

- `video_id`: `1p0aUfRGZscN9KtR3qgrftZQVw5o97B1k`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1p0aUfRGZscN9KtR3qgrftZQVw5o97B1k/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1p0aUfRGZscN9KtR3qgrftZQVw5o97B1k -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1p0aUfRGZscN9KtR3qgrftZQVw5o97B1k -->

### Video - Tutorial 9 - part 2 (VoD).mp4

- `video_id`: `100ZM9T08iyfhUJV5k0QB0aatDC6pEDsk`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/100ZM9T08iyfhUJV5k0QB0aatDC6pEDsk/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 100ZM9T08iyfhUJV5k0QB0aatDC6pEDsk -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 100ZM9T08iyfhUJV5k0QB0aatDC6pEDsk -->

### Lecture 8-Video [Ghantous] (VoD).mp4

- `video_id`: `1keszOBF8strxGdfpAM6iSGL-TQqPQTPc`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1keszOBF8strxGdfpAM6iSGL-TQqPQTPc/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1keszOBF8strxGdfpAM6iSGL-TQqPQTPc -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1keszOBF8strxGdfpAM6iSGL-TQqPQTPc -->

### Assembly 1 Recording - Dr. Nada (VoD).mp4

- `video_id`: `1sHX3ueyBoFqL7gU8bFOw_6fsoY6DXwXj`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1sHX3ueyBoFqL7gU8bFOw_6fsoY6DXwXj/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1sHX3ueyBoFqL7gU8bFOw_6fsoY6DXwXj -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1sHX3ueyBoFqL7gU8bFOw_6fsoY6DXwXj -->

### Assembly 2 Recording - Dr. Nada (VoD).mp4

- `video_id`: `1brFKsCfnjUe52M6xtO0xYSINUlyjyayZ`
- `content_type`: `other`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1brFKsCfnjUe52M6xtO0xYSINUlyjyayZ/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1brFKsCfnjUe52M6xtO0xYSINUlyjyayZ -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1brFKsCfnjUe52M6xtO0xYSINUlyjyayZ -->

### Video- Tutorial 8 (VoD).mp4

- `video_id`: `1VGoGJGQDZvw1tTtGvDgq_I81p_Zr8JqJ`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1VGoGJGQDZvw1tTtGvDgq_I81p_Zr8JqJ/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1VGoGJGQDZvw1tTtGvDgq_I81p_Zr8JqJ -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1VGoGJGQDZvw1tTtGvDgq_I81p_Zr8JqJ -->

### Lecture 7 - Part 1 (IO) [Ghantous] (VoD).mp4

- `video_id`: `1tx1ZawanTyXpCbzISRFRGlQV_QcgKu5B`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1tx1ZawanTyXpCbzISRFRGlQV_QcgKu5B/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1tx1ZawanTyXpCbzISRFRGlQV_QcgKu5B -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1tx1ZawanTyXpCbzISRFRGlQV_QcgKu5B -->

### IO Lecture Recording - Dr. Nada (VoD).mp4

- `video_id`: `1-DFtzCGdXQuVrX-VqVKovAFlXq-hdSxV`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1-DFtzCGdXQuVrX-VqVKovAFlXq-hdSxV/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1-DFtzCGdXQuVrX-VqVKovAFlXq-hdSxV -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1-DFtzCGdXQuVrX-VqVKovAFlXq-hdSxV -->

### Lecture 7 - Part 2 (Control unit) [Ghantous] (VoD).mp4

- `video_id`: `1dA_474HLKP_LNCkZmnSDs56hSCfHbDwP`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1dA_474HLKP_LNCkZmnSDs56hSCfHbDwP/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1dA_474HLKP_LNCkZmnSDs56hSCfHbDwP -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1dA_474HLKP_LNCkZmnSDs56hSCfHbDwP -->

### Video- Tutorial 7 (VoD).mp4

- `video_id`: `1vc5TZ435Zg2YlNjEMW2rRacMv5vyfqYZ`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1vc5TZ435Zg2YlNjEMW2rRacMv5vyfqYZ/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1vc5TZ435Zg2YlNjEMW2rRacMv5vyfqYZ -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1vc5TZ435Zg2YlNjEMW2rRacMv5vyfqYZ -->

### Lecture 6-Video (Dr. Ghantous) (VoD).mp4

- `video_id`: `1zhFaX_Co9_7Xpiak2Go0mwjiMvuh_AmP`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1zhFaX_Co9_7Xpiak2Go0mwjiMvuh_AmP/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1zhFaX_Co9_7Xpiak2Go0mwjiMvuh_AmP -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1zhFaX_Co9_7Xpiak2Go0mwjiMvuh_AmP -->

### Lecture Recording Dr. Nada (VoD).mp4

- `video_id`: `1rvZ0HWWs-ZzadTCP2ZvSMaLH_IOAtV-D`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1rvZ0HWWs-ZzadTCP2ZvSMaLH_IOAtV-D/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1rvZ0HWWs-ZzadTCP2ZvSMaLH_IOAtV-D -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1rvZ0HWWs-ZzadTCP2ZvSMaLH_IOAtV-D -->

### VIDEO - Tutorial 6 (VoD).mp4

- `video_id`: `1Vh8AlSK7PYe2i9hwYH5b4VEqLkP-A-wS`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Vh8AlSK7PYe2i9hwYH5b4VEqLkP-A-wS/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Vh8AlSK7PYe2i9hwYH5b4VEqLkP-A-wS -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Vh8AlSK7PYe2i9hwYH5b4VEqLkP-A-wS -->

### Lecture 5 Recording - Dr. Nada (VoD).mp4

- `video_id`: `1_4iwJRUUqC4k8MHx1g4yu8PS90_JnM4y`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1_4iwJRUUqC4k8MHx1g4yu8PS90_JnM4y/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1_4iwJRUUqC4k8MHx1g4yu8PS90_JnM4y -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1_4iwJRUUqC4k8MHx1g4yu8PS90_JnM4y -->

### VIDEO-Lecture-5 (Dr. Milad) (VoD).mp4

- `video_id`: `1-r2JOp1pTjSnDSzYtgqHiONCle67DAnH`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1-r2JOp1pTjSnDSzYtgqHiONCle67DAnH/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1-r2JOp1pTjSnDSzYtgqHiONCle67DAnH -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1-r2JOp1pTjSnDSzYtgqHiONCle67DAnH -->

### VIDEO - Tutorial 5 (VoD).mp4

- `video_id`: `1aUaNp4ShBLIB_RqJrLrf_54MwchMSqMb`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1aUaNp4ShBLIB_RqJrLrf_54MwchMSqMb/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1aUaNp4ShBLIB_RqJrLrf_54MwchMSqMb -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1aUaNp4ShBLIB_RqJrLrf_54MwchMSqMb -->

### VIDEO - Tutorial 4 (VoD).mp4

- `video_id`: `1ysatM8l_i5cHH3_6fXy5kAOuAzltH2hh`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1ysatM8l_i5cHH3_6fXy5kAOuAzltH2hh/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1ysatM8l_i5cHH3_6fXy5kAOuAzltH2hh -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1ysatM8l_i5cHH3_6fXy5kAOuAzltH2hh -->

### Lecture 4 Recording - Dr. Nada (VoD).mp4

- `video_id`: `1YJRenDhZR9LheHNTAgpYwzymQLn5sXz3`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1YJRenDhZR9LheHNTAgpYwzymQLn5sXz3/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1YJRenDhZR9LheHNTAgpYwzymQLn5sXz3 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1YJRenDhZR9LheHNTAgpYwzymQLn5sXz3 -->

### Lecture Recording (Dr. Nada) (VoD).mp4

- `video_id`: `1-h12KKz0TdrcYTGi1WqxWeUu7idR3Evb`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1-h12KKz0TdrcYTGi1WqxWeUu7idR3Evb/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1-h12KKz0TdrcYTGi1WqxWeUu7idR3Evb -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1-h12KKz0TdrcYTGi1WqxWeUu7idR3Evb -->

### VIDEO - Tutorial 3 (VoD).mp4

- `video_id`: `1A-sGFfac4T7MlpEdF3o8CltQ9kqCFp5F`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1A-sGFfac4T7MlpEdF3o8CltQ9kqCFp5F/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1A-sGFfac4T7MlpEdF3o8CltQ9kqCFp5F -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1A-sGFfac4T7MlpEdF3o8CltQ9kqCFp5F -->

### Lecture 2 - Recording (VoD).mp4

- `video_id`: `1Y3Vw_0I5T98CLwSJFZWgPxUofh7Co9OO`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Y3Vw_0I5T98CLwSJFZWgPxUofh7Co9OO/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Y3Vw_0I5T98CLwSJFZWgPxUofh7Co9OO -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Y3Vw_0I5T98CLwSJFZWgPxUofh7Co9OO -->

### VIDEO - Tutorial 2 (VoD).mp4

- `video_id`: `15StD3cF8cmBYMUEvPfAmQCn5HOEQu-OM`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/15StD3cF8cmBYMUEvPfAmQCn5HOEQu-OM/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 15StD3cF8cmBYMUEvPfAmQCn5HOEQu-OM -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 15StD3cF8cmBYMUEvPfAmQCn5HOEQu-OM -->

### Lecture 4-Video (Dr. Milad) (VoD).mp4

- `video_id`: `1P7bapChLbSH289zql3sE1dmGpOLSBW9w`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1P7bapChLbSH289zql3sE1dmGpOLSBW9w/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1P7bapChLbSH289zql3sE1dmGpOLSBW9w -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1P7bapChLbSH289zql3sE1dmGpOLSBW9w -->

### Lecture 2 - VIDEO (Dr. Milad) (VoD).mp4

- `video_id`: `1E07DySAN5ZSK3wWUWyVXQ2F9CRCy0grP`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1E07DySAN5ZSK3wWUWyVXQ2F9CRCy0grP/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1E07DySAN5ZSK3wWUWyVXQ2F9CRCy0grP -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1E07DySAN5ZSK3wWUWyVXQ2F9CRCy0grP -->

### VIDEO - Lecture 1 (VoD).mp4

- `video_id`: `1kYfURgI6hNp1kfatyb4d4vEc9FU8OEz6`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1kYfURgI6hNp1kfatyb4d4vEc9FU8OEz6/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1kYfURgI6hNp1kfatyb4d4vEc9FU8OEz6 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1kYfURgI6hNp1kfatyb4d4vEc9FU8OEz6 -->

### VIDEO - Lecture 0 (VoD).mp4

- `video_id`: `1wmfLloow0MH1dBcPkzX3v9YW_2PB4UDu`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1wmfLloow0MH1dBcPkzX3v9YW_2PB4UDu/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1wmfLloow0MH1dBcPkzX3v9YW_2PB4UDu -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1wmfLloow0MH1dBcPkzX3v9YW_2PB4UDu -->

### Lecture 3-Video (Dr. Milad) (VoD).mp4

- `video_id`: `1NrOoisR0hPE1K85c_Y2O9BfNuAzvPivc`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1NrOoisR0hPE1K85c_Y2O9BfNuAzvPivc/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1NrOoisR0hPE1K85c_Y2O9BfNuAzvPivc -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1NrOoisR0hPE1K85c_Y2O9BfNuAzvPivc -->

## Math 4 (MATH4)

Mixed lecture, tutorial, and revision recordings for Math 4.

### Final Revision - Part 1 (VoD).mp4

- `video_id`: `1WNYtj63ViAPCdOGkmJpGO3KTaK46rMou`
- `content_type`: `revision`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1WNYtj63ViAPCdOGkmJpGO3KTaK46rMou/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1WNYtj63ViAPCdOGkmJpGO3KTaK46rMou -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1WNYtj63ViAPCdOGkmJpGO3KTaK46rMou -->

### Final Revision - Part 2 (VoD).mp4

- `video_id`: `1PwdN4UoyGtqlqjc1Nu4llvLj1cw-585P`
- `content_type`: `revision`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1PwdN4UoyGtqlqjc1Nu4llvLj1cw-585P/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1PwdN4UoyGtqlqjc1Nu4llvLj1cw-585P -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1PwdN4UoyGtqlqjc1Nu4llvLj1cw-585P -->

### Final Revision - Part 3 (VoD).mp4

- `video_id`: `1tprUNMA-nX61BujEOI3F66bDDp4987gy`
- `content_type`: `revision`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1tprUNMA-nX61BujEOI3F66bDDp4987gy/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1tprUNMA-nX61BujEOI3F66bDDp4987gy -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1tprUNMA-nX61BujEOI3F66bDDp4987gy -->

### Tutorial 10 (ws 10) (VoD).mp4

- `video_id`: `1RQvEs1Zunq9c91YXIZwr_OTaZKoNQNJl`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1RQvEs1Zunq9c91YXIZwr_OTaZKoNQNJl/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1RQvEs1Zunq9c91YXIZwr_OTaZKoNQNJl -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1RQvEs1Zunq9c91YXIZwr_OTaZKoNQNJl -->

### Lecture 12 (VoD).mp4

- `video_id`: `1w6VZ68FVT0s-JuJqN51bpigQUJT779uw`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1w6VZ68FVT0s-JuJqN51bpigQUJT779uw/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1w6VZ68FVT0s-JuJqN51bpigQUJT779uw -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1w6VZ68FVT0s-JuJqN51bpigQUJT779uw -->

### Tutorial 11 (ws 11) (VoD).mp4

- `video_id`: `1gTNhi4OWe7GBjouAMaGQ6vsJMzOGfGKY`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1gTNhi4OWe7GBjouAMaGQ6vsJMzOGfGKY/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1gTNhi4OWe7GBjouAMaGQ6vsJMzOGfGKY -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1gTNhi4OWe7GBjouAMaGQ6vsJMzOGfGKY -->

### Lecture 10 (VoD).mp4

- `video_id`: `1BYpJgJNiQnbRMJEr5e2_JFQqQwXcL5gM`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1BYpJgJNiQnbRMJEr5e2_JFQqQwXcL5gM/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1BYpJgJNiQnbRMJEr5e2_JFQqQwXcL5gM -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1BYpJgJNiQnbRMJEr5e2_JFQqQwXcL5gM -->

### Lecture 9 (VoD).mp4

- `video_id`: `1XmDK6HSB4wA0KjTuoQAsmOopBOAbMOMB`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1XmDK6HSB4wA0KjTuoQAsmOopBOAbMOMB/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1XmDK6HSB4wA0KjTuoQAsmOopBOAbMOMB -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1XmDK6HSB4wA0KjTuoQAsmOopBOAbMOMB -->

### Tutorial 8 (ws 8) (VoD).mp4

- `video_id`: `1csZgCnqDQbsURVYtU5USdOFP52zMXeGx`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1csZgCnqDQbsURVYtU5USdOFP52zMXeGx/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1csZgCnqDQbsURVYtU5USdOFP52zMXeGx -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1csZgCnqDQbsURVYtU5USdOFP52zMXeGx -->

### Tutorial 9 (ws 9) (VoD).mp4

- `video_id`: `1eCslMn1S4KBLCCedHokajxDdXTzSmPLK`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1eCslMn1S4KBLCCedHokajxDdXTzSmPLK/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1eCslMn1S4KBLCCedHokajxDdXTzSmPLK -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1eCslMn1S4KBLCCedHokajxDdXTzSmPLK -->

### Lecture (7-II) + 8 (VoD).mp4

- `video_id`: `17qiJxea5vTK0rzV4EoSV4JjvOSWCdUha`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/17qiJxea5vTK0rzV4EoSV4JjvOSWCdUha/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 17qiJxea5vTK0rzV4EoSV4JjvOSWCdUha -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 17qiJxea5vTK0rzV4EoSV4JjvOSWCdUha -->

### Tutorial 7 (ws 7) (VoD).mp4

- `video_id`: `1syhS1eMrXAxWwqQQ26xX8NNBQUKw8Bus`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1syhS1eMrXAxWwqQQ26xX8NNBQUKw8Bus/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1syhS1eMrXAxWwqQQ26xX8NNBQUKw8Bus -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1syhS1eMrXAxWwqQQ26xX8NNBQUKw8Bus -->

### Tutorial 6 (ws 6) (VoD).mp4

- `video_id`: `1UQYYvraW-mBepDQFP40kO16P49Fcx3fj`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1UQYYvraW-mBepDQFP40kO16P49Fcx3fj/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1UQYYvraW-mBepDQFP40kO16P49Fcx3fj -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1UQYYvraW-mBepDQFP40kO16P49Fcx3fj -->

### Midterm Revision (VoD).mp4

- `video_id`: `1SyiyN2opvnm4F35xfHx8I0lHkfw1_jVB`
- `content_type`: `revision`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1SyiyN2opvnm4F35xfHx8I0lHkfw1_jVB/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1SyiyN2opvnm4F35xfHx8I0lHkfw1_jVB -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1SyiyN2opvnm4F35xfHx8I0lHkfw1_jVB -->

### Lecture 7 (VoD).mp4

- `video_id`: `1jt1koH8Eg18dQQCWnrIAvaXfWMyFiYpD`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1jt1koH8Eg18dQQCWnrIAvaXfWMyFiYpD/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1jt1koH8Eg18dQQCWnrIAvaXfWMyFiYpD -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1jt1koH8Eg18dQQCWnrIAvaXfWMyFiYpD -->

### Lecture 6 (VoD).mp4

- `video_id`: `1kxP3vY89xGp3kOaPBX4_6RJIo2RC0DkK`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1kxP3vY89xGp3kOaPBX4_6RJIo2RC0DkK/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1kxP3vY89xGp3kOaPBX4_6RJIo2RC0DkK -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1kxP3vY89xGp3kOaPBX4_6RJIo2RC0DkK -->

### Tutorial 5 (ws 5) (VoD).mp4

- `video_id`: `1LL4hlj6S4L7UEcWr4wBjRAgYTXCg-wwr`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1LL4hlj6S4L7UEcWr4wBjRAgYTXCg-wwr/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1LL4hlj6S4L7UEcWr4wBjRAgYTXCg-wwr -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1LL4hlj6S4L7UEcWr4wBjRAgYTXCg-wwr -->

### Lecture 5 (VoD).mp4

- `video_id`: `1riG22POrOpwgjH3WkjhkelCcATwgTUq5`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1riG22POrOpwgjH3WkjhkelCcATwgTUq5/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1riG22POrOpwgjH3WkjhkelCcATwgTUq5 -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1riG22POrOpwgjH3WkjhkelCcATwgTUq5 -->

### Tutorial 4 (ws 4) (VoD).mp4

- `video_id`: `110_PuSDJRYDABdcsUsyKQSxz_PgxWL_X`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/110_PuSDJRYDABdcsUsyKQSxz_PgxWL_X/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 110_PuSDJRYDABdcsUsyKQSxz_PgxWL_X -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 110_PuSDJRYDABdcsUsyKQSxz_PgxWL_X -->

### Lecture 4 (VoD).mp4

- `video_id`: `1bABEvUHORnEOIliUnEnV7I9Ppuvh38sR`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1bABEvUHORnEOIliUnEnV7I9Ppuvh38sR/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1bABEvUHORnEOIliUnEnV7I9Ppuvh38sR -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1bABEvUHORnEOIliUnEnV7I9Ppuvh38sR -->

### Tutorial 3 (ws 3) Part-1 (VoD).mp4

- `video_id`: `1VJnD6Ot8qF3gW_PAwKvwhL7cC0HyunDc`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1VJnD6Ot8qF3gW_PAwKvwhL7cC0HyunDc/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1VJnD6Ot8qF3gW_PAwKvwhL7cC0HyunDc -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1VJnD6Ot8qF3gW_PAwKvwhL7cC0HyunDc -->

### Tutorial 3 (ws 3) Part-2 (VoD).mp4

- `video_id`: `1Oj0BRPLx4s7Ue22FpaXqRhBWFIm96PpT`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Oj0BRPLx4s7Ue22FpaXqRhBWFIm96PpT/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Oj0BRPLx4s7Ue22FpaXqRhBWFIm96PpT -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Oj0BRPLx4s7Ue22FpaXqRhBWFIm96PpT -->

### Lecture 3 (VoD).mp4

- `video_id`: `1JvxkAJ8yBkJnh-f2SgsLLPKqWIvKT7Ec`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1JvxkAJ8yBkJnh-f2SgsLLPKqWIvKT7Ec/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1JvxkAJ8yBkJnh-f2SgsLLPKqWIvKT7Ec -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1JvxkAJ8yBkJnh-f2SgsLLPKqWIvKT7Ec -->

### Tutorial 2 (ws 2) (VoD).mp4

- `video_id`: `1jlHee1-yobx1F6Ee9gqiyePAIqD9uwGX`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1jlHee1-yobx1F6Ee9gqiyePAIqD9uwGX/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1jlHee1-yobx1F6Ee9gqiyePAIqD9uwGX -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1jlHee1-yobx1F6Ee9gqiyePAIqD9uwGX -->

### Lecture 2 (VoD).mp4

- `video_id`: `1Azdonq0MkfmZeytJLF3TGa9Wj8yvNT4M`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1Azdonq0MkfmZeytJLF3TGa9Wj8yvNT4M/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1Azdonq0MkfmZeytJLF3TGa9Wj8yvNT4M -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1Azdonq0MkfmZeytJLF3TGa9Wj8yvNT4M -->

### Tutorial 1 (ws 1) (VoD).mp4

- `video_id`: `1tS_5GRBpCkcUZpsuPhS8x01L2R0wZO_K`
- `content_type`: `tutorial`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1tS_5GRBpCkcUZpsuPhS8x01L2R0wZO_K/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1tS_5GRBpCkcUZpsuPhS8x01L2R0wZO_K -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1tS_5GRBpCkcUZpsuPhS8x01L2R0wZO_K -->

### Lecture 1 (VoD).mp4

- `video_id`: `1K1SCYZnMqfYQpjyR9KkxtOvgOn8BVk-Y`
- `content_type`: `lecture`
- `source`: [Open Google Drive video](https://drive.google.com/file/d/1K1SCYZnMqfYQpjyR9KkxtOvgOn8BVk-Y/view?usp=drivesdk)

#### Transcript context

<!-- TRANSCRIPT START: 1K1SCYZnMqfYQpjyR9KkxtOvgOn8BVk-Y -->
[PASTE AI TRANSCRIPT OR DETAILED SUMMARY HERE]
<!-- TRANSCRIPT END: 1K1SCYZnMqfYQpjyR9KkxtOvgOn8BVk-Y -->
