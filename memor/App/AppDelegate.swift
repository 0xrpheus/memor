import AVFoundation
import MediaPlayer
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    private var audioEngine = AVAudioEngine()
    private var silenceNode: AVAudioSourceNode?
    private var notificationsStarted = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        registerAudioObservers()
        keepMusicNotificationsAlive()
        // Begin/end must be balanced, so generation is started exactly once here.
        MPMusicPlayerController.systemMusicPlayer.beginGeneratingPlaybackNotifications()
        notificationsStarted = true
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        keepMusicNotificationsAlive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        keepMusicNotificationsAlive()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        audioEngine.stop()
        if notificationsStarted {
            MPMusicPlayerController.systemMusicPlayer.endGeneratingPlaybackNotifications()
            notificationsStarted = false
        }
    }

    // MARK: - Keepalive

    /// The app is not the audio source (Apple Music is) and iOS offers no API to wake a
    /// suspended app on system-player track changes, so the only way to keep receiving
    /// playback notifications in the background is to stay alive via the `audio` background
    /// mode. This plays perpetual silence to do so. It is an accepted, documented tradeoff
    /// (battery / App Review) that is required for background scrobbling to work.
    private func keepMusicNotificationsAlive() {
        configureAudioSession()
        startSilentKeepaliveAudioIfNeeded()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            assertionFailure("Failed to activate audio session: \(error.localizedDescription)")
        }
    }

    private func startSilentKeepaliveAudioIfNeeded() {
        guard !audioEngine.isRunning else { return }

        if silenceNode == nil {
            let format = audioEngine.outputNode.inputFormat(forBus: 0)
            let node = AVAudioSourceNode(format: format) { _, _, _, audioBufferList -> OSStatus in
                for buffer in UnsafeMutableAudioBufferListPointer(audioBufferList) {
                    if let data = buffer.mData {
                        memset(data, 0, Int(buffer.mDataByteSize))
                    }
                }
                return noErr
            }
            silenceNode = node
            audioEngine.attach(node)
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: format)
        }

        do {
            try audioEngine.start()
        } catch {
            assertionFailure("Failed to start silent audio keepalive: \(error.localizedDescription)")
        }
    }

    // MARK: - Resilience

    /// Without these observers the keepalive silently dies on the first interruption
    /// (phone call, other exclusive audio) or media-services reset, and the app is then
    /// suspended — so scrobbling stops mid-session. Handling them is what makes background
    /// scrobbling survive long idle windows.
    private func registerAudioObservers() {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(handleInterruption(_:)),
                           name: AVAudioSession.interruptionNotification,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(handleMediaServicesReset),
                           name: AVAudioSession.mediaServicesWereResetNotification,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(handleEngineConfigurationChange),
                           name: .AVAudioEngineConfigurationChange,
                           object: audioEngine)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }

        switch type {
        case .ended:
            // Resume the keepalive after the interrupting audio ends.
            keepMusicNotificationsAlive()
        default:
            break
        }
    }

    @objc private func handleMediaServicesReset() {
        // After a media-services reset all audio objects are invalid and must be rebuilt.
        silenceNode = nil
        audioEngine = AVAudioEngine()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleEngineConfigurationChange),
                                               name: .AVAudioEngineConfigurationChange,
                                               object: audioEngine)
        keepMusicNotificationsAlive()
    }

    @objc private func handleEngineConfigurationChange() {
        // The engine stops itself on a configuration change (e.g. route change); restart it.
        keepMusicNotificationsAlive()
    }
}
