package com.adyen.checkout.flutter.apiOnly

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

internal class CardValidationTest {
    @Test
    fun `when valid card number is validated then it returns true`() {
        assertTrue(CardValidation.validateCardNumber("4111111111111111", true))
    }

    @Test
    fun `when invalid card number is validated then it returns false`() {
        assertFalse(CardValidation.validateCardNumber("1111111111111111", true))
    }

    @Test
    fun `when expiry date uses two digit month and year then it returns true`() {
        assertTrue(CardValidation.validateCardExpiryDate("12", "30"))
    }

    @Test
    fun `when expiry date uses four digit year then it returns false`() {
        assertFalse(CardValidation.validateCardExpiryDate("12", "2030"))
    }

    @Test
    fun `when valid security code is validated then it returns true`() {
        assertTrue(CardValidation.validateCardSecurityCode("123", "visa"))
    }

    @Test
    fun `when invalid security code is validated then it returns false`() {
        assertFalse(CardValidation.validateCardSecurityCode("12", "visa"))
    }
}
