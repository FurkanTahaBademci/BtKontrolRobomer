package com.robotcontrol.bt_kontrol_robomer

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Ekranı açık tut (opsiyonel - robot kontrolü sırasında)
        // window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        // Hardware acceleration zaten varsayılan olarak açık
    }
}
