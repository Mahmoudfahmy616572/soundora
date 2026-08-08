# 🎧 Soundora

Soundora is a smart Arabic music experience built with **Flutter** and **Supabase** — maqam-aware playback, synced lyrics, karaoke and a personal listening journey.

## ✨ Key Features
* **Live Synced Lyrics:** Real-time lyric highlighting and auto-scrolling synced with audio timestamps.
* **Interactive Playback:** Seek audio by tapping specific lyric lines.
* **Relational Backend:** Powered by **Supabase (PostgreSQL)** for managing artists, albums, and tracks.
* **Secure Auth:** User authentication and session management via Supabase Auth.
* **State Management:** Clean implementation using the **BLoC/Cubit** pattern for predictable UI states.

## 🛠️ Technical Stack
* **Frontend:** [Flutter](https://flutter.dev) (Dart)
* **Backend:** [Supabase](https://supabase.com) (Database, Auth, Storage)
* **Audio Engine:** `just_audio`
* **Architecture:** Clean Architecture (Data, Domain, & Presentation layers)
