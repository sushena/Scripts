#!/usr/bin/env bash

ToDate=$(date +%Y-%m-%d)
memReport="/home/ansible/snaplogic/memory_${ToDate}_report.csv"
cpuReport="/home/ansible/snaplogic/cpu_${ToDate}_report.csv"
mem_cpu_report="/home/ansible/snaplogic/mem_cpu_${ToDate}_report.csv"
mem_1="/home/ansible/snaplogic/mem_1.txt"
mem_2="/home/ansible/snaplogic/mem_2.txt"
cpu_1="/home/ansible/snaplogic/cpu_1.txt"
cpu_2="/home/ansible/snaplogic/cpu_2.txt"

cat /dev/null > ${mem_1};cat /dev/null > ${mem_2}
cat /dev/null > ${cpu_1};cat /dev/null > ${cpu_2}

#### Get Memory details ####
ansible -m shell -a "free -m" snaplogic >> ${mem_1}
ansible -m shell -a "free -m" snap-onprem >> ${mem_1}

sed -i '/^Swap:/d' ${mem_1};sed -i '/^\-\/\+/d' ${mem_1};sed -i '/total/d' ${mem_1}
echo "hostname used free total" >> ${mem_2}

while IFS= read -r line
do
  if echo "${line}" | grep -q "CHANGED"; then
    hostname="$( awk '{print $1}' <<<"${line}")"
    echo -n "${hostname} " >> ${mem_2}
  fi

  if echo "${line}" | grep -q "Mem"; then
    dtNum="$( awk '{print $2, $3, $4}'  <<<"${line}")"
    echo -n "${dtNum}" >> ${mem_2}
    echo "" >> ${mem_2}
  fi
  unset hostname dtNum
done <"${mem_1}"
echo "Report done"
sed -i 's/\s/,/g' ${mem_2}

#### Get CPU details ####
ansible -m shell -a "sar -u 1 1" snaplogic >> ${cpu_1}
ansible -m shell -a "sar -u 1 1" snap-onprem >> ${cpu_1}

echo "hostname CPU-Usage" >> ${cpu_2}
sed -i '/^Linux/,+3d' ${cpu_1}
while IFS= read -r line
do
  if echo "${line}" | grep -q "CHANGED"; then
    hostname="$( awk '{print $1}' <<<"${line}")"
    echo -n "${hostname} " >> ${cpu_2}
  fi
  if echo "${line}" | grep -q "Average"; then
    dtNum="$( awk '{print $NF}'  <<<"${line}")"
    dtNum=`expr "100 - ${dtNum}" | bc`
    echo -n "${dtNum}" >> ${cpu_2}
    echo "" >> ${cpu_2}
  fi
  unset hostname dtNum
done <"${cpu_1}"
sed -i 's/\s/,/g' ${cpu_2}

echo "renaming in progress"
mv ${mem_2} ${memReport}
mv ${cpu_2} ${cpuReport}

cat ${memReport} > ${mem_cpu_report};echo "" >> ${mem_cpu_report};cat ${cpuReport} >> ${mem_cpu_report}
rm -rf ${memReport} ${cpuReport}
echo " --- done ---"