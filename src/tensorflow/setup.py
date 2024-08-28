# setup.py
from setuptools import setup, find_packages
import os

default_version = "0.1.0"

if os.getenv("PACKAGE_VERSION") is not None:
    version = os.getenv("PACKAGE_VERSION")
else:
    version = default_version

setup(
    version=version,
     packages=find_packages(include=['mlserver_tensorflow*']),
)