#!/bin/bash

# -----------------------
# $1 - name of the hwmon property 'name' identifying the hwmon directory to observe
function get_hwmondir()
{
   local basedir="/sys/class/hwmon"
   local cachefile="/tmp/hwmondir_$1"
   
   if [ -e $cachefile ];then
      echo `cat $cachefile`
   else
      for file in $basedir/*; do
         if [ -d "$file" ] && [ -f "$file/name" ]; then
            if [ `cat "$file/name"` = $1 ];then
               echo $file > $cachefile
               echo $file
            fi
         fi
      done
   fi
}

# -----------------------
# $1 - hwmon basedir
function print_core_clock_mhz()
{
   local propname=`cat $1/device/pp_dpm_sclk | grep -m 1 -ia "*" | cut -d " " -f 2 | rev | cut -c 4- | rev`
   echo $propname
}

# -----------------------
# $1 - hwmon basedir
function print_memory_clock_mhz()
{
   local propname=`cat $1/device/pp_dpm_mclk | grep -m 1 -ia "*" | cut -d " " -f 2 | rev | cut -c 4- | rev`
   echo $propname
}

# -----------------------
# $1 - hwmon basedir
function print_temperature()
{
   local propname=`cat $1/temp1_input`
   echo $(( $propname / 1000 ))
}

# -----------------------
# $1 - hwmon basedir
function print_pci_speed()
{
   local propname=`cat $1/device/pp_dpm_pcie | grep -ia "*" | cut -d " " -f 2,3`
   echo $propname
}

# -----------------------
# $1 - hwmon basedir
function print_performance_level()
{
   local propname=`cat $1/device/power_dpm_force_performance_level`
   echo $propname
}

# -----------------------
# $1 - hwmon basedir
function print_power_avg()
{
   local propname=""
   
   if [ -f $1/power1_average ];then
      propname=`cat $1/power1_average`
      elif [ -f $1/power1_input ];then
      propname=`cat $1/power1_input`
   fi
   
   if [ "x$propname" != "x" ];then
      echo $(( $propname / 1000000 ))
   fi
}

# -----------------------
# $1 - hwmon basedir
function print_fanspeed_rpm()
{
   if [ ! -e "$1/fan1_input" ];then
      echo "0"
      return
   fi

   local propname=`cat $1/fan1_input`
   local fan_usage=$(print_fan_usage_percent $hwmondir)
   
   if [ $fan_usage == "0" ];then
      echo "0"
   else
      echo $propname
   fi
}

# -----------------------
# $1 - hwmon basedir
function print_fan_usage_percent()
{
   if [ ! -e "$1/pwm1_max" ];then
      echo "0"
      return
   fi

   local pwm_max=`cat $1/pwm1_max`
   # local pwm_min=`cat $1/pwm1_min`
   local pwm=`cat $1/pwm1`
   
   echo $(( $pwm * 100 / $pwm_max ))
}

# -----------------------
# $1 - hwmon basedir
function print_gpu_busy_percent()
{
   local propname=`cat $1/device/gpu_busy_percent`
   echo $propname
}

# -----------------------
# $1 - hwmon basedir
function print_mem_busy_percent()
{
   if [ ! -e "$1/device/mem_busy_percent" ];then
      echo "0"
      return
   fi

   local propname=`cat $1/device/mem_busy_percent`
   echo $propname
}

# -----------------------
# $1 - hwmon basedir
function print_mem_usage_percent()
{
   local vram_total=`cat $1/device/mem_info_vram_total`
   local vram_used=`cat $1/device/mem_info_vram_used`
   echo $(( $vram_used * 100 / $vram_total ))
}

function show_help()
{
   echo "Print sensor information from amdgpu."
   echo "Usage: amdgpu-sensor-info.sh [OPTIONS]"
   echo ""
   echo "-a print core clock in MHz (pp_dpm_sclk)"
   echo "-b print memory clock in MHz (pp_dpm_mclk)"
   echo "-c print temperature in °C (temp1_input)"
   echo "-d print PCI speed (pp_dpm_pcie)"
   echo "-e print performance level (power_dpm_force_performance_level)"
   echo "-f print power average in Watt (power1_average)"
   echo "-g print fanspeed in RPM (fan1_input)"
   echo "-h this page"
   echo "-i print fan usage in percent (pwm1 * 100 / pwm1_max)"
   echo "-j print GPU load in percent (gpu_busy_percent)"
   echo "-k print memory usage load in percent (mem_busy_percent)"
   echo "-l print memory usage in percent (mem_info_vram_used * 100 / mem_info_vram_total)"
}

#################################################################

function main() {
   local positional=()
   local hwmondir=$(get_hwmondir "amdgpu")
   
   if [ "$hwmondir"x == "x" ];then
      echo ""
      exit 0
   fi
   
   while [[ $# -gt 0 ]]
   do
      key="$1"
      case $key in
         -a) # core clock
            print_core_clock_mhz $hwmondir
            exit 0
         ;;
         
         -b) # memory clock
            print_memory_clock_mhz $hwmondir
            exit 0
         ;;
         
         -c) # temperature
            print_temperature $hwmondir
            exit 0
         ;;
         
         -d) # PCI speed
            print_pci_speed $hwmondir
            exit 0
         ;;
         
         -e) # performance level
            print_performance_level $hwmondir
            exit 0
         ;;
         
         -f) # power average
            print_power_avg $hwmondir
            exit 0
         ;;
         
         -g) # fanspeed
            print_fanspeed_rpm $hwmondir
            exit 0
         ;;
         
         -h|--help)
            show_help
            exit 0
         ;;
         
         -i) # fan usage
            print_fan_usage_percent $hwmondir
            exit 0
         ;;
         
         -j) # gpu usage
            print_gpu_busy_percent $hwmondir
            exit 0
         ;;
         
         -k) # memory busy
            print_mem_busy_percent $hwmondir
            exit 0
         ;;
         
         -l) # memory usage
            print_mem_usage_percent $hwmondir
            exit 0
         ;;
         
         *)
            positional+=("$1") # save it in an array for later
            shift
         ;;
      esac
   done
   set -- "${positional[@]}" # restore positional parameters
}

main $*
exit $?
