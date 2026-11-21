package it.davidebertolino.db_flow

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * File .flow aperti da Gmail, File, Drive…: ne legge il testo dal
 * ContentResolver e lo passa a Dart sul canale "dbflow/files".
 * Nessun accesso alla rete.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private val pending = mutableListOf<String>()
    private var dartReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dbflow/files")
        ch.setMethodCallHandler { call, result ->
            if (call.method == "pending") {
                dartReady = true
                result.success(ArrayList(pending))
                pending.clear()
            } else {
                result.notImplemented()
            }
        }
        channel = ch
        receive(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        receive(intent)
    }

    private fun receive(intent: Intent?) {
        val uri: Uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND ->
                if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
            else -> null
        } ?: return
        // Lo stesso intent non va riletto (es. dopo una rotazione).
        intent?.action = null
        val text = try {
            contentResolver.openInputStream(uri)?.use { it.readBytes().toString(Charsets.UTF_8) }
        } catch (e: Exception) {
            null
        } ?: return
        if (dartReady) channel?.invokeMethod("open", text) else pending.add(text)
    }
}
