#!/usr/bin/env bash
# Build a local Maven repo with Chaquopy 15.0.1 (minSdk21, Python3.8) + a VersionNumber shim
# so it runs on Gradle 9. Injects the repo into settings.gradle pluginManagement (first).
set -euo pipefail
CQ_VER=15.0.1
ROOT="$(pwd)"
LM="$ROOT/local-maven"
GDIR="$LM/com/chaquo/python/gradle/$CQ_VER"
MDIR="$LM/com/chaquo/python/com.chaquo.python.gradle.plugin/$CQ_VER"
mkdir -p "$GDIR" "$MDIR"
echo "[1/5] download Chaquopy $CQ_VER jar+pom"
curl -fsSL -o "$GDIR/gradle-$CQ_VER.jar" "https://repo1.maven.org/maven2/com/chaquo/python/gradle/$CQ_VER/gradle-$CQ_VER.jar"
curl -fsSL -o "$GDIR/gradle-$CQ_VER.pom" "https://repo1.maven.org/maven2/com/chaquo/python/gradle/$CQ_VER/gradle-$CQ_VER.pom"
echo "[2/5] compile VersionNumber shim"
SHIM="$(mktemp -d)"; mkdir -p "$SHIM/src/org/gradle/util"
cp patchfiles/VersionNumber.java "$SHIM/src/org/gradle/util/VersionNumber.java"
javac -d "$SHIM/classes" "$SHIM/src/org/gradle/util/VersionNumber.java"
echo "[3/5] inject shim into jar"
python3 - "$GDIR/gradle-$CQ_VER.jar" "$SHIM/classes/org/gradle/util/VersionNumber.class" <<'PY'
import sys, zipfile, shutil
jar, cls = sys.argv[1], sys.argv[2]
tmp = jar + '.tmp'
with zipfile.ZipFile(jar) as zin, zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as zout:
    for it in zin.infolist():
        if it.filename == 'org/gradle/util/VersionNumber.class':
            continue
        zout.writestr(it, zin.read(it.filename))
    zout.write(cls, 'org/gradle/util/VersionNumber.class')
shutil.move(tmp, jar)
print('shim injected into', jar)
PY
echo "[4/5] marker pom"
cat > "$MDIR/com.chaquo.python.gradle.plugin-$CQ_VER.pom" <<POM
<project xmlns="http://maven.apache.org/POM/4.0.0"><modelVersion>4.0.0</modelVersion>
  <groupId>com.chaquo.python</groupId><artifactId>com.chaquo.python.gradle.plugin</artifactId>
  <version>$CQ_VER</version><packaging>pom</packaging>
  <dependencies><dependency><groupId>com.chaquo.python</groupId><artifactId>gradle</artifactId><version>$CQ_VER</version></dependency></dependencies>
</project>
POM
echo "[5/5] inject local repo into settings.gradle (first)"
python3 - "$LM" <<'PY'
import sys
lm = sys.argv[1]; p = 'settings.gradle'; s = open(p).read()
if 'local-maven' not in s:
    s = s.replace('    repositories {\n        gradlePluginPortal()',
                  '    repositories {\n        maven { url = uri("%s") }\n        gradlePluginPortal()' % lm, 1)
open(p, 'w').write(s)
assert 'local-maven' in s, 'inject failed'
print('settings.gradle local-maven injected')
PY
echo "DONE local-maven ready at $LM"
