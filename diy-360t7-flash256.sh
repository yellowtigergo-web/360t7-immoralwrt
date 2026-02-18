#!/bin/bash
set -eux

cd openwrt

echo "==== 360T7 Flash 256MB Patch Start ===="

DTS="target/linux/mediatek/dts/mt7981b-qihoo-360t7.dts"
if [ ! -f "$DTS" ]; then
  DTS="$(grep -RIl --include='*.dts' '360T7\|qihoo' target/linux/mediatek | head -n 1 || true)"
fi
[ -f "$DTS" ] || { echo "ERROR: Cannot find 360T7 DTS file"; exit 1; }
echo "Using DTS: $DTS"

# 目标：256MiB=0x10000000，保留与原 128MiB 一样的尾部空洞 0x0600000
# UBI:    start 0x0580000, end 0x0f180000 => size 0x0ec00000
# config: start 0x0f180000 size 0x0100000
# factory:start 0x0f280000 size 0x0080000
# log:    start 0x0f300000 size 0x0700000  (end 0x0fa00000)
# gap:    0x0fa00000 ~ 0x10000000 (0x0600000)

# 1) 扩大 UBI
sed -i \
  -e 's/reg = <0x0580000 0x6c00000>;/reg = <0x0580000 0x0ec00000>;/' \
  "$DTS"

# 2) 移动尾部分区（同时改 node 名更干净；不改也能编，但建议改）
sed -i \
  -e 's/partition@7180000/partition@f180000/g' \
  -e 's/reg = <0x7180000 0x0100000>;/reg = <0x0f180000 0x0100000>;/' \
  "$DTS"

sed -i \
  -e 's/partition@7280000/partition@f280000/g' \
  -e 's/reg = <0x7280000 0x0080000>;/reg = <0x0f280000 0x0080000>;/' \
  "$DTS"

sed -i \
  -e 's/partition@7300000/partition@f300000/g' \
  -e 's/reg = <0x7300000 0x0700000>;/reg = <0x0f300000 0x0700000>;/' \
  "$DTS"

echo "==== Patch Result (key lines) ===="
grep -nE 'label = "(ubi|config|factory|log)"|reg = <0x0580000' "$DTS" || true
echo "==== 360T7 Flash 256MB Patch Done ===="
