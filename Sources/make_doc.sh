#!/bin/sh
rm -rf api-doc/
jazzy --objc \
				--clean \
				--author Batch \
				--author_url https://batch.com \
				--module Batch \
				--hide-documentation-coverage \
				--umbrella-header Batch/Batch.h \
				--framework-root .\
				--sdk iphonesimulator \
				--output api-doc/
