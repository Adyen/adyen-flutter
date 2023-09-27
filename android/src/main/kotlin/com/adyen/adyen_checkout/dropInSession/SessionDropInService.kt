package com.adyen.adyen_checkout.dropInSession

import DeletedStoredPaymentMethodResultDTO
import android.content.Intent
import android.os.IBinder
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ServiceLifecycleDispatcher
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInPaymentMethodDeletionPlatformMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInPaymentMethodDeletionResultMessenger
import com.adyen.adyen_checkout.models.DropInFlowType
import com.adyen.adyen_checkout.models.DropInStoredPaymentMethodDeletionModel
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.dropin.DropInServiceResult
import com.adyen.checkout.dropin.ErrorDialog
import com.adyen.checkout.dropin.RecurringDropInServiceResult
import com.adyen.checkout.dropin.SessionDropInService

class SessionDropInService : SessionDropInService(), LifecycleOwner {
    private val dispatcher = ServiceLifecycleDispatcher(this)

    override fun onRemoveStoredPaymentMethod(storedPaymentMethod: StoredPaymentMethod) {
        try {
            setDropInDeleteStoredPaymentMethodObserver()
            val storedPaymentMethodId = storedPaymentMethod.id.orEmpty()
            val dropInStoredPaymentMethodDeletionModel =
                DropInStoredPaymentMethodDeletionModel(storedPaymentMethodId, DropInFlowType.SESSION)
            DropInPaymentMethodDeletionPlatformMessenger.sendResult(dropInStoredPaymentMethodDeletionModel)
        } catch (exception: Exception) {
            sendResult(
                DropInServiceResult.Error(
                    errorDialog = null,
                    reason = exception.message,
                    dismissDropIn = true
                )
            )
        }
    }

    private fun setDropInDeleteStoredPaymentMethodObserver() {
        DropInPaymentMethodDeletionResultMessenger.instance().removeObservers(this)
        DropInPaymentMethodDeletionResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val deletionResult = mapToDeletionDropInResult(message.contentIfNotHandled)
            sendRecurringResult(deletionResult)
        }
    }

    private fun mapToDeletionDropInResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO?):
        RecurringDropInServiceResult {
        return if (deleteStoredPaymentMethodResultDTO?.isSuccessfullyRemoved == true) {
            RecurringDropInServiceResult.PaymentMethodRemoved(deleteStoredPaymentMethodResultDTO.storedPaymentMethodId)
        } else {
            RecurringDropInServiceResult.Error(errorDialog = ErrorDialog(message = "IOException"))
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        dispatcher.onServicePreSuperOnBind()
        return super.onBind(intent)
    }

    override fun onCreate() {
        dispatcher.onServicePreSuperOnCreate()
        super.onCreate()
    }

    @Deprecated("Deprecated in Java")
    override fun onStart(intent: Intent?, startId: Int) {
        dispatcher.onServicePreSuperOnStart()
        super.onStart(intent, startId)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        dispatcher.onServicePreSuperOnStart()
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        dispatcher.onServicePreSuperOnDestroy()
        super.onDestroy()
    }

    override val lifecycle: Lifecycle
        get() = dispatcher.lifecycle
}
