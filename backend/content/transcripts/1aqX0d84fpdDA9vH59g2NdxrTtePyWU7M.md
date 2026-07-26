# Prof. Slim's Live Lecture 4 Stacks of Object (VoD).mp4

- Course: Data Structures and Algorithms
- Drive file ID: `1aqX0d84fpdDA9vH59g2NdxrTtePyWU7M`
- Type: lecture
- Video: https://drive.google.com/file/d/1aqX0d84fpdDA9vH59g2NdxrTtePyWU7M/view?usp=drivesdk

## Transcript or detailed summary

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
