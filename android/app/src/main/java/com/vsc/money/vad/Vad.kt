package com.ai.vitty.vad

abstract class Vad {
    abstract fun isSpeech(data: ByteArray, length: Int): Boolean
}
