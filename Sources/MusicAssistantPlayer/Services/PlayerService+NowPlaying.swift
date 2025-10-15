// ABOUTME: Now Playing Center integration for media keys and Control Center
// ABOUTME: Observes PlayerService state and updates MPNowPlayingInfoCenter

import Foundation
import MediaPlayer
import Combine

extension PlayerService {
    func setupNowPlayingIntegration() {
        setupRemoteCommandCenter()
        setupNowPlayingObservers()
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.play()
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.pause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.skipNext()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                await self.skipPrevious()
            }
            return .success
        }

        AppLogger.player.info("Now Playing remote commands registered")
    }

    private func setupNowPlayingObservers() {
        // Observe track changes
        $currentTrack
            .sink { [weak self] track in
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        // Observe playback state changes
        $playbackState
            .sink { [weak self] _ in
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        // Observe progress changes (throttle to avoid excessive updates)
        $progress
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        AppLogger.player.info("Now Playing observers registered")
    }

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()

        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progress

            // TODO: Add artwork support when available
            // if let artworkURL = track.artworkURL {
            //     // Fetch and set MPMediaItemArtwork
            // }
        }

        // Set playback rate (0.0 for paused, 1.0 for playing)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = (playbackState == .playing) ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        AppLogger.player.debug("Now Playing info updated: \(self.currentTrack?.title ?? "no track")")
    }
}
