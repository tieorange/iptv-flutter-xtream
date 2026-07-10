package com.tieorange.iptv

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions

/**
 * Wires the app to Google's unregistered "Default Media Receiver"
 * (CC1AD845) — see [com.tieorange.iptv] cast bootstrap comment in
 * lib/core/cast/cast_bootstrap.dart for why no custom receiver is needed.
 * Required by the Cast Application Framework on Android regardless of which
 * Flutter Cast plugin drives it (registered via AndroidManifest.xml
 * meta-data).
 */
class CastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        return CastOptions.Builder()
            .setReceiverApplicationId("CC1AD845")
            .setCastMediaOptions(CastMediaOptions.Builder().build())
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? = null
}
