import re
import sys
from pathlib import Path


def migrate_compiler_options(source: str) -> str:
    """Migrate the JVM target block emitted by older Flutter templates."""
    legacy_options = re.compile(
        r"(?m)^[ \t]*kotlinOptions[ \t]*\{[ \t]*\n"
        r"[ \t]*jvmTarget[ \t]*=[ \t]*"
        r"(JavaVersion\.VERSION_[\d_]+\.toString\(\))[ \t]*\n"
        r"[ \t]*\}[ \t]*\n?"
    )
    match = legacy_options.search(source)
    if match is None:
        if re.search(r"\bkotlinOptions\s*\{", source):
            raise ValueError("Unsupported generated kotlinOptions block")
        return source

    migrated = source[: match.start()] + source[match.end() :]
    if re.search(r"\bkotlinOptions\s*\{", migrated):
        raise ValueError("Unsupported additional kotlinOptions block")

    return (
        migrated.rstrip()
        + "\n\nkotlin {\n"
        + "    compilerOptions {\n"
        + "        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget("
        + match.group(1)
        + "))\n"
        + "    }\n"
        + "}\n"
    )


def main() -> None:
    path = Path(sys.argv[1])
    source = path.read_text()
    migrated = migrate_compiler_options(source)
    if migrated != source:
        path.write_text(migrated)


if __name__ == "__main__":
    main()
