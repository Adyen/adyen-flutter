package com.adyen.adyen_checkout.dropInAdvancedFlow

import DeletedStoredPaymentMethodResultDTO
import PaymentFlowOutcomeDTO
import androidx.lifecycle.LiveData
import com.adyen.adyen_checkout.models.DropInStoredPaymentMethodDeletionModel
import com.adyen.adyen_checkout.utils.Event
import org.json.JSONObject

class DropInServiceResultMessenger : LiveData<Event<JSONObject>>() {
    companion object {
        private val dropInServiceResultMessenger = DropInServiceResultMessenger()
        fun instance() = dropInServiceResultMessenger
        fun sendResult(value: JSONObject) {
            dropInServiceResultMessenger.postValue(Event(value))
        }
    }
}

class DropInPaymentResultMessenger : LiveData<Event<PaymentFlowOutcomeDTO>>() {
    companion object {
        private val dropInPaymentResultMessenger = DropInPaymentResultMessenger()

        fun instance() = dropInPaymentResultMessenger
        fun sendResult(value: PaymentFlowOutcomeDTO) {
            dropInPaymentResultMessenger.postValue(Event(value))
        }
    }
}

class DropInAdditionalDetailsPlatformMessenger : LiveData<Event<JSONObject>>() {
    companion object {
        private val dropInAdditionalDetailsPlatformMessenger =
            DropInAdditionalDetailsPlatformMessenger()

        fun instance() = dropInAdditionalDetailsPlatformMessenger
        fun sendResult(value: JSONObject) {
            dropInAdditionalDetailsPlatformMessenger.postValue(Event(value))
        }
    }
}

class DropInAdditionalDetailsResultMessenger : LiveData<Event<PaymentFlowOutcomeDTO>>() {
    companion object {
        private val dropInAdditionalDetailsResultMessenger =
            DropInAdditionalDetailsResultMessenger()

        fun instance() = dropInAdditionalDetailsResultMessenger
        fun sendResult(value: PaymentFlowOutcomeDTO) {
            dropInAdditionalDetailsResultMessenger.postValue(Event(value))
        }
    }
}

class DropInPaymentMethodDeletionPlatformMessenger : LiveData<Event<DropInStoredPaymentMethodDeletionModel>>() {
    companion object {
        private val dropInPaymentMethodDeletionPlatformMessenger =
            DropInPaymentMethodDeletionPlatformMessenger()

        fun instance() = dropInPaymentMethodDeletionPlatformMessenger
        fun sendResult(value: DropInStoredPaymentMethodDeletionModel) {
            dropInPaymentMethodDeletionPlatformMessenger.postValue(Event(value))
        }
    }
}

class DropInPaymentMethodDeletionResultMessenger : LiveData<Event<DeletedStoredPaymentMethodResultDTO>>() {
    companion object {
        private val dropInPaymentMethodDeletionResultMessenger =
            DropInPaymentMethodDeletionResultMessenger()

        fun instance() = dropInPaymentMethodDeletionResultMessenger
        fun sendResult(value: DeletedStoredPaymentMethodResultDTO) {
            dropInPaymentMethodDeletionResultMessenger.postValue(Event(value))
        }
    }
}
