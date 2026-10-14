export TARGET='https://humansgate.github.io/www/'
export DIFFICULTY=20

if command -v fvm >/dev/null 2>&1; then
  fvm dart run ../bin/server.dart

elif command -v dart >/dev/null 2>&1; then
  dart run ../bin/server.dart
fi;