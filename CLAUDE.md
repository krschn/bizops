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

## Design System

### Philosophy

Minimalist and modern. The UI uses restraint — whitespace does the heavy lifting. Color is used sparingly; Navy Blue is the single accent that signals action and brand identity. Everything else is black, white, and neutral greys.

### Color Palette

Defined in `lib/core/theme/app_colors.dart` as `Color` constants. No other color values may be introduced — all UI must reference these tokens.

```
// Backgrounds
background     = #FFFFFF   (pure white — scaffold, page backgrounds)
surface        = #F8F8FA   (off-white — cards, input fills, bottom nav)
surfaceVariant = #F0F0F5   (slightly deeper — dividers, inactive areas)

// Navy Blue — primary accent (used sparingly)
primary        = #1B2A4A   (deep navy — primary buttons, active nav, links)
primaryLight   = #2E4270   (medium navy — pressed/hover states on navy elements)
primaryMuted   = #E8EBF2   (navy tint — selected chip background, subtle highlights)

// Text
textPrimary    = #0D0D0D   (near-black — headings, body text)
textSecondary  = #6B7280   (grey — subtitles, hints, metadata)
textDisabled   = #B0B7C3   (light grey — disabled labels, placeholders)
textOnPrimary  = #FFFFFF   (white — text/icons on navy backgrounds)

// Borders & Dividers
divider        = #E5E7EB   (light grey — list dividers, card outlines)
border         = #D1D5DB   (mid grey — input borders, unfocused fields)

// Semantic
error          = #C0392B   (red — errors, destructive actions)
errorSurface   = #FDEDED   (light red — error backgrounds)
success        = #1A7A4A   (dark green — success states)
warning        = #B45309   (amber-brown — warnings)

// Trash / Soft-delete
trashAccent    = #9CA3AF   (medium grey — deleted/muted state indicators)
```

### Typography

Use the system font stack (no custom font packages). Flutter's default `Typography.blackMountainView` base is sufficient.

| Role | Style |
|---|---|
| Page title (AppBar) | `titleLarge` — 20sp, weight 600, `textPrimary` |
| Section heading | `titleMedium` — 16sp, weight 600, `textPrimary` |
| Body / list primary | `bodyMedium` — 14sp, weight 400, `textPrimary` |
| Subtitle / metadata | `bodySmall` — 12sp, weight 400, `textSecondary` |
| Button label | `labelLarge` — 14sp, weight 600, `textOnPrimary` or `primary` |
| Caption / hint | `labelSmall` — 11sp, weight 400, `textDisabled` |

No italic. No decorative weights. Line height: 1.4–1.5× default.

### Component Rules

**AppBar**
- Background: `background` (white).
- Elevation: 0. A single `divider`-colored bottom border (1px) separates it from content.
- Title: `textPrimary`, weight 600.
- Icons/actions: `textPrimary`.

**Bottom Navigation Bar**
- Background: `surface`.
- Selected item: `primary` (navy) icon + label.
- Unselected item: `textDisabled` icon, no label.
- Top border: 1px `divider`. No elevation shadow.

**Buttons**
- Primary (`PrimaryButton`): filled `primary` navy background, white label, 12px border radius, 48px height minimum, no elevation.
- Destructive action (e.g. "Delete" in dialogs): `error` color text, no fill (text button style).
- Secondary / ghost: transparent background, `primary` navy text, `border`-colored outline.

**Cards**
- Background: `surface`. Border: 1px `divider`. Border radius: 12px. Elevation: 0.
- Use `Card` with `clipBehavior: Clip.antiAlias`.

**Input Fields**
- Fill: `surface`. Border: 1px `border`, radius 8px.
- Focused border: 1.5px `primary` navy.
- Error border: 1px `error`.
- Label above field (via `LabeledField`), not floating inside.

**List Tiles**
- No default `ListTile` dividers — use explicit `Divider(color: divider, height: 1)` between items.
- Leading icons: `textSecondary`. Trailing action icons: `textSecondary`.

**Chips (period selector)**
- Selected: `primary` fill, `textOnPrimary` label.
- Unselected: `primaryMuted` fill, `primary` label.

**Dialogs**
- Background: `background`. Border radius: 16px.
- Title: `textPrimary` weight 600. Body: `textSecondary`.
- Confirm/destructive action: `error` text. Cancel: `textSecondary` text.

**Trash / deleted states**
- Text: `trashAccent` (strike-through optional).
- Background: `surfaceVariant`.
- Restore icon: `primary` navy. Permanent delete icon: `error`.

**Segmented Button (report period tabs)**
- Selected segment: `primary` fill, `textOnPrimary` label.
- Unselected: `surface` fill, `textSecondary` label.
- Border: `border` color.

### Spacing & Layout

- Base unit: 8px. All padding/margin values are multiples of 8 (8, 16, 24, 32).
- Page horizontal padding: 16px.
- Card internal padding: 16px.
- Between list items: 0px gap (rely on dividers) or 8px gap (card lists).
- FAB: `primary` navy background, white icon, no label text.

### What NOT to do

- Do not introduce additional colors outside the palette above.
- Do not use `Colors.blue`, `Colors.grey[300]`, or any Material color swatch directly — always reference `AppColors` tokens.
- Do not use gradients, shadows (elevation > 0 on cards/buttons), or blur effects.
- Do not use rounded corners larger than 16px on any component.
- Do not use animations beyond Flutter's default route transitions.
