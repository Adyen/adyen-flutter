package com.adyen.checkout.flutter.dropIn.session

import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ServiceLifecycleDispatcher
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.card.BinLookupData
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.dropin.ErrorDialog
import com.adyen.checkout.dropin.RecurringDropInServiceResult
import com.adyen.checkout.dropin.SessionDropInService
import com.adyen.checkout.flutter.dropIn.DropInPlatformApi
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentMethodDeletionPlatformMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentMethodDeletionResultMessenger
import com.adyen.checkout.flutter.dropIn.model.DropInStoredPaymentMethodDeletionModel
import com.adyen.checkout.flutter.dropIn.model.DropInType
import com.adyen.checkout.flutter.generated.DeletedStoredPaymentMethodResultDTO
import com.adyen.checkout.flutter.dropIn.model.toJson
import com.adyen.checkout.flutter.utils.Constants.Companion.ADYEN_LOG_TAG
import kotlinx.coroutines.launch

class SessionDropInService : SessionDropInService(), LifecycleOwner {
    private val dispatcher = ServiceLifecycleDispatcher(this)

    override fun onRemoveStoredPaymentMethod(storedPaymentMethod: StoredPaymentMethod) {
        storedPaymentMethod.id?.let { storedPaymentMethodId ->
            setStoredPaymentMethodDeletionObserver()
            val dropInStoredPaymentMethodDeletionModel =
                DropInStoredPaymentMethodDeletionModel(
                    storedPaymentMethodId,
                    DropInType.SESSION
                )
            DropInPaymentMethodDeletionPlatformMessenger.sendResult(dropInStoredPaymentMethodDeletionModel)
        } ?: run {
            sendRecurringResult(RecurringDropInServiceResult.Error(errorDialog = ErrorDialog()))
        }
    }

    override fun onBinLookup(data: List<BinLookupData>) {
        lifecycleScope.launch {
            try {
                val binLookupDataJson = data.toJson()
                val platformCommunicationModel = PlatformCommunicationModel(
                    PlatformCommunicationType.BINLOOKUP,
                    binLookupDataJson)
                DropInPlatformApi.dropInSessionPlatformMessageFlow.emit(platformCommunicationModel)
            } catch (exception: Exception) {
                Log.d(ADYEN_LOG_TAG, "BinLookupData parsing failed: ${exception.message}")
            }
        }
    }

    override fun onBinValue(binValue: String) {
        lifecycleScope.launch {
            val platformCommunicationModel = PlatformCommunicationModel(PlatformCommunicationType.BINVALUE, binValue)
            DropInPlatformApi.dropInSessionPlatformMessageFlow.emit(platformCommunicationModel)
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

    private fun mapToDeletionDropInResult(
        deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO?
    ): RecurringDropInServiceResult {
        return if (deleteStoredPaymentMethodResultDTO?.isSuccessfullyRemoved == true) {
            RecurringDropInServiceResult.PaymentMethodRemoved(deleteStoredPaymentMethodResultDTO.storedPaymentMethodId)
        } else {
            RecurringDropInServiceResult.Error(errorDialog = null)
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
    override fun onStart(
        intent: Intent?,
        startId: Int
    ) {
        dispatcher.onServicePreSuperOnStart()
        super.onStart(intent, startId)
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
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
