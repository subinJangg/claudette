#!/bin/bash
cd "$(dirname "$0")"

pkill -x Claudette 2>/dev/null

xcodegen generate 2>/dev/null
xcodebuild -project Claudette.xcodeproj -scheme Claudette -configuration Debug build 2>&1 | tail -3

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    open ~/Library/Developer/Xcode/DerivedData/Claudette-*/Build/Products/Debug/Claudette.app
    echo "✓ 실행됨"
else
    echo "✗ 빌드 실패"
fi
