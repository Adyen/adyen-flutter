package com.adyen.adyen_checkout

import CheckoutPlatformInterface
import DropInConfigurationModel
import SessionModel
import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.Mapper.mapToDropInConfiguration
import com.adyen.adyen_checkout.Mapper.mapToSessionModel
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.internal.ui.model.SessionDropInResultContractParams
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Suppress("NAME_SHADOWING")
class CheckoutPlatformApi : CheckoutPlatformInterface {
    lateinit var activity: FragmentActivity
    lateinit var dropInSessionLauncher: ActivityResultLauncher<SessionDropInResultContractParams>

    override fun getPlatformVersion(callback: (Result<String>) -> Unit) {
        callback.invoke(Result.success("Android ${android.os.Build.VERSION.RELEASE}"))
    }

    override fun startPayment(
        sessionModel: SessionModel,
        dropInConfiguration: DropInConfigurationModel,
        callback: (Result<Unit>) -> Unit
    ) {
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val sessionModel = sessionModel.mapToSessionModel()
            val dropInConfiguration =
                dropInConfiguration.mapToDropInConfiguration(activity.applicationContext)
            val checkoutSession = createCheckoutSession(sessionModel, dropInConfiguration)
            withContext(Dispatchers.Main) {
                DropIn.startPayment(
                    activity.applicationContext,
                    dropInSessionLauncher,
                    checkoutSession,
                    dropInConfiguration
                )
            }
        }

    }

    private suspend fun createCheckoutSession(
        sessionModel: com.adyen.checkout.sessions.core.SessionModel,
        dropInConfiguration: com.adyen.checkout.dropin.DropInConfiguration
    ): CheckoutSession {
        val checkoutSessionResult =
            CheckoutSessionProvider.createSession(sessionModel, dropInConfiguration)
        return when (checkoutSessionResult) {
            is CheckoutSessionResult.Success -> checkoutSessionResult.checkoutSession
            is CheckoutSessionResult.Error -> throw checkoutSessionResult.exception
        }
    }

}