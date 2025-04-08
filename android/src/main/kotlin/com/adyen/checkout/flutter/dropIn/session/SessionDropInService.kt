package com.adyen.checkout.flutter.dropIn.session

import android.content.Intent
import android.os.IBinder
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ServiceLifecycleDispatcher
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.card.BinLookupData
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.dropin.DropInServiceResult
import com.adyen.checkout.dropin.ErrorDialog
import com.adyen.checkout.dropin.RecurringDropInServiceResult
import com.adyen.checkout.dropin.SessionDropInService
import com.adyen.checkout.flutter.dropIn.DropInPlatformApi
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentMethodDeletionPlatformMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentMethodDeletionResultMessenger
import com.adyen.checkout.flutter.dropIn.model.DropInServiceEvent
import com.adyen.checkout.flutter.dropIn.model.DropInStoredPaymentMethodDeletionModel
import com.adyen.checkout.flutter.dropIn.model.DropInType
import com.adyen.checkout.flutter.generated.BinLookupDataDTO
import com.adyen.checkout.flutter.generated.CheckoutEvent
import com.adyen.checkout.flutter.generated.CheckoutEventType
import com.adyen.checkout.flutter.generated.DeletedStoredPaymentMethodResultDTO
import com.adyen.checkout.flutter.utils.Constants.Companion.RESULT_CODE_CANCELLED
import kotlinx.coroutines.launch

class SessionDropInService : SessionDropInService(), LifecycleOwner {
    private val dispatcher = ServiceLifecycleDispatcher(this)

    init {
        listenToFlutterEvents()
    }

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
            val binLookupDataDtoList = data.map { BinLookupDataDTO(it.brand) }
            val checkoutEvent =
                CheckoutEvent(
                    CheckoutEventType.BIN_LOOKUP,
                    binLookupDataDtoList
                )
            DropInPlatformApi.dropInMessageFlow.emit(checkoutEvent)
        }
    }

    override fun onBinValue(binValue: String) {
        lifecycleScope.launch {
            val platformCommunicationModel = CheckoutEvent(CheckoutEventType.BIN_VALUE, binValue)
            DropInPlatformApi.dropInMessageFlow.emit(platformCommunicationModel)
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

    private fun listenToFlutterEvents() {
        lifecycleScope.launch {
            DropInPlatformApi.dropInServiceFlow.collect { event ->
                when (event) {
                    DropInServiceEvent.STOP -> stopDropIn()
                }
            }
        }
    }

    private fun stopDropIn() {
        sendResult(DropInServiceResult.Finished(result = RESULT_CODE_CANCELLED))
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
