set -eu
WORK_DIR="${1}"
TB_DIR="${2}"
P='--! Latest baud result: '

for log in "$WORK_DIR"/*_tb_output.log; do
  [ -f "$log" ] || continue
  b="$(awk '/Baud range of/{sub(/^.*Baud range of/,"Baud range of"); x=$0} END{print x}' "$log")"
  [ -n "$b" ] || continue
  f="$TB_DIR/$(basename "$log" _tb_output.log)_tb.vhd"
  [ -f "$f" ] || continue
  awk -v n="$P$b" -v p="$P" 'index($0,p)==1{next}!d&&$0!~/^--!/{print n;d=1}{print}END{if(!d)print n}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done