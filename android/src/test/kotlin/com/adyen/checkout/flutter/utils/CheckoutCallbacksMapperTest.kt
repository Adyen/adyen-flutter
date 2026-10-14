package com.adyen.checkout.flutter.utils

import com.adyen.checkout.card.BinLookupBrand
import com.adyen.checkout.card.BinLookupData
import com.adyen.checkout.core.components.BeforeSubmitResult
import com.adyen.checkout.core.components.SubmitResult
import com.adyen.checkout.core.components.data.Address
import com.adyen.checkout.core.components.data.BeforeSubmitData
import com.adyen.checkout.core.components.data.ShopperName
import com.adyen.checkout.flutter.generated.AdyenPigeonError
import com.adyen.checkout.flutter.generated.BeforeSubmitResultDTO
import com.adyen.checkout.flutter.generated.BinLookupBrandDTO
import com.adyen.checkout.flutter.generated.SubmitResultDTO
import com.adyen.checkout.flutter.generated.SubmitResultTypeDTO
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toDTO
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toNativeAddress
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toNativeBeforeSubmitResult
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toNativeShopperName
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toNativeSubmitResult
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertInstanceOf
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

internal class CheckoutCallbacksMapperTest {
    @Test
    fun `when submit result is completion with result code then it maps to completion`() {
        val result = SubmitResultDTO(type = SubmitResultTypeDTO.COMPLETION, resultCode = "Authorised")
            .toNativeSubmitResult()

        assertEquals("Authorised", assertInstanceOf(SubmitResult.Completion::class.java, result).resultCode)
    }

    @Test
    fun `when submit result is completion without result code then it throws`() {
        val error = assertThrows<AdyenPigeonError> {
            SubmitResultDTO(type = SubmitResultTypeDTO.COMPLETION).toNativeSubmitResult()
        }

        assertEquals("InvalidSubmitResult", error.code)
    }

    @Test
    fun `when submit result is action without action json then it throws`() {
        val error = assertThrows<AdyenPigeonError> {
            SubmitResultDTO(type = SubmitResultTypeDTO.ACTION).toNativeSubmitResult()
        }

        assertEquals("InvalidSubmitResult", error.code)
    }

    @Test
    fun `when submit result is retry then it maps to retry with message`() {
        val result = SubmitResultDTO(type = SubmitResultTypeDTO.RETRY, errorMessage = "Try again")
            .toNativeSubmitResult()

        assertEquals("Try again", assertInstanceOf(SubmitResult.Retry::class.java, result).errorMessage)
    }

    @Test
    fun `when before submit result is aborted then it maps to abort`() {
        val result = BeforeSubmitResultDTO(isAborted = true).toNativeBeforeSubmitResult()

        assertInstanceOf(BeforeSubmitResult.Abort::class.java, result)
    }

    @Test
    fun `when before submit result is not aborted without data then it proceeds with empty data`() {
        val result = BeforeSubmitResultDTO(isAborted = false).toNativeBeforeSubmitResult()

        val proceed = assertInstanceOf(BeforeSubmitResult.Proceed::class.java, result)
        assertEquals(BeforeSubmitData(), proceed.data)
        assertNull(proceed.sessionData)
    }

    @Test
    fun `when address is mapped to dto and back then all fields are kept`() {
        val address = Address(
            city = "Amsterdam",
            country = "NL",
            houseNumberOrName = "6-50",
            postalCode = "1011 DJ",
            stateOrProvince = "North Holland",
            street = "Simon Carmiggeltstraat",
        )

        val result = address.toDTO().toNativeAddress()

        assertEquals(address.city, result.city)
        assertEquals(address.country, result.country)
        assertEquals(address.houseNumberOrName, result.houseNumberOrName)
        assertEquals(address.postalCode, result.postalCode)
        assertEquals(address.stateOrProvince, result.stateOrProvince)
        assertEquals(address.street, result.street)
    }

    @Test
    fun `when shopper name is mapped to dto and back then all fields are kept`() {
        val shopperName = ShopperName(firstName = "Jan", lastName = "Jansen", infix = "van", gender = "MALE")

        val result = shopperName.toDTO().toNativeShopperName()

        assertEquals(shopperName.firstName, result.firstName)
        assertEquals(shopperName.lastName, result.lastName)
        assertEquals(shopperName.infix, result.infix)
        assertEquals(shopperName.gender, result.gender)
    }

    @Test
    fun `when bin lookup data is mapped then country code and brands are kept`() {
        val binLookupData = BinLookupData(
            issuingCountryCode = "NL",
            brands = listOf(
                BinLookupBrand(brand = "visa", supported = true, paymentMethodVariant = "visacredit"),
                BinLookupBrand(brand = "cartebancaire", supported = false, paymentMethodVariant = null),
            ),
        )

        val result = binLookupData.toDTO()

        assertEquals("NL", result.issuingCountryCode)
        assertEquals(
            listOf(
                BinLookupBrandDTO(brand = "visa", supported = true, paymentMethodVariant = "visacredit"),
                BinLookupBrandDTO(brand = "cartebancaire", supported = false, paymentMethodVariant = null),
            ),
            result.brands,
        )
    }
}
