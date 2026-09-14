#!/usr/bin/env bash
#
# index.html (단독 실행용 원본) → 아티팩트 게시용 조각으로 변환한다.
#
# 아티팩트는 <!DOCTYPE>·<html>·<head>·<body>를 게시 시점에 직접 씌우므로
# 그 태그들이 파일에 남아 있으면 안 된다. PWA manifest와 아이콘은
# 아티팩트에서 쓰이지 않으므로 함께 덜어낸다.
#
# 사용법:  ./build-artifact.sh
# 결과물:  build/hanjanrok-artifact.html
#
set -euo pipefail
cd "$(dirname "$0")"

SRC="index.html"
OUT="build/hanjanrok-artifact.html"

[ -f "$SRC" ] || { echo "원본을 찾을 수 없다: $SRC" >&2; exit 1; }
mkdir -p build

# 줄 번호가 아니라 태그로 찾아 지운다 — index.html을 편집해도 계속 동작하도록.
awk '
  /^<!DOCTYPE/             { next }   # 문서형 선언
  /^<\/?html/              { next }   # <html lang="ko"> · </html>
  /^<\/?head>/             { next }   # <head> · </head>
  /^<\/?body>/             { next }   # <body> · </body>
  /^<meta /                { next }   # charset·viewport·theme-color 등 (호스트가 넣어준다)
  /rel="manifest"/         { next }   # PWA manifest
  /rel="icon"/             { next }   # 파비콘 (아티팩트는 이모지로 지정)
  /rel="apple-touch-icon"/ { next }   # iOS 홈화면 아이콘
                           { print }
' "$SRC" > "$OUT"

# <html lang="ko">가 사라지므로 런타임에 보정한다.
printf '<script>try{document.documentElement.lang="ko"}catch(e){}</script>\n' >> "$OUT"

# 남아 있으면 게시가 거부되는 태그를 검사한다.
if grep -qE '^(<!DOCTYPE|</?html|</?head>|</?body>)' "$OUT"; then
  echo "실패: 금지 태그가 남아 있다" >&2
  grep -nE '^(<!DOCTYPE|</?html|</?head>|</?body>)' "$OUT" >&2
  exit 1
fi

echo "생성됨: $OUT"
echo "  $(wc -c < "$OUT") bytes · $(wc -l < "$OUT") lines"
echo
echo "게시할 때 mp3 3개를 첨부 파일로 함께 올린다:"
echo "  bgm.mp3 · night-dose.mp3 · fading-into-the-room.mp3"
