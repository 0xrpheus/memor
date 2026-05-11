# memor 

A free native iOS scrobbler for Apple Music. It scrobbles even when the song isn't added to your library.

---

## Features

- Automatic scrobbling from Apple Music system playback
- Now Playing updates sent to Last.fm in real time
- Offline queue (scrobbles persist across launches and retry on next open)
- Manual retry for failed scrobbles
- Session key stored in Keychain; username in UserDefaults

---

## Requirements

- Xcode 26 or later
- iOS 16.0+ deployment target
- An Apple Developer account (free tier works for device testing)
- A Last.fm API account

---

## Getting a Last.fm API Key

1. Go to [https://www.last.fm/api/account/create](https://www.last.fm/api/account/create) and sign in with your Last.fm account.
2. Fill in the form:
   - **Application name** — anything you like, e.g. `memor`
   - **Application description** — brief description
   - **Callback URL** — leave blank (the app uses the web auth flow without a callback scheme)
   - **Homepage URL** — optional
3. Submit. You'll be shown your **API key** and **Shared secret** immediately. Copy both — the secret is not shown again on the same page (you can retrieve it later from your [API accounts list](https://www.last.fm/api/accounts)).

---

## Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/0xrpheus/memor.git
   cd memor 
   ```

2. Copy the secrets template:

   ```bash
   cp memor/Resources/Secrets.example.swift memor/Resources/Secrets.swift
   ```

3. Open `Secrets.swift` and fill in your credentials:

   ```swift
   enum Secrets {
       static let lastFMApiKey = "your_api_key_here"
       static let lastFMApiSecret = "your_shared_secret_here"
   }
   ```

   `Secrets.swift` is listed in `.gitignore` and will not be committed.

4. Open `memor.xcodeproj` in Xcode.

5. Select your development team in the project's **Signing & Capabilities** tab.

6. Build and run your device (simulator will have no Apple Music library, so the Now Playing screen will stay empty).

---

## How It Works

`NowPlayingMonitor` subscribes to `MPMusicPlayerController.systemMusicPlayer` notifications. When a track starts playing it:

- Sends a `track.updateNowPlaying` call to Last.fm
- Schedules a timer for the scrobble threshold (`max(30s, min(duration / 2, 240s))`)
- Accumulates elapsed play time, pausing the clock when playback pauses

When the threshold is reached the track is handed to `ScrobbleQueue`, which persists it to disk and attempts `track.scrobble`. On failure the record is moved to a failed bucket and can be retried manually from the History tab.

---

## Project Structure

```
memor/
├── App/
│   ├── AppDelegate.swift         # Audio session + MPMusicPlayer notification bootstrap
│   └── MainTabView.swift
├── Features/
│   ├── Auth/                     # Login flow, ASWebAuthenticationSession, Keychain store
│   ├── History/                  # Scrobble history list with retry
│   ├── NowPlaying/               # Track monitor + now playing UI
│   └── Settings/                 # Account info, stats, links
├── Models/
│   ├── Track.swift               # MPMediaItem wrapper with scrobble logic
│   └── ScrobbleRecord.swift      # Codable record with pending/submitted/failed status
├── Resources/
│   ├── Secrets.example.swift     # Template — copy to Secrets.swift
│   └── Secrets.swift             # Gitignored — your actual credentials go here
└── Services/
    ├── LastFMClient.swift         # API client: auth, now playing, scrobble
    └── ScrobbleQueue.swift        # Persistent queue with flush + retry logic
```

---

## License

MIT. See [LICENSE](LICENSE).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
