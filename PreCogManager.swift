import Foundation
import AVFoundation
import CoreMotion
import UIKit
import AudioToolbox

class PreCogManager: NSObject, ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    @Published var alertTriggered: Bool = false

    // Thresholds (tuneable)
    private let loudNoiseThreshold: Float = -10.0 // dB
    private let accelThreshold: Double = 2.5      // g-force
    private let gyroThreshold: Double = 5.0       // rad/s

    override init() {
        super.init()
        startAudioMonitoring()
        startMotionMonitoring()
    }

    private func startAudioMonitoring() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let channelDataValue = channelData[Int(buffer.frameLength) - 1]

            let amplitude = abs(channelDataValue)
            let db = 20 * log10(amplitude)
            if db > self.loudNoiseThreshold {
                DispatchQueue.main.async {
                    self.triggerAlert(reason: "Loud Noise")
                }
            }
        }

        try? audioEngine.start()
    }

    private func startMotionMonitoring() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: queue) { data, _ in
                if let acceleration = data?.acceleration {
                    let totalAccel = sqrt(pow(acceleration.x, 2) +
                                         pow(acceleration.y, 2) +
                                         pow(acceleration.z, 2))
                    if totalAccel > self.accelThreshold {
                        DispatchQueue.main.async {
                            self.triggerAlert(reason: "Sudden Movement")
                        }
                    }
                }
            }
        }

        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: queue) { data, _ in
                if let rotation = data?.rotationRate {
                    let magnitude = sqrt(pow(rotation.x, 2) +
                                         pow(rotation.y, 2) +
                                         pow(rotation.z, 2))
                    if magnitude > self.gyroThreshold {
                        DispatchQueue.main.async {
                            self.triggerAlert(reason: "Sudden Rotation")
                        }
                    }
                }
            }
        }
    }

    private func triggerAlert(reason: String) {
        print("⚠️ Pre-Cognitive Alert: \(reason)")
        self.alertTriggered = true
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        if let window = UIApplication.shared.windows.first {
            let flashView = UIView(frame: window.bounds)
            flashView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
            window.addSubview(flashView)
            UIView.animate(withDuration: 0.5, animations: {
                flashView.alpha = 0
            }, completion: { _ in
                flashView.removeFromSuperview()
            })
        }
    }
}
