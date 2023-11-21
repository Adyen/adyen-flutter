package com.adyen.adyen_checkout.components

import PaymentResultModelDTO
import androidx.lifecycle.LiveData
import com.adyen.adyen_checkout.utils.Event
import org.json.JSONObject

class ComponentActionMessenger : LiveData<Event<JSONObject>>() {
    companion object {
        private val componentActionMessenger = ComponentActionMessenger()
        fun instance() = componentActionMessenger
        fun sendResult(value: JSONObject) {
            componentActionMessenger.postValue(Event(value))
        }
    }
}

class ComponentHeightMessenger : LiveData<Event<Long>>() {
    companion object {
        private val componentHeightMessenger = ComponentHeightMessenger()
        fun instance() = componentHeightMessenger
        fun sendResult(value: Long) {
            componentHeightMessenger.postValue(Event(value))
        }
    }
}

class ComponentResultMessenger: LiveData<Event<PaymentResultModelDTO>>(){
    companion object {
        private val componentResultMessenger = ComponentResultMessenger()
        fun instance() = componentResultMessenger
        fun sendResult(value: PaymentResultModelDTO) {
            componentResultMessenger.postValue(Event(value))
        }
    }
}



