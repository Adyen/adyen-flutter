package com.adyen.checkout.flutter.dropIn.session

import DeletedStoredPaymentMethodResultDTO
import android.content.Intent
import android.os.IBinder
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ServiceLifecycleDispatcher
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.dropin.ErrorDialog
import com.adyen.checkout.dropin.RecurringDropInServiceResult
import com.adyen.checkout.dropin.SessionDropInService
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentMethodDeletionPlatformMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentMethodDeletionResultMessenger
import com.adyen.checkout.flutter.dropIn.model.DropInStoredPaymentMethodDeletionModel
import com.adyen.checkout.flutter.dropIn.model.DropInType

class SessionDropInService : SessionDropInService(), LifecycleOwner {
    private val dispatcher = ServiceLifecycleDispatcher(this)

    override fun onRemoveStoredPaymentMethod(storedPaymentMethod: StoredPaymentMethod) {
        storedPaymentMethod.id?.let { storedPaymentMethodId ->
            setStoredPaymentMethodDeletionObserver()
            val dropInStoredPaymentMethodDeletionModel = DropInStoredPaymentMethodDeletionModel(
                storedPaymentMethodId,
                DropInType.SESSION
            )
            DropInPaymentMethodDeletionPlatformMessenger.sendResult(dropInStoredPaymentMethodDeletionModel)
        } ?: run {
            sendRecurringResult(RecurringDropInServiceResult.Error(errorDialog = ErrorDialog()))
        }
    }

    private fun setStoredPaymentMethodDeletionObserver() {
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
            // TODO - the error message should be provided by the native SDK
            RecurringDropInServiceResult.Error(
                errorDialog = ErrorDialog(
                    message = "Removal of the stored payment method failed. Please try again later."
                )
            )
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
