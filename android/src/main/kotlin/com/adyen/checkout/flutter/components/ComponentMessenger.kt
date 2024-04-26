package com.adyen.checkout.flutter.components

import ErrorDTO
import PaymentResultModelDTO
import androidx.lifecycle.LiveData
import com.adyen.checkout.flutter.utils.Event
import org.json.JSONObject

class ComponentHeightMessenger : LiveData<Event<Long>>() {
    companion object {
        private val componentHeightMessenger = ComponentHeightMessenger()

        fun instance() = componentHeightMessenger

        fun sendResult(value: Long) {
            componentHeightMessenger.postValue(Event(value))
        }
    }
}
