package com.adyen.checkout.flutter.dropIn.model

import com.adyen.checkout.card.BinLookupData
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

@Throws(JSONException::class)
fun List<BinLookupData>.toJson(): String {
    val jsonArray = JSONArray()
    for (item in this) {
        val jsonObject = JSONObject()
        // Let's discuss if we want to use models instead of JSON to avoid unnoticed changes
        jsonObject.put("brand", item.brand)
        jsonArray.put(jsonObject)
    }
    return jsonArray.toString()
}
