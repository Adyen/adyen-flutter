package com.adyen.checkout.flutter

import android.content.Context
import android.content.res.TypedArray
import android.view.ContextThemeWrapper
import com.adyen.checkout.flutter.utils.ThemeUtil
import org.junit.jupiter.api.Assertions.assertNotSame
import org.junit.jupiter.api.Assertions.assertSame
import org.junit.jupiter.api.Test
import org.mockito.Mockito.any
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import kotlin.test.assertIs

internal class ThemeUtilTest {
    @Test
    fun `when the host theme is a material theme, then the context is used as is`() {
        val context = mockContext(isMaterialTheme = true)

        val themedContext = ThemeUtil.applyAdyenTheme(context)

        assertSame(context, themedContext)
    }

    @Test
    fun `when the host theme is not a material theme, then the adyen theme is applied`() {
        val context = mockContext(isMaterialTheme = false)

        val themedContext = ThemeUtil.applyAdyenTheme(context)

        assertIs<ContextThemeWrapper>(themedContext)
        assertNotSame(context, themedContext)
    }

    @Test
    fun `when the host theme is resolved, then the typed array is recycled`() {
        val typedArray = mock(TypedArray::class.java)
        val context = mockContext(isMaterialTheme = true, typedArray = typedArray)

        ThemeUtil.applyAdyenTheme(context)

        verify(typedArray).recycle()
    }

    private fun mockContext(
        isMaterialTheme: Boolean,
        typedArray: TypedArray = mock(TypedArray::class.java),
    ): Context {
        `when`(typedArray.hasValue(0)).thenReturn(isMaterialTheme)
        val context = mock(Context::class.java)
        `when`(context.obtainStyledAttributes(any(IntArray::class.java))).thenReturn(typedArray)
        return context
    }
}
