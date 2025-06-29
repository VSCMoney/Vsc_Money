//
//  YamnetVADStrategy.swift
//  ios-vad
//
//  Created by baochuquan on 2024/11/10.
//

import Foundation

class YamnetVADStrategy: VADStrategy {
    private var yamnetVAD: YamnetVAD?
    private var state: VADState = .silence
    private var handler: ((VADState) -> Void)?
    private var sampleRate: Int = 0

    func setup(sampleRate: SampleRate, frameSize: FrameSize, quality: VADQuality, silenceTriggerDurationMs: Int64, speechTriggerDurationMs: Int64) {
        self.sampleRate = sampleRate.rawValue
        yamnetVAD = YamnetVAD(
            sampleRate: Int64(sampleRate.rawValue),
            sliceSize: Int64(frameSize.rawValue),
            threshold: quality.threshold,
            silenceTriggerDurationMs: silenceTriggerDurationMs,
            speechTriggerDurationMs: speechTriggerDurationMs
        )
        yamnetVAD?.delegate = self
    }

    func checkVAD(pcm: [Int16], handler: @escaping (VADState) -> Void) {
        self.handler = handler
        yamnetVAD?.predict(data: pcm)
    }

    func currentState() -> VADState {
        return state
    }
}

extension YamnetVADStrategy: YamnetVADDelegate {
    func yamnetVADDidDetectSpeechStart() {
        state = .start
        handler?(.start)
    }

    func yamnetVADDidDetectSpeechEnd() {
        state = .end
        handler?(.end)
    }

    func yamnetVADDidDetectSilence() {
        state = .silence
        handler?(.silence)
    }

    func yamnetVADDidDetectSpeeching() {
        state = .speeching
        handler?(.speeching)
    }
}
