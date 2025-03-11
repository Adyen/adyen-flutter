package com.adyen.checkout.flutter.dropIn.advanced

import androidx.lifecycle.LiveData
import com.adyen.checkout.flutter.dropIn.model.DropInStoredPaymentMethodDeletionModel
import com.adyen.checkout.flutter.generated.DeletedStoredPaymentMethodResultDTO
import com.adyen.checkout.flutter.generated.OrderCancelResultDTO
import com.adyen.checkout.flutter.generated.PaymentEventDTO
import com.adyen.checkout.flutter.utils.Event
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

class DropInPaymentResultMessenger : LiveData<Event<PaymentEventDTO>>() {
    companion object {
        private val dropInPaymentResultMessenger = DropInPaymentResultMessenger()

        fun instance() = dropInPaymentResultMessenger

        fun sendResult(value: PaymentEventDTO) {
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

class DropInAdditionalDetailsResultMessenger : LiveData<Event<PaymentEventDTO>>() {
    companion object {
        private val dropInAdditionalDetailsResultMessenger =
            DropInAdditionalDetailsResultMessenger()

        fun instance() = dropInAdditionalDetailsResultMessenger

        fun sendResult(value: PaymentEventDTO) {
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

class DropInBalanceCheckResultMessenger : LiveData<Event<String>>() {
    companion object {
        private val dropInBalanceCheckResultMessenger =
            DropInBalanceCheckResultMessenger()

        fun instance() = dropInBalanceCheckResultMessenger

        fun sendResult(value: String) {
            dropInBalanceCheckResultMessenger.postValue(Event(value))
        }
    }
}

class DropInOrderRequestResultMessenger : LiveData<Event<String>>() {
    companion object {
        private val dropInOrderRequestResultMessenger =
            DropInOrderRequestResultMessenger()

        fun instance() = dropInOrderRequestResultMessenger

        fun sendResult(value: String) {
            dropInOrderRequestResultMessenger.postValue(Event(value))
        }
    }
}

class DropInOrderCancelResultMessenger : LiveData<Event<OrderCancelResultDTO>>() {
    companion object {
        private val dropInOrderCancelResultMessenger =
            DropInOrderCancelResultMessenger()

        fun instance() = dropInOrderCancelResultMessenger

        fun sendResult(value: OrderCancelResultDTO) {
            dropInOrderCancelResultMessenger.postValue(Event(value))
        }
    }
}
