#!/usr/bin/env bash
# fail if any commands fails
set -e
# debug log
set -x

# Building archive without Batch SDK
xcodebuild clean archive -workspace $BITRISE_PROJECT_PATH -scheme $BITRISE_SIZE_REPORT_SCHEME -configuration Release -sdk iphoneos -archivePath "SizeReport.xcarchive" SKIP_INSTALL=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED="NO"

# Extracting archive and size report
xcodebuild -exportArchive -archivePath SizeReport.xcarchive -exportPath "Generated" -exportOptionsPlist OptionsPlist.plist

# Reading size report
cat Generated/App\ Thinning\ Size\ Report.txt 
initial_size=$(sed -n 14p Generated/App\ Thinning\ Size\ Report.txt)

# Installing Batch SDK
cd SizeReport
sed -i '' '9i\                                
pod "Batch", "~> 1.17"' Podfile
pod install
cd SizeReport
sed -i '' '8i\                                
@import Batch;' AppDelegate.m
sed -i '' '18i\                                
[Batch startWithAPIKey:@"YOUR_API_KEY"];' AppDelegate.m

cd ..

# Building archive with Batch SDK
xcodebuild clean archive -workspace SizeReport.xcworkspace -scheme $BITRISE_SIZE_REPORT_SCHEME -configuration Release -sdk iphoneos -archivePath "../SizeReport.xcarchive" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED="NO"

cd ..

# Extracting archive and size report
xcodebuild -exportArchive -archivePath SizeReport.xcarchive -exportPath "Generated" -exportOptionsPlist OptionsPlist.plist -allowProvisioningUpdates

# Reading size report
cat Generated/App\ Thinning\ Size\ Report.txt 
final_size=$(sed -n 14p Generated/App\ Thinning\ Size\ Report.txt)

# Writting report file
echo $initial_size >> report.txt
echo $final_size >> report.txt