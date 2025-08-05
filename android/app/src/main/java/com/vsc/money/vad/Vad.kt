package com.vitty.ai.vad

abstract class Vad {
    abstract fun isSpeech(data: ByteArray, length: Int): Boolean
}
