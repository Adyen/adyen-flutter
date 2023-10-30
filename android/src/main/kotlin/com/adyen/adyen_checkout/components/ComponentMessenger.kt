package com.adyen.adyen_checkout.components

import androidx.lifecycle.LiveData
import com.adyen.adyen_checkout.utils.Event
import org.json.JSONObject

class ComponentMessenger: LiveData<Event<JSONObject>>() {
    companion object {
        private val componentMessenger = ComponentMessenger()
        fun instance() = componentMessenger
        fun sendResult(value: JSONObject) {
            componentMessenger.postValue(Event(value))
        }
    }
}

