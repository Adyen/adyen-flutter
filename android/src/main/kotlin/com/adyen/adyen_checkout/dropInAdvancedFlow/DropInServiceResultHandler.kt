package com.adyen.adyen_checkout.dropInAdvancedFlow

import androidx.lifecycle.LifecycleCoroutineScope
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.components.core.internal.util.StatusResponseUtils.RESULT_REFUSED
import com.adyen.checkout.dropin.DropInServiceResult
import org.json.JSONObject

class DropInServiceResultHandler(val lifecycleCoroutineScope: LifecycleCoroutineScope) {

    fun handleResponse(jsonResponse: JSONObject?): DropInServiceResult? {
        return when {
            jsonResponse == null -> {
                DropInServiceResult.Error(reason = "IOException")
            }

            isError(jsonResponse) -> {
                DropInServiceResult.Error(
                    errorMessage = jsonResponse.get("message").toString(),
                    dismissDropIn = true
                )
            }

            isRefusedInPartialPaymentFlow(jsonResponse) -> {
                DropInServiceResult.Error(reason = "Refused")
            }

            isAction(jsonResponse) -> {
                val action = Action.SERIALIZER.deserialize(jsonResponse.getJSONObject("action"))
                DropInServiceResult.Action(action)
            }

            isNonFullyPaidOrder(jsonResponse) -> {
//                TODO Not yet implemented
//                val order = getOrderFromResponse(jsonResponse)
//                fetchPaymentMethods(order)
                null
            }

            else -> {
                val resultCode = if (jsonResponse.has("resultCode")) {
                    jsonResponse.get("resultCode").toString()
                } else {
                    "EMPTY"
                }
                DropInServiceResult.Finished(resultCode)
            }
        }
    }

    private fun isError(jsonResponse: JSONObject): Boolean {
        return jsonResponse.has("errorCode")
    }

    private fun isRefusedInPartialPaymentFlow(jsonResponse: JSONObject) =
        isRefused(jsonResponse) && isNonFullyPaidOrder(jsonResponse)

    private fun isRefused(jsonResponse: JSONObject): Boolean {
        return jsonResponse.optString("resultCode")
            .equals(other = RESULT_REFUSED, ignoreCase = true)
    }

    private fun isAction(jsonResponse: JSONObject): Boolean {
        return jsonResponse.has("action")
    }

    private fun isNonFullyPaidOrder(jsonResponse: JSONObject): Boolean {
        return jsonResponse.has("order") && (getOrderFromResponse(jsonResponse).remainingAmount?.value
            ?: 0) > 0
    }

    private fun getOrderFromResponse(jsonResponse: JSONObject): OrderResponse {
        val orderJSON = jsonResponse.getJSONObject("order")
        return OrderResponse.SERIALIZER.deserialize(orderJSON)
    }
}