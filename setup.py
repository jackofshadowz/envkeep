from pathlib import Path

from setuptools import setup

readme = Path(__file__).parent / "README.md"

setup(
    name="envkeep",
    version="1.0.0",
    description="Secure, age-encrypted ENV-secret manager with a CLI for AI coding agents",
    long_description=readme.read_text(encoding="utf-8") if readme.exists() else "",
    long_description_content_type="text/markdown",
    url="https://github.com/jackofshadowz/envkeep",
    license="MIT",
    python_requires=">=3.8",
    # `envkeep` is a single self-contained stdlib script; install it as-is.
    scripts=["envkeep"],
    classifiers=[
        "License :: OSI Approved :: MIT License",
        "Operating System :: MacOS",
        "Environment :: Console",
        "Topic :: Security",
    ],
)
