//
//  AudioManager.swift
//  CodingAssignment2021
//
//  Created by Jeff Huang on 1/20/21.
//
import AVFoundation

public class AudioManager {
    
    let audioEngine = AVAudioEngine()
    static let shared = AudioManager()
    
    private init() {
        setupAudioSession()
        setupAudioEngineGraph()
    }
    
    
    // MARK: - Public Methods
    /// Use this to start getting audio data from microphone.
    public func start() {
        startAudioSession()
        startAudioEngine()
    }
    
    /// Use this to stop receiving audio data from microphone.
    public func stop() {
        stopAudioSession()
        audioEngine.stop()
    }
    
    /// This method allows you to listen to the microphone data. Use this to pipe
    /// audio data to the deep learning model.
    public func installTap(tapBlock: @escaping AVAudioNodeTapBlock) {
        removeTap()
        audioEngine.inputNode.installTap(
            onBus: 0,
            bufferSize: 15600,
            format: audioEngine.inputNode.outputFormat(forBus: 0),
            block: tapBlock
        )
    }
    
    public func removeTap() {
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    public func getInputNodeFormat() -> AVAudioFormat {
        return audioEngine.inputNode.outputFormat(forBus: 0)
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() {
        let category: AVAudioSession.Category = .playAndRecord
        let mode: AVAudioSession.Mode = .default
        let options: AVAudioSession.CategoryOptions = [
            .mixWithOthers
        ]
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(category, mode: mode, options: options)
            try session.setPreferredIOBufferDuration(256/16000)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func setupAudioEngineGraph() {
        audioEngine.connect(audioEngine.mainMixerNode,
                            to: audioEngine.outputNode,
                            format: audioEngine.outputNode.inputFormat(forBus: 0))
        audioEngine.connect(audioEngine.inputNode,
                            to: audioEngine.mainMixerNode,
                            format: audioEngine.mainMixerNode.inputFormat(forBus: 0))
        
        // Set the output volume to almost zero so we don't produce any sound
        audioEngine.mainMixerNode.outputVolume = 0.0001
        audioEngine.prepare()
    }
    
    private func startAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(
                true,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func stopAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func startAudioEngine() {
        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
