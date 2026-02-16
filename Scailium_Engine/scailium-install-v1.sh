#!/bin/bash
############################################ Log File ###########################################################################################
LOG_FILE="/tmp/sqream-installV1.log"
logit() 
{
    echo "[`date`] - ${*}" >> ${LOG_FILE}    
}
########################## TOTAL RAM ##########################################################################################################
total_ram(){
# Get total RAM in GB (rounded down)
TOTAL_RAM_GB=$(awk '/MemTotal/ { printf "%d\n", $2 / 1024 / 1024 }' /proc/meminfo)
AVAILABLE_RAM_GB=0
if (( TOTAL_RAM_GB < 32 )); then
    AVAILABLE_RAM_GB=8
elif (( TOTAL_RAM_GB < 64 )); then
    AVAILABLE_RAM_GB=16
elif (( TOTAL_RAM_GB <= 128 )); then
    AVAILABLE_RAM_GB=32
elif (( TOTAL_RAM_GB < 256 )); then
    AVAILABLE_RAM_GB=32
elif (( TOTAL_RAM_GB <= 512 )); then
    AVAILABLE_RAM_GB=64
elif (( TOTAL_RAM_GB < 1024 )); then
    AVAILABLE_RAM_GB=64
else
    AVAILABLE_RAM_GB=128
fi
AVAILABLE_RAM_GB=$(( TOTAL_RAM_GB -  AVAILABLE_RAM_GB ))
}

########################## TOTAL RAM with METADATA #############################################################################
total_ram_meta(){
# Get total RAM in GB (rounded down)
TOTAL_RAM_GB=$(awk '/MemTotal/ { printf "%d\n", $2 / 1024 / 1024 }' /proc/meminfo)
if (( TOTAL_RAM_GB < 512 )); then
TOTAL_RAM_GB=$(awk '/MemTotal/ { printf "%d\n", $2 / 1024 / 1024 }' /proc/meminfo)
else
TOTAL_RAM_GB=$(awk '/MemTotal/ { printf "%d\n", ($2 / 1024 / 1024) - 50 }' /proc/meminfo)
fi
AVAILABLE_RAM_GB=0
if (( TOTAL_RAM_GB < 32 )); then
    AVAILABLE_RAM_GB=8
elif (( TOTAL_RAM_GB < 64 )); then
    AVAILABLE_RAM_GB=16
elif (( TOTAL_RAM_GB <= 128 )); then
    AVAILABLE_RAM_GB=32
elif (( TOTAL_RAM_GB < 256 )); then
    AVAILABLE_RAM_GB=32
elif (( TOTAL_RAM_GB <= 512 )); then
    AVAILABLE_RAM_GB=64
elif (( TOTAL_RAM_GB < 1024 )); then
    AVAILABLE_RAM_GB=64
else
    AVAILABLE_RAM_GB=128
fi
AVAILABLE_RAM_GB=$(( TOTAL_RAM_GB -  AVAILABLE_RAM_GB ))
}

############################################ etc backup #########################################################################################
etc_backup () {
logit "Started etc_backup"
if
[ -d /etc/sqream ];then
sudo cp -r /etc/sqream /etc/sqream_etc_backup_$today
logit "Success: /etc/sqream >  backup to sqream_etc_backup_$today"
fi
}
############################## Prepare_for_SQream ############################################################################################
Prepare_for_SQream () {
logit "Started Prepare_for_SQream "
LinuxDistro=$(cat /etc/os-release |grep VERSION_ID |cut -d "=" -f2)
#IS_CENTUS=$(echo ${SQ_OS_NAME} | grep CentOS | wc -l)

if [[ $(echo $LinuxDistro|grep '7') ]];then
        logit "Prepare SQream for RHEL 7"
        sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
        sudo yum install ntp pciutils monit zlib-devel openssl-devel kernel-devel-$(uname -r) kernel-headers-$(uname -r) gcc net-tools wget jq libffi-devel gdbm-devel tk-devel xz-devel sqlite-devel readline-devel bzip2-devel ncurses-devel zlib-devel -y
        

   elif [[ $(echo $LinuxDistro|grep '8') ]];then   
    logit "Prepare SQream for RHEL 8"
    sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
    sudo subscription-manager repos --enable rhel-8-for-x86_64-highavailability-rpms
    sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    sudo dnf install chrony pciutils monit zlib-devel openssl-devel kernel-devel-$(uname -r) kernel-headers-$(uname -r) gcc net-tools wget jq libffi-devel xz-devel ncurses-compat-libs libnsl gdbm-devel tk-devel sqlite-devel readline-devel texinfo -y 
elif [[ $(echo $LinuxDistro|grep '9') ]];then
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms
    sudo subscription-manager repos --enable rhel-9-for-x86_64-highavailability-rpms
    sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    sudo dnf install chrony pciutils monit zlib-devel openssl-devel kernel-devel-$(uname -r) kernel-headers-$(uname -r) gcc net-tools wget jq libffi-devel xz-devel ncurses-compat-libs libnsl gdbm-devel tk-devel sqlite-devel readline-devel texinfo -y
    else
    echo "Unsupported OS version: $LinuxDistro"
    exit 1
   fi
}
#################################### Function advance_configuration ############################################################################
advance_configuration_mig () {
logit "Started: advance_configuration_mig"
clear
echo "#######################################################################################################"
echo "Welcome to SQream MIG Installation"
echo "#######################################################################################################"
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "#######################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
echo "#######################################################################################################"
read -p "Will this Server host METADATA SERVER service ? (Y/n) " Yn
echo "#######################################################################################################"
case $Yn in
n ) 
echo "#######################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "#######################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
echo "#######################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "#######################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
logit "Success: advance_configuration"
create_storage
permission_sqream
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file_mig
install_sqream_services_mig
check_monit_service_health_no_meta_mig
limitQuery_no_meta_mig
;;
* ) 
echo "Continue with Standard SQream Installation"
logit "Success: Continue with Standard SQream Installation"
metadataServerIp=$machineip
echo "#######################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "#######################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
done
logit "Success: Storage Path is $cluster"
logit "Success: function advance_configuration"
create_storage
permission_sqream
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file_mig
install_sqream_services_mig
check_monit_service_health_mig
limitQuery_mig
 ;;
esac
}
##################################### verify_and_extract #######################################################################################
verify_and_extract_mig()
{
logit "Started verify_and_extract"
#clear
echo "################################################################################"
echo "Starting SQreamDB MIG installation Please wait While Extracting TAR file" 
echo "################################################################################"
if
[ -d /tmp/sqreampkg ];then
rm -rf /tmp/sqreampkg > /dev/null
mkdir -p /tmp/sqreampkg > /dev/null
tar -C /tmp/sqreampkg/ -zxf $TARFILE --checkpoint=.1000
echo " Done, Continue with Installation "
logit "Success: /tmp/sqreampkg  deleted, Continue with Installation "
else
mkdir -p /tmp/sqreampkg > /dev/null
logit "Success: /tmp/sqreampkg created"
tar -C /tmp/sqreampkg/ -zxf $TARFILE --checkpoint=.1000
echo "################################################################################"
echo " Done, Continue with Installation "
echo "################################################################################"
fi
logit "Success: verify_and_extract"
}
################################# Function to generate and update config files Monit ########################################################
generate_config_files_monit_mig() {
logit "Started generate_config_files_monit_mig"
    gpu_id=$1  
    worker_count=$2
    i=0    
        sport=5099
        port=4999
        while [ $i -lt $worker_count ]; do
        ##################################################################################################
        # Copy template files ############################################################################
        ##################################################################################################
        config_file="sqream${current_worker_id}_config.json"
        cp default_config.json "$config_file"
        config_service_file="sqream${current_worker_id}-service.conf"
	      cp default_service.conf "$config_service_file"
        service_file="sqream${current_worker_id}.service"
        cp default.service "$service_file"
        ##################################################################################################
        # Update "gpu" and "cudaMemQuota" in the config file #############################################
        ##################################################################################################
        #sed -i "s/\"gpu\": 0,/\"gpu\": $gpu_id,/" "$config_file"
        #sed -i "s/\"cudaMemQuota\": 90,/\"cudaMemQuota\": $new_cuda,/" "$config_file"
        sed -i "s|@regular_port@|$((port + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sslport@|$((sport + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sqream_00@|sqream_0${current_worker_id}|g" "$config_file"
        sed -i "s/\SERVICE_NAME\=sqream/\SERVICE_NAME\=sqream$current_worker_id/" "$config_service_file"
        sed -i "s|@sqream@|sqream${current_worker_id}.log|g" "$config_service_file"
        sed -i "s|@sqreamX-service.conf@|sqream${current_worker_id}-service.conf|g" "$service_file"
                ######################### Monit X times###########################################################
        echo "#SQREAM$current_worker_id-START" >> /etc/monit.d/monitrc
        echo "check process sqream$current_worker_id with pidfile /var/run/sqream$current_worker_id.pid" >> /etc/monit.d/monitrc
        echo start program = ' "/usr/bin/systemctl start 'sqream$current_worker_id'"' >> /etc/monit.d/monitrc
        echo stop program = ' "/usr/bin/systemctl stop 'sqream$current_worker_id'"' >> /etc/monit.d/monitrc
        echo "#SQREAM$current_worker_id-END" >> /etc/monit.d/monitrc
        ## Add Varibales X times##########################################################################
        current_worker_id=$((current_worker_id + 1))
        i=$((i + 1))
        done
        logit "Success: generate_config_files_monit_mig" 
        install_legacy_mig
        install_metadata
        #sudo systemctl enable monit > /dev/null 2&>1
        #sudo monit reload > /dev/null         
        #################################################################################################    
        
}
############################################## generate_config_files ############################################################################
generate_config_files_mig() {
logit "Started generate_config_files_mig"
    gpu_id=$1
    worker_count=$2
    i=0    
    
        sport=5099
        port=4999
        while [ $i -lt $worker_count ]; do
        ##################################################################################################
        # Copy template files ############################################################################
        ##################################################################################################
        config_file="sqream${current_worker_id}_config.json"
        cp default_config.json "$config_file"
        config_service_file="sqream${current_worker_id}-service.conf"
	      cp default_service.conf "$config_service_file"
        service_file="sqream${current_worker_id}.service"
        cp default.service "$service_file"
        ##################################################################################################
        # Update "gpu" and "cudaMemQuota" in the config file #############################################
        ##################################################################################################
        sed -i "s/\"gpu\": 0,/\"gpu\": $gpu_id,/" "$config_file"
        sed -i "s/\"cudaMemQuota\": 90,/\"cudaMemQuota\": $new_cuda,/" "$config_file"
        sed -i "s|@regular_port@|$((port + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sslport@|$((sport + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sqream_00@|sqream_0${current_worker_id}|g" "$config_file"
        sed -i "s/\SERVICE_NAME\=sqream/\SERVICE_NAME\=sqream$current_worker_id/" "$config_service_file"
        sed -i "s|@sqream@|sqream${current_worker_id}.log|g" "$config_service_file"
        sed -i "s|@sqreamX-service.conf@|sqream${current_worker_id}-service.conf|g" "$service_file"
        ######################### Monit X times###########################################################
        echo "#SQREAM$current_worker_id-START" >> /etc/sqream/monitrc
                echo "check process sqream$current_worker_id with pidfile /var/run/sqream$current_worker_id.pid" >> /etc/sqream/monitrc
        echo start program = ' "/usr/bin/systemctl start 'sqream$current_worker_id'"' >> /etc/sqream/monitrc
        echo stop program = ' "/usr/bin/systemctl stop 'sqream$current_worker_id'"' >> /etc/sqream/monitrc
        echo "#SQREAM$current_worker_id-END" >> /etc/sqream/monitrc
        ## Add Varibales X times##########################################################################
        
        current_worker_id=$((current_worker_id + 1))
        i=$((i + 1))
        done
        install_legacy_mig
        install_metadata
        ################################################################################################# 
        logit "Success: generate_config_files_mig"    
}
#################### formula_advance #################################################################################################################
formula_advance_mig () {
logit "Started: formula_advance_mig"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "#######################################################################################################"
echo "Number of GPUs: $num_gpus"
migs=$(nvidia-smi -L |grep MIG |wc -l)

echo "#######################################################################################################"
echo "Total Number of SQream Workers : $migs"
worker_count_gpu=$migs
create_config_template_file
generate_config_files "0" "$worker_count_gpu"    

logit "Success: formula_advance_mig"
}

##################################### Function formula_advance #################################################################################
formula_advance_monit_mig () {
logit "Started: formula_advance_monit_mig"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "#######################################################################################################"
echo "Number of GPUs: $num_gpus"
migs=$(nvidia-smi -L |grep MIG |wc -l)
echo "#######################################################################################################"
echo "Total Number of SQream Workers : $migs"
worker_count_gpu=$migs
echo "#######################################################################################################"
    current_worker_id=1
    logit "Success: formula_advance_monit_mig"  
    create_config_template_file_mig
    gpu_id=0
    generate_config_files_monit_mig "$gpu_id" "$worker_count_gpu"   
}
###### check_monit_service_health #########################################################################################################
check_monit_service_health_mig () {
logit "Started check_monit_service_health_mig"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
#clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: check_monit_service_health_mig"
monit
formula_advance_monit_mig
echo "###############################################################################"
sleep 2
else
#clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: check_monit_service_health_mig"
sleep 2
monit_backup
formula_advance_mig
fi
}
############################# limitQuery #####################################################################################################
limitQuery_mig () {
logit "Started limitQuery_mig"
if [[ $new_limitQueryMemoryGB -ge 1 ]];then
logit "Success : limitQuery check"
custom_limitQuery
else
logit "Success : limitQuery_mig"
default_limitQuery_mig
fi
}
################################ default_limitQuery ###########################################################################################
default_limitQuery_mig () {
logit "Started:  default_limitQuery_mig"
copy_files
total_ram_meta
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"       
done
logit "Success:  default_limitQuery_mig"        
install_legacy_mig
}
########################## limitQuery no meta ###############################################################################################
limitQuery_no_meta_mig () {
logit "Started:  limitQuery_no_meta_mig"
copy_files
total_ram
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"       
done
logit "Success:  limitQuery_no_meta_mig"        
install_legacy_mig
} 
################################ Function to Create SQream Legacy Conf File #####################################################################
install_legacy_mig()
{
logit "Started install_legacy_mig"
cat <<EOF | tee /etc/sqream/sqream_config_legacy.json > /dev/null
{
"diskSpaceMinFreePercent": 1,
    "DefaultPathToLogs": "${cluster}/logs/",
    "enableLogDebug": false,
    "insertCompressors": 8,
    "insertParsers": 8,
    "isUnavailableNode": false,
    "logBlackList": "webui",
    "logDebugLevel": 6,
    "nodeInfoLoggingSec": 60,
    "useClientLog": true,
    "useMetadataServer": true,
    "spoolMemoryGB": $spoolMemoryGB,
    "queryTimeoutMinutes": 0,
    "waitForClientSeconds": 18000
}
EOF
logit "Success: install_legacy_mig"
}
############################# SQream Config Json ###################################################################
create_config_template_file_mig(){
logit "Started: create_config_template_file_mig"
cat <<EOF | tee default_config.json > /dev/null
{
    "cluster": "$cluster",
    "cudaMemQuota": 96,
    "gpu": 0,
    "legacyConfigFilePath": "sqream_config_legacy.json",
    "licensePath": "/etc/sqream/license.enc",
    "limitQueryMemoryGB": limitQueryMemoryGB,
    "machineIP": "$machineip",
    "metadataServerIp": "$metadataServerIp",
    "metadataServerPort": 3105,
    "port": @regular_port@,
    "instanceId": "@sqream_00@",
    "portSsl": @sslport@,
    "initialSubscribedServices": "sqream",
    "useConfigIP": true
}
EOF
logit "Success: create_config_template_file_mig"
}
############################# SQream Servic Config #################################################################
create_service_config_template_file_mig(){
logit "Started: create_service_config_template_file_mig"
echo 'SERVICE_NAME=sqream
RUN_USER=sqream
DIR=/usr/local/sqream
BINDIR=/usr/local/sqream/bin/
LOGFILE=/var/log/sqream/@sqream@

CUDA_VISIBLE_DEVICES=
NUMA_NODE=
' > default_service.conf
logit "Success: create_service_config_template_file_mig"
}
############################# SQream Service.Service ###############################################################
install_sqream_services_mig(){
logit "Started: install_sqream_services_mig"
cat > default.service << 'EOM'
[Unit]
After=serverpicker.service
Description=SQream SQL Server
Documentation=http://docs.sqream.com/latest/manual/

[Service]
Type=simple
EnvironmentFile=/etc/sqream/sqream1-service.conf

# RUN_USER, DIR, SERVICE_NAME, LOGFILE, CUDA_VISIBLE_DEVICES, NUMA_NODE come from the EnvironmentFile
ExecStart=/bin/su - ${RUN_USER} -c 'export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES}; source /etc/sqream/sqream_env.sh && exec /usr/bin/numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} "${DIR}/bin/sqreamd" -config "/etc/sqream/${SERVICE_NAME}_config.json" &>> "${LOGFILE}"'
ExecStartPost=/bin/sh -c 'sleep 2; /bin/ps --ppid ${MAINPID} -o pid= > /var/run/${SERVICE_NAME}.pid'
ExecStop=/bin/sh -c '/bin/kill -9 "$(cat /var/run/${SERVICE_NAME}.pid)"'
ExecStopPost=/bin/rm -f /var/run/${SERVICE_NAME}.pid
ExecReload=/bin/sh -c '/bin/kill -s HUP "$(cat /var/run/${SERVICE_NAME}.pid)"'

KillMode=process
TimeoutSec=30s

[Install]
WantedBy=multi-user.target
EOM
logit "Success: install_sqream_services_migg"
}
###################################Check Permission sqream:sqream on Cluster ###################################################################
permission_sqream () {
logit "Started permission_sqream"
permission=$(stat -c  %G:%U $cluster)
if [[ $permission == sqream:sqream ]]; then
  echo "Cluster Permission is OK"
  logit "Success: permission_sqream > Cluster Permission is OK"
  else
          echo "Please fix Cluster permission to sqream:sqream"
          logit "Error: Please fix Cluster permission to sqream:sqream"
fi
logit "Success: permission_sqream"
}
############################# MIG Setup ############################################################################
sqream_mig_setup(){
logit "Started: sqream_mig_setup"
clear
echo "##########################################################"
echo "Welcome to SQreamDB with MIG Installation support"
echo "##########################################################"
echo "##########################################################"
echo "Please choose MIG PROFILE ID and MIG INSTANCES PER GPU"
echo "##########################################################"
sleep 3
sudo nvidia-smi mig -lgip
echo "Please enter MIG PROFILE ID:"
read mipid
echo "##########################################################"
echo "Please enter MIG INSTANCES PER GPU:"
read mipg
echo "##########################################################"
cat > /usr/local/sbin/sqream-mig-setup.sh << 'EOM'
#!/bin/bash
# sqream-mig-setup.sh
#
# Recreate MIG layout on all GPUs and regenerate /etc/sqream/sqreamN-service.conf
# so that each SQream instance is bound to exactly one MIG slice with the correct
# NUMA node, taken directly from `nvidia-smi topo -m`.

set -euo pipefail

CONF_DIR="/etc/sqream"
#MIG_PROFILE_ID=15          # MIG 1g.20gb profile ID on A100 80GB (1g.20gb)
MIG_PROFILE_ID=mig_pr_id         # MIG 1g.20gb profile ID on A100 80GB (1g.20gb)
MIG_INSTANCES_PER_GPU=mig_in_per_gpu    # Number of MIG instances per GPU

log()  { echo "[sqream-mig-setup] $*" >&2; }
fail() { log "ERROR: $*"; exit 1; }

# ---------- Helper: get NUMA node for a GPU index via topo ----------
get_numa_node_for_gpu() {
    local gpu_index="$1"
    local numa

    # Use the same logic you tested by hand, but filter to the specific GPU index
    numa="$(nvidia-smi topo -m 2>/dev/null | awk -v idx="$gpu_index" '
        NR > 1 && $1 ~ /^GPU[0-9]+$/ {
            g = $1
            sub("GPU", "", g)
            if (g == idx) {
                print $(NF-1)
                exit
            }
        }')"

    if [[ "$numa" =~ ^[0-9]+$ ]]; then
        log "INFO: topo reports GPU ${gpu_index} NUMA node ${numa}"
        echo "$numa"
        return 0
    fi

    log "WARN: could not get NUMA node from topo for GPU ${gpu_index}, defaulting to 0 (got: '${numa}')"
    echo "0"
    return 0
}

# ---------- Helper: write one sqreamN-service.conf ----------
write_sqream_conf() {
    local conf_file="$1"      # /etc/sqream/sqreamN-service.conf
    local mig_uuid="$2"
    local numa_node="$3"

    # Load existing values if present
    local SERVICE_NAME RUN_USER DIR BINDIR LOGFILE
    SERVICE_NAME=""
    RUN_USER=""
    DIR=""
    BINDIR=""
    LOGFILE=""

    if [[ -f "$conf_file" ]]; then
        # shellcheck source=/dev/null
        source "$conf_file" || true
    fi

    # Derive SERVICE_NAME from filename if missing
    if [[ -z "${SERVICE_NAME:-}" ]]; then
        SERVICE_NAME="$(basename "$conf_file" | sed 's/-service\.conf$//')"
    fi

    # Sensible defaults if missing
    RUN_USER="${RUN_USER:-sqream}"
    DIR="${DIR:-/usr/local/sqream}"
    BINDIR="${BINDIR:-/usr/local/sqream/bin/}"
    LOGFILE="${LOGFILE:-/var/log/sqream/${SERVICE_NAME}.log}"

    cat > "$conf_file" <<EOF
SERVICE_NAME=${SERVICE_NAME}
RUN_USER=${RUN_USER}
DIR=${DIR}
BINDIR=${BINDIR}
LOGFILE=${LOGFILE}

CUDA_VISIBLE_DEVICES=${mig_uuid}
NUMA_NODE=${numa_node}
EOF

    log "Updated ${conf_file}: CUDA_VISIBLE_DEVICES=${mig_uuid}, NUMA_NODE=${numa_node}"
}

# ---------- 1. Discover GPUs ----------
if ! command -v nvidia-smi >/dev/null 2>&1; then
    fail "nvidia-smi not found in PATH"
fi

mapfile -t GPU_INDICES < <(nvidia-smi --query-gpu=index --format=csv,noheader 2>/dev/null)

if [[ "${#GPU_INDICES[@]}" -eq 0 ]]; then
    fail "No GPUs detected by nvidia-smi"
fi

log "Found GPUs: ${GPU_INDICES[*]}"

# ---------- 2. Ensure MIG mode is enabled on all GPUs ----------
for gpu in "${GPU_INDICES[@]}"; do
    local_mode="$(nvidia-smi --query-gpu=mig.mode.current --format=csv,noheader -i "$gpu" 2>/dev/null | head -n1 || true)"

    if [[ -z "$local_mode" ]]; then
        log "WARN: Could not read mig.mode.current for GPU $gpu; assuming MIG mode is enabled because nvidia-smi shows MIG M. Enabled."
        continue
    fi

    if [[ "$local_mode" != "Enabled" ]]; then
        fail "GPU $gpu MIG mode is not Enabled (current: $local_mode). Enable once with 'nvidia-smi -i $gpu -mig 1' and reboot."
    fi
done

# ---------- 3. Recreate MIG layout on all GPUs ----------
for gpu in "${GPU_INDICES[@]}"; do
    log "Cleaning existing MIG instances on GPU $gpu"
    nvidia-smi mig -dci -i "$gpu" || true
    nvidia-smi mig -dgi -i "$gpu" || true

    # Build e.g. "15,15,15,15" list for -cgi
    profile_list=""
    for ((i=0; i< MIG_INSTANCES_PER_GPU; i++)); do
        if [[ -z "$profile_list" ]]; then
            profile_list="${MIG_PROFILE_ID}"
        else
            profile_list="${profile_list},${MIG_PROFILE_ID}"
        fi
    done

    log "Creating ${MIG_INSTANCES_PER_GPU}x MIG profile ID ${MIG_PROFILE_ID} on GPU $gpu"
    nvidia-smi mig -cgi "$profile_list" -C -i "$gpu"
done

# ---------- 4. Collect MIG UUIDs in (GPU, MIG) order ----------
log "Collecting MIG UUIDs from nvidia-smi -L"

# MIG_ENTRIES: each line is "<gpu_index> <MIG-UUID>"
mapfile -t MIG_ENTRIES < <(
    nvidia-smi -L | awk '
        /^GPU [0-9]+:/ {
            # Line looks like: "GPU 0: NVIDIA A100 ..."
            # $1 = "GPU", $2 = "0:"
            idx = $2
            sub(":", "", idx)
            gpu_index = idx
        }
        /^[[:space:]]+MIG/ {
            # Indented MIG line, e.g.:
            #   MIG 1g.20gb     Device  0: (UUID: MIG-xxxx)
            if (match($0, /(MIG-[^ )]+)/, m)) {
                print gpu_index, m[1]
            }
        }
    '
)

if [[ "${#MIG_ENTRIES[@]}" -eq 0 ]]; then
    fail "No MIG devices found after reconfiguration"
fi

log "Found MIG devices:"
for line in "${MIG_ENTRIES[@]}"; do
    log "  $line"
done

# ---------- 5. Build GPU→NUMA map using get_numa_node_for_gpu ----------
declare -A GPU_NUMA
for gpu in "${GPU_INDICES[@]}"; do
    numa_node="$(get_numa_node_for_gpu "$gpu")"
    GPU_NUMA["$gpu"]="$numa_node"
done

# Log the map
for gpu in "${!GPU_NUMA[@]}"; do
    log "GPU ${gpu} → NUMA node ${GPU_NUMA[$gpu]} (from topo)"
done

# ---------- 6. Get list of sqreamN-service.conf files ----------
mapfile -t SQREAM_CONF_FILES < <(ls "${CONF_DIR}"/sqream*-service.conf 2>/dev/null | sort -V || true)

if [[ "${#SQREAM_CONF_FILES[@]}" -eq 0 ]]; then
    fail "No ${CONF_DIR}/sqream*-service.conf files found"
fi

TOTAL_MIG="${#MIG_ENTRIES[@]}"
TOTAL_SERVICES="${#SQREAM_CONF_FILES[@]}"

log "Total MIG devices: ${TOTAL_MIG}"
log "Total SQream service configs: ${TOTAL_SERVICES}"

if (( TOTAL_MIG < TOTAL_SERVICES )); then
    fail "Not enough MIG devices (${TOTAL_MIG}) for ${TOTAL_SERVICES} service configs"
fi

# ---------- 7. Assign MIGs to service configs ----------
log "Assigning MIG devices to SQream service configs"

for ((i=0; i< TOTAL_SERVICES; i++)); do
    conf_file="${SQREAM_CONF_FILES[$i]}"
    entry="${MIG_ENTRIES[$i]}"

    gpu_index="$(awk '{print $1}' <<< "$entry")"
    mig_uuid="$(awk '{print $2}' <<< "$entry")"
    numa_node="${GPU_NUMA[$gpu_index]:-0}"

    write_sqream_conf "$conf_file" "$mig_uuid" "$numa_node"
done

log "MIG + SQream configuration completed successfully."
EOM
sudo sed -i "s/^MIG_PROFILE_ID=.*/MIG_PROFILE_ID=$mipid/" /usr/local/sbin/sqream-mig-setup.sh
sudo sed -i "s/^MIG_INSTANCES_PER_GPU=.*/MIG_INSTANCES_PER_GPU=$mipg/" /usr/local/sbin/sqream-mig-setup.sh
sudo chmod +x /usr/local/sbin/sqream-mig-setup.sh
logit "Success: sqream_mig_setup"
}
##################### MIG Service #################################################################################
mig_service(){
logit "Started: mig_service"
cat > /etc/systemd/system/sqream-mig-setup.service << 'EOM'
[Unit]
Description=Configure MIG layout and SQream service configs
After=local-fs.target sysinit.target
Before=monit.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/sqream-mig-setup.sh

[Install]
WantedBy=multi-user.target
EOM
sudo systemctl daemon-reload
sudo systemctl enable sqream-mig-setup.service
#sudo systemctl start sqream-mig-setup.service &> /dev/null
logit "Success: mig_service"
}
################################ re_meta_copy_files ############################################################################################
re_meta_copy_files() {
  logit "Started metadata_copy_files"
sudo mv metadataserver.conf /etc/sqream
sudo mv metadataserver.service /etc/sqream
sudo mv metadataserver_config.json /etc/sqream 
sudo mv  server_picker* /etc/sqream
sudo mv  serverpicker* /etc/sqream
sudo mv /etc/sqream/metadataserver.service /usr/lib/systemd/system/
sudo mv /etc/sqream/serverpicker.service /usr/lib/systemd/system/
sudo chown -R sqream:sqream /usr/local/sqream
sudo chown -R sqream:sqream /etc/sqream
sudo systemctl daemon-reload
logit "Success: metadata_copy_files"
}
############################################## Reconfig metadata_only ##########################################################################
re_metadata_only () {
logit "Started: metadata_only"
clear
echo "##########################################################################################################################################"
echo "Reconfig SQreamDB Metadata Server only"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Machine IP is $machineip"
echo "##########################################################################################################################################"
echo "Enter Your SQream Cluster Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
logit "Success: metadata_only"
echo "
##################################################################################################
##################################################################################################
# SQream Installation Completed to Start SQream add License file to /etc/sqream and then         #
# sudo systemctl start monit                                                                     #
# sudo monit start all                                                                           #
# sudo monit status                                                                              #
# To View Installer logfile        > more /tmp/sqream-installV1.log                              #
# To View Summary logfile          > more /tmp/sqreamdb-summary.log                              #
##################################################################################################"
}
############## Monit ###########################################################################################################################
monit () {
logit "Started monit"
cat <<EOF | sudo tee /etc/monit.d/monitrc > /dev/null
set daemon  5              # check services at 30 seconds intervals
set logfile syslog

#METADATASERVER-START
check process metadataserver with pidfile /var/run/metadataserver.pid
start program = "/usr/bin/systemctl start metadataserver"
stop program = "/usr/bin/systemctl stop metadataserver"
#METADATASERVER-END
#SERVERPICKER-START
check process serverpicker with pidfile /var/run/serverpicker.pid
start program = "/usr/bin/systemctl start serverpicker"
stop program = "/usr/bin/systemctl stop serverpicker"
#SERVERPICKER-END
EOF
sudo cp /etc/monit.d/monitrc /etc/sqream
logit "Success: Prepare monit Function"
}
############## Monit No Meta ####################################################################################################################
monit_no_meta () {
logit "Started monit_no_meta"
cat <<EOF | sudo tee /etc/monit.d/monitrc > /dev/null
set daemon  5              # check services at 30 seconds intervals
set logfile syslog

EOF
sudo cp /etc/monit.d/monitrc /etc/sqream
logit "Success: Prepare monit_no_meta Function"
}
############################################## metadata_only ###############################################################################
metadata_only () {
logit "Started: metadata_only"
clear
echo "##########################################################################################################################################"
echo "Install SQreamDB Metadata Server only"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Machine IP is $machineip"
echo "##########################################################################################################################################"
echo "Enter Your SQream Cluster Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
logit "Success: metadata_only"
}
########################################### AWS ###############################################################################################
#################### formula_advance #################################################################################################################
formula_advance_aws () {
logit "Started: formula_advance_aws"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "##########################################################################################################################################"
echo "Number of GPUs: $num_gpus"
i=0
while [ $i -lt $num_gpus ]; do
echo "##########################################################################################################################################"
echo "Total GPU Memory per GPU Card ID"
echo "GPU $i: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i $i) MB"
echo "##########################################################################################################################################"
    i=$((i + 1))
done
current_worker_id=1
gpu_id=0
while [ $gpu_id -lt $num_gpus ]; do
echo "Enter the number of workers you want to run on GPU $gpu_id: "
read worker_count_gpu
echo "##########################################################################################################################################"
while [ -z "$worker_count_gpu" ]
do	printf "Enter the number of workers you want to run on GPU $gpu_id: "
	read -r worker_count_gpu
	[ -z "$worker_count_gpu" ] && echo 'worker_count_gpu cannot be empty; try again.'
done

read -p "Do You want to customize cudaMemQuota ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y )
echo "Enter the desired cudaMemQuota value "
read new_cuda
echo "##########################################################################################################################################"
 ;;
* )
echo "##########################################################################################################################################"
echo "Using Default Value ( 96% / worker_count ) "
new_cuda=$((96 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac

    create_config_template_file_aws
    generate_config_files "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done
logit "Success: formula_advance_aws"
}
##################################### Function formula_advance #################################################################################
formula_advance_monit_aws () {
logit "Started: formula_advance_monit_aws"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "##########################################################################################################################################"
echo "Number of GPUs: $num_gpus"
i=0
while [ $i -lt $num_gpus ]; do
echo "##########################################################################################################################################"
echo "Total GPU Memory per GPU Card ID"
echo "GPU $i: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i $i) MB"
echo "##########################################################################################################################################"
    i=$((i + 1))
done
current_worker_id=1
gpu_id=0
while [ $gpu_id -lt $num_gpus ]; do
echo "Enter the number of workers you want to run on GPU $gpu_id: "
read worker_count_gpu
echo "##########################################################################################################################################"
while [ -z "$worker_count_gpu" ]
do	printf "Enter the number of workers you want to run on GPU $gpu_id: "
	read -r worker_count_gpu
	[ -z "$worker_count_gpu" ] && echo 'worker_count_gpu cannot be empty; try again.'
done
read -p "Do You want to customize cudaMemQuota ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y )
echo "Enter the desired cudaMemQuota value "
read new_cuda
echo "##########################################################################################################################################"
 ;;
* )
echo "##########################################################################################################################################"
echo "Using Default Value ( 96% / worker_count ) "
new_cuda=$((96 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac

    logit "Success: formula_advance_monit_aws"
    create_config_template_file_aws
    generate_config_files_monit "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done

}
################################ custom_limitQuery #############################################################################################
custom_limitQuery_aws () {
logit "Started custom_limitQuery_aws"
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$(expr $RAM_KB / 1024)
RAM_GB=$(expr $RAM_MB / 1024)
global_limitQueryMemoryGB=$((RAM_GB * 90 / 100 ))
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((global_limitQueryMemoryGB / number_of_workers))
spoolMemoryGB=$(($limitQueryMemoryGB - 10 ))
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $new_limitQueryMemoryGB,/" "$config_file"

done
logit "Success:  custom_limitQuery_aws"
install_legacy_aws
}
################################ default_limitQuery ###########################################################################################
default_limitQuery_aws () {
logit "Started:  default_limitQuery_aws"
total_ram_meta
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"
done
logit "Success:  default_limitQuery_aws"
install_legacy_aws
}
############################# limitQuery #####################################################################################################
limitQuery_aws () {
logit "Started limitQuery_aws"
if [[ $new_limitQueryMemoryGB -ge 1 ]];then
logit "Success : limitQuery check"
custom_limitQuery
else
logit "Success : limitQuery check_aws"
default_limitQuery_aws
fi
}
########################## limitQuery no meta ###############################################################################################
limitQuery_no_meta_aws () {
logit "Started:  limitQuery_no_meta_aws"
total_ram
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"
done
logit "Success:  limitQuery_no_meta_aws"
install_legacy_aws
}
#################################################################################################################################################
################# check_monit_service_health #########################################################################################################
check_monit_service_health_aws () {
logit "Started check_monit_service_health_aws"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: check_monit_service_health"
monit
formula_advance_monit_aws
copy_files
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: check_monit_service_health_oci"
sleep 2
monit_backup
formula_advance_aws
copy_files
end
fi
}
################# check_monit_service_health_no_meta #########################################################################################################
check_monit_service_health_no_meta_aws () {
logit "Started check_monit_service_health_no_meta_aws"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: check_monit_service_health_no_meta_aws"
monit_no_meta
formula_advance_monit_aws
copy_files
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: check_monit_service_health_no_meta_aws"
sleep 2
monit_backup
formula_advance_aws
copy_files
end
fi
}
################################ Function to Create SQream Legacy Conf File #####################################################################
install_legacy_aws()
{
logit "Started install_legacy_aws"
cat <<EOF | tee /etc/sqream/sqream_config_legacy.json > /dev/null
{
    "tablespaceURL": "$bucket_path/sqream_cluster",
    "logBlackList": "webui",
    "nodeInfoLoggingSec": 0,
    "useMetadataServer": true,
    "spoolMemoryGB": $spoolMemoryGB,
    "developerMode": true,
    "reextentUse": false,
    "showFullExceptionInfo": true,
    "extentStorageFileSizeMB": 50,
    "ReadaheadBlockSize":128,
    "scaleVirtualSqreamds":1,
    "queryTimeoutMinutes": 0,
    "useLoadBalancer": true

}
EOF
logit "Success: install_legacy_aws"
}

################################ Function create_config_template_file ############################################################################
create_config_template_file_aws() {
logit "Started create_config_template_file_aws"
cat <<EOF | tee default_config.json > /dev/null
{
    "cluster": "$cluster",
    "cudaMemQuota": 90,
    "gpu": 0,
    "legacyConfigFilePath": "sqream_config_legacy.json",
    "licensePath": "/etc/sqream/license.enc",
    "metadataPath": "$cluster/leveldb",
    "tempPath": "$bucket_path/sqream_cluster/temp",
    "limitQueryMemoryGB": limitQueryMemoryGB,
    "machineIP": "$machineip",
    "metadataServerIp": "$metadataServerIp",
    "metadataServerPort": 3105,
    "port": @regular_port@,
    "instanceId": "@sqream_00@",
    "portSsl": @sslport@,
    "initialSubscribedServices": "sqream",
    "useConfigIP": true
    }
EOF
logit "Success create_config_template_file_oci"
}
###############################################################################################################################################
#################################### Function advance_configuration ############################################################################
advance_configuration_aws () {
logit "Started: advance_configuration_aws"
clear
echo "##########################################################################################################################################"
echo "Welcome to SQream Advance Configuration - AWS"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
echo "##########################################################################################################################################"
read -p "Will this Server host METADATA SERVER service ? (Y/n) " Yn
echo "##########################################################################################################################################"
case $Yn in
n )
echo "##########################################################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "##########################################################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
echo "##########################################################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
echo "##########################################################################################################################################"
echo "Please enter bucket PATH"
echo "#######################################################"
echo "Example : s3://<bucket Name>"
echo "#######################################################"
read bucket_path
echo "##########################################################################################################################################"
while [ -z "$bucket_path" ]
do	printf 'Please enter bucket PATH: '
	read -r bucket_path
	[ -z "$bucket_path" ] && echo 'bucket PATH cannot be empty; try again.'
done
echo "##########################################################################################################################################"

logit "Success: $bucket_path"
logit "Success: advance_configuration_aws complete"
create_storage
permission_sqream
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
check_monit_service_health_no_meta_aws
limitQuery_no_meta_aws
;;
* )
echo "Continue with Standard SQream Installation"
logit "Success: Continue with Standard SQream Installation"
metadataServerIp=$machineip
echo "##########################################################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
done
logit "Success: Storage Path is $cluster"
echo "##########################################################################################################################################"
echo "##########################################################################################################################################"
echo "Please enter Bucket PATH"
echo "#######################################################"
echo "Exapmle : s3://<Bucket Name>"
echo "#######################################################"
read bucket_path
echo "##########################################################################################################################################"
while [ -z "$bucket_path" ]
do	printf 'Please enter Bucket PATH: '
	read -r bucket_path
	[ -z "$bucket_path" ] && echo 'Bucket PATH cannot be empty; try again.'
done
logit "Success: $bucket_path"
logit "Success: advance_configuration_aws complete"
logit "Success: function advance_configuration_aws"
create_storage
permission_sqream
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
check_monit_service_health_aws
limitQuery_aws
 ;;
esac
}
################################################################################################################################################

############################################ OCI ###############################################################################################
################# formula_advance #################################################################################################################
formula_advance_oci () {
logit "Started: formula_advance_oci"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "##########################################################################################################################################"
echo "Number of GPUs: $num_gpus"
i=0
while [ $i -lt $num_gpus ]; do
echo "##########################################################################################################################################"
echo "Total GPU Memory per GPU Card ID"
echo "GPU $i: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i $i) MB"
echo "##########################################################################################################################################"
    i=$((i + 1))
done
current_worker_id=1
gpu_id=0
while [ $gpu_id -lt $num_gpus ]; do
echo "Enter the number of workers you want to run on GPU $gpu_id: "
read worker_count_gpu
echo "##########################################################################################################################################"
while [ -z "$worker_count_gpu" ]
do	printf "Enter the number of workers you want to run on GPU $gpu_id: "
	read -r worker_count_gpu
	[ -z "$worker_count_gpu" ] && echo 'worker_count_gpu cannot be empty; try again.'
done

read -p "Do You want to customize cudaMemQuota ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y )
echo "Enter the desired cudaMemQuota value "
read new_cuda
echo "##########################################################################################################################################"
 ;;
* )
echo "##########################################################################################################################################"
echo "Using Default Value ( 96% / worker_count ) "
new_cuda=$((96 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac

    create_config_template_file_oci
    generate_config_files "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done
logit "Success: formula_advance_oci"
}

##################################### Function formula_advance #################################################################################
formula_advance_monit_oci () {
logit "Started: formula_advance_monit_oci"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "##########################################################################################################################################"
echo "Number of GPUs: $num_gpus"
i=0
while [ $i -lt $num_gpus ]; do
echo "##########################################################################################################################################"
echo "Total GPU Memory per GPU Card ID"
echo "GPU $i: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i $i) MB"
echo "##########################################################################################################################################"
    i=$((i + 1))
done
current_worker_id=1
gpu_id=0
while [ $gpu_id -lt $num_gpus ]; do
echo "Enter the number of workers you want to run on GPU $gpu_id: "
read worker_count_gpu
echo "##########################################################################################################################################"
while [ -z "$worker_count_gpu" ]
do	printf "Enter the number of workers you want to run on GPU $gpu_id: "
	read -r worker_count_gpu
	[ -z "$worker_count_gpu" ] && echo 'worker_count_gpu cannot be empty; try again.'
done
read -p "Do You want to customize cudaMemQuota ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y )
echo "Enter the desired cudaMemQuota value "
read new_cuda
echo "##########################################################################################################################################"
 ;;
* )
echo "##########################################################################################################################################"
echo "Using Default Value ( 96% / worker_count ) "
new_cuda=$((96 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac

    logit "Success: formula_advance_monit_oci"
    create_config_template_file_oci
    generate_config_files_monit "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done

}

################# check_monit_service_health #########################################################################################################
check_monit_service_health_oci () {
logit "Started check_monit_service_health_oci"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: check_monit_service_health"
monit
formula_advance_monit_oci
copy_files
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: check_monit_service_health_oci"
sleep 2
monit_backup
formula_advance_oci
copy_files
end
fi
}
################# check_monit_service_health_no_meta #########################################################################################################
check_monit_service_health_no_meta_oci () {
logit "Started check_monit_service_health_no_meta_oci"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: check_monit_service_health_no_meta_oci"
monit_no_meta
formula_advance_monit_oci
copy_files
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: check_monit_service_health_no_meta"
sleep 2
monit_backup
formula_advance_oci
copy_files
end
fi
}
################# reconfig_monit_service_health_oci ##############################################################################################
reconfig_monit_service_health_oci () {
logit "Started reconfig_monit_service_health_oci"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: Monit is installed"
monit
formula_advance_monit_oci
move_advance_conf
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
echo "###############################################################################"
logit "Error: Monit is not installed Continue install without Monit"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: reconfig_monit_service_health_aws"
sleep 2
monit_backup
formula_advance_oci
move_advance_conf
end
fi
}
################# reconfig_monit_service_health_no_meta_oci ##############################################################################################
reconfig_monit_service_health_no_meta_oci () {
logit "Started reconfig_monit_service_health_no_meta_oci"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: Monit is installed"
monit_no_meta
formula_advance_monit_oci
move_advance_conf
end_monit
echo "###############################################################################"
logit "Success: reconfig_monit_service_health_no_meta_oci"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: reconfig_monit_service_health_no_meta_oci"
sleep 2
monit_backup
formula_advance_oci
move_advance_conf
end
fi
}
#################################### Function advance_configuration ############################################################################
advance_configuration_oci () {
logit "Started: advance_configuration"
clear
echo "##########################################################################################################################################"
echo "Welcome to SQream Advance Configuration"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
echo "##########################################################################################################################################"
read -p "Will this Server host METADATA SERVER service ? (Y/n) " Yn
echo "##########################################################################################################################################"
case $Yn in
n )
echo "##########################################################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "##########################################################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
echo "##########################################################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
echo "##########################################################################################################################################"
echo "Please enter Bucket PATH"
echo "#######################################################"
echo "Exapmle :  o2://<NameSpace>/<Bucket Name>"
echo "#######################################################"
read bucket_path
echo "##########################################################################################################################################"
while [ -z "$bucket_path" ]
do	printf 'Please enter Bucket PATH: '
	read -r bucket_path
	[ -z "$bucket_path" ] && echo 'Bucket PATH cannot be empty; try again.'
done
echo "##########################################################################################################################################"
echo "Please enter the Oci Base Region"
read OciBaseRegion
echo "##########################################################################################################################################"
while [ -z "$OciBaseRegion" ]
do	printf 'Please enter the Oci Base Region: '
	read -r OciBaseRegion
	[ -z "$OciBaseRegion" ] && echo 'Oci Base Region cannot be empty; try again.'
done
echo "##########################################################################################################################################"
echo "Please enter the Oci Access Key"
read OciAccessKey
echo "##########################################################################################################################################"
while [ -z "$OciAccessKey" ]
do	printf 'Please enter the Oci Access Key: '
	read -r OciAccessKey
	[ -z "$OciAccessKey" ] && echo 'Oci Access Key cannot be empty; try again.'
done
echo "##########################################################################################################################################"
echo "Please enter the Oci Access Secret"
read OciAccessSecret
echo "##########################################################################################################################################"
while [ -z "$OciAccessSecret" ]
do	printf 'Please enter the Oci Access Secret: '
	read -r OciAccessSecret
	[ -z "$OciAccessSecret" ] && echo 'Oci Access Secret cannot be empty; try again.'
done
logit "Success: $bucket_path"
logit "Success: $OciBaseRegion"
logit "Success: $OciAccessKey"
logit "Success: $OciAccessSecret"
logit "Success: advance_configuration complete"
create_storage
permission_sqream
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
check_monit_service_health_no_meta_oci
limitQuery_no_meta_oci
;;
* )
echo "Continue with Standard SQream Installation"
logit "Success: Continue with Standard SQream Installation"
metadataServerIp=$machineip
echo "##########################################################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
done
logit "Success: Storage Path is $cluster"
echo "##########################################################################################################################################"
echo "Please enter Bucket PATH"
echo "#######################################################"
echo "Exapmle :  o2://<NameSpace>/<Bucket Name>"
echo "#######################################################"
read bucket_path
echo "##########################################################################################################################################"
while [ -z "$bucket_path" ]
do	printf 'Please enter Bucket PATH: '
	read -r bucket_path
	[ -z "$bucket_path" ] && echo 'Bucket PATH cannot be empty; try again.'
done
echo "##########################################################################################################################################"
echo "Please enter the Oci Base Region"
read OciBaseRegion
echo "##########################################################################################################################################"
while [ -z "$OciBaseRegion" ]
do	printf 'Please enter the Oci Base Region: '
	read -r OciBaseRegion
	[ -z "$OciBaseRegion" ] && echo 'Oci Base Region cannot be empty; try again.'
done
echo "##########################################################################################################################################"
echo "Please enter the Oci Access Key"
read OciAccessKey
echo "##########################################################################################################################################"
while [ -z "$OciAccessKey" ]
do	printf 'Please enter the Oci Access Key: '
	read -r OciAccessKey
	[ -z "$OciAccessKey" ] && echo 'Oci Access Key cannot be empty; try again.'
done
echo "##########################################################################################################################################"
echo "Please enter the Oci Access Secret"
read OciAccessSecret
echo "##########################################################################################################################################"
while [ -z "$OciAccessSecret" ]
do	printf 'Please enter the Oci Access Secret: '
	read -r OciAccessSecret
	[ -z "$OciAccessSecret" ] && echo 'Oci Access Secret cannot be empty; try again.'
done
logit "Success: $bucket_path"
logit "Success: $OciBaseRegion"
logit "Success: $OciAccessKey"
logit "Success: $OciAccessSecret"
logit "Success: advance_configuration complete"
logit "Success: function advance_configuration"
create_storage
permission_sqream
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
check_monit_service_health_oci
limitQuery_oci
 ;;
esac
}
################################ Advance Reconfiguration OCI ####################################################################################
#################################### Function advance_reconfiguration ############################################################################
advance_reconfiguration_oci () {
logit "Started: advance_reconfiguration"
clear
current_ip=$(cat /etc/sqream/sqream1_config.json | grep 'machineIP' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
echo "##########################################################################################################################################"
echo "Welcome to SQream Advance reconfiguration OCI"
echo "##########################################################################################################################################"
echo "Your Current IP address is $current_ip"
logit "Success: Your Current IP address is $current_ip"
echo "##########################################################################################################################################"
read -p "Do you want to change current IP ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
        y )
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Success: You choose this IP address $machineip"
;;
        * )
echo "Stay with Current IP address is $current_ip"
logit "Success: Stay with Current IP address is $current_ip"
echo "##########################################################################################################################################"
machineip=$current_ip
;;
esac
echo "##########################################################################################################################################"
current_cluster=$(cat /etc/sqream/sqream1_config.json | grep '"cluster"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
echo "Your Current Storage is $current_cluster"
logit "Success: Your Current Storage is $current_cluster"
echo "##########################################################################################################################################"
read -p "Do you want to change current Storage Path ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y)
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Your SQream Storage Path is: $cluster"
create_storage
permission_sqream

;;
* )
echo "Stay with Current Storage Path. "
echo "##########################################################################################################################################"
cluster=$current_cluster
logit "Success: Stay with Current Storage Path: $current_cluster  "
;;
esac
echo "##########################################################################################################################################"
current_bucket_path=o2:$(cat /etc/sqream/sqream_config_legacy.json | grep '"tablespaceURL"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//' | sed 's/sqream_cluster//g' | sed 's/\/$//')
echo "Your Current Bucket PATH is $current_bucket_path"
logit "Success: Your Current Bucket PATH is $current_bucket_path"
echo "##########################################################################################################################################"
read -p "Do you want to change current Bucket PATH ? (y/N) " yN
case $yN in
y )
echo "Please enter Bucket PATH"
echo "#######################################################"
echo "Exapmle :  o2://<NameSpace>/<Bucket Name>"
echo "#######################################################"
read bucket_path
echo "##########################################################################################################################################"
while [ -z "$bucket_path" ]
do	printf 'Please enter Bucket PATH: '
	read -r bucket_path
	[ -z "$bucket_path" ] && echo 'Bucket PATH cannot be empty; try again.'
done
;;
* )
echo "Stay with Current Bucket PATH. "
logit "Stay with Current Bucket PATH $current_bucket_path. "
bucket_path=$current_bucket_path
;;
esac

echo "##########################################################################################################################################"
current_OciBaseRegion=$(cat /etc/sqream/sqream1_config.json | grep '"OciBaseRegion"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//' | sed 's/\/$//')
echo "Your Current Oci Base Region is $current_OciBaseRegion"
logit "Success: Your Current Oci Base Region is $current_OciBaseRegion"
echo "##########################################################################################################################################"
read -p "Do you want to change current Oci Base Region ? (y/N) " yN
case $yN in
y)
echo "Please enter the Oci Base Region"
read OciBaseRegion
echo "##########################################################################################################################################"
while [ -z "$OciBaseRegion" ]
do	printf 'Please enter the Oci Base Region: '
	read -r OciBaseRegion
	[ -z "$OciBaseRegion" ] && echo 'Oci Base Region cannot be empty; try again.'
done
;;
* )
echo "Stay with Current Oci Base Region. "
logit "Stay with Current Oci Base Region $OciBaseRegion. "
OciBaseRegion=$current_OciBaseRegion
;;
esac
echo "##########################################################################################################################################"
current_OciAccessKey=$(cat /etc/sqream/sqream1_config.json | grep '"OciAccessKey"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//' | sed 's/\/$//')
echo "Your Current Oci Access Key is $current_OciAccessKey"
logit "Success: Your Current Oci Access Key is $current_OciAccessKey"
echo "##########################################################################################################################################"
read -p "Do you want to change current Oci Access Key ? (y/N) " yN
case $yN in
y)
echo "##########################################################################################################################################"
echo "Please enter the Oci Access Key"
read OciAccessKey
echo "##########################################################################################################################################"
while [ -z "$OciAccessKey" ]
do	printf 'Please enter the Oci Access Key: '
	read -r OciAccessKey
	[ -z "$OciAccessKey" ] && echo 'Oci Access Key cannot be empty; try again.'
done
;;
* )
echo "Stay with Current Oci Access Key. "
logit "Stay with Current Oci Access Key $current_OciAccessKey . "
OciAccessKey=$current_OciAccessKey
;;
esac
echo "##########################################################################################################################################"
current_OciAccessSecret=$(cat /etc/sqream/sqream1_config.json | grep '"OciAccessSecret"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/[ "]//')
logit "Success: Your Current Oci Access Secret is $current_OciAccessSecret"
echo "Your Current Oci Access Secret is $current_OciAccessSecret"
read -p "Do you want to change current Oci Access Secret ? (y/N) " yN
case $yN in
y)
echo "##########################################################################################################################################"
echo "Please enter the Oci Access Secret"
read OciAccessSecret
echo "##########################################################################################################################################"
while [ -z "$OciAccessSecret" ]
do	printf 'Please enter the Oci Access Secret: '
	read -r OciAccessSecret
	[ -z "$OciAccessSecret" ] && echo 'Oci Access Secret cannot be empty; try again.'
done
;;
* )
echo "Stay with Current Oci Access Secret. "
logit "Success: Stay with Current Oci Access Secret $current_OciAccessSecret"
OciAccessSecret=$current_OciAccessSecret
;;
esac
echo "##########################################################################################################################################"
current_metadata=$(cat /etc/sqream/sqream1_config.json | grep 'metadataServerIp' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
if [ $current_ip = $current_metadata ]; then
echo "Currently Metadata server is local on this PC"
fi
echo "Current METADATA SERVER is $current_metadata"
logit "Success: Current METADATA SERVER is $current_metadata"
echo "##########################################################################################################################################"

read -p "Do you want to change current METADATA SERVER service ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in

y )
echo "##########################################################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "##########################################################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "##########################################################################################################################################"
if [ $machineip = $metadataServerIp ]; then
echo "Metadata Service will be local"
logit "Success: Metadata Server will be Local"
sleep 2
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_oci
limitQuery_oci
else 
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
sleep 2
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_no_meta_oci
limitQuery_no_meta_oci
fi
;;

* )

echo "Stay with Current Metadata Server"
sleep 2
if [ $machineip = $current_metadata ]; then
metadataServerIp=$current_metadata
logit "Success: Metadata Server will be Local"
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_oci
limitQuery_oci
else 
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
sleep 2
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_no_meta_oci
limitQuery_no_meta_oci
fi

;;
esac
logit "Success advance reconfiguration OCI"
}
################################ Function to Create SQream Legacy Conf File #####################################################################
install_legacy_oci()
{
logit "Started install_legacy_oci"
cat <<EOF | tee /etc/sqream/sqream_config_legacy.json > /dev/null
{
    "tablespaceURL": "$bucket_path/sqream_cluster",
    "logBlackList": "webui",
    "nodeInfoLoggingSec": 0,
    "useMetadataServer": true,
    "spoolMemoryGB": $spoolMemoryGB,    
    "developerMode": true,
    "reextentUse": false,
    "showFullExceptionInfo": true,
    "extentStorageFileSizeMB": 50,
    "ReadaheadBlockSize":128,
    "scaleVirtualSqreamds":1,
    "queryTimeoutMinutes": 0,
    "useLoadBalancer": true

}
EOF
logit "Success: install_legacy_oci"
}

################################ Function create_config_template_file ############################################################################
create_config_template_file_oci() {
logit "Started create_config_template_file_oci"
cat <<EOF | tee default_config.json > /dev/null
{
    "cluster": "$cluster",
    "cudaMemQuota": 90,
    "gpu": 0,
    "legacyConfigFilePath": "sqream_config_legacy.json",
    "licensePath": "/etc/sqream/license.enc",
    "metadataPath": "$cluster/leveldb",
    "tempPath": "$bucket_path/sqream_cluster/temp",
    "limitQueryMemoryGB": limitQueryMemoryGB,
    "machineIP": "$machineip",
    "metadataServerIp": "$metadataServerIp",
    "metadataServerPort": 3105,
    "port": @regular_port@,
    "instanceId": "@sqream_00@",
    "portSsl": @sslport@,
    "initialSubscribedServices": "sqream",
    "useConfigIP": true,
    "OciBaseRegion": "$OciBaseRegion",
    "OciVerifySsl": false,
    "OciAccessKey": "$OciAccessKey",
    "OciAccessSecret": "$OciAccessSecret"
}
EOF
logit "Success create_config_template_file_oci"
}
###############################################################################################################################################
################################ custom_limitQuery #############################################################################################
custom_limitQuery_oci () {
logit "Started custom_limitQuery_oci"
total_ram
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $new_limitQueryMemoryGB,/" "$config_file"

done
logit "Success:  custom_limitQuery_oci"
install_legacy_oci
}
################################ default_limitQuery ###########################################################################################
default_limitQuery_oci () {
logit "Started:  default_limitQuery_oci"
total_ram_meta
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"
done
logit "Success:  default_limitQuery_oci"
install_legacy_oci
}
############################# limitQuery #####################################################################################################
limitQuery_oci () {
logit "Started limitQuery_oci"
if [[ $new_limitQueryMemoryGB -ge 1 ]];then
logit "Success : limitQuery check"
custom_limitQuery
else
logit "Success : limitQuery check_oci"
default_limitQuery_oci
fi
}
########################## limitQuery no meta ###############################################################################################
limitQuery_no_meta_oci () {
logit "Started:  default_limitQuery_oci"
total_ram
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"
done
logit "Success:  default_limitQuery_oci"
install_legacy_oci
}
############################################ LDAP Connect #######################################################################################
ldap_connect () {
echo "TLS_REQCERT     allow" >> /etc/openldap/ldap.conf
clear
echo "#############################################################"
echo "Please enter LDAP User Name"
read username
echo "#############################################################"
echo "Please enter LDAP IP Address"
read ldapip
echo "#############################################################"
echo "Done.  SQream is ready for LDAP"
echo "Please restart SQreamDB"
echo "#############################################################"
/usr/local/sqream/bin/sqream sql --username=sqream --password=sqream -d master --port=5000  -c "CREATE ROLE $username;" &> /dev/null
/usr/local/sqream/bin/sqream sql --username=sqream --password=sqream -d master --port=5000  -c "GRANT LOGIN TO $username;" &> /dev/null
/usr/local/sqream/bin/sqream sql --username=sqream --password=sqream -d master --port=5000  -c "GRANT CONNECT ON DATABASE master TO $username;" &> /dev/null
/usr/local/sqream/bin/sqream sql --username=sqream --password=sqream -d master --port=5000  -c "ALTER SYSTEM SET authenticationMethod = 'ldap';" &> /dev/null
/usr/local/sqream/bin/sqream sql --username=sqream --password=sqream -d master --port=5000  -c "ALTER SYSTEM SET ldapIpAddress = 'ldaps://$ldapip';" &> /dev/null
/usr/local/sqream/bin/sqream sql --username=sqream --password=sqream -d master --port=5000  -c "ALTER SYSTEM SET ldapConnTimeoutSec = 15;" &> /dev/null
/usr/local/sqream/bin/sqream sql --username=sqream --password=sqream -d master --port=5000  -c "GRANT  SUPERUSER TO $username;" &> /dev/null
}
############################################ Expert With Vim ###################################################################################
expert () {
workers_count=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
logit "Started: expert"
logit "Current Number of SQream Workers: $workers_count"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
clear
echo "##################################################################################"
echo "Your Current Number of GPUs $num_gpus" 
echo "##################################################################################"
echo "##################################################################################"
echo "Your Current Number of SQream Workers: $workers_count"
echo "##################################################################################"
for i in $(seq 1 ${workers_count}); do
config_file="/etc/sqream/sqream${i}_config.json"
gpu_count=$(cat /etc/sqream/sqream${i}_config.json | grep '"gpu"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
cudaMemQuota_count=$(cat /etc/sqream/sqream${i}_config.json | grep '"cudaMemQuota"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )

echo "################## Expert Configuration ##########################################"
echo "Current worker sqream$i configuration "
cat  $config_file
echo "##################################################################################"
read -p "Do you want to change configuration ? (y/N) " yN
echo "##################################################################################"
case $yN in
y )
vim $config_file
;;
*)
        echo "Stay with Current Configuration"
        echo "##################################################################################"
        ;;
esac
done
spoolMemoryGB_count=$(cat /etc/sqream/sqream_config_legacy.json | grep '"spoolMemoryGB"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
echo "Current spoolMemoryGB : $spoolMemoryGB_count"
read -p "Do you want to change SQream Legacy configuration ? (y/N) " yN
echo "##################################################################################"
case $yN in
y )
vim /etc/sqream/sqream_config_legacy.json
;;
*)
echo "Stay with Current Configuration"
;;
esac
echo "##################################################################################"
echo " Done Expert Configuration"
echo "##################################################################################"
logit "Success: expert"
machineip=$(cat /etc/sqream/sqream1_config.json | grep 'machineIP' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
cluster=$(cat /etc/sqream/sqream1_config.json | grep 'cluster' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
expert_summary
}
############################################ Expert Auto #######################################################################################
expert_auto () {
workers_count=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
logit "Started: expert"
logit "Current Number of SQream Workers: $workers_count"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
clear
echo "##################################################################################"
echo "Your Current Number of GPUs $num_gpus" 
echo "##################################################################################"
echo "##################################################################################"
echo "Your Current Number of SQream Workers: $workers_count"
echo "##################################################################################"
for i in $(seq 1 ${workers_count}); do
config_file="/etc/sqream/sqream${i}_config.json"
gpu_count=$(cat /etc/sqream/sqream${i}_config.json | grep '"gpu"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
cudaMemQuota_count=$(cat /etc/sqream/sqream${i}_config.json | grep '"cudaMemQuota"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )

echo "################## Expert Configuration ##########################################"
echo "Current worker sqream$i GPU ID: $gpu_count" 
read -p "Do you want to change configuration ? (y/N) " yN
echo "##################################################################################"
case $yN in
y )
echo "Please choose GPU ID for sqream$i"
read new_gpu
sed -i "s/\"gpu\": $gpu_count,/\"gpu\": $new_gpu,/" "/etc/sqream/sqream${i}_config.json"
;;
*)
        echo "Stay with Current Configuration"
        echo "##################################################################################"
        ;;
esac
echo "----------------------------------------------------------------------------------"
echo "Current worker sqream$i cudaMemQuota: $cudaMemQuota_count"
read -p "Do you want to change configuration ? (y/N) " yN
echo "##################################################################################"
case $yN in
y )
echo "Enter the desired cudaMemQuota for sqream$i"
read new_cudaMemQuota
sed -i "s/\"cudaMemQuota\": $cudaMemQuota_count,/\"cudaMemQuota\": $new_cudaMemQuota,/" "/etc/sqream/sqream${i}_config.json"
;;
*)
echo "Stay with Current Configuration"
echo "##################################################################################"
;;
esac
limitQueryMemoryGB_count=$(cat /etc/sqream/sqream${i}_config.json | grep '"limitQueryMemoryGB"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
echo "----------------------------------------------------------------------------------"
echo "Current worker sqream$i limitQueryMemoryGB: $limitQueryMemoryGB_count"
read -p "Do you want to change configuration ? (y/N) " yN
echo "##################################################################################"
case $yN in
y )
echo "Enter the desired limitQueryMemoryGB for sqream$i"
read new_limitQueryMemoryGB
sed -i "s/\"limitQueryMemoryGB\": $limitQueryMemoryGB_count,/\"limitQueryMemoryGB\": $new_limitQueryMemoryGB,/" "/etc/sqream/sqream${i}_config.json"
;;
*)
echo "Stay with Current Configuration"
echo "##################################################################################"
;;
esac
done

spoolMemoryGB_count=$(cat /etc/sqream/sqream_config_legacy.json | grep '"spoolMemoryGB"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
echo "Current spoolMemoryGB : $spoolMemoryGB_count"
read -p "Do you want to change configuration ? (y/N) " yN
echo "##################################################################################"
case $yN in
y )
echo "Enter the desired spoolMemoryGB value"
read new_spoolMemoryGB
sed -i "s/\"spoolMemoryGB\": $spoolMemoryGB_count,/\"spoolMemoryGB\": $new_spoolMemoryGB,/" "/etc/sqream/sqream_config_legacy.json"
;;
*)
echo "Stay with Current Configuration"
;;
esac
echo "##################################################################################"
echo " Done Expert Configuration"
echo "##################################################################################"
logit "Success: expert"
machineip=$(cat /etc/sqream/sqream1_config.json | grep 'machineIP' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
cluster=$(cat /etc/sqream/sqream1_config.json | grep 'cluster' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
expert_summary
}
############################################ Expert summary ############################################################################################
expert_summary () {
logit "Started: Expert summary" 
summary=/tmp/sqreamdb-summary.log
workers_count=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
spoolMemoryGB_count=$(cat /etc/sqream/sqream_config_legacy.json | grep '"spoolMemoryGB"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
         echo "################### summary ##############################" > $summary
         echo "Number of GPUs $gpu_count" >> $summary
         echo "Number of SQream workers: $workers_count" >> $summary
         echo "SQream Storage Path: $cluster" >> $summary
         echo "Choosen IP $machineip" >> $summary
         echo "##########################################################" >> $summary
        logit "################### summary ##############################" 
        logit "Number of GPUs $gpu_count"
        logit "Number of SQream workers: $workers_count"
        logit "SQream Storage Path: $cluster"
        logit "Choosen IP $machineip"
        logit "##########################################################"  

for i in $(seq 1 ${workers_count}); do
config_file="/etc/sqream/sqream${i}_config.json"
        
        echo "##########################################################" >> $summary
        cudaMemQuota_count=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota | sed -e 's/.*://' | sed -e 's/["],$//')
        gpu_count=$(cat /etc/sqream/sqream${i}_config.json | grep gpu | sed -e 's/.*://' | sed -e 's/["],$//')
        limitQueryMemoryGB_count=$(cat /etc/sqream/sqream${i}_config.json | grep '"limitQueryMemoryGB"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
        echo "SQream Worker: SQREAM$i" >> $summary
        echo "GPU ID: $gpu_count" >> $summary
        echo "CudaMemQuota: $cudaMemQuota_count" >> $summary
        echo "SpoolMemory size: $spoolMemoryGB_count" >> $summary
        echo "limitQueryMemoryGB: $limitQueryMemoryGB_count" >> $summary
        echo "##########################################################" >> $summary
        logit "##########################################################"
        logit "SQream Worker: SQREAM$i"
        logit "GPU ID: $gpu_count"
        logit "CudaMemQuota: $cudaMemQuota_count"
        logit "SpoolMemory size: $spoolMemoryGB_count"
        logit "limitQueryMemoryGB: $limitQueryMemoryGB_count"
        logit "##########################################################"
done  
logit "Success: Expert summary"
read -p "Do you want to view summary configuration ? (y/N) " yN
case $yN in
y)
more $summary
;;
*) 
;;
esac
}
############################################ summary ############################################################################################
summary () {
logit "Started: summary" 
summary=/tmp/sqreamdb-summary.log
workers_count=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
spoolMemoryGB_count=$(cat /etc/sqream/sqream_config_legacy.json | grep '"spoolMemoryGB"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
         echo "################### summary ##############################" > $summary
         echo "Number of GPUs $gpu_count" >> $summary
         echo "Number of SQream workers: $workers_count" >> $summary
         echo "SQream Storage Path: $cluster" >> $summary
         echo "Choosen IP $machineip" >> $summary
         echo "##########################################################" >> $summary
        logit "################### summary ##############################"
        logit "Number of GPUs $gpu_count"
        logit "Number of SQream workers: $workers_count"
        logit "SQream Storage Path: $cluster"
        logit "Choosen IP $machineip"
        logit "##########################################################"  

for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
        
        
         echo "##########################################################" >> $summary
        limitQueryMemoryGB_count=$(cat /etc/sqream/sqream${i}_config.json | grep '"limitQueryMemoryGB"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
        cudaMemQuota_count=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota | sed -e 's/.*://' | sed -e 's/["],$//')
        gpu_count=$(cat /etc/sqream/sqream${i}_config.json | grep gpu | sed -e 's/.*://' | sed -e 's/["],$//')
         echo "SQream Worker: SQREAM$i" >> $summary
         echo "GPU ID: $gpu_count" >> $summary
         echo "CudaMemQuota: $cudaMemQuota_count" >> $summary
         echo "SpoolMemory size: $spoolMemoryGB_count" >> $summary
         echo "limitQueryMemoryGB: $limitQueryMemoryGB_count" >> $summary
         echo "##########################################################" >> $summary
        logit "##########################################################"
        logit "SQream Worker: SQREAM$i"
        logit "GPU ID: $gpu_count"
        logit "CudaMemQuota: $cudaMemQuota_count"
        logit "SpoolMemory size: $spoolMemoryGB_count"
        logit "limitQueryMemoryGB: $limitQueryMemoryGB_count"
        logit "##########################################################"
done  
logit "Success: summary"
read -p "Do you want to view summary configuration ? (y/N) " yN
case $yN in
y)
more $summary
;;
*) 
;;
esac
}
############################################ run_with_sudo ######################################################################################
run_with_sudo () {
        if ! [ $(id -u) = 0 ]; then
   echo "Please run This script with sudo." >&2
   logit "Error: run_with_sudo - Please run This script with sudo."
   exit 1
fi
logit "Success: run_with_sudo"
}
########################################### Check Log File #####################################################################################
check_logfile () {
if [ -f $LOG_FILE ];then
sudo rm -f $LOG_FILE

fi
}
########################################### Check summary File #################################################################################
check_summary () {
summary=$summary
 if [ -f $summary ];then
sudo rm -f $summary
fi
}
################# reconfig_monit_service_health_no_meta_aws ##############################################################################################
reconfig_monit_service_health_no_meta_aws () {
logit "Started reconfig_monit_service_health_no_meta_aws"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: Monit is installed"
monit_no_meta
formula_advance_monit_aws
move_advance_conf
end_monit
echo "###############################################################################"
logit "Success: reconfig_monit_service_health_no_meta_aws"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: reconfig_monit_service_health_no_meta_aws"
sleep 2
monit_backup
formula_advance_aws
move_advance_conf
end
fi
}
################# reconfig_monit_service_health_aws ##############################################################################################
reconfig_monit_service_health_aws () {
logit "Started reconfig_monit_service_health_aws"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: Monit is installed"
monit
formula_advance_monit_aws
move_advance_conf
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
echo "###############################################################################"
logit "Error: Monit is not installed Continue install without Monit"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: reconfig_monit_service_health_aws"
sleep 2
monit_backup
formula_advance_aws
move_advance_conf
end
fi
}
########################################### advance_reconfiguration_aws ########################################################################
advance_reconfiguration_aws () {
logit "Started: advance_reconfiguration_aws"
current_ip=$(cat /etc/sqream/sqream1_config.json | grep 'machineIP' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
clear
echo "##########################################################################################################################################"
echo "Welcome to SQream Advance Reconfiguration for AWS"
echo "##########################################################################################################################################"
echo "Your Current IP address is $current_ip"
logit "Success: Your Current IP address is $current_ip"
echo "##########################################################################################################################################"
read -p "Do you want to change current IP ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
        y )
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Success: You choose this IP address $machineip"
echo "$(hostname -i) $machineip " | sudo tee -a  /etc/hosts
;;
        * )
echo "Stay with Current IP address is $current_ip"
logit "Success: Stay with Current IP address is $current_ip"
echo "$(hostname -i) $current_ip " | sudo tee -a  /etc/hosts
echo "##########################################################################################################################################"
machineip=$current_ip
;;
esac
echo "##########################################################################################################################################"
current_cluster=$(cat /etc/sqream/sqream1_config.json | grep '"cluster"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
echo "Your Current Storage is $current_cluster"
logit "Success: Your Current Storage is $current_cluster"
echo "##########################################################################################################################################"
read -p "Do you want to change current Storage Path ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y)
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Your SQream Storage Path is: $cluster"
create_storage
permission_sqream

;;
* )
echo "Stay with Current Storage Path. "
echo "##########################################################################################################################################"
cluster=$current_cluster
logit "Success: Stay with Current Storage Path: $current_cluster  "
;;
esac

current_bucket_path=s3:$(cat /etc/sqream/sqream_config_legacy.json | grep '"tablespaceURL"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//' | sed 's/sqream_cluster//g' | sed 's/\/$//')
echo "Your Current bucket PATH is $current_bucket_path"
logit "Success: Your Current bucket PATH is $current_bucket_path"
echo "##########################################################################################################################################"
read -p "Do you want to change current bucket PATH ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y)
echo "Please enter bucket PATH"
echo "#######################################################"
echo "Example : s3://<bucket Name>"
echo "##########################################################################################################################################"
read bucket_path
while [ -z "$bucket_path" ]
do	printf 'Enter Your SQream bucket PATH: '
	read -r bucket_path
	[ -z "$bucket_path" ] && echo 'SQream bucket PATH cannot be empty; try again.'
 done
logit "Success: Your SQream bucket PATH is: $bucket_path"
;;
* )
echo "Stay with Current bucket PATH. "
bucket_path=$current_bucket_path
logit "Success: Stay with Current bucket PATH: $bucket_path  "
;;
esac
echo "##########################################################################################################################################"
current_metadata=$(cat /etc/sqream/sqream1_config.json | grep 'metadataServerIp' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
if [ $current_ip = $current_metadata ]; then
echo "Currently Metadata server is local on this PC"
fi
echo "Current METADATA SERVER is $current_metadata"
logit "Success: Current METADATA SERVER is $current_metadata"
echo "##########################################################################################################################################"

read -p "Do you want to change current METADATA SERVER service ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y )
echo "##########################################################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "##########################################################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "##########################################################################################################################################"
if [ $machineip = $metadataServerIp ]; then
echo "Metadata Service will be local"
logit "Success: Metadata Server will be Local"
sleep 2
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_aws
limitQuery_aws
else 
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
sleep 2
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_no_meta_aws
limitQuery_no_meta_aws
fi
;;
* )
echo "Stay with Current Metadata Server"
sleep 2
metadataServerIp=$current_metadata
logit "Success: Metadata Server will be Local"
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_aws
limitQuery_aws
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
;;
esac
logit "Success advance reconfiguration AWS"
}
########################################### advance_reconfiguration_pcs ########################################################################
advance_reconfiguration_pcs () {
logit "Started: advance_reconfiguration_pcs"
clear
current_ip=$(cat /etc/sqream/sqream1_config.json | grep 'machineIP' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
clear
echo "##########################################################################################################################################"
echo "Welcome to SQream Advance Reconfiguration"
echo "##########################################################################################################################################"
echo "Your Current IP address is $current_ip"
echo "##########################################################################################################################################"
read -p "Do you want to change current IP ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
        y )
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Success: Current Host IP Address $machineip"
;;
        * )
echo "Stay with Current IP address is $current_ip"
echo "##########################################################################################################################################"
machineip=$current_ip
logit "Success: Stay with Current IP address is $current_ip"
;;
esac
echo "##########################################################################################################################################"
current_cluster=$(cat /etc/sqream/sqream1_config.json | grep 'cluster' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
echo "Your Current Storage is $current_cluster"
echo "##########################################################################################################################################"
read -p "Do you want to change current Storage Path ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y)
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: SQream Storage Path change to $cluster" 
create_storage
permission_sqream

;;
* )
echo "Stay with Current Storage Path. "
cluster=$current_cluster
logit "Success: SQream stay with current Storage Path  $cluster" 
;;
esac
echo "##########################################################################################################################################"
echo "##########################################################################################################################################"
current_metadata=$(cat /etc/sqream/sqream1_config.json | grep 'metadataServerIp' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
if [ $current_ip = $current_metadata ]; then
echo "Currently Metadata server is local on this PC"
fi
echo "Current METADATA SERVER is $current_metadata"
logit "Success: Current METADATA SERVER is $current_metadata"
echo "##########################################################################################################################################"
read -p "Do you want to change current METADATA SERVER service ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y )
echo "##########################################################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "##########################################################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "##########################################################################################################################################"
if [ $machineip = $metadataServerIp ]; then
echo "Metadata Service will be local"
logit "Success: Metadata Server will be Local"
echo "Metadata Server will be Local"
metadataServerIp=$machineip
sleep 2
logit "Success: Metadata Server will be Local"
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
pacemaker_reconfig
formula_advance_pcs
move_advance_conf
limitQuery
else
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
sleep 2
echo "##########################################################################################################################################"
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
pacemaker_reconfig_no_meta
formula_advance_pcs
move_advance_conf
limitQuery_no_meta
fi
;;
* )
echo "Stay with Current Metadata Server"
sleep 2
if [ $machineip = $current_metadata ]; then
metadataServerIp=$current_metadata
logit "Success: Metadata Server will be Local"
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
pacemaker_reconfig
formula_advance_pcs
move_advance_conf
limitQuery
else 
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
sleep 2
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
pacemaker_reconfig_no_meta
formula_advance_pcs
move_advance_conf
limitQuery_no_meta
fi
;;
esac
logit "Success advance reconfiguration PCS"
}
#################################### advance_reconfiguration ####################################################################################
advance_reconfiguration () {
logit "Started: advance_reconfiguration"
current_ip=$(cat /etc/sqream/sqream1_config.json | grep 'machineIP' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
clear
echo "##########################################################################################################################################"
echo "Welcome to SQream Advance Reconfiguration"
echo "##########################################################################################################################################"
echo "Your Current IP address is $current_ip"
logit "Success: Your Current IP address is $current_ip"
echo "##########################################################################################################################################"
read -p "Do you want to change current IP ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
        y )
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Success: You choose this IP address $machineip"
;;
        * )
echo "Stay with Current IP address is $current_ip"
logit "Success: Stay with Current IP address is $current_ip"
echo "##########################################################################################################################################"
machineip=$current_ip
;;
esac
echo "##########################################################################################################################################"
current_cluster=$(cat /etc/sqream/sqream1_config.json | grep 'cluster' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
echo "Your Current Storage is $current_cluster"
logit "Success: Your Current Storage is $current_cluster"
echo "##########################################################################################################################################"
read -p "Do you want to change current Storage Path ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y)
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Your SQream Storage Path is: $cluster" 
create_storage
permission_sqream

;;
* )
echo "Stay with Current Storage Path. "
cluster=$current_cluster
logit "Success: Stay with Current Storage Path: $current_cluster  "
;;
esac
echo "##########################################################################################################################################"
current_metadata=$(cat /etc/sqream/sqream1_config.json | grep 'metadataServerIp' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
if [ $current_ip = $current_metadata ]; then
echo "Currently Metadata server is local on this PC"
fi
echo "Current METADATA SERVER is $current_metadata"
logit "Success: Current METADATA SERVER is $current_metadata"
echo "##########################################################################################################################################"

read -p "Do you want to change current METADATA SERVER service ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y )
echo "##########################################################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "##########################################################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "##########################################################################################################################################"
if [ $machineip = $metadataServerIp ]; then
echo "Metadata Service will be local"
logit "Success: Metadata Server will be Local"
sleep 2
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health
limitQuery
else 
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
sleep 2
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_no_meta
limitQuery_no_meta
fi
;;
* )
echo "Stay with Current Metadata Server"
sleep 2
if [ $machineip = $current_metadata ]; then
metadataServerIp=$current_metadata
logit "Success: Metadata Server will be Local"
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health
limitQuery
else 
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
sleep 2
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
reconfig_monit_service_health_no_meta
limitQuery_no_meta
fi
;;
esac
logit "Success advance reconfiguration"
}
################################ Function to Create SQream Legacy Conf File #####################################################################
install_legacy()
{
logit "Started install_legacy"
cat <<EOF | tee /etc/sqream/sqream_config_legacy.json > /dev/null
{
"diskSpaceMinFreePercent": 1,
    "DefaultPathToLogs": "${cluster}/logs/",
    "enableLogDebug": false,
    "insertCompressors": 8,
    "insertParsers": 8,
    "isUnavailableNode": false,
    "logBlackList": "webui",
    "logDebugLevel": 6,
    "nodeInfoLoggingSec": 60,
    "useClientLog": true,
    "useMetadataServer": true,
    "spoolMemoryGB": $spoolMemoryGB,
    "queryTimeoutMinutes": 0,
    "waitForClientSeconds": 18000
}
EOF
logit "Success: install_legacy"
}
################################ custom_limitQuery #############################################################################################
custom_limitQuery () {
logit "Started custom_limitQuery"
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$(expr $RAM_KB / 1024)
RAM_GB=$(expr $RAM_MB / 1024)
global_limitQueryMemoryGB=$((RAM_GB * 90 / 100 ))
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((global_limitQueryMemoryGB / number_of_workers))
spoolMemoryGB=$(($limitQueryMemoryGB - 10 ))
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $new_limitQueryMemoryGB,/" "$config_file"
        
done
logit "Success:  custom_limitQuery"   
install_legacy
}
################################ default_limitQuery ###########################################################################################
default_limitQuery () {
logit "Started:  default_limitQuery"
total_ram_meta
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"       
done
logit "Success:  default_limitQuery"        
install_legacy
}
############################# limitQuery #####################################################################################################
limitQuery () {
logit "Started limitQuery"
if [[ $new_limitQueryMemoryGB -ge 1 ]];then
logit "Success : limitQuery check"
custom_limitQuery
else
logit "Success : limitQuery check"
default_limitQuery
fi
}
########################## limitQuery no meta ###############################################################################################
limitQuery_no_meta () {
logit "Started limitQuery_no_meta"
total_ram
number_of_workers=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
limitQueryMemoryGB=$((AVAILABLE_RAM_GB / number_of_workers))
if  [ $limitQueryMemoryGB -ge 128 ] ; then
echo "####################################################"
echo "limitQueryMemoryGB greater then 128GB"
echo "Number of workers = $number_of_workers"
echo "####################################################"
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
else
spoolMemoryGB=$(($limitQueryMemoryGB * 50 /100 ))
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"       
done
logit "Success:  limitQuery_no_meta"        
install_legacy
} 
########################## check_if_sqreamdb_exist ##########################################################################################
check_if_sqreamdb_exist () {
logit "Started check_if_sqreamdb_exist"
if [ ! -d /usr/local/sqream ];then
echo "SQreamDB not found"
logit "Error: /usr/local/sqream  > Not Exist"
exit
fi
logit "Success: /usr/local/sqream  > Exist"
}
######################## sqream_temp #######################################################################################################
sqream_temp () {
logit "Started sqream_temp"
if [ -d sqream-temp ];then
sudo rm -rf sqream-temp
logit "Success: sqream_temp Deleted"
else
logit "Success, sqream_temp Not Exist"
fi
}
###################### check_for_sqream_user ###############################################################################################
check_for_sqream_user () {
logit "Started check_for_sqream_user"
getent passwd sqream &> /dev/null
if [ $? != 0 ]; then
clear
echo "###############################################################################"
echo "User SQream was not found, Please create user sqream and start over."
echo "###############################################################################"
logit "Error: User SQream was not found, Please create user sqream and start over." 
exit 
fi
logit "Success: check_for_sqream_user"
}
###################### check_pacemaker_service_health ###########################################################################################
check_pacemaker_service_health () {
logit "Started check_pacemaker_service_health"
if ! rpm -qa | grep pcs &> /dev/null
then
clear
echo "###############################################################################"
echo "Pacemaker is not installed, Please install Pacemaker and start over."
logit "Error: Pacemaker is not installed, Please install Pacemaker and start over."
echo "###############################################################################"
exit 
fi
logit "Success: check_pacemaker_service_health"
}
################# check_metadata_service_health ################################################################################################
check_metadata_service_health () {
logit "Started check_metadata_service_health"
metadata=$(sudo systemctl is-active  metadataserver.service)
if [[ $metadata == active ]]; then
clear
echo "###############################################################################"
echo "SQreamDB is running on this host, Please stop SQreamDB and start over."
logit "Error: SQreamDB is running on this host, Please stop SQreamDB and start over."
echo "###############################################################################"
exit 
fi
logit "Success: check_metadata_service_health"
}
###################################Check Permission sqream:sqream on Cluster ###################################################################
permission_sqream () {
logit "Started permission_sqream"
permission=$(stat -c  %G:%U $cluster)
if [[ $permission == sqream:sqream ]]; then
  echo "Cluster Permission is OK"
  logit "Success: permission_sqream > Cluster Permission is OK"
  else
          echo "Please fix Cluster permission to sqream:sqream"
          logit "Error: Please fix Cluster permission to sqream:sqream"
fi
logit "Success: permission_sqream"
}
################################ Date  ##########################################################################################################
today=$(date +"%Y-%m-%d-%s")
###################################################### END ######################################################################################
end () {
clear
echo "
##################################################################################################
##################################################################################################
# SQream Installation Completed to Start SQream add License file to /etc/sqream and then         #
# sudo systemctl start monit                                                                     #
# sudo monit start all                                                                           #
# sudo monit status                                                                              #
# To View Installer logfile        > more /tmp/sqream-installV1.log                              #
# To View Summary logfile          > more /tmp/sqreamdb-summary.log                              #
##################################################################################################
##################################################################################################
# If you wish to install Monit later.                                                            #
# Monit backup configuration file can be found in /etc/sqream/monitrc                            #
# Just copy it under /etc/monit.d/                                                               #
# then do:                                                                                       # 
# sudo monit reload                                                                              #
##################################################################################################"
logit "Success: Done installing SQreamDB"
}
#################################### END MIG ##################################################################################################
end_mig() {
logit "Started: : end_mig"
echo "#######################################################################################################"
echo "                               SQream MIG Installation Complete"
echo "#######################################################################################################"
echo '
  _____  _____          _____ _      _ _    _ __  __
 / ____|/ ____|   /\   |_   _| |    (_) |  | |  \/  |
| (___ | |       /  \    | | | |     _| |  | | \  / |
 \___ \| |      / /\ \   | | | |    | | |  | | |\/| |
 ____) | |____ / ____ \ _| |_| |____| | |__| | |  | |
|_____/ \_____/_/    \_\_____|______|_|\____/|_|  |_|'
}
########################################### Check Log File #####################################################################################
check_logfile () {
if [ -f $LOG_FILE ];then
sudo rm -f $LOG_FILE

fi
logit "Succes: : end_mig"
}
############################################################### END With Monit #########################################################################################
end_monit () {
clear
echo "
##################################################################################################
##################################################################################################
# SQream Installation Completed to Start SQream add License file to /etc/sqream and then         #
# sudo systemctl start monit                                                                     #        
# sudo systemctl enable monit                                                                    #
# sudo monit start all                                                                           #
# sudo monit status                                                                              #
# To View Installer logfile        > more /tmp/sqream-installV1.log                              #
# To View Summary logfile          > more /tmp/sqreamdb-summary.log                              #                                         
##################################################################################################"
logit "Success: Done installing SQreamDB with Monit"
}
################################### END Pacemaker ########################################################################################################################
end_pacemaker () {
clear
echo "Please Wait while finishing configuration..."
sudo pcs cluster stop $(hostname) > /dev/null
clear
echo "##################################################################################################"
echo "##################################################################################################
To start SQreamDB   >   sudo pcs cluster start $(hostname)

For SQreamDB Status >   sudo pcs status

To stop SQreamDB    >   sudo pcs cluster stop $(hostname)

To View Installer logfile        > more /tmp/sqream-installV1.log 
To View SQreamDB summary logfile > more /tmp/sqreamdb-summary.log                                                                       
########################################################################################################"
logit "Success: Done installing SQreamDB with Pacemaker"
}
######## Move Advance Conf after reconfigure ####################################################################################################
move_advance_conf () {
logit "Started move_advance_conf"
if
[ -d /etc/sqream ];then
sudo cp -r /etc/sqream /etc/sqream_etc_backup_$today
logit "Success: /etc/sqream > exist moving to backup sqream_etc_backup_$today"
fi
sudo rm -f /etc/sqream/sqream*-service.conf
sudo rm -f /etc/sqream/sqream*_config.json
sudo rm -f  /usr/lib/systemd/system/sqream*
sudo systemctl daemon-reload
sudo mv sqream*.service /usr/lib/systemd/system/
sudo mv sqream*-service.conf /etc/sqream/
sudo mv sqream*_config.json /etc/sqream/
sudo rm -f default*
sudo rm -f metadata*
sudo rm -f sqream*
sudo chown -R sqream:sqream /etc/sqream
sudo systemctl daemon-reload
logit "Success: move_advance_conf"
}

############## monit_backup ####################################################################################################################
monit_backup () {
logit "Started monit_backup"
cat <<EOF | sudo tee /etc/sqream/monitrc > /dev/null
set daemon  5              # check services at 30 seconds intervals
set logfile syslog
set httpd port 2812 and
#METADATASERVER-START
check process metadataserver with pidfile /var/run/metadataserver.pid
start program = "/usr/bin/systemctl start metadataserver"
stop program = "/usr/bin/systemctl stop metadataserver"
#METADATASERVER-END
#SERVERPICKER-START
check process serverpicker with pidfile /var/run/serverpicker.pid
start program = "/usr/bin/systemctl start serverpicker"
stop program = "/usr/bin/systemctl stop serverpicker"
EOF
logit "Success: No Monit install so keeping monitrc backup in /etc/sqream"
}
###################################### install_sqream_serverpicker_service ######################################################################
install_sqream_serverpicker_service() {
logit "Started install_sqream_serverpicker_service"
echo '[Unit]
Description=Server Picker - Load Balancer For SQreamDB
Documentation=http://docs.sqream.com/latest/manual/

[Service]
Type=simple
EnvironmentFile=/etc/sqream/server_picker.conf

ExecStart=/bin/su - $RUN_USER -c "exec ${DIR}/bin/server_picker ${IP} ${PORT} &>> ${LOGFILE}"
ExecStartPost=/bin/sh -c "sleep 1; pidof server_picker > /var/run/${SERVICE_NAME}.pid"
ExecStop=/bin/sh -c "/bin/kill -9 `cat /var/run/${SERVICE_NAME}.pid`"
ExecStopPost=/bin/rm -f /var/run/${SERVICE_NAME}.pid
ExecReload=/bin/sh -c "/bin/kill -HUP `cat /var/run/${SERVICE_NAME}.pid`"

KillMode=process
TimeoutSec=30s

[Install]
WantedBy=multi-user.target
' > serverpicker.service 
logit "Success: install_sqream_serverpicker_service"
}
###################################### install_sqream_serverpicker #############################################################################
install_sqream_serverpicker()
{
logit "Started install_sqream_serverpicker"
cat <<EOF | tee server_picker.conf > /dev/null
SERVICE_NAME=serverpicker
RUN_USER=sqream
DIR=/usr/local/sqream
IP=${machineip} 
PORT=3105
LOGFILE=/var/log/sqream/serverpicker.log 
EOF
logit "Success: install_sqream_serverpicker"
}

###################################### Copy All Created Config files and Services to  SQream Folders ###########################################
copy_files() {
logit "Started copy_files"
sudo mkdir -p /etc/sqream
sudo mv metadataserver.conf /etc/sqream
sudo mv metadataserver.service /etc/sqream
sudo mv metadataserver_config.json /etc/sqream
sudo mv sqream*.service /etc/sqream/
sudo mv sqream*-service.conf /etc/sqream/
sudo mv sqream*_config.json /etc/sqream/
sudo mv default* /etc/sqream
sudo mv  server_picker* /etc/sqream
sudo mv  serverpicker* /etc/sqream
sudo mv /etc/sqream/metadataserver.service /usr/lib/systemd/system/
sudo mv /etc/sqream/serverpicker.service /usr/lib/systemd/system/
sudo mv /etc/sqream/sqream*.service /usr/lib/systemd/system/
sudo cp /usr/local/sqream/etc/sqream_env.sh /etc/sqream
sudo cp /usr/local/sqream/etc/server_picker_log_properties /etc/sqream
sudo cp /usr/local/sqream/etc/metadata_log_properties /etc/sqream
sudo cp /usr/local/sqream/etc/sqreamd_log_properties /etc/sqream
sudo cp /usr/local/sqream/etc/flags* /etc/sqream
sudo chown -R sqream:sqream /usr/local/sqream
sudo chown -R sqream:sqream /etc/sqream
sudo systemctl daemon-reload
logit "Success: copy_files"
}
############################ Check if TAR file Exist ##############################################################################################
check_tar_file()
{
  logit "Started check_tar_file"
  if [ -z $TARFILE ]
  then
     echo "ERROR: no archieve file was specified, exiting..."
     logit "ERROR: no archieve file was specified, exiting..."
     exit -1
  fi
  if [ ! -e "$TARFILE" ]
  then
     echo "ERROR: archeive file '$TARFILE' is NOT accessible, exiting..."
     logit "ERROR: archeive file '$TARFILE' is NOT accessible, exiting..."
     exit -1
  fi
  if [ -d "$TARFILE" ]; then
        echo "ERROR: '$TARFILE' is a directory, not a file." 
        logit "ERROR: '$TARFILE' is a directory, not a file."
        exit -1
    fi
    if echo "$TARFILE" | grep -qE "tar.gz" ; then
        echo "SUCCESS: '$TARFILE' is a recognized tar archive type."
        echo "File Type: $TARFILE"
      logit "Success: check TAR file"   
    else
        echo "FAIL: '$TARFILE' is NOT a tar archive."    
        exit -1
        logit "ERROR: archeive file '$TARFILE' is NOT a tar archive."
        fi
  logit "Success: check TAR file"
}
####################### Fix Folders and Files Permissionsfor Upgrade ############################################################################
check_permissions_and_folders_upgrade()
{
logit "Started check_permissions_and_folders_upgrade"
clear
if
[ -L /usr/local/sqream ];then
sudo rm -f  /usr/local/sqream
logit "Success: remove SQream old Link" 
fi
#if
#[ -d /usr/local/sqream-db* ];then
#sudo mv /usr/local/sqream-db* /usr/local/sqream_usr_backup${today}
#fi
if
SQVER1=$(echo "${TARFILE}"| sed "s/.*\///") 
SQVER=${SQVER1%.*.*.*}
[ -d /usr/local/${SQVER} ];then
sudo mv  /usr/local/${SQVER} /usr/local/sqream_${today}
logit "Success: moving /usr/local/$SQVER to /usr/local/sqream_$today"
fi
logit "Success: check_permissions_and_folders_upgrade"
}
####################### Fix Folders and Files Permissions #######################################################################################
check_permissions_and_folders()
{
logit "Started check_permissions_and_folders"
SQVER1=$(echo "${TARFILE}"| sed "s/.*\///") 
SQVER=${SQVER1%.*.*.*}
clear
if [ -f /etc/sqream/sqream-admin-config.json ]
then 
cp /etc/sqream/sqream-admin-config.json .
logit "Success: backup of sqream-admin-config.json"
fi
if [ -f  /etc/sqream/license.enc ] 
then
cp /etc/sqream/license.enc .
logit "Success: backup of license.enc"
fi
if
[ -d /etc/sqream ];then
sudo mv /etc/sqream /etc/sqream_etc_backup_$today
logit "Success: backup old /etc/sqream to sqream_etc_backup_$today"
fi
if
[ -L /usr/local/sqream ];then
sudo rm -f  /usr/local/sqream
logit "Success: remove SQream old Link" 
fi
if
SQVER1=$(echo "${TARFILE}"| sed "s/.*\///") 
SQVER=${SQVER1%.*.*.*}
[ -d /usr/local/${SQVER} ];then
sudo mv  /usr/local/${SQVER} /usr/local/sqream_${SQVER}_${today}
logit "Success: moving /usr/local/$SQVER to /usr/local/sqream_${SQVER}_${today}"
fi
sudo mkdir -p /etc/sqream
sudo chown -R sqream:sqream /etc/sqream
sudo mv license.enc /etc/sqream &> /dev/null
sudo mv sqream-admin-config.json /etc/sqream &> /dev/null
sudo mkdir -p /var/log/sqream
sudo chown -R sqream:sqream /var/log/sqream
logit "Success: check_permissions_and_folders"
}
##################################### verify_and_extract #######################################################################################
verify_and_extract()
{
logit "Started verify_and_extract"
clear
echo "#####################################################################################"
echo "Starting SQreamDB installation Please wait While Extracting TAR file" 
echo "#####################################################################################"
if
[ -d /tmp/sqreampkg ];then
rm -rf /tmp/sqreampkg > /dev/null
mkdir -p /tmp/sqreampkg > /dev/null
tar -C /tmp/sqreampkg/ -zxf $TARFILE --checkpoint=.1000
echo " Done, Continue with Installation "
logit "Success: /tmp/sqreampkg  deleted, Continue with Installation "
else
mkdir -p /tmp/sqreampkg > /dev/null
logit "Success: /tmp/sqreampkg created"
tar -C /tmp/sqreampkg/ -zxf $TARFILE --checkpoint=.1000
echo "#####################################################################################"
echo " Done, Continue with Installation "
echo "#####################################################################################"
fi
logit "Success: verify_and_extract"
}
############################ Move SQream Package to Relevant Folders ###########################################################################
move_package()
{
logit "Started move_package" 
SQVER1=$(echo "${TARFILE}"| sed "s/.*\///") 
SQVER=${SQVER1%.*.*.*}
sudo mv /tmp/sqreampkg/sqream /usr/local/${SQVER}
sudo chown -R sqream:sqream /usr/local/${SQVER}
logit "Success: move_package"
}
########################### Make SQream Symbolic Links ########################################################################################
make_symlink()
{
logit "Started make_symlink"
sudo ln -s /usr/local/${SQVER} /usr/local/sqream
sudo chown -R sqream:sqream /usr/local/sqream
sudo chown -R sqream:sqream /var/log/sqream
sudo chown -R sqream:sqream /usr/local/sqream/
logit "Success: make_symlink"
}
################################ Function Config METADATA SERVER Service File ###################################################################
install_metadata_service()
{
logit "Started install_metadata_service"
echo '[Unit]
Description=Metadata Server For SQreamDB
Documentation=http://docs.sqream.com/latest/manual/

[Service]
Type=simple
EnvironmentFile=/etc/sqream/metadataserver.conf

ExecStart=/bin/su - $RUN_USER -c "/bin/nohup ${DIR}/bin/metadata_server --config /etc/sqream/${SERVICE_NAME}_config.json --log_path ${METADATALOG} --log4_config ${LOG4} --num_deleters ${DELETERS}  &>> ${LOGFILE}/${SERVICE_NAME}.log"
ExecStartPost=/bin/sh -c "sleep 1; pidof metadata_server > /var/run/${SERVICE_NAME}.pid"
ExecStop=/bin/sh -c "kill -9 `cat /var/run/${SERVICE_NAME}.pid`"
ExecStopPost=/bin/rm -f /var/run/${SERVICE_NAME}.pid
ExecReload=/bin/sh -c "/bin/kill -HUP `cat /var/run/${SERVICE_NAME}.pid`"

KillMode=process
TimeoutSec=30s

[Install]
WantedBy=multi-user.target
' > metadataserver.service
logit "Success: install_metadata_service"
}
############################## Function Config SQream METADATASERVER_config.json  Conf File #####################################################
install_metadata_config_json () {
logit "Started install_metadata_config_json"
echo '      {
          "metadataStandAlone": false
      }
' > metadataserver_config.json 
logit "Success: install_metadata_config_json"
}
############################# Function install_metadata metadataserver.conf #####################################################################
install_metadata()
{
logit "Started install_metadata"
cat <<EOF | tee metadataserver.conf > /dev/null
SERVICE_NAME=metadataserver
RUN_USER=sqream
DIR=/usr/local/sqream
LOGFILE=/var/log/sqream
LOG4=/etc/sqream/metadata_log_properties
METADATALOG=${cluster}/metadata_logs
DELETERS=1
EOF
logit "Success: install_metadata"
}
################################ Function create_config_template_file ############################################################################
create_config_template_file() {
logit "Started create_config_template_file"
cat <<EOF | tee default_config.json > /dev/null
{
    "cluster": "$cluster",
    "cudaMemQuota": 90,
    "gpu": 0,
    "legacyConfigFilePath": "sqream_config_legacy.json",
    "licensePath": "/etc/sqream/license.enc",
    "limitQueryMemoryGB": limitQueryMemoryGB,
    "machineIP": "$machineip",
    "metadataServerIp": "$metadataServerIp",
    "metadataServerPort": 3105,
    "port": @regular_port@,
    "instanceId": "@sqream_00@",
    "portSsl": @sslport@,
    "initialSubscribedServices": "sqream",
    "useConfigIP": true
}
EOF
logit "Success: create_config_template_file"
}
############################################## generate_config_files ############################################################################
generate_config_files() {
logit "Started generate_config_files"
    gpu_id=$1
    worker_count=$2
    i=0    
    
        sport=5099
        port=4999
        while [ $i -lt $worker_count ]; do
        ##################################################################################################
        # Copy template files ############################################################################
        ##################################################################################################
        config_file="sqream${current_worker_id}_config.json"
        cp default_config.json "$config_file"
        config_service_file="sqream${current_worker_id}-service.conf"
	      cp default_service.conf "$config_service_file"
        service_file="sqream${current_worker_id}.service"
        cp default.service "$service_file"
        ##################################################################################################
        # Update "gpu" and "cudaMemQuota" in the config file #############################################
        ##################################################################################################
        sed -i "s/\"gpu\": 0,/\"gpu\": $gpu_id,/" "$config_file"
        sed -i "s/\"cudaMemQuota\": 90,/\"cudaMemQuota\": $new_cuda,/" "$config_file"
        sed -i "s|@regular_port@|$((port + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sslport@|$((sport + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sqream_00@|sqream_0${current_worker_id}|g" "$config_file"
        sed -i "s/\SERVICE_NAME\=sqream/\SERVICE_NAME\=sqream$current_worker_id/" "$config_service_file"
        sed -i "s|@sqream@|sqream${current_worker_id}.log|g" "$config_service_file"
        sed -i "s|@sqreamX-service.conf@|sqream${current_worker_id}-service.conf|g" "$service_file"
        ######################### Monit X times###########################################################
        echo "#SQREAM$current_worker_id-START" >> /etc/sqream/monitrc
                echo "check process sqream$current_worker_id with pidfile /var/run/sqream$current_worker_id.pid" >> /etc/sqream/monitrc
        echo start program = ' "/usr/bin/systemctl start 'sqream$current_worker_id'"' >> /etc/sqream/monitrc
        echo stop program = ' "/usr/bin/systemctl stop 'sqream$current_worker_id'"' >> /etc/sqream/monitrc
        echo "#SQREAM$current_worker_id-END" >> /etc/sqream/monitrc
        ## Add Varibales X times##########################################################################
        
        current_worker_id=$((current_worker_id + 1))
        i=$((i + 1))
        done
        install_legacy
        install_metadata
        ################################################################################################# 
        logit "Success: generate_config_files"    
}
################################# Function to generate and update config files Monit ########################################################
generate_config_files_monit() {
logit "Started generate_config_files_monit"
    gpu_id=$1
    worker_count=$2
    i=0    
        sport=5099
        port=4999
        while [ $i -lt $worker_count ]; do
        ##################################################################################################
        # Copy template files ############################################################################
        ##################################################################################################
        config_file="sqream${current_worker_id}_config.json"
        cp default_config.json "$config_file"
        config_service_file="sqream${current_worker_id}-service.conf"
	      cp default_service.conf "$config_service_file"
        service_file="sqream${current_worker_id}.service"
        cp default.service "$service_file"
        ##################################################################################################
        # Update "gpu" and "cudaMemQuota" in the config file #############################################
        ##################################################################################################
        sed -i "s/\"gpu\": 0,/\"gpu\": $gpu_id,/" "$config_file"
        sed -i "s/\"cudaMemQuota\": 90,/\"cudaMemQuota\": $new_cuda,/" "$config_file"
        sed -i "s|@regular_port@|$((port + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sslport@|$((sport + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sqream_00@|sqream_0${current_worker_id}|g" "$config_file"
        sed -i "s/\SERVICE_NAME\=sqream/\SERVICE_NAME\=sqream$current_worker_id/" "$config_service_file"
        sed -i "s|@sqream@|sqream${current_worker_id}.log|g" "$config_service_file"
        sed -i "s|@sqreamX-service.conf@|sqream${current_worker_id}-service.conf|g" "$service_file"
                ######################### Monit X times###########################################################
        echo "#SQREAM$current_worker_id-START" >> /etc/monit.d/monitrc
        echo "check process sqream$current_worker_id with pidfile /var/run/sqream$current_worker_id.pid" >> /etc/monit.d/monitrc
        echo start program = ' "/usr/bin/systemctl start 'sqream$current_worker_id'"' >> /etc/monit.d/monitrc
        echo stop program = ' "/usr/bin/systemctl stop 'sqream$current_worker_id'"' >> /etc/monit.d/monitrc
        echo "#SQREAM$current_worker_id-END" >> /etc/monit.d/monitrc
        ## Add Varibales X times##########################################################################
        current_worker_id=$((current_worker_id + 1))
        i=$((i + 1))
        done
        logit "Success: generate_config_files_monit" 
        install_legacy
        install_metadata
        sudo systemctl enable monit > /dev/null 2&>1
        sudo monit reload > /dev/null 
        #################################################################################################    
        
}
###################################### Function to generate and update config files Pacemaker #############################################
generate_config_files_pcs() {
logit "Started generate_config_files_pcs"
    gpu_id=$1
    worker_count=$2
    i=0  
    
        sport=5099
        port=4999
        while [ $i -lt $worker_count ]; do
        ##################################################################################################
        # Copy template files ############################################################################
        ##################################################################################################
        config_file="sqream${current_worker_id}_config.json"
        cp default_config.json "$config_file"
        config_service_file="sqream${current_worker_id}-service.conf"
	      cp default_service.conf "$config_service_file"
        service_file="sqream${current_worker_id}.service"
        cp default.service "$service_file"
        ##################################################################################################
        # Update "gpu" and "cudaMemQuota" in the config file #############################################
        ##################################################################################################
        sed -i "s/\"gpu\": 0,/\"gpu\": $gpu_id,/" "$config_file"
        sed -i "s/\"cudaMemQuota\": 90,/\"cudaMemQuota\": $new_cuda,/" "$config_file"
        sed -i "s|@regular_port@|$((port + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sslport@|$((sport + ${current_worker_id} ))|g" "$config_file"
        sed -i "s|@sqream_00@|sqream_0${current_worker_id}|g" "$config_file"
        sed -i "s/\SERVICE_NAME\=sqream/\SERVICE_NAME\=sqream$current_worker_id/" "$config_service_file"
        sed -i "s|@sqream@|sqream${current_worker_id}.log|g" "$config_service_file"
        sed -i "s|@sqreamX-service.conf@|sqream${current_worker_id}-service.conf|g" "$service_file"
        
        ######################### Pacemaker X times ######################################################
        echo "==>Creating SQream${current_worker_id} resource"
        sudo pcs resource create SQREAM${current_worker_id} systemd:sqream${current_worker_id} \
	      op start timeout=30s on-fail=restart \
        op stop timeout=30s on-fail=ignore \
        op monitor on-fail=restart interval=20s role=Started
        sudo pcs constraint location SQREAM${current_worker_id} prefers $(hostname)
        ## Add Varibales X times##########################################################################
        current_worker_id=$((current_worker_id + 1))
        i=$((i + 1))
        done
        logit "Success: generate_config_files_pcs"  
        install_legacy
        install_metadata
        #################################################################################################  
         
}
###################################### Function install_sqream_services #########################################################################
install_sqream_services()
{
logit "Started install_sqream_services"
echo '[Unit]
After=serverpicker.service
Description=SQream SQL Server 
Documentation=http://docs.sqream.com/latest/manual/

[Service]
Type=simple
EnvironmentFile=/etc/sqream/@sqreamX-service.conf@

ExecStart=/bin/su - $RUN_USER -c "source /etc/sqream/sqream_env.sh && exec ${DIR}/bin/sqreamd -config /etc/sqream/${SERVICE_NAME}_config.json &>> ${LOGFILE}"
ExecStartPost=/bin/sh -c "sleep 2; /bin/ps --ppid ${MAINPID} -o pid= > /var/run/${SERVICE_NAME}.pid"
ExecStop=/bin/sh -c "/bin/kill -9 `cat /var/run/${SERVICE_NAME}.pid`"
ExecStopPost=/bin/rm -f /var/run/${SERVICE_NAME}.pid
ExecReload=/bin/sh -c "/bin/kill -s -HUP `cat /var/run/${SERVICE_NAME}.pid`"

KillMode=process
TimeoutSec=30s

[Install]
WantedBy=multi-user.target 
' > default.service 
logit "Success: install_sqream_services"
}
###################################### create_service_config_template_file #########################################################################
create_service_config_template_file() {
logit "Started create_service_config_template_file"
echo 'SERVICE_NAME=sqream
RUN_USER=sqream
DIR=/usr/local/sqream
BINDIR=/usr/local/sqream/bin/
LOGFILE=/var/log/sqream/@sqream@
' > default_service.conf 
logit "Success: create_service_config_template_file"
} 
############################ Upgrade Storage ####################################################################################################
upgrade_storage()
{
logit "Started upgrade_storage"
if [ -f  /etc/sqream/sqream1_config.json ];then
current_cluster=$(cat /etc/sqream/sqream1_config.json | grep 'cluster' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
else
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read current_cluster
while [ -z "$current_cluster" ]
do      printf 'Enter Your SQream Storage Path: '
        read -r current_cluster
        [ -z "$current_cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
 fi
clear
echo "##########################################################################################################################################"
echo "Your Current Storage is $current_cluster"
echo "##########################################################################################################################################"
echo "Please Wait, Upgrading."
echo "##########################################################################################################################################"
/usr/local/sqream/bin/upgrade_storage ${current_cluster}
sudo chown -R sqream:sqream ${current_cluster}
sudo systemctl daemon-reload
logit "Success: upgrade_storage"
}
############################## Create Storage ###################################################################################################
{
create_storage () {
logit "Started create_storage"
clear
if [ -d "$cluster" ];then
      logit "Please wait Upgrading existing Storage"
      echo "Please wait Upgrading existing Storage"      
      /usr/local/sqream/bin/upgrade_storage ${cluster} > /dev/null 2&>1
      sudo systemctl daemon-reload
      logit "Success: create_storage"
      else
   
logit "Please wait Creating Storage"
echo "Please wait Creating Storage"
/usr/local/sqream/bin/SqreamStorage -Cr ${cluster} > /dev/null 2&>1
echo "____________________________________________________________"
echo "------------------------------------------------------------"
echo "==> SQream Storage Created in" ${cluster}
echo "____________________________________________________________"
echo "------------------------------------------------------------"
logit "Success: create_storage"
sudo chown -R sqream:sqream ${cluster}
sudo systemctl daemon-reload
fi

}
################# Reconfig Check Service Monit ####################################################################################################
reconfig_monit_service_health () {
logit "Started reconfig_monit_service_health"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: Monit is installed"
monit
formula_advance_monit
move_advance_conf
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
echo "###############################################################################"
logit "Error: Monit is not installed Continue install without Monit"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: reconfig_monit_service_health"
sleep 2
monit_backup
formula_advance
move_advance_conf
end
fi

}
################# reconfig_monit_service_health_no_meta ##############################################################################################
reconfig_monit_service_health_no_meta () {
logit "Started reconfig_monit_service_health_no_meta"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: Monit is installed"
monit_no_meta
formula_advance_monit
move_advance_conf
end_monit
echo "###############################################################################"
logit "Success: reconfig_monit_service_health_no_meta"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: reconfig_monit_service_health_no_meta"
sleep 2
monit_backup
formula_advance
move_advance_conf
end
fi
}
################# check_monit_service_health_no_meta #########################################################################################################
check_monit_service_health_no_meta () {
logit "Started check_monit_service_health_no_meta"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: check_monit_service_health_no_meta"
monit_no_meta
formula_advance_monit
copy_files
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: check_monit_service_health_no_meta"
sleep 2
monit_backup
formula_advance
copy_files
end
fi
}
#############################Monit Metadata Only ########################################################
#########################################################################################################
check_monit_service_health_meta () {
logit "Started check_monit_service_health_meta"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: check_monit_service_health"
monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: check_monit_service_health_meta"
sleep 2
monit_backup
fi
}
###### check_monit_service_health #########################################################################################################
check_monit_service_health () {
logit "Started check_monit_service_health"
if [ -f  /usr/lib/systemd/system/monit.service ] &> /dev/null
then
clear
echo "###############################################################################"
echo "Monit is installed."
logit "Success: check_monit_service_health"
monit
formula_advance_monit
copy_files
end_monit
echo "###############################################################################"
sleep 2
else
clear
echo "###############################################################################"
echo "Monit is not installed."
logit "Warnning: Monit is not installed Continue install without Monit"
echo "###############################################################################"
echo "Continue install without Monit"
echo "###############################################################################"
echo "You will need to start all SQream services manually"
echo "###############################################################################"
logit "Success: check_monit_service_health"
sleep 2
monit_backup
formula_advance
copy_files
end
fi
}
#################################### Function advance_configuration ############################################################################
advance_configuration () {
logit "Started: advance_configuration"
clear
echo "##########################################################################################################################################"
echo "Welcome to SQream Advance Configuration"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
echo "##########################################################################################################################################"
read -p "Will this Server host METADATA SERVER service ? (Y/n) " Yn
echo "##########################################################################################################################################"
case $Yn in
n ) 
echo "##########################################################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "##########################################################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
echo "##########################################################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
logit "Success: advance_configuration"
create_storage
permission_sqream
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
check_monit_service_health_no_meta
limitQuery_no_meta
;;
* ) 
echo "Continue with Standard SQream Installation"
logit "Success: Continue with Standard SQream Installation"
metadataServerIp=$machineip
echo "##########################################################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
done
logit "Success: Storage Path is $cluster"
logit "Success: function advance_configuration"
create_storage
permission_sqream
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
check_monit_service_health
limitQuery
 ;;
esac
}
################################################################################################################################################
advance_configuration_pcs () {
logit "Started: advance_configuration_pcs"
clear
echo "##########################################################################################################################################"
echo "Welcome to SQream Advance Configuration"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please Enter Current Host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
echo "##########################################################################################################################################"
read -p "Will this Server host METADATA SERVER service ? (Y/n) " Yn
echo "##########################################################################################################################################"
case $Yn in
n ) 
echo "##########################################################################################################################################"
echo "Please enter the METADATA SERVER IP Address"
read metadataServerIp
echo "##########################################################################################################################################"
while [ -z "$metadataServerIp" ]
do	printf 'Please Enter metadataServerIp IP Address: '
	read -r metadataServerIp
	[ -z "$metadataServerIp" ] && echo 'metadataServerIp cannot be empty; try again.'
done
echo "This Server will be connected to METADATA SERVER $metadataServerIp"
logit "Success: This Server will be connected to METADATA SERVER $metadataServerIp"
echo "##########################################################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
logit "Success: function advance_configuration_pcs"
create_storage
permission_sqream
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
pacemaker_no_meta
formula_advance_pcs
copy_files
limitQuery_no_meta
;;
* ) 
echo "Continue with Standard SQream Installation"
logit "Success: Continue with Standard SQream Installation"
metadataServerIp=$machineip
echo "##########################################################################################################################################"
echo "Enter Your SQream Storage Path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream Storage Path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage Path cannot be empty; try again.'
done
logit "Success: Storage Path is $cluster"
logit "Success: function advance_configuration_pcs"
create_storage
permission_sqream
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
pacemaker
formula_advance_pcs
copy_files
limitQuery
 ;;
esac

}
################################### Pacemaker_reconfig_end ##############################################################################################
pacemaker_reconfig_end () {
logit "Started: pacemaker_reconfig_end"
clear
echo "##################################################################################################"
echo "Advance Reconfiguration Done."
echo "##################################################################################################"
echo "##################################################################################################
To start SQreamDB   >   sudo pcs cluster start $(hostname)

For SQreamDB Status >   sudo pcs status

To stop SQreamDB    >   sudo pcs cluster stop $(hostname)
##################################################################################################"
logit "Success: pacemaker_reconfig_end"
}
######################## Pacemaker_reconfig_no_meta ###################################################################################################
pacemaker_reconfig_no_meta () {
logit "Started: pacemaker_reconfig_no_meta"
echo "##########################################################################################################################################"
echo "Pacemaker Reconfiguration..."
echo "##########################################################################################################################################"
sudo pcs cluster destroy
sudo pcs cluster setup sqreamdb $(hostname)
sudo pcs cluster start
sudo pcs property set stonith-enabled=false
sudo pcs property set no-quorum-policy=ignore
sudo pcs property set start-failure-is-fatal=false
logit "Success: pacemaker_reconfig_no_meta"
}
######################## Pacemaker_reconfig ###########################################################################################################
pacemaker_reconfig () {
logit "Started: pacemaker_reconfig"
echo "##########################################################################################################################################"
echo "Pacemaker Reconfiguration..."
echo "##########################################################################################################################################"
sudo pcs cluster destroy
sudo pcs cluster setup sqreamdb $(hostname)
sudo pcs cluster start
sudo pcs property set stonith-enabled=false
sudo pcs property set no-quorum-policy=ignore
sudo pcs property set start-failure-is-fatal=false
echo "==>Creating LB resource"
sudo pcs resource create LB systemd:serverpicker \
op start timeout=30s on-fail=restart \
op stop timeout=30s on-fail=ignore \
op monitor on-fail=restart interval=20s role=Started
sudo pcs constraint location LB prefers $(hostname)
echo "==>Creating MS resource"
sudo pcs resource create MS systemd:metadataserver \
    op start timeout=30s on-fail=restart \
    op stop timeout=30s on-fail=ignore \
    op monitor on-fail=restart interval=20s role=Started
sudo pcs constraint location MS prefers $(hostname)
logit "Success: pacemaker_reconfig"
}
###################### Pacemaker_no_meta ###########################################################################################################
pacemaker_no_meta () {
logit "Started: pacemaker_no_meta"
echo "You Have Choose Pacemaker, Please insert hacluster user and password when ask"
sudo pcs cluster destroy
sudo pcs host auth $(hostname)
sudo pcs cluster setup sqreamdb $(hostname)
sudo pcs cluster start
sudo pcs property set stonith-enabled=false
sudo pcs property set no-quorum-policy=ignore
sudo pcs property set start-failure-is-fatal=false
logit "Success: pacemaker_no_meta"
}
###################### Pacemaker ##################################################################################################################
pacemaker () {
logit "Started: function pacemaker"
echo "You Have Choose Pacemaker, Please insert hacluster user and password when ask"
sudo pcs cluster destroy
sudo pcs host auth $(hostname)
sudo pcs cluster setup sqreamdb $(hostname)
sudo pcs cluster start
sudo pcs property set stonith-enabled=false
sudo pcs property set no-quorum-policy=ignore
sudo pcs property set start-failure-is-fatal=false
echo "==>Creating LB resource"
sudo pcs resource create LB systemd:serverpicker \
op start timeout=30s on-fail=restart \
op stop timeout=30s on-fail=ignore \
op monitor on-fail=restart interval=20s role=Started
sudo pcs constraint location LB prefers $(hostname)
echo "==>Creating MS resource"
sudo pcs resource create MS systemd:metadataserver \
    op start timeout=30s on-fail=restart \
    op stop timeout=30s on-fail=ignore \
    op monitor on-fail=restart interval=20s role=Started
sudo pcs constraint location MS prefers $(hostname)
logit "Success: function pacemaker"
}
##################################### Function formula_advance #################################################################################
formula_advance_pcs () {
logit "Started: formula_advance_pcs"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "##########################################################################################################################################"
echo "Number of GPUs: $num_gpus"
i=0
while [ $i -lt $num_gpus ]; do
echo "##########################################################################################################################################"
echo "Total GPU Memory per GPU Card ID"
echo "GPU $i: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i $i) MB"
echo "##########################################################################################################################################"
    i=$((i + 1))
done
current_worker_id=1
gpu_id=0
while [ $gpu_id -lt $num_gpus ]; do 
echo "Enter the number of workers you want to run on GPU $gpu_id: "
read worker_count_gpu
echo "##########################################################################################################################################"
while [ -z "$worker_count_gpu" ]
do	printf "Enter the number of workers you want to run on GPU $gpu_id: "
	read -r worker_count_gpu
	[ -z "$worker_count_gpu" ] && echo 'worker_count_gpu cannot be empty; try again.'
done
read -p "Do You want to customize cudaMemQuota ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y ) 
echo "Enter the desired cudaMemQuota value "
read new_cuda
echo "##########################################################################################################################################"
 ;;
* ) 
echo "##########################################################################################################################################"
echo "Using Default Value ( 96% / worker_count ) "
new_cuda=$((96 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac
      
    create_config_template_file
    generate_config_files_pcs "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done
logit "Success: formula_advance_pcs"
}
##################################### Function formula_advance #################################################################################
formula_advance_monit () {
logit "Started: formula_advance_monit"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "##########################################################################################################################################"
echo "Number of GPUs: $num_gpus"
i=0
while [ $i -lt $num_gpus ]; do
echo "##########################################################################################################################################"
echo "Total GPU Memory per GPU Card ID"
echo "GPU $i: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i $i) MB"
echo "##########################################################################################################################################"
    i=$((i + 1))
done
current_worker_id=1
gpu_id=0
while [ $gpu_id -lt $num_gpus ]; do 
echo "Enter the number of workers you want to run on GPU $gpu_id: "
read worker_count_gpu
echo "##########################################################################################################################################"
while [ -z "$worker_count_gpu" ]
do	printf "Enter the number of workers you want to run on GPU $gpu_id: "
	read -r worker_count_gpu
	[ -z "$worker_count_gpu" ] && echo 'worker_count_gpu cannot be empty; try again.'
done
read -p "Do You want to customize cudaMemQuota ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y ) 
echo "Enter the desired cudaMemQuota value "
read new_cuda
echo "##########################################################################################################################################"
 ;;
* ) 
echo "##########################################################################################################################################"
echo "Using Default Value ( 96% / worker_count ) "
new_cuda=$((96 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac

    logit "Success: formula_advance_monit"  
    create_config_template_file
    generate_config_files_monit "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done

}
#################### formula_advance #################################################################################################################
formula_advance () {
logit "Started: formula_advance"
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "##########################################################################################################################################"
echo "Number of GPUs: $num_gpus"
i=0
while [ $i -lt $num_gpus ]; do
echo "##########################################################################################################################################"
echo "Total GPU Memory per GPU Card ID"
echo "GPU $i: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i $i) MB"
echo "##########################################################################################################################################"
    i=$((i + 1))
done
current_worker_id=1
gpu_id=0
while [ $gpu_id -lt $num_gpus ]; do 
echo "Enter the number of workers you want to run on GPU $gpu_id: "
read worker_count_gpu
echo "##########################################################################################################################################"
while [ -z "$worker_count_gpu" ]
do	printf "Enter the number of workers you want to run on GPU $gpu_id: "
	read -r worker_count_gpu
	[ -z "$worker_count_gpu" ] && echo 'worker_count_gpu cannot be empty; try again.'
done

read -p "Do You want to customize cudaMemQuota ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
y ) 
echo "Enter the desired cudaMemQuota value "
read new_cuda
echo "##########################################################################################################################################"
 ;;
* ) 
echo "##########################################################################################################################################"
echo "Using Default Value ( 96% / worker_count ) "
new_cuda=$((96 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac
      
    create_config_template_file
    generate_config_files "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done
logit "Success: formula_advance"
}
##################### Check  OS Version #########################################################################################
check_os_version () {
LinuxDistro=$(cat /etc/os-release |grep VERSION_ID |cut -d "=" -f2| sed -e 's/[" ]*//' | sed -e 's/[ "]$//'| cut -c -1)

if [[ $(echo $LinuxDistro|grep '7') ]];then
   echo "OS Version 7"
   sudo subscription-manager repos --enable rhel-7-server-optional-rpms
   sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
   sudo yum install epel-release -y
   sudo yum install ntp pciutils monit zlib-devel openssl-devel kernel-devel-$(uname -r) kernel-headers-$(uname -r) gcc net-tools wget jq libffi-devel gdbm-devel tk-devel xz-devel sqlite-devel readline-devel bzip2-devel ncurses-devel zlib-devel -y
   
else
   echo "OS Version 8"
   sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
   sudo subscription-manager repos --enable rhel-8-for-x86_64-appstream-rpms
   sudo subscription-manager repos --enable rhel-8-for-x86_64-baseos-rpms
   sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
   sudo dnf install chrony pciutils monit zlib-devel openssl-devel kernel-devel-$(uname -r) kernel-headers-$(uname -r) gcc net-tools wget jq libffi-devel xz-devel ncurses-compat-libs libnsl gdbm-devel tk-devel sqlite-devel readline-devel texinfo -y
fi
}
###################################### Copy All Created Config files and Services only for Metadata ############################################
meta_copy_files() {
  logit "Started metadata_copy_files"
sudo mkdir -p /etc/sqream
sudo mv metadataserver.conf /etc/sqream
sudo mv metadataserver.service /etc/sqream
sudo mv metadataserver_config.json /etc/sqream 
sudo mv  server_picker* /etc/sqream
sudo mv  serverpicker* /etc/sqream
sudo mv /etc/sqream/metadataserver.service /usr/lib/systemd/system/
sudo mv /etc/sqream/serverpicker.service /usr/lib/systemd/system/
sudo cp /usr/local/sqream/etc/sqream_env.sh /etc/sqream
sudo cp /usr/local/sqream/etc/server_picker_log_properties /etc/sqream
sudo cp /usr/local/sqream/etc/metadata_log_properties /etc/sqream
sudo cp /usr/local/sqream/etc/sqreamd_log_properties /etc/sqream
sudo cp /usr/local/sqream/etc/flags* /etc/sqream
sudo chown -R sqream:sqream /usr/local/sqream
sudo chown -R sqream:sqream /etc/sqream
sudo systemctl daemon-reload
logit "Success: metadata_copy_files"
}
################################# CBO installer #################################################################################
cbo_installer() {
clear
echo "##########################################################################################################################################"
if  [ ! -f /usr/local/sqream/bin/cbo-backend ];then
echo "SQreamDB package has no CBO support"
echo "##########################################################################################################################################"
exit
fi
echo "##########################################################################################################################################"
sudo cp /usr/local/sqream/service/md-service.service /usr/lib/systemd/system/
cp /usr/local/sqream/etc/md-service.conf /etc/sqream
cp /usr/local/sqream/etc/cbo-backend.conf /etc/sqream
sudo cp /usr/local/sqream/service/cbo*.service /usr/lib/systemd/system/
MD_HOST=$(cat /etc/sqream/sqream1_config.json | grep 'metadataServerIp' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
echo "##########################################################################################################################################"
echo "Welcome to SQream CBO installer"
echo "Please Enter JAVA_HOME PATH"
read JAVA_HOME
if  [ ! -f $JAVA_HOME/bin/java ];then
echo "No JAVA_HOME Found"
exit
fi
#echo "##########################################################################################################################################"
#echo "Please insert BACKEND HOST IP Address"
#read BACKEND_HOST
#while [ -z "$BACKEND_HOST" ]
#do      printf 'Please insert BACKEND HOST IP Address: '
#        read -r BACKEND_HOST
#        [ -z "$BACKEND_HOST" ] && echo 'BACKEND HOST IP Address cannot be empty; try again.'
#done
echo "##########################################################################################################################################"
echo "Your current Metadataserver IP: $MD_HOST"
read -p "Do you want to change Metadataserver IP ? (y/N) " yN
case $yN in
y ) echo "Please insert METADATA HOST IP Address"
read MD_HOST
while [ -z "$MD_HOST" ]
do      printf 'Please insert METADATA HOST IP Address: '
        read -r MD_HOST
        [ -z "$MD_HOST" ] && echo 'METADATA HOST IP Address cannot be empty; try again.'
done
cat <<EOF | tee /etc/sqream/cbo-client.conf > /dev/null
JAVA_HOME=$JAVA_HOME
BINDIR=/usr/local/sqream/bin
RUN_USER=sqream
LOG_DIR=/var/log/sqream
CONFDIR=/etc/sqream/
JAR=compiler-frontend.jar
CBO_PORT=6666
BACKEND_HOST=127.0.0.1
BACKEND_PORT=6665
MD_PORT=6668
MD_HOST=127.0.0.1
TMEM=16m
MEM=8g
LOGLEVEL=INFO
EOF
cat <<EOF | tee /etc/sqream/md-service.conf > /dev/null
SERVICE_NAME=md-service
RUN_USER=sqream
BINDIR=/usr/local/sqream/bin
BINFILE=metadata_service
LOG_DIR=/var/log/sqream
CONFDIR=/etc/sqream/
MDS_PORT=6668
MDS_ADDRESS=0.0.0.0
MD_SERVER_PORT=3105
MD_SERVER_ADDR=$MD_HOST
EOF
;;
* )
echo "##########################################################################################################################################"
echo "stay with current METADATA HOST IP Address: $MD_HOST"
echo "##########################################################################################################################################"
MD_HOST=$MD_HOST
cat <<EOF | tee /etc/sqream/cbo-client.conf > /dev/null
JAVA_HOME=$JAVA_HOME
BINDIR=/usr/local/sqream/bin
RUN_USER=sqream
LOG_DIR=/var/log/sqream
CONFDIR=/etc/sqream/
JAR=compiler-frontend.jar
CBO_PORT=6666
BACKEND_HOST=127.0.0.1
BACKEND_PORT=6665
MD_PORT=6668
MD_HOST=127.0.0.1
TMEM=16m
MEM=8g
LOGLEVEL=INFO
EOF
cat <<EOF | tee /etc/sqream/md-service.conf > /dev/null
SERVICE_NAME=md-service
RUN_USER=sqream
BINDIR=/usr/local/sqream/bin
BINFILE=metadata_service
LOG_DIR=/var/log/sqream
CONFDIR=/etc/sqream/
MDS_PORT=6668
MDS_ADDRESS=0.0.0.0
MD_SERVER_PORT=3105
MD_SERVER_ADDR=$MD_HOST
EOF
;;
esac
sudo chown -R sqream:sqream /etc/sqream
sudo systemctl daemon-reload
echo '
check process cbo-backend with pidfile /var/run/cbo-backend.pid
start program =  "/usr/bin/systemctl start cbo-backend.service"
stop program =  "/usr/bin/systemctl stop cbo-backend.service"

check process cbo-client with pidfile /var/run/cbo-client.pid
start program =  "/usr/bin/systemctl start cbo-client.service"
stop program =  "/usr/bin/systemctl stop cbo-client.service"

check process md-service with pidfile /var/run/md-service.pid
start program =  "/usr/bin/systemctl start md-service.service"
stop program =  "/usr/bin/systemctl stop md-service.service"
'| sudo tee -a   /etc/monit.d/monitrc >> /dev/null
json_file=/etc/sqream/sqream_config_legacy.json
jq '.developerMode = true  | .useGrpcCompiler = true'   "$json_file" > temp.json && mv temp.json "$json_file"
sudo monit reload all
echo "###################################################################################################"
echo "CBO installed successfuly"
echo "###################################################################################################"
sleep 3
echo "###################################################################################################"
echo '
to check CBO services:
sudo monit start all
sudo monit status all'
echo "###################################################################################################"
}
#################################################################################################################################
help () 
{
  echo "usage: $0 [OPTIONS]"
  echo "Options:"
  clear
  echo "###################################################################################################"
  echo "-h, --help              show this help message end exit"
  echo "---------------------------------------------------------------------------------------------------"
  echo "-f,                     Install SQreamDB On-Prem with Monit"
  echo "                        example: sudo ./sqream-install-v1.sh -f < path to SQreamDB Package> "
  echo "---------------------------------------------------------------------------------------------------"  
  echo "-a,                     Reconfig SQreamDB On-Prem with Monit"
  echo "                        example: sudo ./sqream-install-v1.sh -a "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-u,                     Upgrade SQreamDB Version"
  echo "                        example: sudo ./sqream-install-v1.sh -u < path to SQreamDB Package> "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-aws,                   Install SQreamDB On AWS Cloud"
  echo "                        example: sudo ./sqream-install-v1.sh -aws < path to SQreamDB Package>  "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-reaws,                 Reconfig SQreamDB On AWS Cloud"
  echo "                        example: sudo ./sqream-install-v1.sh -reaws "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-oci,                   Install SQreamDB On OCI Cloud "
  echo "                        example: sudo ./sqream-install-v1.sh -oci < path to SQreamDB Package> "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-reoci,                 Reconfig SQreamDB On OCI Cloud "
  echo "                        example: sudo ./sqream-install-v1.sh -oci "  
  echo "---------------------------------------------------------------------------------------------------"
  echo "-metadata,              Install SQreamDB METADATA only"
  echo "                        example: sudo ./sqream-install-v1.sh -metadata < path to SQreamDB Package> "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-cbo,                   Install SQreamDB CBO project"
  echo "                        example: sudo ./sqream-install-v1.sh -cbo "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-mig,                   Install SQreamDB with MIG support"
  echo "                        example: sudo ./sqream-install-v1.sh -mig "
  echo "---------------------------------------------------------------------------------------------------"  
  echo "-E,                     Expert Reconfiguration for SQreamDB on monit"
  echo "                        example: sudo ./sqream-install-v1.sh -E "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-L,                     View Log File ( logfile path: /tmp/sqream-installV1.log )"
  echo "                        example: sudo ./sqream-install-v1.sh -L "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-S,                     View Summary Log File"
  echo "                        example: sudo ./sqream-install-v1.sh -S "
  echo "###################################################################################################"
  exit
}
if [[ $# = 0 ]];then
help
fi
while [[ $# > 0 ]]
do
key="$1"
case $key in
        # Shows help
  -h|--help)
    help
  shift
  ;;

  -f|--file)
    shift; 
run_with_sudo
check_logfile
check_summary
sqream_temp
check_for_sqream_user
check_metadata_service_health
TARFILE=$1 
check_tar_file 
check_permissions_and_folders
verify_and_extract
move_package
make_symlink
mkdir sqream-temp 
cd sqream-temp
install_metadata_service
install_metadata_config_json
advance_configuration
cd ..
sudo rm -rf sqream-temp
summary
logit "SQream Install successfully"
shift;
  ;;

  -u|--upgrade_SQreamDB_With_Monit)
    shift;
         run_with_sudo
         check_logfile
         check_summary
         sqream_temp
         check_for_sqream_user
         check_metadata_service_health
         TARFILE=$1
         check_tar_file
         verify_and_extract
         check_permissions_and_folders_upgrade
         move_package
         make_symlink
         upgrade_storage
         echo "####################################################################"
         echo "SQreamDB Upgraded to $SQVER  Done."
         logit "Success: SQreamDB Upgraded to $SQVER  Done."
         echo "####################################################################"
         shift;
  ;;


  
  -a|--Advance_Configuration_Monit)
 shift; 
 run_with_sudo
 check_logfile
 check_summary
 check_if_sqreamdb_exist
 sqream_temp
 check_for_sqream_user
 check_metadata_service_health
  mkdir sqream-temp 
 cd sqream-temp
 advance_reconfiguration 
 echo "###################################"
 echo "Advance Reconfiguration Done."
 logit "Success: Advance Reconfiguration Done."
 echo "###################################"
 cd ..
 sudo rm -rf sqream-temp
 summary
 shift;
  ;;
  
  -p|--SQream_install_with_Pacemaker)
  shift;
run_with_sudo
check_logfile
check_summary
sqream_temp
check_for_sqream_user
check_pacemaker_service_health
check_metadata_service_health
TARFILE=$1 
check_tar_file 
check_permissions_and_folders
verify_and_extract
move_package
make_symlink
mkdir sqream-temp 
cd sqream-temp
install_metadata_service
install_metadata_config_json
sudo systemctl enable pcsd 
advance_configuration_pcs
end_pacemaker
cd ..
sudo rm -rf sqream-temp
summary
logit "SQream Install successfully"
  shift;
  ;;
  -A|--Advance_Configuration_PCS)
 shift; 
 run_with_sudo
 check_logfile
 check_summary
 check_if_sqreamdb_exist
 sqream_temp
 check_pacemaker_service_health
 check_metadata_service_health
 mkdir sqream-temp 
 cd sqream-temp
 advance_reconfiguration_pcs
 cd ..
 sudo rm -rf sqream-temp
 sudo pcs cluster stop --force
 pacemaker_reconfig_end
 summary
 shift;
  ;;
  -L| --SQream_Installer_Log_File)
  shift;
  more /tmp/sqream-installV1.log
  shift;
  ;;
 -E| --Expert_Configuration)
 shift;
 run_with_sudo
 check_logfile
 check_summary
 check_metadata_service_health
 etc_backup
 expert
 shift;
 ;;
 -EA| --Expert_Configuration_Auto)
 shift;
 run_with_sudo
 check_logfile
 check_summary
 check_metadata_service_health
 etc_backup
 expert_auto
 shift;
 ;;
 -S| --SQream_Summary_Log_File)
  shift;
  more /tmp/sqreamdb-summary.log
  shift;
  ;;
  -install| --SQream_Package_install)
  shift;
  check_os_version
  shift;
  ;;
  -ldap| --ldap_connect)
  ldap_connect
  shift;
  ;;
  -oci|--file)
    shift;
run_with_sudo
check_logfile
check_summary
sqream_temp
check_for_sqream_user
check_metadata_service_health
TARFILE=$1
check_tar_file
check_permissions_and_folders
verify_and_extract
move_package
make_symlink
mkdir sqream-temp
cd sqream-temp
install_metadata_service
install_metadata_config_json
advance_configuration_oci
cd ..
sudo rm -rf sqream-temp
summary
logit "SQream Install successfully"
shift;
  ;;
  -metadata|--metadata_only)
 shift;
 run_with_sudo;
check_metadata_service_health;
check_logfile;
sqream_temp;
etc_backup;
TARFILE=$1;
check_tar_file;
check_permissions_and_folders;
verify_and_extract;
move_package;
make_symlink;
mkdir sqream-temp;
cd sqream-temp;
metadata_only
install_metadata;
install_sqream_serverpicker_service;
install_sqream_serverpicker;
install_metadata_service;
install_metadata_config_json;
check_monit_service_health_meta;
meta_copy_files;
echo "SQream Install successfully"
cd ..
sudo rm -rf sqream-temp;
end_monit;
 exit;shift;
    ;;  
   -remetadata|--re_metadata_only)
 shift;
 run_with_sudo;
check_metadata_service_health;
check_logfile;
sqream_temp;
etc_backup;
mkdir sqream-temp;
cd sqream-temp;
re_metadata_only
install_metadata;
install_sqream_serverpicker_service;
install_sqream_serverpicker;
install_metadata_service;
install_metadata_config_json;
check_monit_service_health_meta;
re_meta_copy_files;
end_monit;
cd ..
sudo rm -rf sqream-temp;
 exit;shift;
    ;; 
-aws|--file)
    shift;
run_with_sudo
check_logfile
check_summary
sqream_temp
check_for_sqream_user
check_metadata_service_health
TARFILE=$1
check_tar_file
check_permissions_and_folders
verify_and_extract
move_package
make_symlink
mkdir sqream-temp
cd sqream-temp
install_metadata_service
install_metadata_config_json
advance_configuration_aws
cd ..
sudo rm -rf sqream-temp
summary
logit "SQream Install successfully"
shift;
  ;;
   -prepare| --prepare_for_SQream)
   shift;
   Prepare_for_SQream
   exit;shift;
    ;;
    
   -reaws|--reconfig_aws)
 shift; 
 run_with_sudo
 check_logfile
 check_summary
 check_if_sqreamdb_exist
 sqream_temp
 
 check_for_sqream_user
 check_metadata_service_health
  mkdir sqream-temp 
 cd sqream-temp
 advance_reconfiguration_aws
 echo "###################################"
 echo "Advance Reconfiguration AWS Done."
 logit "Success: Advance Reconfiguration AWS Done."
 echo "###################################"
 cd ..
 sudo rm -rf sqream-temp
 summary
 shift;
  ;;   
 -reoci|--reconfig_OCI)
 shift; 
 run_with_sudo
 check_logfile
 check_summary
 check_if_sqreamdb_exist
 sqream_temp
  check_for_sqream_user
 check_metadata_service_health
  mkdir sqream-temp 
 cd sqream-temp
 advance_reconfiguration_oci
 echo "###################################"
 echo "Advance Reconfiguration OCI Done."
 logit "Success: Advance Reconfiguration OCI Done."
 echo "###################################"
 cd ..
 sudo rm -rf sqream-temp
 summary
 shift;
  ;; 
-cbo|--cbo_install)
  shift;
  cbo_installer
  shift;
  ;; 
-mig|--sqreamdb_with_mig_support)
  shift;
  run_with_sudo
  TARFILE=$1 
  check_tar_file
  sqream_mig_setup
  mig_service
  check_logfile
  check_for_sqream_user
  check_permissions_and_folders
  verify_and_extract_mig
  move_package
  make_symlink
  mkdir sqream-temp 
  cd sqream-temp
  install_metadata_service
  install_metadata_config_json
  advance_configuration_mig
  cd ..
  sudo rm -rf sqream-temp
  sudo systemctl start sqream-mig-setup.service
  sudo systemctl enable monit
  sudo systemctl start monit 
  sudo monit reload &> /dev/null
  end_mig
  shift;
  ;;  
  
  *)
  echo "unrecognised option: $1"
  help
    ;;
esac
done
}
######################### END of Script ############################################################################################################################################
