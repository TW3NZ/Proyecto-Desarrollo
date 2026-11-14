package com.example.my_daily_routine

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import javax.net.ssl.HttpsURLConnection

/** APK distribution outside Play Store. Android always owns installation consent. */
@Suppress("DEPRECATION")
class AppUpdater(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "my_daily_routine/updates")
    private val executor = Executors.newSingleThreadExecutor()
    private val busy = AtomicBoolean(false)
    @Volatile private var closed = false
    private val directory get() = File(activity.cacheDir, "updates").apply { mkdirs() }
    private val apk get() = File(directory, "update.apk")
    private fun current() = activity.packageManager.getPackageInfo(activity.packageName, PackageManager.GET_SIGNATURES)
    private fun code(info: android.content.pm.PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "installed" -> result.success(mapOf("build" to code(current()),
                    "arm64" to Build.SUPPORTED_ABIS.contains("arm64-v8a")))
                "download", "install" -> {
                    if (!busy.compareAndSet(false, true)) {
                        result.error("busy", "Ya hay una actualización en curso.", null)
                    } else {
                        executor.execute {
                            try {
                                val hash = call.argument<String>("sha256") ?: error("Falta la verificación.")
                                val version = call.argument<Number>("build")?.toLong() ?: error("Falta la versión.")
                                val size = call.argument<Number>("size")?.toLong() ?: error("Falta el tamaño.")
                                require(hash.matches(Regex("[a-fA-F0-9]{64}"))) { "Verificación inválida." }
                                require(size in 1..150_000_000L) { "Tamaño de actualización inválido." }
                                if (call.method == "download") {
                                    download(call.argument<String>("url") ?: error("Falta la dirección."), size)
                                }
                                verify(hash, version, size)
                                activity.runOnUiThread {
                                    if (!closed) {
                                        try {
                                            if (call.method == "install") result.success(install())
                                            else result.success("ready")
                                        } catch (e: Exception) {
                                            result.error("install", "No se pudo abrir el instalador de Android.", null)
                                        }
                                    }
                                }
                            } catch (e: Exception) {
                                apk.delete()
                                activity.runOnUiThread {
                                    if (!closed) result.error("update", e.message ?: "No se pudo descargar la actualización.", null)
                                }
                            } finally { busy.set(false) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun download(address: String, expected: Long) {
        val url = URL(address)
        require(url.protocol == "https" && url.host == "raw.githubusercontent.com" &&
            url.port == -1 && url.userInfo == null &&
            url.path.startsWith("/TW3NZ/Proyecto-Desarrollo/") &&
            url.path.endsWith("/my-daily-rutine-android-arm64.apk")) { "Origen de actualización inválido." }
        val partial = File(directory, "update.part")
        apk.delete()
        val connection = url.openConnection() as HttpsURLConnection
        connection.connectTimeout = 20_000
        connection.readTimeout = 30_000
        connection.instanceFollowRedirects = false
        try {
            require(connection.responseCode == 200) { "GitHub no pudo entregar el APK. Reintenta más tarde." }
            var bytes = 0L
            var lastProgress = 0L
            val started = System.currentTimeMillis()
            connection.inputStream.use { input ->
                partial.outputStream().use { output ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        check(!closed && !Thread.currentThread().isInterrupted) { "Descarga interrumpida." }
                        check(System.currentTimeMillis() - started < 600_000) { "La descarga tardó demasiado. Reintenta." }
                        val count = input.read(buffer)
                        if (count < 0) break
                        bytes += count
                        require(bytes <= expected) { "El APK no coincide con la versión publicada." }
                        output.write(buffer, 0, count)
                        val now = System.currentTimeMillis()
                        if (now - lastProgress > 250) {
                            val progress = bytes.toDouble() / expected
                            activity.runOnUiThread { if (!closed) channel.invokeMethod("progress", progress) }
                            lastProgress = now
                        }
                    }
                }
            }
            require(bytes == expected) { "La descarga quedó incompleta." }
            check(partial.renameTo(apk)) { "No se pudo guardar la actualización." }
        } finally { connection.disconnect(); partial.delete() }
    }

    private fun verify(hash: String, version: Long, size: Long) {
        require(apk.isFile && apk.length() == size) { "Vuelve a descargar la actualización." }
        val digest = MessageDigest.getInstance("SHA-256")
        apk.inputStream().use { input ->
            val buffer = ByteArray(64 * 1024)
            while (true) { val n = input.read(buffer); if (n < 0) break; digest.update(buffer, 0, n) }
        }
        require(digest.digest().joinToString("") { "%02x".format(it) }.equals(hash, true)) {
            "El APK cambió o está incompleto. Busca la actualización de nuevo."
        }
        val incoming = activity.packageManager.getPackageArchiveInfo(apk.path, PackageManager.GET_SIGNATURES)
            ?: error("El archivo no es un APK válido.")
        val installed = current()
        require(incoming.packageName == activity.packageName && code(incoming) == version && version > code(installed)) {
            "La actualización no corresponde a esta app o ya está instalada."
        }
        require(incoming.signatures?.toSet() == installed.signatures?.toSet() && !incoming.signatures.isNullOrEmpty()) {
            "La firma del APK es distinta. Debe compilarse con la misma clave."
        }
        require((incoming.applicationInfo?.minSdkVersion ?: 999) <= Build.VERSION.SDK_INT) {
            "Esta versión necesita una versión más reciente de Android."
        }
    }

    private fun install(): String {
        if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
            activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${activity.packageName}")))
            return "permission"
        }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", apk)
        activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        })
        return "installer"
    }

    fun close() { closed = true; channel.setMethodCallHandler(null); executor.shutdownNow() }
}
