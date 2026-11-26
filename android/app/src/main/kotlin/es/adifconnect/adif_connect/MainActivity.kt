package es.adifconnect.adif_connect

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private var sharingChannel: MethodChannel? = null
    private var initialSharedPath: String? = null
    private var notificationPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIncomingIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sharingChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "es.adifconnect.app/sharing"
        )
        sharingChannel?.setMethodCallHandler(::handleSharingCall)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "es.adifconnect.app/pdf"
        ).setMethodCallHandler { call, result ->
            if (call.method == "extractPdfText") {
                val bytes = call.arguments as? ByteArray
                if (bytes == null) {
                    result.error("INVALID_PDF_DATA", "O contido do PDF non é válido.", null)
                } else {
                    extractPdfText(bytes, result)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "es.adifconnect.app/widget-cache"
        ).setMethodCallHandler { call, result ->
            handleWidgetCacheCall(call, result)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "es.adifconnect.app/live_activity"
        ).setMethodCallHandler { call, result ->
            handleLiveActivityCall(call, result)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleSharingCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInitialPass" -> {
                val path = initialSharedPath
                initialSharedPath = null
                result.success(path)
            }
            "getSharedInbox" -> {
                val inbox = File(cacheDir, "shared_inbox")
                if (!inbox.exists()) inbox.mkdirs()
                result.success(
                    inbox.listFiles()
                        ?.filter { it.isFile && (it.extension.equals("pkpass", true) || it.extension.equals("pdf", true)) }
                        ?.sortedBy { it.name }
                        ?.map { it.absolutePath }
                        ?: emptyList<String>()
                )
            }
            "removeSharedInboxItem" -> {
                val path = call.arguments as? String
                val removed = path?.let { File(it).delete() } == true
                if (removed) result.success(null)
                else result.error("INVALID_INBOX_ITEM", "Non se puido retirar o ficheiro compartido.", null)
            }
            "requestNotificationPermission" -> {
                notificationPermissionResult = result
                requestNotificationPermission()
            }
            else -> result.notImplemented()
        }
    }

    private fun handleWidgetCacheCall(call: MethodCall, result: MethodChannel.Result) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val args = call.arguments as? Map<*, *>
        when (call.method) {
            "updateDefaultStation" -> {
                val code = args?.get("stationCode") as? String
                val name = args?.get("stationName") as? String
                if (code == null || name == null) {
                    result.error("INVALID_WIDGET_DATA", "Os datos da estación non son válidos.", null)
                    return
                }
                prefs.edit()
                    .putString("flutter.defaultStationCode", code)
                    .putString("flutter.defaultStationName", name)
                    .apply()
                updateAndroidWidget()
                result.success(null)
            }
            "cacheDepartures" -> {
                val code = args?.get("stationCode") as? String
                val departures = args?.get("departuresJson") as? String
                if (code == null || departures == null) {
                    result.error("INVALID_DEPARTURES", "Os datos das saídas non son válidos.", null)
                    return
                }
                prefs.edit()
                    .putString("flutter.stationDeparturesJSON.$code", departures)
                    .apply()
                updateAndroidWidget()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handleLiveActivityCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestNotificationPermission" -> {
                notificationPermissionResult = result
                requestNotificationPermission()
            }
            "startOrUpdate" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                val notificationId = (args["notificationId"] as? Number)?.toInt() ?: 4201
                val enabled = ensureNotificationPermission()
                if (!enabled) {
                    result.error("NOTIFICATION_PERMISSION", "A notificación precisa permiso.", null)
                    return
                }
                startOrUpdateTripNotification(notificationId, args)
                result.success(notificationId)
            }
            "end" -> {
                val notificationId = (call.arguments as? Number)?.toInt() ?: 4201
                NotificationManagerCompat.from(this).cancel(notificationId)
                result.success(null)
            }
            "areNotificationsEnabled" -> {
                result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
            }
            else -> result.notImplemented()
        }
    }

    private fun ensureNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) !=
            android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                4201
            )
        } else {
            notificationPermissionResult?.success(true)
            notificationPermissionResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 4201) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
            notificationPermissionResult?.success(granted)
            notificationPermissionResult = null
        }
    }

    private fun startOrUpdateTripNotification(id: Int, args: Map<*, *>) {
        val channelId = "adif_connect_live_trip"
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Viaxes en curso",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Información en directo da viaxe"
            manager.createNotificationChannel(channel)
        }

        val origin = args["origin"] as? String ?: "Orixe"
        val destination = args["destination"] as? String ?: "Destino"
        val departure = args["departureTime"] as? String ?: ""
        val platform = args["platform"] as? String ?: "Vía —"
        val coach = args["coach"] as? String ?: ""
        val seat = args["seat"] as? String ?: ""
        val progress = (args["progress"] as? Number)?.toInt()?.coerceIn(0, 100) ?: 0

        val pendingIntent = PendingIntent.getActivity(
            this,
            id,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setContentIntent(pendingIntent)
            .setContentTitle("$origin → $destination")
            .setContentText("$departure · $platform · Coche $coach · Asento $seat")
            .setSubText(args["operatorName"] as? String ?: "ADIF")
            .setProgress(100, progress, false)
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "$origin → $destination\nSaída: $departure\n$platform\nCoche $coach · Asento $seat"
                )
            )
            .build()

        NotificationManagerCompat.from(this).notify(id, notification)
    }

    private fun updateAndroidWidget() {
        val intent = Intent(this, StationDeparturesWidgetProvider::class.java).apply {
            action = android.appwidget.AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        sendBroadcast(intent)
    }

    private fun extractPdfText(bytes: ByteArray, result: MethodChannel.Result) {
        val tempFile = File(cacheDir, "renfe_ticket_${System.currentTimeMillis()}.pdf")
        try {
            tempFile.writeBytes(bytes)
            ParcelFileDescriptor.open(tempFile, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                PdfRenderer(descriptor).use { renderer ->
                    if (renderer.pageCount == 0) {
                        result.error("PDF_TEXT_EXTRACTION_FAILED", "O PDF non ten páxinas.", null)
                        tempFile.delete()
                        return
                    }
                    val page = renderer.openPage(0)
                    val width = (page.width * 300.0 / 72.0).toInt().coerceAtLeast(page.width)
                    val height = (page.height * 300.0 / 72.0).toInt().coerceAtLeast(page.height)
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    page.close()

                    val recognizer = TextRecognition.getClient(TextRecognizerOptions.Builder().build())
                    recognizer.process(InputImage.fromBitmap(bitmap, 0))
                        .addOnSuccessListener { visionText ->
                            result.success(visionText.text)
                            recognizer.close()
                            bitmap.recycle()
                            tempFile.delete()
                        }
                        .addOnFailureListener { error ->
                            result.error(
                                "PDF_TEXT_EXTRACTION_FAILED",
                                error.message ?: "Non se puido ler o PDF.",
                                null
                            )
                            recognizer.close()
                            bitmap.recycle()
                            tempFile.delete()
                        }
                }
            }
        } catch (error: Exception) {
            tempFile.delete()
            result.error(
                "PDF_TEXT_EXTRACTION_FAILED",
                error.message ?: "Non se puido ler o PDF.",
                null
            )
        }
    }

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent == null) return
        intent.data?.let { uri ->
            if (uri.scheme == "https" &&
                uri.host == "pay.google.com" &&
                uri.path?.startsWith("/gp/v/save/") == true
            ) {
                initialSharedPath = null
                sharingChannel?.invokeMethod("onWalletUrlReceived", uri.toString())
                return
            }
        }
        val uri = when (intent.action) {
            Intent.ACTION_SEND -> intent.clipData?.getItemAt(0)?.uri
                ?: intent.getParcelableExtra(Intent.EXTRA_STREAM)
            Intent.ACTION_VIEW -> intent.data
            else -> null
        } ?: return

        val copied = copySharedUri(uri)
        if (copied != null) {
            initialSharedPath = copied.absolutePath
            sharingChannel?.invokeMethod("onPassReceived", copied.absolutePath)
        }
    }

    private fun copySharedUri(uri: Uri): File? {
        val nameHint = uri.lastPathSegment?.substringAfterLast('/') ?: "billete"
        val extension = nameHint.substringAfterLast('.', "pkpass")
        val safeName = "shared.${extension.lowercase()}"
        val inbox = File(cacheDir, "shared_inbox")
        if (!inbox.exists()) inbox.mkdirs()
        val destination = File(inbox, safeName)
        return try {
            val input = contentResolver.openInputStream(uri) ?: return null
            input.use { source ->
                FileOutputStream(destination).use { target ->
                    source.copyTo(target)
                }
            }
            destination
        } catch (_: Exception) {
            null
        }
    }
}
