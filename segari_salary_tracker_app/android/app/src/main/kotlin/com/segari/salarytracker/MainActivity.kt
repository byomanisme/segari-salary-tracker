package com.segari.salarytracker

import android.content.Intent
import android.media.AudioAttributes
import android.media.SoundPool
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val INSTALLER_CHANNEL = "com.segari.salarytracker/installer"
    private val SOUNDPOOL_CHANNEL = "com.segari.salarytracker/soundpool"

    private var soundPool: SoundPool? = null
    private val soundMap = HashMap<String, Int>()
    private var isMuted = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Installer Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALLER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    val file = File(filePath)
                    if (file.exists()) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW)
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                            } else {
                                Uri.fromFile(file)
                            }
                            intent.setDataAndType(uri, "application/vnd.android.package-archive")
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("FILE_NOT_FOUND", "File APK tidak ditemukan di $filePath", null)
                    }
                } else {
                    result.error("INVALID_PATH", "Path APK kosong", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // 2. High-Performance Zero-Latency Native SoundPool Channel for Game SFX
        initSoundPool()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOUNDPOOL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    initSoundPool()
                    result.success(true)
                }
                "play" -> {
                    val soundName = call.argument<String>("name")
                    val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    if (!isMuted && soundName != null) {
                        playSound(soundName, volume)
                    }
                    result.success(true)
                }
                "setMuted" -> {
                    isMuted = call.argument<Boolean>("muted") ?: false
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initSoundPool() {
        if (soundPool != null) return

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(16)
            .setAudioAttributes(audioAttributes)
            .build()

        val soundFiles = listOf(
            "place_1", "place_2", "place_3", "place_4", "place",
            "pickup", "invalid", "caterpillar_step", "snake_step",
            "mascot_spawn", "mascot_pop",
            "clear_1", "clear_2", "clear_3", "clear_4", "clear_5", "clear_6",
            "combo_mega", "level_up", "game_over", "revive"
        )

        val loader = FlutterInjector.instance().flutterLoader()
        for (name in soundFiles) {
            try {
                val assetKey = loader.getLookupKeyForAsset("assets/sounds/$name.wav")
                val cacheFile = File(cacheDir, "sfx_$name.wav")
                // Always overwrite or ensure valid size
                if (!cacheFile.exists() || cacheFile.length() == 0L) {
                    assets.open(assetKey).use { input ->
                        FileOutputStream(cacheFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                }
                val soundId = soundPool?.load(cacheFile.path, 1) ?: 0
                if (soundId > 0) {
                    soundMap[name] = soundId
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun playSound(name: String, volume: Float) {
        val soundId = soundMap[name] ?: return
        soundPool?.play(soundId, volume, volume, 1, 0, 1.0f)
    }

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
