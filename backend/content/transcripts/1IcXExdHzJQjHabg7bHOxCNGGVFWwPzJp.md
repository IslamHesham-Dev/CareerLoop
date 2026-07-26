# Prof. Slim's Lecture 11 Hashtable - Summer (VoD).mp4

- Course: Data Structures and Algorithms
- Drive file ID: `1IcXExdHzJQjHabg7bHOxCNGGVFWwPzJp`
- Type: lecture
- Video: https://drive.google.com/file/d/1IcXExdHzJQjHabg7bHOxCNGGVFWwPzJp/view?usp=drivesdk

## Transcript or detailed summary

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
