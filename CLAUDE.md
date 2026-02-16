# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**bizops** is a Flutter application targeting Mobile (Android, iOS) and Web platforms. The codebase uses a single adaptive approach — web-only patterns (hover effects, mouse cursors, right-click menus) must **not** be used. All UI must work correctly across all platforms without platform-specific branches in UI code.

## Architecture

The project follows **Clean Architecture** with **BLoC** for state management and **functional programming** idioms. Modularity and abstraction are first-class — all external dependencies are hidden behind interfaces so they can be swapped without touching feature code.

### Layer Structure

```
lib/
├── core/
│   ├── di/            # Dependency injection registration (GetIt + injectable)
│   ├── error/         # Failure types and Either handling
│   ├── network/       # HTTP client abstraction
│   ├── storage/       # Local storage abstraction
│   └── utils/         # Pure utility functions
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/   # Remote and local data source implementations
│       │   ├── models/        # DTOs with JSON serialization
│       │   └── repositories/  # Repository implementations
│       ├── domain/
│       │   ├── entities/      # Immutable business objects (no framework deps)
│       │   ├── repositories/  # Repository interfaces (abstract classes)
│       │   └── usecases/      # Single-responsibility use cases returning Either
│       └── presentation/
│           ├── bloc/          # Events, states, BLoC class
│           ├── pages/         # Full-screen route pages
│           └── widgets/       # Feature-scoped widgets
├── shared/
│   └── widgets/       # App-wide reusable widgets (no feature logic)
└── main.dart          # Entry point; wires DI and runs app
```

### Key Conventions

**Functional programming:**
- Use `Either<Failure, T>` for all fallible operations across layer boundaries — never throw exceptions.
- Use cases return `Either` or `Stream`/`TaskEither`. No void use cases that silently fail.
- Domain entities and BLoC states must be immutable (`freezed` or `equatable`).

**BLoC:**
- One BLoC per feature screen or major logical unit.
- Events are past-tense facts: `UserLoggedIn`, `OrderSubmitted`.
- States are sealed classes: typically `initial`, `loading`, `loaded`, `error`.
- BLoCs depend only on domain use cases — never import from the `data` layer.

**Dependency injection:**
- Abstract interfaces live in `domain/`; concrete implementations in `data/`.
- All wiring happens in `core/di/`. Features never instantiate dependencies directly.

**Cross-platform UI:**
- Do **not** use `kIsWeb`, `Platform.isAndroid`, or similar guards in UI code.
- Use `LayoutBuilder` / `MediaQuery` for responsive layouts.
- No web-only UX patterns (hover states, cursor changes) as primary interactions.

**Repository pattern:**
- Domain defines the interface; data layer implements it.
- Data sources (remote/local) are injected into repository implementations, never accessed directly from BLoC.

## Testing

Tests mirror the `lib/` structure under `test/`. Each layer is tested in isolation:

- **Domain use cases** — pure unit tests; mock the repository interface.
- **BLoC** — use `bloc_test` package; mock use cases.
- **Repository implementations** — mock data sources.
- **Data sources** — mock HTTP client or local DB.
- **Widgets** — use `flutter_test`; provide a mocked BLoC via `MockBloc` from `bloc_test`.

All mocks are generated with `mockito` (or `mocktail`) and kept alongside their test file, not in a shared mocks directory.
