package com.adyen.checkout.flutter.components.googlepay

import ComponentFlutterInterface
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.advanced.GooglePayAdvancedComponent
import com.adyen.checkout.flutter.components.googlepay.session.GooglePaySessionComponent
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

class GooglePayComponentManager(
    private val activity: FragmentActivity,
    //private val paymentFinishedFlow: MutableStateFlow<Boolean>
) {
    private val googlePayComponents: MutableList<BaseGooglePayComponent> = mutableListOf()

    fun isGooglePayAvailable(
        paymentMethod: PaymentMethod,
        componentId: String,
        sessionHolder: SessionHolder,
        componentFlutterInterface: ComponentFlutterInterface,
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        callback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        if (!GooglePayComponent.PROVIDER.isPaymentMethodSupported(paymentMethod)) {
            val model = InstantPaymentSetupResultDTO(
                instantPaymentComponentConfigurationDTO.instantPaymentType,
                false,
                ""
            )
            callback(Result.success(model))
        }

        val googlePayAvailableFlow = MutableStateFlow<Boolean?>(null)
        val googlePayAvailabilityChecker = GooglePayAvailabilityChecker(activity, googlePayAvailableFlow)
        val googlePlayConfiguration = instantPaymentComponentConfigurationDTO.mapToGooglePayConfiguration(activity)
        googlePayAvailabilityChecker.checkGooglePayAvailability(paymentMethod, googlePlayConfiguration)
        activity.lifecycleScope.launch {
            googlePayAvailableFlow.collectLatest {
                if (it == true) {
                    val googlePayComponent = setupGooglePayComponent(
                        activity,
                        sessionHolder,
                        componentFlutterInterface,
                        instantPaymentComponentConfigurationDTO,
                        componentId,
                        paymentMethod,
                        callback
                    )
                    googlePayComponents.add(googlePayComponent)
                } else if (it == false) {
                    callback(Result.failure(Exception("Google pay not available")))
                }
            }
        }
    }


    fun startGooglePayScreen(componentId: String) {
        googlePayComponents.firstOrNull { it.componentId == componentId }?.startGooglePayScreen()
    }

    private fun setupGooglePayComponent(
        activity: FragmentActivity,
        sessionHolder: SessionHolder,
        componentFlutterInterface: ComponentFlutterInterface,
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        componentId: String,
        paymentMethod: PaymentMethod,
        callback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ): BaseGooglePayComponent {
        if (instantPaymentComponentConfigurationDTO.instantPaymentType == InstantPaymentType.GOOGLEPAYSESSION) {
            val googlePaySessionComponent =
                GooglePaySessionComponent(
                    activity,
                    sessionHolder,
                    componentFlutterInterface,
                    instantPaymentComponentConfigurationDTO.mapToGooglePayConfiguration(activity),
                    componentId
                )
            val googlePayComponent = googlePaySessionComponent.setupGooglePayComponent(paymentMethod)

            val allowedPaymentMethods: String = googlePayComponent.getGooglePayButtonParameters().allowedPaymentMethods
            val model = InstantPaymentSetupResultDTO(
                InstantPaymentType.GOOGLEPAYSESSION,
                true,
                allowedPaymentMethods
            )
            callback(Result.success(model))
            return googlePaySessionComponent
        }

        if (instantPaymentComponentConfigurationDTO.instantPaymentType == InstantPaymentType.GOOGLEPAYADVANCED) {
            val googlePayAdvancedComponent =
                GooglePayAdvancedComponent(
                    activity,
                    componentFlutterInterface,
                    instantPaymentComponentConfigurationDTO.mapToGooglePayConfiguration(activity),
                    componentId
                )
            val googlePayComponent = googlePayAdvancedComponent.setupGooglePayComponent(paymentMethod)
            val allowedPaymentMethods: String = googlePayComponent.getGooglePayButtonParameters().allowedPaymentMethods
            val model = InstantPaymentSetupResultDTO(
                InstantPaymentType.GOOGLEPAYADVANCED,
                true,
                allowedPaymentMethods
            )
            callback(Result.success(model))
            return googlePayAdvancedComponent
        }

        throw Exception("Google pay setup failed")
    }

    fun handleGooglePayActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            Constants.GOOGLE_PAY_SESSION_REQUEST_CODE -> {
                googlePayComponents.firstOrNull { it is GooglePaySessionComponent }
                    ?.handleActivityResult(resultCode, data)
                true
            }

            Constants.GOOGLE_PAY_ADVANCED_REQUEST_CODE -> {
                googlePayComponents.firstOrNull { it is GooglePayAdvancedComponent }
                    ?.handleActivityResult(resultCode, data)
                true
            }

            else -> false
        }
    }

    fun onDispose(componentId: String) {
        val googlePayComponent = googlePayComponents.firstOrNull { it.componentId == componentId }
        googlePayComponent?.dispose()
        googlePayComponents.remove(googlePayComponent)
    }
}

