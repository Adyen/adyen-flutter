package com.adyen.checkout.flutter.components

import androidx.lifecycle.LiveData
import com.adyen.checkout.flutter.utils.Event

class ComponentHeightMessenger : LiveData<Event<Long>>() {
    companion object {
        private val componentHeightMessenger = ComponentHeightMessenger()

        fun instance() = componentHeightMessenger

        fun sendResult(value: Long) {
            componentHeightMessenger.postValue(Event(value))
        }
    }
}
