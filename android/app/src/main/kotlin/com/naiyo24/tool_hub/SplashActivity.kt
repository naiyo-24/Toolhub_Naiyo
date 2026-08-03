package com.naiyo24.tool_hub

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.VideoView

class SplashActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_splash)

        val videoView = findViewById<VideoView>(R.id.splashVideoView)
        val videoPath = "android.resource://" + packageName + "/" + R.raw.splash_video
        val uri = Uri.parse(videoPath)
        
        videoView.setVideoURI(uri)
        
        // Mute the video completely
        videoView.setOnPreparedListener { mediaPlayer ->
            mediaPlayer.setVolume(0f, 0f)
        }
        
        videoView.setOnCompletionListener {
            startActivity(Intent(this, MainActivity::class.java))
            finish()
        }
        
        videoView.start()
    }
}
