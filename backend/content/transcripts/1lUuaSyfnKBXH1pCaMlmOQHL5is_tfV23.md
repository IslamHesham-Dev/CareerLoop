# Prof. Slim's Lecture 9 Trees I - Summer (VoD).mp4

- Course: Data Structures and Algorithms
- Drive file ID: `1lUuaSyfnKBXH1pCaMlmOQHL5is_tfV23`
- Type: lecture
- Video: https://drive.google.com/file/d/1lUuaSyfnKBXH1pCaMlmOQHL5is_tfV23/view?usp=drivesdk

## Transcript or detailed summary

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
