#!/bin/bash
PINK=$(tput setaf 13)
PURPLE=$(tput setaf 99)
CYAN=$(tput setaf 14)
RED=$(tput setaf 9)
GREY=$(tput setaf 7)
DEFAULT=$(tput sgr0)

function main()
{
  pinner
  printer
}

function pinner()
{
  cpu_total=$(($(nproc) / 2))
  for (( i=0, u=0; i<$cpu_total; i++ )); do
    cpu_group=$(lscpu -p | tail -n +5 | grep ",,[0-9]*,[0-9]*,$i,[0-9]*" | cut -d"," -f1)

    ((p=1))
    for core in $cpu_group; do
      cpu_array[$u]=$(echo $cpu_group | cut -d" " -f$p)
      ((u++, p++))
    done
  done

  reserved_cpus="$(echo $cpu_group | tr " " ",")"
  all_cpus="0-$(($(nproc)-1))"
}

function printer()
{
	cat <<- DOC
		${GREY}# Add this to your libvirt XML${DEFAULT}
		${CYAN}<cputune>${DEFAULT}
	DOC
		for (( i=0; i<${#cpu_array[@]}-2; i++ )); do
			echo "  ${CYAN}<vcpupin ${PURPLE}vcpu=${PINK}\"$i\"${PURPLE} cpuset=${PINK}\"${cpu_array[$i]}\"${CYAN}/>${DEFAULT}"
		done
	cat <<- DOC
		${CYAN}</cputune>${DEFAULT}
		${GREY}# Start isolation${DEFAULT}
		systemctl set-property --runtime -- user.slice AllowedCPUs=$reserved_cpus
		systemctl set-property --runtime -- system.slice AllowedCPUs=$reserved_cpus
		systemctl set-property --runtime -- init.scope AllowedCPUs=$reserved_cpus
		${GREY}# End isolation${DEFAULT}
		systemctl set-property --runtime -- user.slice AllowedCPUs=$all_cpus
		systemctl set-property --runtime -- system.slice AllowedCPUs=$all_cpus
		systemctl set-property --runtime -- init.scope AllowedCPUs=$all_cpus
	DOC
}
main
