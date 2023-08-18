package com.adyen.adyen_checkout.dropInAdvancedFlow

import androidx.lifecycle.LiveData
import org.json.JSONObject

class DropInServiceResultMessenger : LiveData<JSONObject>() {
    companion object {
        private val dropInServiceResultMessenger = DropInServiceResultMessenger()
        fun instance() = dropInServiceResultMessenger
        fun sendResult(value: JSONObject) {
            dropInServiceResultMessenger.postValue(value)
        }
    }
}

class DropInPaymentResultMessenger : LiveData<JSONObject>() {
    companion object {
        private val dropInPaymentResultMessenger = DropInPaymentResultMessenger()

        fun instance() = dropInPaymentResultMessenger
        fun sendResult(value: JSONObject) {
            dropInPaymentResultMessenger.postValue(value)
        }
    }
}

class DropInAdditionalDetailsResultMessenger : LiveData<JSONObject>() {
    companion object {
        private val dropInAdditionalDetailsResultMessenger =
            DropInAdditionalDetailsResultMessenger()

        fun instance() = dropInAdditionalDetailsResultMessenger
        fun sendResult(value: JSONObject) {
            dropInAdditionalDetailsResultMessenger.postValue(value)
        }
    }
}