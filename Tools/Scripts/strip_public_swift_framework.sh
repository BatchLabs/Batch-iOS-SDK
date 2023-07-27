#!/bin/bash

## This script removes public Swift stuff from a Batch framework.
## Run it into a "Batch.framework" directory

## 1/ It removes Headers/Batch-Swift.h
## 2/ It removes PrivateHeaders/
## 3/ It removes _CodeSignature/
## 4/ It removes Modules/Batch.swiftmodule/
## 5/ It removes what is between //#start-remove-prod and //#end-remove-prod in Modules/module.modulemap
## 6/ It removes the Batch.Swift module

## 1/
rm Headers/Batch-Swift.h

## 2/
rm -r PrivateHeaders

## 3/
rm -r _CodeSignature

## 4/
rm -r Modules/Batch.swiftmodule

## 5/
perl -pi -000 -e "s/\\/\\/#start-remove-prod.*#end-remove-prod//s" Modules/module.modulemap

## 6/
perl -pi -000 -e "s/module Batch\\.Swift \\{.*}//s" Modules/module.modulemap