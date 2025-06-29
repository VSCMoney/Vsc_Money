import Foundation
import AVFoundation

protocol AudioRecorderNewDelegate: AnyObject {
    func audioRecorderNewDidRecordAudio(_ pcm: [Int16])
}

class AudioRecorderNew {
    weak var delegate: AudioRecorderNewDelegate?

    private var frameSize: Int = 0
    private var sampleRate: Int = 0

    private var audioEngine: AVAudioEngine?
    private let sessionQueue = DispatchQueue(label: "sessionQueue")

    func startRecord(sampleRate: SampleRate, frameSize: FrameSize) {
        print("[AudioRecorderNew] Called startRecord. SampleRate: \(sampleRate.rawValue), FrameSize: \(frameSize.rawValue)")

        self.sampleRate = sampleRate.rawValue
        self.frameSize = frameSize.rawValue

        self.audioEngine = AVAudioEngine()
        guard let inputNode = audioEngine?.inputNode else {
            print("[AudioRecorderNew] ❌ inputNode nil")
            return
        }
        let outputFormat = inputNode.outputFormat(forBus: 0)
        print("[AudioRecorderNew] outputFormat: \(outputFormat)")

        guard let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(self.sampleRate), channels: 1, interleaved: true) else {
            print("[AudioRecorderNew] ❌ audioFormat nil")
            return
        }
        print("[AudioRecorderNew] audioFormat: \(audioFormat)")

        guard let formatConverter = AVAudioConverter(from: outputFormat, to: audioFormat) else {
            print("[AudioRecorderNew] ❌ formatConverter nil")
            return
        }
        print("[AudioRecorderNew] formatConverter initialized")

        // installs a tap on the audio engine and specifying the buffer size and the input format.
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(self.frameSize), format: outputFormat) { [weak self] (buffer, _) in
            guard let self = self else {
                print("[AudioRecorderNew] ❌ self nil in tap")
                return
            }
            self.sessionQueue.async {
                print("[AudioRecorderNew] 🔊 inputNode tap called")
                // An AVAudioConverter is used to convert the microphone input to the format required
                // for the model (pcm 16)
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(self.frameSize))
                guard let pcmBuffer = pcmBuffer else {
                    print("[AudioRecorderNew] ❌ pcmBuffer nil")
                    return
                }

                var error: NSError?
                let inputBlock: AVAudioConverterInputBlock = { (_, inputStatus) in
                    inputStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }

                print("[AudioRecorderNew] AVAudioConverter converting...")
                formatConverter.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)

                if let error = error {
                    print("[AudioRecorderNew] ❌ Error converting buffer: \(error.localizedDescription)")
                    return
                }

                print("[AudioRecorderNew] [Audio Record] frameLength -> \(pcmBuffer.frameLength), buffer.stride -> \(buffer.stride)")
                guard let channelData = pcmBuffer.int16ChannelData else {
                    print("[AudioRecorderNew] ❌ channelData nil")
                    return
                }
                let channelDataPointee = channelData.pointee

                let step = max(1, buffer.stride)
                let frameCount = Int(pcmBuffer.frameLength)
                guard frameCount > 0 else {
                    print("[AudioRecorderNew] ❌ frameLength is 0")
                    return
                }
                print("[AudioRecorderNew] stride: \(step), frameCount: \(frameCount)")

                let channelDataArray = stride(from: 0, to: frameCount, by: step).map { channelDataPointee[$0] }
                print("[AudioRecorderNew] channelDataArray.count: \(channelDataArray.count)")

                if !channelDataArray.isEmpty {
                    print("[AudioRecorderNew] 🎤 Sending audio to delegate")
                    self.delegate?.audioRecorderNewDidRecordAudio(channelDataArray)
                } else {
                    print("[AudioRecorderNew] ⚠️ channelDataArray is empty")
                }
            }
        }

        // start record
        print("[AudioRecorderNew] Preparing audioEngine...")
        audioEngine?.prepare()
        do {
            try audioEngine?.start()
            print("[AudioRecorderNew] ✅ audioEngine started")
        } catch {
            print("[AudioRecorderNew] ❌ audioEngine start error: \(error.localizedDescription)")
            return
        }
    }

    func stopRecord() {
        print("[AudioRecorderNew] Called stopRecord")
        audioEngine?.stop()
        audioEngine?.reset()
        audioEngine = nil
        print("[AudioRecorderNew] audioEngine stopped and released")
    }
}
