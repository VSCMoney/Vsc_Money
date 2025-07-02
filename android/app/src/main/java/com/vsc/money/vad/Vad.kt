package com.vsc.money.vad

abstract class Vad {
    abstract fun isSpeech(data: ByteArray, length: Int): Boolean
}
