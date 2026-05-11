# Contributing

Thanks for looking at this. A few things to know before you open a PR.

---

## Getting Set Up

Follow the [setup steps in the README](README.md#setup). You'll need your own Last.fm API key to test anything auth-related.

---

## Submitting a PR

1. Fork the repo and create a branch from `main`.
2. Keep changes focused.
3. If you're fixing a bug, describe what the bug is and how to reproduce it in the PR description.
4. If you're adding a feature, open an issue first to discuss it before writing code.
5. Make sure the project builds cleanly with no warnings before submitting.

---

## Code Style

- Swift 5 / SwiftUI. No UIKit views unless there's no SwiftUI equivalent.
- `@MainActor` on `ObservableObject` subclasses. Async work that leaves the main actor should be explicit about it.
- Errors should surface to the UI where the user can do something about them. Silent failures are acceptable only when truly unrecoverable (e.g. a now-playing update failing mid-session).
- No `print` statements in production paths. Use `assertionFailure` for programmer errors.

---

## Reporting Bugs

Open an issue with:

- iOS version
- Xcode version used to build
- Steps to reproduce
- What you expected vs. what happened

If it's a scrobble correctness issue (wrong track, wrong timestamp, wrong threshold), include the track duration and how long you actually listened.
