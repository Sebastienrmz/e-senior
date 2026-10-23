#!/usr/bin/env bash
set -euo pipefail
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb logcat -c
adb shell am start -W -n com.example.e_senior/.MainActivity
sleep 15
adb shell pidof com.example.e_senior
adb shell dumpsys activity activities > android-activity.txt
grep -E 'mResumedActivity|topResumedActivity' android-activity.txt | grep com.example.e_senior
adb logcat -d > android-startup.log
if grep -E 'FATAL EXCEPTION|Unhandled Exception' android-startup.log; then
  echo 'Erreur au démarrage de la démonstration Android.' >&2
  exit 1
fi
adb shell screencap -p /sdcard/e-senior.png
adb pull /sdcard/e-senior.png android-startup.png
