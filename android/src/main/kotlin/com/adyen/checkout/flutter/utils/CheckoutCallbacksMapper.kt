package com.adyen.checkout.flutter.utils

import com.adyen.checkout.card.BinLookupData
import com.adyen.checkout.core.action.data.Action
import com.adyen.checkout.core.components.AdditionalDetailsResult
import com.adyen.checkout.core.components.BeforeSubmitResult
import com.adyen.checkout.core.components.SubmitResult
import com.adyen.checkout.core.components.data.Address
import com.adyen.checkout.core.components.data.BeforeSubmitData
import com.adyen.checkout.core.components.data.ShopperName
import com.adyen.checkout.flutter.generated.AdditionalDetailsResultDTO
import com.adyen.checkout.flutter.generated.AddressDTO
import com.adyen.checkout.flutter.generated.AdyenPigeonError
import com.adyen.checkout.flutter.generated.BeforeSubmitDataDTO
import com.adyen.checkout.flutter.generated.BeforeSubmitResultDTO
import com.adyen.checkout.flutter.generated.BinLookupBrandDTO
import com.adyen.checkout.flutter.generated.BinLookupDataDTO
import com.adyen.checkout.flutter.generated.ShopperNameDTO
import com.adyen.checkout.flutter.generated.SubmitResultDTO
import com.adyen.checkout.flutter.generated.SubmitResultTypeDTO
import org.json.JSONObject

internal object CheckoutCallbacksMapper {
    internal fun SubmitResultDTO.toNativeSubmitResult(): SubmitResult =
        when (type) {
            SubmitResultTypeDTO.COMPLETION -> {
                val code =
                    resultCode ?: throw AdyenPigeonError(
                        ErrorCodes.INVALID_SUBMIT_RESULT,
                        "Submit completion did not contain a result code.",
                    )
                SubmitResult.Completion(code)
            }

            SubmitResultTypeDTO.ACTION -> {
                val actionJson =
                    actionJson ?: throw AdyenPigeonError(
                        ErrorCodes.INVALID_SUBMIT_RESULT,
                        "Submit action did not contain action data.",
                    )
                SubmitResult.Action(Action.SERIALIZER.deserialize(JSONObject(actionJson)))
            }

            SubmitResultTypeDTO.RETRY -> SubmitResult.Retry(errorMessage)
        }

    internal fun AdditionalDetailsResultDTO.toNativeAdditionalDetailsResult(): AdditionalDetailsResult =
        AdditionalDetailsResult.Completion(resultCode)

    internal fun BeforeSubmitResultDTO.toNativeBeforeSubmitResult(): BeforeSubmitResult =
        if (isAborted) {
            BeforeSubmitResult.Abort()
        } else {
            BeforeSubmitResult.Proceed(
                data = data?.toNativeBeforeSubmitData() ?: BeforeSubmitData(),
                sessionData = sessionData,
            )
        }

    internal fun BeforeSubmitData.toDTO(): BeforeSubmitDataDTO =
        BeforeSubmitDataDTO(
            billingAddress = billingAddress?.toDTO(),
            deliveryAddress = deliveryAddress?.toDTO(),
            shopperName = shopperName?.toDTO(),
            shopperEmail = shopperEmail,
        )

    internal fun BeforeSubmitDataDTO.toNativeBeforeSubmitData(): BeforeSubmitData =
        BeforeSubmitData(
            billingAddress = billingAddress?.toNativeAddress(),
            deliveryAddress = deliveryAddress?.toNativeAddress(),
            shopperName = shopperName?.toNativeShopperName(),
            shopperEmail = shopperEmail,
        )

    internal fun Address.toDTO(): AddressDTO =
        AddressDTO(
            city = city,
            country = country,
            houseNumberOrName = houseNumberOrName,
            postalCode = postalCode,
            stateOrProvince = stateOrProvince,
            street = street,
        )

    internal fun AddressDTO.toNativeAddress(): Address =
        Address(
            city = city,
            country = country,
            houseNumberOrName = houseNumberOrName,
            postalCode = postalCode,
            stateOrProvince = stateOrProvince,
            street = street,
        )

    internal fun ShopperName.toDTO(): ShopperNameDTO =
        ShopperNameDTO(
            firstName = firstName,
            lastName = lastName,
            infix = infix,
            gender = gender,
        )

    internal fun ShopperNameDTO.toNativeShopperName(): ShopperName =
        ShopperName(
            firstName = firstName,
            lastName = lastName,
            infix = infix,
            gender = gender,
        )

    internal fun BinLookupData.toDTO(): BinLookupDataDTO =
        BinLookupDataDTO(
            issuingCountryCode = issuingCountryCode,
            brands =
                brands.map { brand ->
                    BinLookupBrandDTO(
                        brand = brand.brand,
                        supported = brand.supported,
                        paymentMethodVariant = brand.paymentMethodVariant,
                    )
                },
        )
}
