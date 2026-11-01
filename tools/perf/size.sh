#!/usr/bin/env bash
# The prod APK's size (docs/reference/performance.md, **Size**):
#   tools/perf/size.sh
# Three release builds of the prod flavor in app/, signed with whatever key the Gradle
# config finds (the debug key when the FT_RELEASE_* variables are absent, as here):
#   1. `--target-platform android-arm64 --analyze-size`, without --obfuscate and
#      --split-debug-info, which the flag refuses: the Dart code's size by package, its JSON
#      (written under ~/.flutter-devtools/) copied to app/build/perf/analyze-size.arm64.json
#      and summarised in the record;
#   2. the shipped build, `--obfuscate --split-debug-info=build/perf/symbols`, universal
#      (the size of the symbols too, unless a build that found itself up to date never
#      wrote them);
#   3. the same with `--split-per-abi`.
# For each APK of 2 and 3: its bytes, `apkanalyzer apk download-size` where the SDK has
# apkanalyzer, and the uncompressed sizes `unzip -l` lists for libapp.so, libflutter.so and
# libsqlite3mc.so per ABI, the dex files, resources.arsc, the fonts and the Flutter assets.
# No device. Prints one summary line and writes app/build/perf/size.json; the APKs stay
# under app/build/perf/size/.
set -uo pipefail
# shellcheck source=tools/perf/lib.sh
source "$(dirname "$0")/lib.sh"
perf_init size
APKANALYZER="$SDK/cmdline-tools/latest/bin/apkanalyzer"
OUT_APK="app/build/app/outputs/flutter-apk"
mkdir -p "$PERF_OUT/size"
rm -f "$PERF_OUT"/size/*.apk

build() {
  local name="$1"; shift
  perf_say "flutter build apk --release --flavor prod $* ($name)"
  (cd app && $FLUTTER build apk --release --flavor prod -t lib/main_prod.dart "$@") \
    >"$PERF_OUT/size.$name.log" 2>&1 \
    || { tail -30 "$PERF_OUT/size.$name.log"; perf_die "the $name build failed"; }
}

build analyze --target-platform android-arm64 --analyze-size
analysis="$(sed -n 's/.*A summary of your APK analysis can be found at: *//p' "$PERF_OUT/size.analyze.log" | tail -1 | tr -d '\r')"
[ -s "$analysis" ] || perf_die "no --analyze-size JSON named in $PERF_OUT/size.analyze.log"
cp "$analysis" "$PERF_OUT/analyze-size.arm64.json"
cp "$OUT_APK/app-prod-release.apk" "$PERF_OUT/size/analyze-arm64.apk"

# The symbols are not removed first: a build Flutter finds up to date writes none, and the
# files (one per ABI, overwritten by every build that compiles) are the same for the same code.
build universal --obfuscate --split-debug-info=build/perf/symbols
cp "$OUT_APK/app-prod-release.apk" "$PERF_OUT/size/universal.apk"
symbols="$(find "$PERF_OUT/symbols" -type f -name '*.symbols' -exec stat -f %z {} + 2>/dev/null | awk '{ s += $1 } END { print s + 0 }')"
if [ "$symbols" -eq 0 ]; then
  perf_say "no split debug info under $PERF_OUT/symbols (the build was up to date); symbols_bytes is not recorded"
  symbols=null
fi
build split --obfuscate --split-debug-info=build/perf/symbols --split-per-abi
for abi in armeabi-v7a arm64-v8a x86_64; do
  cp "$OUT_APK/app-$abi-prod-release.apk" "$PERF_OUT/size/$abi.apk"
done

# One APK as JSON: its bytes, its download size and the entries that matter.
apk_json() {
  local apk="$1" download=null
  if [ -x "$APKANALYZER" ]; then
    download="$("$APKANALYZER" apk download-size "$apk" 2>/dev/null | tr -d '\r' | tail -1)"
    [[ "$download" =~ ^[0-9]+$ ]] || download=null
  fi
  unzip -l "$apk" | awk 'NR > 3 && $1 ~ /^[0-9]+$/ && NF >= 4 { print $1 "\t" $4 }' \
    | jq -R -s --argjson bytes "$(stat -f %z "$apk")" --argjson download "$download" '
      split("\n") | map(select(length > 0) | split("\t") | {size: (.[0] | tonumber), name: .[1]}) as $e
      | def sum(f): [$e[] | select(.name | test(f)) | .size] | add // 0;
      {apk_bytes: $bytes, download_bytes: $download,
       libs: ([$e[] | select(.name | test("^lib/[^/]+/lib(app|flutter|sqlite3mc)\\.so$"))
               | {key: (.name | ltrimstr("lib/")), value: .size}] | from_entries),
       dex_bytes: sum("^classes[0-9]*\\.dex$"),
       resources_arsc_bytes: sum("^resources\\.arsc$"),
       font_bytes: sum("^assets/flutter_assets/.*\\.(ttf|otf)$"),
       flutter_assets_bytes: sum("^assets/flutter_assets/")}'
}

apks="{}"
for name in universal armeabi-v7a arm64-v8a x86_64; do
  apks="$(jq --arg n "$name" --argjson a "$(apk_json "$PERF_OUT/size/$name.apk")" '. + {($n): $a}' <<<"$apks")"
done

# The analysis: the Dart AOT snapshot's size and its largest packages.
dart="$(jq '
  [.. | objects | select((.n // "") | startswith("libapp.so"))][0] as $app
  | {libapp_bytes: $app.value,
     packages: ([$app.children[]? | {name: .n, bytes: ([.. | objects | select(has("children") | not) | .value // 0] | add // 0)}] | sort_by(-.bytes) | .[:12])}' \
  "$PERF_OUT/analyze-size.arm64.json")"

metrics="$(jq -n --argjson a "$apks" --argjson d "$dart" --argjson symbols "$symbols" \
  --argjson analyzed "$(stat -f %z "$PERF_OUT/size/analyze-arm64.apk")" '
  {universal_apk_bytes: $a.universal.apk_bytes,
   universal_download_bytes: $a.universal.download_bytes,
   arm64_apk_bytes: $a["arm64-v8a"].apk_bytes,
   arm64_download_bytes: $a["arm64-v8a"].download_bytes,
   armeabi_v7a_apk_bytes: $a["armeabi-v7a"].apk_bytes,
   x86_64_apk_bytes: $a.x86_64.apk_bytes,
   arm64_libapp_bytes: $a["arm64-v8a"].libs["arm64-v8a/libapp.so"],
   arm64_libflutter_bytes: $a["arm64-v8a"].libs["arm64-v8a/libflutter.so"],
   arm64_libsqlite3mc_bytes: $a["arm64-v8a"].libs["arm64-v8a/libsqlite3mc.so"],
   dex_bytes: $a.universal.dex_bytes,
   resources_arsc_bytes: $a.universal.resources_arsc_bytes,
   font_bytes: $a.universal.font_bytes,
   flutter_assets_bytes: $a.universal.flutter_assets_bytes,
   symbols_bytes: $symbols,
   analyze_arm64_apk_bytes: $analyzed,
   analyze_arm64_libapp_bytes: $d.libapp_bytes}')"
detail="$(jq -n --argjson a "$apks" --argjson d "$dart" '{apks: $a, dart_aot_arm64: $d}')"
notes='["prod flavor release builds; the shipped ones with --obfuscate --split-debug-info, universal and --split-per-abi; the --analyze-size build is arm64 only and neither obfuscated nor split (the flag refuses both), so its figures are its own","entry sizes are uncompressed (unzip -l); download sizes from apkanalyzer"]'
perf_record "$metrics" "$detail" "$notes"
echo "$metrics" | jq -r 'def mb: . / 1048576 * 10 | round / 10 | tostring + " MB";
  "size: universal \(.universal_apk_bytes | mb) (download \(.universal_download_bytes // 0 | mb)), arm64 \(.arm64_apk_bytes | mb), armeabi-v7a \(.armeabi_v7a_apk_bytes | mb), x86_64 \(.x86_64_apk_bytes | mb); arm64 libapp.so \(.arm64_libapp_bytes | mb), libflutter.so \(.arm64_libflutter_bytes | mb); symbols \(.symbols_bytes | mb)"'
