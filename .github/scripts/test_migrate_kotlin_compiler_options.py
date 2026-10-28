import unittest

from migrate_kotlin_compiler_options import migrate_compiler_options


LEGACY_TEMPLATE = """\
plugins {
    id("org.jetbrains.kotlin.android")
}

android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_TARGET
        targetCompatibility = JavaVersion.VERSION_TARGET
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_TARGET.toString()
    }

    defaultConfig {
        minSdk = 23
    }
}

flutter {
    source = "../.."
}
"""

MODERN_TEMPLATE = """\
android {
    compileSdk = 36
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
"""


class MigrateCompilerOptionsTest(unittest.TestCase):
    def test_migrates_legacy_targets_without_changing_other_configuration(self):
        for target in ("11", "17"):
            with self.subTest(target=target):
                source = LEGACY_TEMPLATE.replace("VERSION_TARGET", f"VERSION_{target}")
                migrated = migrate_compiler_options(source)

                self.assertNotIn("kotlinOptions", migrated)
                self.assertIn(
                    "jvmTarget.set("
                    "org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget("
                    f"JavaVersion.VERSION_{target}.toString()))",
                    migrated,
                )
                self.assertIn(
                    f"sourceCompatibility = JavaVersion.VERSION_{target}", migrated
                )
                self.assertIn(
                    f"targetCompatibility = JavaVersion.VERSION_{target}", migrated
                )
                self.assertIn('flutter {\n    source = "../.."\n}', migrated)
                self.assertIn("defaultConfig {\n        minSdk = 23\n    }", migrated)
                self.assertIn("}\n\nkotlin {\n    compilerOptions {", migrated)

    def test_migration_is_idempotent(self):
        source = LEGACY_TEMPLATE.replace("VERSION_TARGET", "VERSION_11")
        migrated = migrate_compiler_options(source)

        self.assertEqual(migrated, migrate_compiler_options(migrated))

    def test_preserves_modern_templates_verbatim(self):
        self.assertEqual(MODERN_TEMPLATE, migrate_compiler_options(MODERN_TEMPLATE))

    def test_preserves_templates_without_kotlin_options(self):
        source = "android {\n    compileSdk = 36\n}\n"

        self.assertEqual(source, migrate_compiler_options(source))

    def test_does_not_discard_unrecognized_legacy_compiler_options(self):
        source = LEGACY_TEMPLATE.replace("VERSION_TARGET", "VERSION_17").replace(
            "    kotlinOptions {",
            '    kotlinOptions {\n        freeCompilerArgs += "-Xjsr305=strict"',
        )

        with self.assertRaisesRegex(ValueError, "Unsupported"):
            migrate_compiler_options(source)


if __name__ == "__main__":
    unittest.main()
