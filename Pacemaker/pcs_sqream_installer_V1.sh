#!/bin/bash
################################ Date  ##########################################################################################################
today=$(date +"%Y-%m-%d-%s")
################################ 
############################################ Log File ###########################################################################################
LOG_FILE="/tmp/pcs_sqream_installer_V1.log"
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
########################## SPOOL MEMORY (limitQueryMemoryGB lower then 128GB) ##################################################################
spool_memory(){
# spoolMemoryGB must be at least 10GB lower than limitQueryMemoryGB, otherwise the SQream workers will not start
# limitQueryMemoryGB and spoolMemoryGB are limits, not reserved RAM, so a worker gets at least a minimum limit
# (16GB on hosts with less than 20GB RAM, 20GB otherwise) as long as all workers together stay within 1.5 x RAM
logit "Started spool_memory"
if (( TOTAL_RAM_GB < 20 )); then
    min_limitQueryMemoryGB=16
else
    min_limitQueryMemoryGB=20
fi
if (( limitQueryMemoryGB < min_limitQueryMemoryGB )); then
    total_limitQueryMemoryGB=$(( number_of_workers * min_limitQueryMemoryGB ))
    if (( total_limitQueryMemoryGB * 2 > TOTAL_RAM_GB * 3 )); then
        clear
        echo "##################################################################################################"
        echo "##################################################################################################"
        echo "# ERROR: Not enough RAM for $number_of_workers workers"
        echo "# Each worker needs limitQueryMemoryGB of at least ${min_limitQueryMemoryGB}GB (spoolMemoryGB must be 10GB lower)"
        echo "# $number_of_workers workers x ${min_limitQueryMemoryGB}GB = ${total_limitQueryMemoryGB}GB, more than 1.5 x ${TOTAL_RAM_GB}GB RAM"
        echo "# Reduce the number of workers or add RAM, then run the installer again"
        echo "# Installation stopped"
        echo "##################################################################################################"
        echo "##################################################################################################"
        logit "Error: spool_memory - $number_of_workers workers x ${min_limitQueryMemoryGB}GB is more than 1.5 x ${TOTAL_RAM_GB}GB RAM, installation stopped"
        exit 1
    fi
    echo "##################################################################################################"
    echo "# WARNING: limitQueryMemoryGB per worker raised from ${limitQueryMemoryGB}GB to ${min_limitQueryMemoryGB}GB"
    echo "# $number_of_workers workers can use up to ${total_limitQueryMemoryGB}GB on a ${TOTAL_RAM_GB}GB RAM host"
    echo "##################################################################################################"
    logit "Warning: spool_memory - limitQueryMemoryGB raised from ${limitQueryMemoryGB}GB to ${min_limitQueryMemoryGB}GB, $number_of_workers workers up to ${total_limitQueryMemoryGB}GB on ${TOTAL_RAM_GB}GB RAM"
    limitQueryMemoryGB=$min_limitQueryMemoryGB
fi
if (( limitQueryMemoryGB < 30 )); then
    spoolMemoryGB=$(( limitQueryMemoryGB - 10 ))
else
    spoolMemoryGB=$(( limitQueryMemoryGB * 50 / 100 ))
fi
logit "Success: spool_memory"
}
###################### Start PCS Cluster #####################################################################################
start_pcs ()
{
echo "##########################################################################################################################################"
echo "To start SQreamDB HA Cluster:
      sudo pcs cluster start --all "
echo "##########################################################################################################################################"
}
##############################################################################################################################
remove_old_files () { 
logit "Started remove_old_files"
sudo mkdir /etc/sqream_etc_backup_$today 
sudo mv /etc/sqream/sqream*.conf /etc/sqream_etc_backup_$today/
sudo mv /etc/sqream/sqream*.json /etc/sqream_etc_backup_$today/
sudo chown -R sqream:sqream /etc/sqream_etc_backup_$today
logit "Success remove_old_files"
}
##############################################################################################################################
pcs_node_join () {
clear
echo "#####################################################################################"
logit "Started pcs_node_join"
echo "Please insert the new node hostname"
read join_hostname
while [ -z "$join_hostname" ]
do	printf 'Please insert the new node hostname: '
	read -r join_hostname
	[ -z "$join_hostname" ] && echo 'New Node Hostname cannot be empty; try again.'
done
echo "#####################################################################################"
logit "Join Hostname $join_hostname"
echo "Please insert the new node IP address"
read join_ip
while [ -z "$join_ip" ]
do	printf 'Please insert the new node IP address: '
	read -r join_ip
	[ -z "$join_ip" ] && echo 'new node IP address cannot be empty; try again.'
done
echo "#####################################################################################"
logit "Join IP Address $join_ip"
nodeid=$(cat  /var/lib/pacemaker/cib/cib.xml | grep 'node id' | wc -l )
echo "new node ID in the Cluster will be: $(( nodeid + 1 ))"
logit "New Node Number $join_node is: $(( nodeid + 1 ))"
PCS=$(pcs --version | cut -d . -f2)
if [ ${PCS} -eq 10 ]
   then     
   sudo pcs host auth $join_hostname addr=$join_ip
   fi
   if [ ${PCS} -eq 9 ]
   then
   echo "$join_hostname  $join_ip" | sudo tee -a  /etc/hosts
   sudo pcs cluster auth $join_hostname     
   fi
sudo pcs cluster node add $join_hostname
sudo pcs cluster enable $join_hostname
sudo pcs cluster start $join_hostname
sudo pcs constraint location PublicVIP prefers $join_hostname=90
sudo pcs constraint location LB prefers $join_hostname=90
sudo pcs constraint location MS prefers $join_hostname=90
sudo pcs constraint location lb_group prefers $join_hostname=90
echo "#####################################################################################"
echo "How many workers to add on this slave node"
read add_slave_worker_count_gpu
while [ -z "$add_slave_worker_count_gpu" ]
do	printf 'Please enter number of workers: '
	read -r add_master_worker_count_gpu
	[ -z "$add_slave_worker_count_gpu" ] && echo 'number of workers cannot be empty; try again.'
done
echo "#####################################################################################"
#### Pacemaker X times on Slave NODE ######################################################
join_node=$((join_node - 1))
i=0
current_worker_id=1
while [ $i -lt $add_slave_worker_count_gpu ]; do
echo "==>Creating SQream_${nodeid}_${current_worker_id} resource"
sudo pcs resource create SQREAM_${nodeid}_${current_worker_id} systemd:sqream${current_worker_id} \
op start timeout=60s on-fail=restart \
op stop timeout=60s on-fail=ignore \
op monitor on-fail=restart interval=20s role=Started 
sudo pcs constraint location SQREAM_${nodeid}_${current_worker_id} prefers $join_hostname 
sudo pcs constraint order start lb_group then start SQREAM_${nodeid}_${current_worker_id}
current_worker_id=$((current_worker_id + 1))
i=$((i + 1))
done
}
################################ pcs_add_workers ################################################################################################
pcs_add_workers () {
clear
echo "#####################################################################################"
echo "####### This proccess will add SQream workers to the Cluster ########################"
echo "#####################################################################################"
read -p "Do you want to add workers on master node ? (y/N) " yN
case $yN in
y ) 
echo "#####################################################################################"
current_workers=$(sudo cat /var/lib/pacemaker/cib/cib.xml | grep $HOSTNAME | grep location-SQREAM | sed -E 's/.*id="([^"]+)".*/\1/' | sed -E 's/.*INFINITY"([^"]+)".*/\1/')
echo "#####################################################################################"
echo "Current SQream Cluster workers details:
$current_workers"
echo "#####################################################################################"
echo "How many workers to add on master node"
read add_master_worker_count_gpu
while [ -z "$add_master_worker_count_gpu" ]
do	printf 'Please enter number of workers: '
	read -r add_master_worker_count_gpu
	[ -z "$add_master_worker_count_gpu" ] && echo 'number of workers cannot be empty; try again.'
done
#### Pacemaker X times on Master NODE ######################################################    
current_workers_num=$(sudo cat /var/lib/pacemaker/cib/cib.xml | grep $HOSTNAME | grep location-SQREAM | sed -E 's/.*id="([^"]+)".*/\1/' | sed -E 's/.*INFINITY"([^"]+)".*/\1/' | wc -l)
i=$(( current_workers_num + 1 ))
master_worker_count_gpu=$(( i + add_master_worker_count_gpu ))
while [ $i -lt  $master_worker_count_gpu  ] ; do
echo "==>Creating SQream_0_${i} resource"
sudo pcs resource create SQREAM_0_${i} systemd:sqream${i} \
op start timeout=60s on-fail=restart \
op stop timeout=60s on-fail=ignore \
op monitor on-fail=restart interval=20s role=Started 
sudo pcs constraint location SQREAM_0_${i} prefers $(hostname)
i=$((i + 1))
done
sudo pcs resource cleanup
;;
* )
continue
;;
esac
echo "#####################################################################################"
read -p "Do you want to add workers on slave node ? (y/N) " yN
case $yN in
y ) 
echo "#####################################################################################"
echo "Please enter slave node hostname"
read slave_hostname
while [ -z "$slave_hostname" ]
do	printf 'Please enter slave node hostname: '
	read -r slave_hostname
	[ -z "$slave_hostname" ] && echo 'slave node hostname cannot be empty; try again.'
done
echo "#####################################################################################"
nodeid=$(cat  /var/lib/pacemaker/cib/cib.xml | grep 'node id' | grep $slave_hostname |  grep -oP 'id="\K\d+')
echo "slave node ID in the Cluster is: $nodeid"
nodeid=$((nodeid - 1))
echo "#####################################################################################"
current_workers=$(sudo cat /var/lib/pacemaker/cib/cib.xml | grep $slave_hostname | grep location-SQREAM | sed -E 's/.*id="([^"]+)".*/\1/' | sed -E 's/.*INFINITY"([^"]+)".*/\1/')
echo "Current SQream Cluster workers details:
$current_workers"
echo "How many workers to add on slave node"
read add_slave_worker_count_gpu
while [ -z "$add_slave_worker_count_gpu" ]
do	printf 'How many workers to add on slave node: '
	read -r add_slave_worker_count_gpu
	[ -z "$add_slave_worker_count_gpu" ] && echo 'slave node number of workers to add cannot be empty; try again.'
done
echo "#####################################################################################"
#### Pacemaker X times on Slave NODE ######################################################
current_workers_num=$(sudo cat /var/lib/pacemaker/cib/cib.xml | grep $slave_hostname | grep location-SQREAM | sed -E 's/.*id="([^"]+)".*/\1/' | sed -E 's/.*INFINITY"([^"]+)".*/\1/' | wc -l)
i=$(( current_workers_num + 1 ))
slave_worker_count_gpu=$(( i + add_slave_worker_count_gpu ))
while [ $i -lt $slave_worker_count_gpu ]; do
echo "==>Creating SQream_${nodeid}_${i} resource"
sudo pcs resource create SQREAM_${nodeid}_${i} systemd:sqream${i} \
op start timeout=60s on-fail=restart \
op stop timeout=60s on-fail=ignore \
op monitor on-fail=restart interval=20s role=Started 
sudo pcs constraint location SQREAM_${nodeid}_${i} prefers $slave_hostname 
#current_worker_count_gpu=$((current_worker_count_gpu + 1))
i=$((i + 1))
done
sudo pcs resource cleanup
;;
* )
exit
;;
esac
sudo pcs cluster enable --all
}
################################ Delete Workers from Cluster #################################################
delete_workers () {
clear
echo "#####################################################################################"
echo "############ This proccess will delete SQream workers from Cluster ##################"
echo "--------------[ from start Worker number to end of Worker number ]-------------------"
echo "#####################################################################################"
echo "#####################################################################################"
current_workers=$(sudo cat /var/lib/pacemaker/cib/cib.xml | grep location-SQREAM | sed -E 's/.*id="([^"]+)".*/\1/' | sed -E 's/.*INFINITY"([^"]+)".*/\1/')
echo "Current SQream Cluster workers details:
$current_workers"
echo "#####################################################################################"
echo "#####################################################################################"
echo "Please enter node number in the Cluster to delete workers"
read nodeid
while [ -z "$nodeid" ]
do	printf 'Please enter node number in the Cluster: '
	read -r nodeid
	[ -z "$nodeid" ] && echo 'node number in the Cluster cannot be empty; try again.'
done
nodeid=$((nodeid - 1))
echo "Please enter start Worker number to delete"
read start_worker_count_node_0
echo "#####################################################################################"
echo "Please enter end Worker number to delete"
read end_worker_count_node_0

for i in $(seq $start_worker_count_node_0 $end_worker_count_node_0); do
sudo  pcs resource remove "SQREAM_${nodeid}_${i}" --force
i=$(( i + 1 )) 
done
}
################################ Remove Node From Cluster ######################################################
pcs_remove_node () {
echo "Please insert node hostname to be removed from Cluster"
read remove_hostname
sudo pcs cluster stop $remove_hostname
current_workers=$(sudo cat /var/lib/pacemaker/cib/cib.xml | grep $remove_hostname |grep location-SQREAM | sed -E 's/.*id="([^"]+)".*/\1/' | sed -E 's/.*INFINITY"([^"]+)".*/\1/' | wc -l)
benodeid=$(cat  /var/lib/pacemaker/cib/cib.xml | grep 'node id' | grep $remove_hostname |  grep -oP 'id="\K\d+')
nodeid=$(( benodeid - 1 ))
for i in $(seq 1 ${current_workers}); do
sudo pcs  resource remove SQREAM_${nodeid}_${i}
done
sleep 2
echo "removing $remove_hostname from Cluster"
sudo pcs cluster node remove $remove_hostname
sudo pcs host deauth $remove_hostname
echo "Currently Cluster node's $(sudo pcs cluster auth) "
}
################################ Join Node to Cluster ###########################################################################################
pcs_metadata_join () {
logit "Started pcs_metadata_join"
clear
echo "#####################################################################################"
echo "################# This proccess will Join metadata server to the Cluster ############"
echo "#####################################################################################"
echo "Please insert the new metadata node hostname"
read join_hostname
while [ -z "$join_hostname" ]
do	printf 'Please insert the new node hostname: '
	read -r join_hostname
	[ -z "$join_hostname" ] && echo 'New Node Hostname cannot be empty; try again.'
done
logit "Join Hostname $join_hostname"
echo "Please insert the new metadata node IP Address"
read join_ip
while [ -z "$join_ip" ]
do	printf 'Please insert the new node IP Address: '
	read -r join_ip
	[ -z "$join_hostname" ] && echo 'New Node IP Address cannot be empty; try again.'
done
logit "Join IP $join_ip"
PCS=$(pcs --version | cut -d . -f2)
if [ ${PCS} -eq 10 ]
   then     
   sudo pcs host auth ${join_hostname} addr=${join_ip} 
   sudo pcs cluster node add ${join_hostname}
   fi
   if [ ${PCS} -eq 9 ]
   then
   echo "$join_hostname  $join_ip" | sudo tee -a  /etc/hosts
   sudo pcs cluster auth ${join_hostname}
   sudo pcs cluster node add ${join_hostname}
   fi
sudo pcs cluster enable ${join_hostname}
sudo pcs cluster start ${join_hostname}
sudo pcs constraint location PublicVIP prefers $join_hostname=INFINITY
sudo pcs constraint location LB prefers $join_hostname=INFINITY
sudo pcs constraint location MS prefers $join_hostname=INFINITY
sudo pcs constraint location lb_group prefers $join_hostname=INFINITY
sudo pcs resource cleanup
logit "Success pcs_metadata_join"
}
########################################### Check summary File #################################################################################
check_summary () {
summary=$summary
 if [ -f $summary ];then
sudo rm -f $summary
fi
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
################# check_sqream_service_health ################################################################################################
check_sqream_service_health () {
logit "Started check_sqream_service_health"
sqream=$(sudo systemctl is-active  sqream1.service)
if [[ $sqream == active ]]; then
clear
echo "###############################################################################"
logit "Error: SQreamDB is running on this host, Please stop SQreamDB and start over."
echo "SQreamDB is running on this host, Please stop SQreamDB and start over."
read -p "Do you want to stop the Cluster ? (Y/n) " Yn
case $Yn in
n ) 
exit
logit "exit"
;;
* )
sudo pcs cluster stop --all
logit "sudo pcs cluster stop --all"
;;
esac
fi
logit "Success: check_sqream_service_health"
}
################# check_metadata_service_health ################################################################################################
check_metadata_service_health () {
logit "Started check_metadata_service_health"
metadata=$(sudo systemctl is-active  metadataserver.service)
if [[ $metadata == active ]]; then
clear
echo "###############################################################################"
echo "SQreamDB is running on this host, Please stop SQreamDB and start over."
echo "sudo pcs cluster stop --all"
logit "Error: SQreamDB is running on this host, Please stop SQreamDB and start over."
echo "###############################################################################"
exit 
fi
logit "Success: check_metadata_service_health"
}

############################################ summary ############################################################################################
summary () {
logit "Started: summary" 
summary=/tmp/sqreamdb-summary.log
num_gpus=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
workers_count=$(ls -dq /etc/sqream/*sqream*-service.conf | wc -l)
spoolMemoryGB_count=$(cat /etc/sqream/sqream_config_legacy.json | grep '"spoolMemoryGB"' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//'| sed -e 's/[, ]*$//' )
         echo "################### summary ##############################" > $summary
         echo "Number of GPUs $num_gpus" >> $summary
         echo "Number of SQream workers: $workers_count" >> $summary
         echo "SQream Storage Path: $cluster" >> $summary
         echo "Choosen IP $machineip" >> $summary
         echo "Choosen VIP $PublicVIP" >> $summary
         echo "##########################################################" >> $summary
        logit "################### summary ##############################"
        logit "Number of GPUs $num_gpus"
        logit "Number of SQream workers: $workers_count"
        logit "SQream Storage Path: $cluster"
        logit "Choosen IP $machineip"
        logit "Choosen VIP $PublicVIP"
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
############################## Prepare_for_SQream ############################################################################################
Prepare_for_SQream () {
logit "Started Prepare_for_SQream "
LinuxDistro=$(cat /etc/os-release |grep VERSION_ID |cut -d "=" -f2)
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
    logit "Prepare SQream for RHEL 9"
    sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms
    sudo subscription-manager repos --enable rhel-9-for-x86_64-highavailability-rpms
    sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    sudo dnf install chrony pciutils monit zlib-devel openssl-devel kernel-devel-$(uname -r) kernel-headers-$(uname -r) gcc net-tools wget jq libffi-devel xz-devel ncurses-compat-libs libnsl gdbm-devel tk-devel sqlite-devel readline-devel texinfo -y
    else
    echo "Unsupported OS version: $LinuxDistro"
    exit 1
   fi
}
############################## Prepare_PaceMaker ############################################################################################
Prepare_PaceMaker () {
logit "Started Prepare_for_SQream "
LinuxDistro=$(cat /etc/os-release |grep VERSION_ID |cut -d "=" -f2)
if [[ $(echo $LinuxDistro|grep '7') ]];then
        logit "Prepare Pacemaker for RHEL 7"
        sudo yum -y install corosync pacemaker pcs fence-agents-all
        sudo systemctl disable corosync.service
        sudo systemctl start pcsd.service
        sudo systemctl enable pcsd.service      

   elif [[ $(echo $LinuxDistro|grep '8') ]];then   
    logit "Prepare Pacemaker for RHEL 8"
    sudo subscription-manager repos --enable rhel-8-for-x86_64-highavailability-rpms
    sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    sudo dnf -y install corosync pacemaker pcs fence-agents-all
    sudo systemctl disable corosync.service
    sudo systemctl start pcsd.service
    sudo systemctl enable pcsd.service
elif [[ $(echo $LinuxDistro|grep '9') ]];then
    logit "Prepare Pacemaker for RHEL 9"
    sudo subscription-manager repos --enable rhel-9-for-x86_64-highavailability-rpms
    sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    sudo dnf -y install corosync pacemaker pcs fence-agents-all
    sudo systemctl disable corosync.service
    sudo systemctl start pcsd.service
    sudo systemctl enable pcsd.service

    else
    echo "Unsupported OS version: $LinuxDistro"
    exit 1
   fi
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
sudo mv  /usr/local/${SQVER} /usr/local/sqream_${today}
logit "Success: moving /usr/local/$SQVER to /usr/local/sqream_$today"
fi
sudo mkdir -p /etc/sqream
sudo chown -R sqream:sqream /etc/sqream
sudo mv license.enc /etc/sqream &> /dev/null
sudo mv sqream-admin-config.json /etc/sqream &> /dev/null
sudo mkdir -p /var/log/sqream
sudo chown -R sqream:sqream /var/log/sqream
logit "Success: check_permissions_and_folders"
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
spoolMemoryGB=$(($limitQueryMemoryGB - 50 ))
cudaMemQuota=$(cat /etc/sqream/sqream${i}_config.json | grep cudaMemQuota)
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $new_limitQueryMemoryGB,/" "$config_file"

done
logit "Success:  custom_limitQuery"
install_legacy
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
###################### check_pacemaker_service_health ###########################################################################################
check_pacemaker_service_health () {
logit "Started check_pacemaker_service_health"
if ! rpm -qa | grep pcs &> /dev/null
then
clear
echo "###############################################################################"
echo "Pacemaker is not installed, Please install Pacemaker and start over."
echo "-------------------------------------------------------------------------------"
echo "To prepare this server to SQreamDB and Pacemaker:
sudo ./pcs_sqream_installer_V1.sh -prepare"
logit "Error: Pacemaker is not installed, Please install Pacemaker and start over."
echo "###############################################################################"
exit
fi
logit "Success: check_pacemaker_service_health"
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
IP=${PublicVIP}
PORT=3105
LOGFILE=/var/log/sqream/serverpicker.log
EOF
logit "Success: install_sqream_serverpicker"
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

ExecStart=/bin/su - $RUN_USER -c "/bin/nohup ${DIR}/bin/metadata_server --config /etc/sqream/${SERVICE_NAME}_config.json --log_path ${METADATALOG}--log4_config ${LOG4} --num_deleters ${DELETERS}  &>> ${LOGFILE}/${SERVICE_NAME}.log"
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
spool_memory
echo "####################################################"
echo "limitQueryMemoryGB lower then 128GB" 
echo "Number of workers = $number_of_workers"
echo "####################################################"
echo "Limitquery = $limitQueryMemoryGB"
echo "####################################################"
echo "SpoolMemorey = $spoolMemoryGB"
echo "####################################################"
fi
for i in $(seq 1 ${number_of_workers}); do
config_file="/etc/sqream/sqream${i}_config.json"
sed -i "s/\"limitQueryMemoryGB\": limitQueryMemoryGB,/\"limitQueryMemoryGB\": $limitQueryMemoryGB,/" "$config_file"
done
logit "Success:  default_limitQuery"
install_legacy
}
############################# Function install_metadata metadataserver.conf #####################################################################
install_metadata() {
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
    "metadataServerIp": "$PublicVIP",
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
###################################### Function to generate and update config files Pacemaker #############################################
generate_config_files_pcs() {
logit "Started generate_config_files_pcs"
    gpu_id=$1
    #worker_count=$2
    i=0
    
        sport=5099
        port=4999
        while [ $i -lt $worker_count_gpu ]; do
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
        sed -i "s|@sqream_00@|sqream_0_${current_worker_id}|g" "$config_file"
        sed -i "s/\SERVICE_NAME\=sqream/\SERVICE_NAME\=sqream$current_worker_id/" "$config_service_file"
        sed -i "s|@sqream@|sqream${current_worker_id}.log|g" "$config_service_file"
        sed -i "s|@sqreamX-service.conf@|sqream${current_worker_id}-service.conf|g" "$service_file"

        ######################### Pacemaker X times ######################################################
        echo "==>Creating SQream_0_${current_worker_id} resource"
        sudo pcs resource create SQREAM_0_${current_worker_id} systemd:sqream${current_worker_id} \
	      op start timeout=60s on-fail=restart \
        op stop timeout=60s on-fail=ignore \
        op monitor on-fail=restart interval=20s role=Started
        sudo pcs constraint location SQREAM_0_${current_worker_id} prefers $(hostname)
        sudo pcs constraint order start lb_group then start SQREAM_0_${current_worker_id}
        ## Add Varibales X times##########################################################################
        ######################## Pacemaker X times ######################################################
        current_worker_id=$((current_worker_id + 1))
        i=$((i + 1))
        done
        install_metadata        
}
        
        ######################### Pacemaker X times ######################################################
        generate_config_files_pcs_slave() {
        clear
        echo "##########################################################################################"
        echo "How many workers to add on slave node"
        echo "##########################################################################################"
        read worker_count_gpu
        while [ -z "$worker_count_gpu" ]
        do	printf 'How many workers to add on slave node: '
	      read -r $worker_count_gpu
      	[ -z "$worker_count_gpu" ] && echo 'nuber of workers cannot be empty; try again.'
        done
        i=0
        current_worker_id=1
        while [ $i -lt $worker_count_gpu ]; do
        echo "==>Creating SQream_1_${current_worker_id} resource"
        sudo pcs resource create SQREAM_1_${current_worker_id} systemd:sqream${current_worker_id} \
	      op start timeout=60s on-fail=restart \
        op stop timeout=60s on-fail=ignore \
        op monitor on-fail=restart interval=20s role=Started
        sudo pcs constraint location SQREAM_1_${current_worker_id} prefers $slave_hostname
        sudo pcs constraint order start lb_group then start SQREAM_1_${current_worker_id}
        ## Add Varibales X times##########################################################################
        current_worker_id=$((current_worker_id + 1))
        i=$((i + 1))
        done
        logit "Success: generate_config_files_pcs"

        
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
############################## Check Storage ###################################################################################################
check_storage () {
logit "Started check_storage"
clear
if [ -d "$cluster" ];then
      logit "Storage exist "
      echo "Storage exist"
echo "____________________________________________________________"
echo "------------------------------------------------------------"
echo "==> SQream Storage exist in" ${cluster}
echo "____________________________________________________________"
echo "------------------------------------------------------------"
      logit "Success: check_storage"
      else
logit "Storage not exist"
logit "Cannot resume SQreamDB installation"
echo "Storage not exist"
echo "Cannot resume SQreamDB installation"
echo "____________________________________________________________"
exit
logit "Success: check_storage"
fi
}
############################## Create Storage ###################################################################################################
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
###################### Pacemaker ##################################################################################################################
pacemaker () {
logit "Started: function pacemaker"
sudo systemctl disable corosync.service &> /dev/null
sudo systemctl start pcsd.service &> /dev/null
sudo systemctl enable pcsd.service &> /dev/null
clear
echo "##########################################################################################################################################"
echo "                  You have choose SQreamDB HA , Please insert hacluster user and password when ask                                           "
echo "##########################################################################################################################################"
PCS=$(pcs --version | cut -d . -f2)
sudo pcs cluster destroy --all &> /dev/null
if [ ${PCS} -ge 10 ]
   then     
   sudo pcs host auth $(hostname) addr=${machineip} ${slave_hostname} addr=${slaveip}
   sudo pcs cluster setup sqreamdb $(hostname) addr=$machineip $slave_hostname addr=$slaveip
   fi
   if [ ${PCS} -eq 9 ]
   then
   echo "$machineip  $(hostname)" | sudo tee -a  /etc/hosts
   echo "$slaveip  $slave_hostname" | sudo tee -a  /etc/hosts
   sudo pcs cluster auth $(hostname)  $slave_hostname 
   #sudo pcs cluster sync
   sudo pcs cluster setup --name sqreamdb $(hostname) $slave_hostname --force
   fi
#sudo pcs cluster destroy --all &> /dev/null
sudo pcs cluster enable --all
sudo pcs cluster start --all
sudo pcs property set stonith-enabled=false
sudo pcs property set no-quorum-policy=ignore
sudo pcs property set symmetric-cluster=false
sudo pcs property set start-failure-is-fatal=false
echo "==>Creating PublicVIP resource"
sudo pcs resource create PublicVIP ocf:heartbeat:IPaddr2 ip=$PublicVIP \
    cidr_netmask=$netmask op monitor interval=20s
sudo pcs constraint location PublicVIP prefers $(hostname)=90
sudo pcs constraint location PublicVIP prefers $slave_hostname=90
echo "==>Creating LB resource"
sudo pcs resource create LB systemd:serverpicker \
op start timeout=30s on-fail=restart \
op stop timeout=30s on-fail=ignore \
op monitor on-fail=restart interval=20s role=Started
sudo pcs constraint location LB prefers $(hostname)=90
sudo pcs constraint location LB prefers $slave_hostname=90
echo "==>Creating MS resource"
sudo pcs resource create MS systemd:metadataserver \
    op start timeout=30s on-fail=restart \
    op stop timeout=30s on-fail=ignore \
    op monitor on-fail=restart interval=20s role=Started
sudo pcs constraint location MS prefers $(hostname)=90
sudo pcs constraint location MS prefers $slave_hostname=90
sudo pcs resource group add lb_group PublicVIP MS LB
sudo pcs constraint location lb_group prefers $(hostname)=90
sudo pcs constraint location lb_group prefers $slave_hostname=90
logit "Success: function pacemaker"
}
###################### Pacemaker_no_meta ###########################################################################################################
pacemaker_no_meta () {
logit "Started: pacemaker_no_meta"
echo "You have choose SQreamDB HA , Please insert hacluster user and password when ask"
sudo pcs cluster destroy
sudo pcs host auth $(hostname)
sudo pcs cluster setup sqreamdb $(hostname)
sudo pcs cluster start
sudo pcs property set stonith-enabled=false
sudo pcs property set no-quorum-policy=ignore
sudo pcs property set start-failure-is-fatal=false
logit "Success: pacemaker_no_meta"
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
spool_memory
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
#################### formula_advance ############################################################################################################
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
echo "##########################################################################################################################################"
echo "Enter the number of workers you want to run on GPU $gpu_id: "
echo "##########################################################################################################################################"
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
new_cuda=$((94 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac
      
    create_config_template_file
    generate_config_files "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done
logit "Success: formula_advance"
}
########################################### advance_reconfiguration_pcs ########################################################################
advance_reconfiguration_pcs () {
logit "Started: advance_reconfiguration_pcs"
clear
current_ip=$(cat /etc/sqream/sqream1_config.json | grep 'machineIP' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
clear
echo "##########################################################################################################################################"
echo "Welcome to SQreamDB HA reconfiguration"
echo "##########################################################################################################################################"
echo "Your current IP address is $current_ip"
echo "##########################################################################################################################################"
read -p "Do you want to change current IP ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
        y )
hostip=$(hostname -I)
echo "Please enter current host IP Address, select from below IP addresses list"
echo "$hostip"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please enter current host IP Address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Success: Current host IP Address $machineip"
;;
        * )
echo "Stay with Current IP address is $current_ip"
echo "##########################################################################################################################################"
machineip=$current_ip
netmask=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | grep $machineip | cut -c14-16 | grep -Eo "[0-9]+")
logit "Success: Stay with Current IP address is $current_ip"
;;
esac
node=0
echo "##########################################################################################################################################"
#current_vip=$(sudo pcs resource show PublicVIP | grep ip= |  cut -d '=' -f 2)
current_vip=$( cat /var/lib/pacemaker/cib/cib.xml | grep PublicVIP-instance_attributes-ip | sed -E 's/.*value="([^"]+)".*/\1/' )
echo "Your current Cluster VIP ip address is $current_vip"
echo "##########################################################################################################################################"
read -p "Do you want to change current VIP ip address ? (y/N) " yN
case $yN in
y )
echo "Please enter VIP ip address"
read PublicVIP
logit "PublicVIP is $PublicVIP "
while [ -z "$PublicVIP" ]
do	printf 'Please enter VIP ip address: '
	read -r PublicVIP
	[ -z "$PublicVIP" ] && echo 'VIP ip address cannot be empty; try again.'
done
;;
* )
PublicVIP=$current_vip
echo "Stay with Current VIP ip address"
;;
esac
echo "##########################################################################################################################################"
echo "Please enter slave node hostname"
read slave_hostname
while [ -z "$slave_hostname" ]
do	printf 'Please insert slave node hostname: '
	read -r slave_hostname
	[ -z "$slave_hostname" ] && echo 'slave node hostname cannot be empty; try again.'
done
logit "Slave Hostname is $slave_hostname"
echo "##########################################################################################################################################"
echo "Please enter slave node IP address"
read slaveip
while [ -z "$slaveip" ]
do	printf 'Please enter slave node IP address: '
	read -r slaveip
	[ -z "$slaveip" ] && echo 'slave node IP address cannot be empty; try again.'
done
logit "Slave Node IP is $slaveip"
echo "##########################################################################################################################################"
logit "Success: This server will be connected to VIP $PublicVIP"
echo "##########################################################################################################################################"
cluster=$(cat /etc/sqream/sqream1_config.json | grep 'cluster' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
echo "Your Current Storage is $cluster"
echo "##########################################################################################################################################"
logit "Success: SQream Storage Path change to $cluster" 
logit "Success: advance_reconfiguration_pcs"
#permission_sqream
install_sqream_serverpicker_service
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
pacemaker
formula_advance_pcs
remove_old_files
copy_files
limitQuery
}
#################################### advance_reconfiguration ####################################################################################
advance_reconfiguration () {
logit "Started: advance_reconfiguration"
current_ip=$(cat /etc/sqream/sqream1_config.json | grep 'machineIP' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
clear
echo "##########################################################################################################################################"
echo "Welcome to SQreamDB HA reconfiguration"
echo "##########################################################################################################################################"
echo "Your current IP address is $current_ip"
logit "Success: Your Current IP address is $current_ip"
echo "##########################################################################################################################################"
read -p "Do you want to change current IP ? (y/N) " yN
echo "##########################################################################################################################################"
case $yN in
        y )
hostip=$(hostname -I)
echo "Please enter current host IP address, select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please enter current host IP address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
netmask=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | grep $machineip | cut -c14-16 | grep -Eo "[0-9]+")
logit "Success: You choose this IP address $machineip"
;;
* )
echo "Stay with current IP address: $current_ip"
logit "Success: Stay with Current IP address is $current_ip"
echo "##########################################################################################################################################"
machineip=$current_ip
;;
esac
echo "##########################################################################################################################################"
#current_vip=$(sudo pcs resource show PublicVIP | grep ip= |  cut -d '=' -f 2)
current_vip=$( cat /var/lib/pacemaker/cib/cib.xml | grep PublicVIP-instance_attributes-ip | sed -E 's/.*value="([^"]+)".*/\1/' )
echo "Your current Cluster VIP ip address is $current_vip"
echo "##########################################################################################################################################"
read -p "Do you want to change current VIP ip address ? (y/N) " yN
case $yN in
y )
echo "Please enter VIP ip address"
read PublicVIP
logit "PublicVIP is $PublicVIP "
while [ -z "$PublicVIP" ]
do	printf 'Please enter VIP ip address: '
	read -r PublicVIP
	[ -z "$PublicVIP" ] && echo 'VIP ip address cannot be empty; try again.'
done
;;
* )
PublicVIP=$current_vip
echo "Stay with Current VIP ip address"
;;
esac
logit "Success: This Server will be connected to VIP $PublicVIP"
echo "##########################################################################################################################################"
echo "Please enter slave node number in the Cluster"
echo "Master=1 ,first slave=2 , all other slaves from 3 and above"
echo "##########################################################################################################################################"
read slave_node_id
while [ -z "$slave_node_id" ]
do	printf 'Please enter slave node number in the Cluster: '
	read -r slave_node_id
	[ -z "$slave_node_id" ] && echo 'slave node number in the Cluster cannot be empty; try again.'
done
node=$((slave_node_id - 1 ))
echo "##########################################################################################################################################"
echo "##########################################################################################################################################"
current_cluster=$(cat /etc/sqream/sqream1_config.json | grep 'cluster' | sed -e 's/.*://' | sed -e 's/[" ]*//' | sed -e 's/["],$//')
echo "Your current storage is $current_cluster"
echo "##########################################################################################################################################"
read -p "Do you want to change current sqream storage ? (y/N) " yN
case $yN in
y )
echo "Please enter new sqream storage path"
read new_cluster
while [ -z "$new_cluster" ]
do	printf 'Please enter new sqream storage path: '
	read -r new_cluster
	[ -z "$new_cluster" ] && echo 'sqream storage path cannot be empty; try again.'
done
cluster=$new_cluster
logit "SQream storage path is: $new_cluster "
;;
* )
cluster=$current_cluster
echo "Stay with Current sqream storage path $cluster"
logit "Success: Stay with Current sqream storage path $cluster"
;;
esac
echo "##########################################################################################################################################"
logit "Success: Your SQream Storage Path is: $cluster" 
logit "Success advance reconfiguration"
install_metadata
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
formula_advance
remove_old_files
copy_files
limitQuery
}
#################################### Function advance_configuration ############################################################################
advance_configuration () {
logit "Started: advance_configuration"
clear
echo "##########################################################################################################################################"
echo "Welcome to SQreamDB HA advance configuration"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please enter current host IP address, select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
logit "Machine IP is $machineip"
while [ -z "$machineip" ]
do	printf 'Please enter current host IP address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
netmask=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | grep $machineip | cut -c14-16 | grep -Eo "[0-9]+")
logit "PublicVIP netmask is $netmask"
echo "##########################################################################################################################################"
PCS=$(pcs --version | cut -d . -f2)
if [ ${PCS} -eq 9 ]
   then
echo "##########################################################################################################################################"
echo "Please enter Master Node Name"
read master_name
while [ -z "$master_name" ]
do	printf 'Please enter Master Node Name: '
	read -r master_name
	[ -z "$master_name" ] && echo 'Master Node Name cannot be empty; try again.'
done
logit "Master Node name is $master_name"
echo "##########################################################################################################################################"
echo "Please enter Master Node IP address"
read master_ip
while [ -z "$master_ip" ]
do	printf 'Please enter Master Node IP address: '
	read -r master_ip
	[ -z "$master_ip" ] && echo 'Master Node IP address cannot be empty; try again.'
done
logit "Master Node IP is $master_ip"
echo "##########################################################################################################################################"
echo "$master_ip  $master_name" | sudo tee -a  /etc/hosts
fi
echo "##########################################################################################################################################"
echo "Please enter VIP ip address"
read PublicVIP
logit "PublicVIP is $PublicVIP"
while [ -z "$PublicVIP" ]
do	printf 'Please enter VIP ip address: '
	read -r PublicVIP
	[ -z "$PublicVIP" ] && echo 'VIP cannot be empty; try again.'
done
logit "Success: Public VIP"
echo "##########################################################################################################################################"
echo "Please enter slave node number in the Cluster"
echo "Master=1 ,first slave=2 , all other slaves from 3 and above"
echo "##########################################################################################################################################"
read slave_node_id
while [ -z "$slave_node_id" ]
do	printf 'Please enter slave node number in the Cluster: '
	read -r slave_node_id
	[ -z "$slave_node_id" ] && echo 'slave node number in the Cluster cannot be empty; try again.'
done
node=$((slave_node_id - 1 ))
echo "##########################################################################################################################################"
echo "Enter Your SQream storage path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream storage path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream Storage path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
logit "Success: advance_configuration"
create_storage
permission_sqream
install_metadata
install_sqream_serverpicker_service 
install_sqream_serverpicker
create_service_config_template_file
install_sqream_services
formula_advance
copy_files
limitQuery
 
}

############################################## advance_configuration_pcs #####################################################################
advance_configuration_pcs () {
logit "Started: advance_configuration_pcs"
clear
echo "##########################################################################################################################################"
echo "Welcome to SQreamDB HA advance configuration"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please enter current host IP address, select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please enter current host IP address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Machine IP is $machineip"
netmask=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | grep $machineip | cut -c14-16 | grep -Eo "[0-9]+")
echo "##########################################################################################################################################"
echo "Please enter slave node IP address"
read slaveip
while [ -z "$slaveip" ]
do	printf 'Please enter slave node IP address: '
	read -r slaveip
	[ -z "$slaveip" ] && echo 'slave node IP cannot be empty; try again.'
logit "Slave Node IP is $slaveip"
done
echo "Please enter slave node hostname"
read slave_hostname
while [ -z "$slave_hostname" ]
do	printf 'Please enter slave node hostname: '
	read -r slave_hostname
	[ -z "$slave_hostname" ] && echo 'Slave node hostname cannot be empty; try again.'
done
logit "Slave Node Hostname is $slave_hostname"
echo "##########################################################################################################################################"
benode=2
node=$((benode - 1))
echo "Slave node ID in the Cluster, is $benode"
logit "Slave node ID in the Cluster, is $benode"
echo "##########################################################################################################################################"
echo "Please enter VIP ip address"
read PublicVIP
logit "PublicVIP is $PublicVIP"
while [ -z "$PublicVIP" ]
do	printf 'Please enter VIP ip address: '
	read -r PublicVIP
	[ -z "$PublicVIP" ] && echo 'VIP cannot be empty; try again.'
done
logit "Success: Public VIP"
echo "##########################################################################################################################################"
echo "Enter Your SQream storage path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream storage path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream storage path cannot be empty; try again.'
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
        sed -i "s|@sqream_00@|sqream_${node}_${current_worker_id}|g" "$config_file"
        sed -i "s/\SERVICE_NAME\=sqream/\SERVICE_NAME\=sqream$current_worker_id/" "$config_service_file"
        sed -i "s|@sqream@|sqream${current_worker_id}.log|g" "$config_service_file"
        sed -i "s|@sqreamX-service.conf@|sqream${current_worker_id}-service.conf|g" "$service_file"
                
        current_worker_id=$((current_worker_id + 1))
        i=$((i + 1))
        done
        
        install_metadata
        ################################################################################################# 
        logit "Success: generate_config_files"    
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
echo "##########################################################################################################################################"
echo "Enter the number of workers you want to run on GPU $gpu_id: "
echo "##########################################################################################################################################"
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
while [ -z "$new_cuda" ]
do	printf 'Enter the desired cudaMemQuota value: '
	read -r new_cuda
	[ -z "$new_cuda" ] && echo 'desired cudaMemQuota value cannot be empty; try again.'
done
echo "##########################################################################################################################################"
 ;;
* )
echo "##########################################################################################################################################"
echo "Using Default Value ( 96% / worker_count ) "
new_cuda=$((94 / $worker_count_gpu))
echo "##########################################################################################################################################"
;;
esac

    create_config_template_file
    generate_config_files_pcs "$gpu_id" "$worker_count_gpu"
    gpu_id=$((gpu_id + 1))
done
logit "Success: formula_advance_pcs"
generate_config_files_pcs_slave
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

############################################## pcs_metadata_only ###############################################################################
pcs_metadata_only () {
logit "Started: pcs_metadata_only"
clear
echo "##########################################################################################################################################"
echo "Welcome to SQreamDB HA , metadata server only"
echo "##########################################################################################################################################"
hostip=$(hostname -I)
echo "Please Enter Current Host IP Address, Select from below IP addresses list"
echo "$hostip"
echo "Please choose the relevant IP"
echo "Or use 127.0.0.1 as local host"
echo "##########################################################################################################################################"
read machineip
while [ -z "$machineip" ]
do	printf 'Please enter current host IP address: '
	read -r machineip
	[ -z "$machineip" ] && echo 'MachineIP cannot be empty; try again.'
done
logit "Machine IP is $machineip"
netmask=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | grep $machineip | cut -c14-16 | grep -Eo "[0-9]+")
logit "PublicVIP netmask is $netmask"
echo "##########################################################################################################################################"
echo "Please enter VIP ip address"
read PublicVIP
while [ -z "$PublicVIP" ]
do	printf 'Please enter VIP ip address: '
	read -r PublicVIP
	[ -z "$PublicVIP" ] && echo 'VIP ip address cannot be empty; try again.'
done
logit "Success: This Server will be connected to VIP $PublicVIP"
echo "##########################################################################################################################################"
echo "Enter Your SQream Cluster storage path: "
echo "##########################################################################################################################################"
read cluster
while [ -z "$cluster" ]
do	printf 'Enter Your SQream storage path: '
	read -r cluster
	[ -z "$cluster" ] && echo 'SQream storage path cannot be empty; try again.'
 done
logit "Success: Storage Path is $cluster"
logit "Success: pcs_metadata_only"
}
######################## some warnnings #####################################################
on_master () {
echo "###################################################"
echo "      This proccess should run on master node"
echo "###################################################"
read -p "Do you want to continue ? (y/N) " yN
echo "###################################################"
case $yN in
        y )
        ;;
        * )
        exit
        ;;
esac
}
on_slave () {
echo "###################################################"
echo "    This proccess should run on any slave node"
echo "###################################################"
echo "###################################################"
read -p "Do you want to continue ? (y/N) " yN
echo "###################################################"
case $yN in
        y )
        ;;
        * )
        exit
        ;;
esac
}
on_metadata () {
echo "###################################################"
echo " This proccess should run on metadata server node"
echo "###################################################"
echo "###################################################"
read -p "Do you want to continue ? (y/N) " yN
echo "###################################################"
case $yN in
        y )
        continue
        ;;
        * )
        exit
        ;;
esac
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
JAVA_HOME=/home/sqream/jdk-17.0.10
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
JAVA_HOME=/home/sqream/jdk-17.0.10
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

sudo systemctl daemon-reload
sudo systemctl enable --now cbo-backend.service
sudo systemctl enable --now cbo-client.service
sudo systemctl enable --now md-service.service
echo "###################################################################################################"
echo "CBO installed successfuly"
echo "###################################################################################################"
sleep 3
echo "###################################################################################################"
echo '
to check CBO services:
sudo systemctl status cbo-backend.service
sudo systemctl status cbo-client.service
sudo systemctl status md-service.service'
echo "###################################################################################################"
}
#################################################### HELP ########################################################################
help ()
{
  echo "usage: $0 [OPTIONS]"
  echo "Options:"
  clear
  echo "###################################################################################################"
  echo "-h, --help        show this help message end exit"
  echo "---------------------------------------------------------------------------------------------------"
  echo "-master,          Install master node Pacemaker Cluster"
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -master < path to SQreamDB Package >"
  echo "---------------------------------------------------------------------------------------------------"
  echo "-slave,           Install any slave node Pacemaker Cluster"
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -slave < path to SQreamDB Package > "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-remaster,        Reconfig master node"
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -remaster "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-reslave,         Reconfig slave node"
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -reslave "
  echo "---------------------------------------------------------------------------------------------------"
  #echo "-add-workers,     Add workers to SQream DB HA Cluster"
  #echo "                  example: sudo ./pcs_sqream_installer_V1.sh -add-workers"
  #echo "---------------------------------------------------------------------------------------------------"
  #echo "---------------------------------------------------------------------------------------------------"
  #echo "-delete-workers,  Delete workers from SQream HA Cluster"
  #echo "                  example: sudo ./pcs_sqream_installer_V1.sh -delete-workers"
  #echo "---------------------------------------------------------------------------------------------------"
  #echo "---------------------------------------------------------------------------------------------------"
  echo "-prepare,         Prepare OS for SQreamDB and Pacemaker"
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -prepare "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-metadata,        Install SQream DB metadata server for Pacemaker Cluster"      
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -metadata < path to SQreamDB Package >"
  echo "---------------------------------------------------------------------------------------------------"
  echo "-join,            Join new GPU node to Pacemaker Cluster"
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -join "
  echo "---------------------------------------------------------------------------------------------------"
  echo "-join_metadata,   Join SQreamDB Metadata Server to Pacemaker Cluster"         
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -join_metadata"
  echo "---------------------------------------------------------------------------------------------------"
  echo "-S, --Summary Log File"
  echo "                  example: sudo ./pcs_sqream_installer_V1.sh -S "
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

  -master|--file)
    shift;
    check_pacemaker_service_health;
    on_master;
    check_sqream_service_health;
    check_metadata_service_health;
    run_with_sudo;
    check_logfile;
    check_summary;
    sqream_temp;
    etc_backup;
    TARFILE=$1 ;
    check_tar_file ;
    check_permissions_and_folders;
    verify_and_extract;
    move_package;
    make_symlink;
    mkdir sqream-temp;
    cd sqream-temp;
    install_metadata_service;
    install_metadata_config_json;
    advance_configuration_pcs;
    cd .. ;
    sudo rm -rf sqream-temp;
    sudo pcs cluster stop --all;
    sudo chown sqream:sqream /etc/sqream/*
    start_pcs;
    summary;    
logit "SQream Install successfully"
  shift;
    exit;shift;
    ;;
    
 -slave|--file)
    shift;
    check_pacemaker_service_health;
    on_slave;
    check_sqream_service_health;
    check_metadata_service_health;
    run_with_sudo;
    sqream_temp;
    etc_backup;
    TARFILE=$1 ;
    check_tar_file ;
    check_permissions_and_folders;
    verify_and_extract;
    move_package;
    make_symlink;
    mkdir sqream-temp;
    cd sqream-temp;
    install_metadata_service;
    install_metadata_config_json;
    advance_configuration;
    cd .. ;
    sudo rm -rf sqream-temp;
    sudo chown sqream:sqream /etc/sqream/*
    summary;
logit "SQream Install successfully"
  shift;
    exit;shift;
    ;;
  -prepare|--Prepare_Pacemake_SQream)
   shift;
   Prepare_PaceMaker;
   Prepare_for_SQream;
   exit;shift;
    ;;
  -remove|--remove_resource)
  shift;
  echo "Please Enter Resource Name to Delete"
  read resource_name
  sudo pcs resource delete $resource_name
  exit;shift;
    ;;

  -reslave|--Reconfigure_Slave_Node)
  shift;
 on_slave;
 run_with_sudo;
 check_sqream_service_health;
 check_metadata_service_health;
 check_logfile;
 check_summary;
 check_if_sqreamdb_exist;
 sqream_temp; 
 mkdir sqream-temp;
 cd sqream-temp;
 install_metadata_service;
 install_metadata_config_json;
 install_metadata
 advance_reconfiguration;
 cd .. ;
 sudo rm -rf sqream-temp;
 summary;
 exit;shift;
    ;;
-remaster|--Reconfigure_Master_Node)
  shift;
 on_master;
 run_with_sudo;
 check_sqream_service_health;
 check_metadata_service_health;
 check_logfile;
 check_summary;
 check_if_sqreamdb_exist;
 sqream_temp;
 mkdir sqream-temp;
 cd sqream-temp;
 install_metadata_service;
 install_metadata_config_json;
 advance_reconfiguration_pcs;
 cd .. ;
 sudo rm -rf sqream-temp;
 summary;
 exit;shift;
    ;;
 -metadata|--pcs_metadata_only)
 shift;
check_pacemaker_service_health;
on_metadata;
 run_with_sudo;
check_sqream_service_health;
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
pcs_metadata_only;
check_storage;
install_metadata;
install_sqream_serverpicker_service;
install_sqream_serverpicker;
install_metadata_service;
install_metadata_config_json;
meta_copy_files;
cd ..
sudo chown sqream:sqream /etc/sqream/*
sudo rm -rf sqream-temp;
echo "#####################################"
echo "# SQreamDB Meatadata Only Installed"
echo "#####################################"
 exit;shift;
    ;;  
-sqreamdb|--SQream_DB_only)
 shift;
run_with_sudo;
check_sqream_service_health;
check_metadata_service_health;
check_logfile;
sqream_temp;
check_pacemaker_service_health;
TARFILE=$1;
check_tar_file;
etc_backup;
check_permissions_and_folders;
verify_and_extract;
move_package;
make_symlink;
mkdir sqream-temp;
cd sqream-temp;
install_metadata;
install_metadata_service;
install_metadata_config_json;
advance_configuration;
cd ..
sudo rm -rf sqream-temp;
 exit;shift;
    ;;  
-join_gpu|--pcs_node_join)    
    shift;
    pcs_node_join
    exit;shift;
    ;; 
    -join_metadata|--pcs_metadata_join)    
    shift;
    pcs_metadata_join
    exit;shift;
    ;; 
-S|--summery_report)
  shift;
  more /tmp/sqreamdb-summary.log
exit;shift;
    ;; 
-add-workers|--add-workers)
  shift;
  on_master;
  pcs_add_workers
  exit;shift;
    ;;
-delete-workers|--delete-workers)
  shift;
  on_master;
  delete_workers
  exit;shift;
    ;;    
-remove_node|--remove_node)
  shift;
  on_master;
  pcs_remove_node
  exit;shift;
    ;; 
-status|--clsuster-status)
  shift;
 sudo pcs resource cleanup | watch sudo pcs status
 exit;shift;
    ;; 
-cbo|--cbo_install)
  shift;
  cbo_installer
  shift;
  ;; 
*)
  echo "unrecognised option: $1"
  help
    ;;
esac
done




