# Azm sandbox environment. Source this before EVERY command, from ROOT:
#   source ./env.sh && <command>
# All SDKs, caches and temp files live in ./.tooling (relative to this script),
# so the whole ROOT folder can be moved to another disk (see tools/relocate.sh).
# iOS device builds / code signing need the real HOME: use ./ios_env instead.

# Resolve this script's own directory, whether sourced from zsh, bash, or executed.
if [ -n "${BASH_SOURCE:-}" ]; then
  _azm_src="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  _azm_src="${(%):-%x}"
else
  _azm_src="$0"
fi
AZM_ROOT="$(cd "$(dirname "$_azm_src")" && pwd -P)"  # -P: canonical on-disk case
unset _azm_src
export AZM_ROOT
T="$AZM_ROOT/.tooling"

# --- Drop inherited toolchain vars that may point outside ROOT -------------------
unset JAVA_HOME JDK_HOME ANDROID_HOME ANDROID_SDK_ROOT ANDROID_NDK_HOME ANDROID_NDK_ROOT \
      ANDROID_USER_HOME ANDROID_EMULATOR_HOME ANDROID_AVD_HOME GRADLE_USER_HOME GRADLE_OPTS \
      PUB_CACHE FLUTTER_ROOT FLUTTER_STORAGE_BASE_URL PUB_HOSTED_URL GEM_HOME GEM_PATH \
      RUBYOPT RUBYLIB BUNDLE_PATH CP_HOME_DIR CHROME_EXECUTABLE NVM_BIN NVM_INC

# --- Isolated home: anything that writes to "~" lands inside ROOT --------------
# (Dart/Flutter analytics + settings, Kotlin daemon, Ruby, git global config, ...)
# Real home comes from the user database (not $HOME), so re-sourcing is safe.
AZM_REAL_HOME="$(eval echo "~$(id -un)")"
export AZM_REAL_HOME
export HOME="$T/home"
export XDG_CONFIG_HOME="$T/home/.config"
export XDG_CACHE_HOME="$T/home/.cache"
export XDG_DATA_HOME="$T/home/.local/share"
export TMPDIR="$T/tmp"
export TMP="$TMPDIR" TEMP="$TMPDIR"

# --- Flutter / Dart ------------------------------------------------------------
export FLUTTER_ROOT="$T/flutter"
export PUB_CACHE="$T/pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true

# --- Java (portable JDK inside ROOT; JVMs ignore $HOME, so force user.home) -----
if [ -d "$T/jdk/current/Contents/Home" ]; then
  export JAVA_HOME="$T/jdk/current/Contents/Home"
elif [ -d "$T/jdk/current" ]; then
  export JAVA_HOME="$T/jdk/current"
fi
export JAVA_TOOL_OPTIONS="-Duser.home=$T/home -Djava.io.tmpdir=$T/tmp"

# --- Gradle / Android ----------------------------------------------------------
export GRADLE_USER_HOME="$T/gradle"
export ANDROID_HOME="$T/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$T/android-user"
export ANDROID_EMULATOR_HOME="$T/android-user"
export ANDROID_AVD_HOME="$T/android-user/avd"

# --- Ruby / CocoaPods (portable Ruby in .tooling/ruby; system Ruby 2.6 is too old) --
export GEM_HOME="$T/gems"
export GEM_PATH="$T/gems"
export GEM_SPEC_CACHE="$T/gems/specs"
export CP_HOME_DIR="$T/cocoapods"
export CP_REPOS_DIR="$T/cocoapods/repos"
export CP_CACHE_DIR="$T/cocoapods/cache"

# --- Xcode (pass -derivedDataPath "$AZM_XCODE_DERIVED" to xcodebuild) ----------
export AZM_XCODE_DERIVED="$T/xcode-derived"

# --- PATH: sandbox tools + macOS system dirs ONLY ---------------------------------
# The user's own PATH is deliberately dropped: it may point at other Flutter/JDK/
# Android SDK installs outside ROOT. Xcode is reached via /usr/bin/xcrun.
export AZM_REAL_PATH="${AZM_REAL_PATH:-$PATH}"
export PATH="$T/ruby/bin:$T/flutter/bin:$T/flutter/bin/cache/dart-sdk/bin:$PUB_CACHE/bin:$T/gems/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator${JAVA_HOME:+:$JAVA_HOME/bin}:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin"
unset T
