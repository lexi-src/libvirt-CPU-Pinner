#!/bin/bash
PINK=$(tput setaf 13)
PURPLE=$(tput setaf 99)
CYAN=$(tput setaf 14)
GREEN=$(tput setaf 10)
RED=$(tput setaf 9)
GREY=$(tput setaf 7)
DEFAULT=$(tput sgr0)

pin_information="$(pwd)/libvirt-pins.sh"
isolate_start="$(pwd)/start-isolate.sh"
isolate_end="$(pwd)/end-isolate.sh"

function main()
{
  [[ -e $pin_information ]] && rm -rf $pin_information
  [[ -e $isolate_start ]] && rm -rf $isolate_start
  [[ -e $isolate_end ]] && rm -rf $isolate_end

  get_pins
  create_files
}

function get_pins()
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

function create_files()
{
	cat <<- DOC >> $pin_information
		<cputune>
	DOC
		for (( i=0; i<${#cpu_array[@]}-2; i++ )); do
			echo "  <vcpupin vcpu=\"$i\" cpuset=\"${cpu_array[$i]}\"/>" >> $pin_information
		done
	cat <<- DOC >> $pin_information
		</cputune>
	DOC
	cat <<- DOC >> $isolate_start
		systemctl set-property --runtime -- user.slice AllowedCPUs=$reserved_cpus
		systemctl set-property --runtime -- system.slice AllowedCPUs=$reserved_cpus
		systemctl set-property --runtime -- init.scope AllowedCPUs=$reserved_cpus
	DOC
	cat <<- DOC >> $isolate_end
		systemctl set-property --runtime -- user.slice AllowedCPUs=$all_cpus
		systemctl set-property --runtime -- system.slice AllowedCPUs=$all_cpus
		systemctl set-property --runtime -- init.scope AllowedCPUs=$all_cpus
	DOC

  [[ -e $pin_information ]] && echo "Created file: ${GREEN}$pin_information${DEFAULT}" || echo "Error creating file"
  [[ -e $isolate_start ]]   && echo "Created file: ${GREEN}$isolate_start${DEFAULT}"   || echo "Error creating file"
  [[ -e $isolate_end ]]     && echo "Created file: ${GREEN}$isolate_end${DEFAULT}"     || echo "Error creating file"
}
main
