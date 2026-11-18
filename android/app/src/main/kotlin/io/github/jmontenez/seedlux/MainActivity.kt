package io.github.jmontenez.seedlux

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// Expose le capteur de luminosité ambiante (TYPE_LIGHT) à Dart :
// - MethodChannel `seedlux/light/info`   : hasSensor, sensorInfo (nom/vendor)
// - EventChannel  `seedlux/light/stream` : flux de lux (double)
class MainActivity : FlutterActivity() {
    private var sensorListener: SensorEventListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val lightSensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "seedlux/light/info").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSensor" -> result.success(lightSensor != null)
                "sensorInfo" -> result.success(
                    lightSensor?.let {
                        mapOf(
                            "name" to it.name,
                            "vendor" to it.vendor,
                            "resolution" to it.resolution.toDouble(),
                            "maxRange" to it.maximumRange.toDouble(),
                        )
                    }
                )
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "seedlux/light/stream").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null) return
                    if (lightSensor == null) {
                        events.error("NO_SENSOR", "Pas de capteur de luminosité", null)
                        return
                    }
                    // Enregistré depuis le main thread → callbacks sur le main
                    // thread, comme l'exige EventSink.
                    val listener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent) {
                            events.success(event.values[0].toDouble())
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }
                    sensorListener = listener
                    sensorManager.registerListener(
                        listener,
                        lightSensor,
                        SensorManager.SENSOR_DELAY_UI,
                    )
                }

                override fun onCancel(arguments: Any?) {
                    sensorListener?.let { sensorManager.unregisterListener(it) }
                    sensorListener = null
                }
            }
        )
    }
}
