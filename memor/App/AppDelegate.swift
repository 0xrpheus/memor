import AVFoundation
import MediaPlayer
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let audioEngine = AVAudioEngine()
    private var silenceNode: AVAudioSourceNode?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        keepMusicNotificationsAlive()
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
        MPMusicPlayerController.systemMusicPlayer.endGeneratingPlaybackNotifications()
    }

    private func keepMusicNotificationsAlive() {
        configureAudioSession()
        startSilentKeepaliveAudioIfNeeded()
        MPMusicPlayerController.systemMusicPlayer.beginGeneratingPlaybackNotifications()
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
}
