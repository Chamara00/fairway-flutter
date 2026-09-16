# Fairway

A small golf-equipment marketplace built with Flutter, backed by the
[DummyJSON](https://dummyjson.com/products) API. Browse listings, view a
listing, and post a new one.

**[Screen recording](https://drive.google.com/drive/folders/1ihWyfC_hxRTm9zATK5cWv-TFt7XqDHOj?usp=drive_link)**

## Setup

Requires Flutter 3.32 or later.

```bash
flutter pub get
flutter run
```

Tested on an Android emulator (Pixel 4, API 35). Run the tests with `flutter test` — 17 tests covering the state layer and the listings screen.

## State management: Riverpod

Chosen for compile-safe dependency injection and `AsyncValue`, which models
loading/data/error as one type — a direct fit for the loading, error, empty and
offline states this app needs everywhere.

Two patterns, used deliberately:

- **`Notifier` with a custom state class** for the listings screen, which
  tracks nine things at once (two separate loading flags, filters, offline
  status, cache timestamp).
- **`AsyncNotifier`/`FutureProvider`** for the detail screen, categories and
  similar items — one request, one result, no custom state class needed.

Providers are also what make the tests cheap: overriding
`listingRepositoryProvider` with a mock swaps the entire data layer in one line.

## Architecture

```
UI (widgets) → state (controllers) → data (repository) → API client / cache
```

Layered architecture with a repository pattern.

`ApiClient` is the only file that touches dio, and the repository maps every
failure to a typed `ApiException` with a user-facing message, so no widget
inspects status codes.

## Trade-offs and unfinished edges

**Search and category cannot combine.** `/products/search` ignores `category`,
and `/products/category/{slug}` ignores `q` — verified against the live API.
Starting a search therefore clears the category and disables the dropdown,
rather than showing a filter that is not applied.

**Sorted search is per-page.** DummyJSON sorts within the returned page, not
across the whole result set.

**Create and delete are simulated.** `POST /products/add` returns a fake id and
does not persist, so new listings are kept in memory for the session. Deletion
is reflected in local state only.

**Offline caching covers the unfiltered first page only.** Caching every filter
combination would need a real database for no benefit here.

**Connectivity is not reachability.** `connectivity_plus` reports connection
type, so it drives the banner only — the cache fallback triggers on an actual
failed request.
