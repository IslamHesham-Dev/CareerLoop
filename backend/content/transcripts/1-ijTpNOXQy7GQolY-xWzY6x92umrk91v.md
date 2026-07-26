# Prof. Slim's Lecture 6 Priority Queues - Live Lecture (VoD) (2).mp4

- Course: Data Structures and Algorithms
- Drive file ID: `1-ijTpNOXQy7GQolY-xWzY6x92umrk91v`
- Type: lecture
- Video: https://drive.google.com/file/d/1-ijTpNOXQy7GQolY-xWzY6x92umrk91v/view?usp=drivesdk

## Transcript or detailed summary

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
