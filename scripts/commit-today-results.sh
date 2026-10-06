#!/usr/bin/env bash
# 사용법: 레포 루트에서  bash scripts/commit-today-results.sh [과목명]   (기본값: FSA)
set -euo pipefail
SUBJ="${1:-FSA}"
DATE="$(date +%Y-%m-%d)"
DL="$HOME/Downloads"
DEST="results/$SUBJ"
mkdir -p "$DEST"

# 1) 오늘 날짜 결과 파일 이동 (브라우저가 붙인 " (1)" 등 중복본은 최신 것만 사용)
LATEST="$(ls -t "$DL"/"${SUBJ}"_results_"${DATE}"*.json 2>/dev/null | head -n1 || true)"
if [ -n "$LATEST" ]; then
  mv -f "$LATEST" "$DEST/${SUBJ}_results_${DATE}.json"
  rm -f "$DL"/"${SUBJ}"_results_"${DATE}"*.json 2>/dev/null || true
fi
FILE="$DEST/${SUBJ}_results_${DATE}.json"

# 2) pull → add → (변경 있을 때만) commit → push
git pull
git add results/
if git diff --cached --quiet; then
  echo "변경 없음"
  exit 0
fi
SCORE="$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]))['latest'];print(f\"{d['correct']}/{d['answered']}\")" "$FILE" 2>/dev/null || echo "?/?")"
git commit -m "${SUBJ} quiz results ${DATE} (정답 ${SCORE})"
if git push; then echo "push 성공"; else echo "push 실패"; exit 1; fi
