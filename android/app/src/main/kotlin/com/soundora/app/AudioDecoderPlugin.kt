package com.soundora.app

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

class AudioDecoderPlugin(engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "audio_decoder")

    private val executor = java.util.concurrent.Executors.newSingleThreadExecutor()

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "decodeToWav" -> {
                    val inputPath = call.argument<String>("inputPath")!!
                    val outputPath = call.argument<String>("outputPath")!!
                    // Decoding a full song with MediaCodec can take seconds and must
                    // never run on the platform main thread (it would ANR the app).
                    executor.execute {
                        try {
                            decodeToWav(inputPath, outputPath)
                            result.success(outputPath)
                        } catch (e: Exception) {
                            result.error("DECODE_ERROR", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun decodeToWav(inputPath: String, outputPath: String) {
        val extractor = MediaExtractor()
        extractor.setDataSource(inputPath)

        var audioTrackIndex = -1
        var audioFormat: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            if (format.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                audioTrackIndex = i
                audioFormat = format
                break
            }
        }

        if (audioTrackIndex == -1 || audioFormat == null) {
            extractor.release()
            throw Exception("No audio track found")
        }

        val sampleRate = audioFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val channelCount = audioFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

        extractor.selectTrack(audioTrackIndex)

        val mime = audioFormat.getString(MediaFormat.KEY_MIME)!!
        val decoder = MediaCodec.createDecoderByType(mime)
        decoder.configure(audioFormat, null, null, 0)
        decoder.start()

        val bufferInfo = MediaCodec.BufferInfo()
        val decodedBuffers = mutableListOf<ByteArray>()
        var totalSize = 0
        var isInputDone = false
        var isOutputDone = false

        while (!isOutputDone) {
            if (!isInputDone) {
                val inputIndex = decoder.dequeueInputBuffer(10000)
                if (inputIndex >= 0) {
                    val inputBuffer = decoder.getInputBuffer(inputIndex)!!
                    val sampleSize = extractor.readSampleData(inputBuffer, 0)
                    if (sampleSize < 0) {
                        decoder.queueInputBuffer(inputIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        isInputDone = true
                    } else {
                        decoder.queueInputBuffer(inputIndex, 0, sampleSize, extractor.sampleTime, 0)
                        extractor.advance()
                    }
                }
            }

            val outputIndex = decoder.dequeueOutputBuffer(bufferInfo, 10000)
            if (outputIndex >= 0) {
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    isOutputDone = true
                }
                if (bufferInfo.size > 0) {
                    val outputBuffer = decoder.getOutputBuffer(outputIndex)!!
                    outputBuffer.position(bufferInfo.offset)
                    val data = ByteArray(bufferInfo.size)
                    outputBuffer.get(data)
                    decodedBuffers.add(data)
                    totalSize += data.size
                }
                decoder.releaseOutputBuffer(outputIndex, false)
            } else if (outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                if (isInputDone) isOutputDone = true
            }
        }

        decoder.stop()
        decoder.release()
        extractor.release()

        val wavFile = File(outputPath)
        val fos = FileOutputStream(wavFile)

        val byteRate = sampleRate * channelCount * 2
        val dataSize = totalSize
        val fileSize = 36 + dataSize

        writeWavHeader(fos, sampleRate, channelCount, 16, dataSize, fileSize)
        for (buf in decodedBuffers) {
            fos.write(buf)
        }
        fos.close()
    }

    private fun writeWavHeader(fos: FileOutputStream, sampleRate: Int, channels: Int, bitsPerSample: Int, dataSize: Int, fileSize: Int) {
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray())
        header.putInt(fileSize)
        header.put("WAVE".toByteArray())
        header.put("fmt ".toByteArray())
        header.putInt(16)
        header.putShort(1)
        header.putShort(channels.toShort())
        header.putInt(sampleRate)
        header.putInt(sampleRate * channels * bitsPerSample / 8)
        header.putShort((channels * bitsPerSample / 8).toShort())
        header.putShort(bitsPerSample.toShort())
        header.put("data".toByteArray())
        header.putInt(dataSize)
        fos.write(header.array())
    }
}
