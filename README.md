# Vertical Video Feed

A SwiftUI application that displays a vertically scrolling video feed
with automatic playback, background preloading, and in-memory caching
for a smooth user experience.

------------------------------------------------------------------------

## Features

-   Vertical paging using SwiftUI
-   Automatic playback of the currently visible video
-   Play / Pause support
-   Mute / Unmute support
-   Background video preloading
-   In-memory `AVPlayerItem` caching
-   Automatic cache cleanup
-   Unit tests for business logic and playback manager

------------------------------------------------------------------------

## Architecture

The project follows the **MVVM** architecture.

``` text
Views
   │
   ▼
FeedsViewModel
   │
   ├── VideoServiceProtocol
   └── VideoPlaybackManagerProtocol
```

### Responsibilities

#### Views

-   Display the UI.
-   Forward user interactions to the ViewModel.

#### FeedsViewModel

-   Fetches videos.
-   Handles playback state.
-   Coordinates the service and playback manager.

#### VideoPlaybackManager

-   Owns a single `AVPlayer`.
-   Creates and caches `AVPlayerItem`s.
-   Preloads nearby videos.
-   Cleans cached items outside the preload range.

#### VideoService

-   Loads video metadata from the bundled JSON file.

------------------------------------------------------------------------

## Video Preloading

To provide smooth scrolling, nearby videos are preloaded in the
background.

Example (preload distance = 2):

``` text
Current Index = 5

3   4   [5]   6   7
```

Videos outside the configured preload range are removed from memory to
reduce memory usage.

------------------------------------------------------------------------

## Error Handling & Retry Logic

-   The application includes a resilient retry mechanism designed to handle network fluctuations and playback failures seamlessly.

-   Automatic Error Detection: The VideoPlaybackManager observes AVPlayerItem.status using Combine to monitor for .failed events.

-   State Pipeline: Upon failure, the system transitions to a .failed(error) state, which is propagated to the FeedsViewModel to inform the UI.

-   Retry Mechanism: Users can trigger retryCurrentVideo() to reset the playback engine. This action clears the faulty AVPlayerItem and re-initializes the stream, ensuring a smooth recovery process.

------------------------------------------------------------------------

## Unit Tests

### FeedsViewModel

-   Fetch videos
-   Handle empty responses
-   Play first video
-   Change current video
-   Toggle mute
-   Toggle play/pause

### VideoPlaybackManager

-   Play valid and invalid videos
-   Mute and play state
-   Video preloading
-   Cache refresh
-   Preload task management

------------------------------------------------------------------------

## Requirements

-   Xcode 16 or later
-   iOS 17.0+
-   Swift 6

------------------------------------------------------------------------

## Running the Application

1.  Open the project in Xcode.
2.  Select the **Vertical Video Feed** scheme.
3.  Run on an iOS Simulator or physical device.

------------------------------------------------------------------------

## Running Tests

Run all tests with:

-   **⌘ + U**

or

-   **Product → Test**

------------------------------------------------------------------------

## Project Structure

``` text
Vertical Video Feed
│
├── Views
├── ViewModels
├── Models
├── Services
├── Managers
├── Resources
└── Tests
    ├── FeedsViewModelTests
    └── VideoPlaybackManagerTests
```
