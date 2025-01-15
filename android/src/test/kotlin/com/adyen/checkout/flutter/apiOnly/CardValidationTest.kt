package com.adyen.checkout.flutter.apiOnly

import CardNumberValidationResultDTO
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

internal class CardValidationTest {
    @Nested
    inner class ValidateCardNumberTest {
        @Test
        fun `given card number is correct when validate then result should be valid`() {
            val cardNumber = "4111111111111111"

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given MC card number is correct when validate then result should be valid`() {
            val cardNumber = "5454 5454 5454 5454"

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given VISA card number is correct when validate then result should be valid`() {
            val cardNumber = "5392 6394 1013 2039"

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given AMEX card number is correct when validate then result should be valid`() {
            val cardNumber = "3795 5311 0957 637"

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given card number is not correct when validate then result with Luhn check should be invalid luhn check`() {
            val cardNumber = "1111 1111 1111 1111"

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.INVALIDLUHNCHECK, validationResult)
        }

        @Test
        fun `given card number is too short when validate then result should be invalid to short`() {
            val cardNumber = "3795 5311"

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.INVALIDTOOSHORT, validationResult)
        }

        @Test
        fun `given card number is too long when validate then result should be invalid to long`() {
            val cardNumber = "37955311444214324114413423"

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.INVALIDTOOLONG, validationResult)
        }

        @Test
        fun `given card number contains unsupported characters when validate then result should be invalid illegal characters`() {
            val cardNumber = "35311TEST-123456"

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.INVALIDILLEGALCHARACTERS, validationResult)
        }

        @Test
        fun `given card number is empty when validate then result should be invalid too short`() {
            val cardNumber = ""

            val validationResult = CardValidation.validateCardNumber(cardNumber, true)

            assertEquals(CardNumberValidationResultDTO.INVALIDTOOSHORT, validationResult)
        }
    }

    @Nested
    inner class ValidateExpiryDateTest {

        @Test
        fun `given date is valid when validate card expiry date then result should be valid`() {
            val validationResult = CardValidation.validateCardExpiryDate("12", "2030")

            assertEquals(CardExpiryDateValidationResultDTO.VALID, validationResult)
        }


        @Test
        fun `given date is too far in the future when validate card expiry date then result should be invalid`() {
            val validationResult = CardValidation.validateCardExpiryDate("12", "2099")

            assertEquals(CardExpiryDateValidationResultDTO.INVALIDTOOFARINTHEFUTURE, validationResult)
        }

        @Test
        fun `given date is too old when validate card expiry date then result should be invalid`() {
            val validationResult = CardValidation.validateCardExpiryDate("12", "2018")

            assertEquals(CardExpiryDateValidationResultDTO.INVALIDTOOOLD, validationResult)
        }


        @Test
        fun `given date is empty when validate card expiry date then result should be invalid`() {
            val validationResult = CardValidation.validateCardExpiryDate("", "")

            assertEquals(CardExpiryDateValidationResultDTO.NONPARSEABLEDATE, validationResult)
        }

        @Test
        fun `given date is invalid when validate card expiry date then result should be invalid`() {
            val validationResult = CardValidation.validateCardExpiryDate("30", "10")

            assertEquals(CardExpiryDateValidationResultDTO.NONPARSEABLEDATE, validationResult)
        }

        @Test
        fun `given month is missing when validate card expiry date then result should be invalid`() {
            val validationResult = CardValidation.validateCardExpiryDate("", "10")

            assertEquals(CardExpiryDateValidationResultDTO.NONPARSEABLEDATE, validationResult)
        }

        @Test
        fun `given year is missing when validate card expiry date then result should be invalid`() {
            val validationResult = CardValidation.validateCardExpiryDate("5", "")

            assertEquals(CardExpiryDateValidationResultDTO.NONPARSEABLEDATE, validationResult)
        }

        @Test
        fun `given values are wrong when validate card expiry date then result should be invalid`() {
            val validationResult = CardValidation.validateCardExpiryDate("av", "test")

            assertEquals(CardExpiryDateValidationResultDTO.NONPARSEABLEDATE, validationResult)
        }

        @Test
        fun `given values are too long when validate card expiry date then result should be invalid`() {
            val validationResult = CardValidation.validateCardExpiryDate("1234", "56789")

            assertEquals(CardExpiryDateValidationResultDTO.NONPARSEABLEDATE, validationResult)
        }
    }

    @Nested
    inner class ValidateSecurityCodeTest {
        @Test
        fun `given valid security code and Visa card when validate then result should be valid`() {
            val validationResult = CardValidation.validateCardSecurityCode("123", "visa")

            assertEquals(CardSecurityCodeValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given valid security code and MasterCard when validate then result should be valid`() {
            val validationResult = CardValidation.validateCardSecurityCode("456", "mc")

            assertEquals(CardSecurityCodeValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given valid security code and Amex card when validate then result should be valid`() {
            val validationResult = CardValidation.validateCardSecurityCode("1234", "amex")

            assertEquals(CardSecurityCodeValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given invalid security code and Visa card when validate then result should be invalid`() {
            val validationResult = CardValidation.validateCardSecurityCode("12", "visa")

            assertEquals(CardSecurityCodeValidationResultDTO.INVALID, validationResult)
        }

        @Test
        fun `given invalid security code and MasterCard when validate then result should be invalid`() {
            val validationResult = CardValidation.validateCardSecurityCode("12", "mc")

            assertEquals(CardSecurityCodeValidationResultDTO.INVALID, validationResult)
        }

        @Test
        fun `given valid security code with null card brand when validate then result should be valid`() {
            val validationResult = CardValidation.validateCardSecurityCode("123", null)

            assertEquals(CardSecurityCodeValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given valid security code with unsupported card brand when validate then result should be valid`() {
            val validationResult = CardValidation.validateCardSecurityCode("123", "")

            assertEquals(CardSecurityCodeValidationResultDTO.VALID, validationResult)
        }

        @Test
        fun `given invalid security code with null card brand when validate then result should be invalid`() {
            val validationResult = CardValidation.validateCardSecurityCode("1", null)

            assertEquals(CardSecurityCodeValidationResultDTO.INVALID, validationResult)
        }
    }
}