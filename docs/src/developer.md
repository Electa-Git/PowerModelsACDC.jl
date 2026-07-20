# Developer documentation

This section provides guidance for developers and contributors to PowerModelsACDC.
It records the design decisions that shape the package, explains the rationale behind them, and describes the conventions to follow when extending the codebase.
It is intended to evolve alongside the project and serve as a shared reference for maintaining a consistent and maintainable implementation.

!!! info "Work in progress"
    This section is a living document.
    It will be expanded and refined as development practices and design decisions are documented.

## Unit tests

- Add test sets to a file named after the unit they test, such as a specific network component or optimization problem.
- Use this hierarchy for organizing test sets:
  1. Network component or optimization problem under test.
  2. Specific feature of the network component, or specific implementation of the optimization problem (if there is more than one).
  3. Network model.
  4. Test case (if there is more than one).
- If a test case is used in multiple related test sets, load it only once before those test sets.
- Always test the termination status. This helps debug failing tests.
