First:

sudo chmod +x sqream-install-v1.sh

For Help Use :

sudo ./sqream-install-v1.sh -h

SQream install option are:
---------------------------------------------------------------------------
* -h, show this help massage and exit
---------------------------------------------------------------------------
* -f, Install SQreamDB with Monit 
*  example: sudo ./sqream-install-v1.sh -f < path to SQreamDB Package>
*  Installs sqreamDB, generates configs
---------------------------------------------------------------------------
* -u, Upgrade SQreamDB Version with Monit 
*  example: sudo ./sqream-install-v1.sh -u < path to SQreamDB Package>
*  Does not change configs. Only upgrades SqreamDB version and upgrades storage.
---------------------------------------------------------------------------
* -aws, Install SQreamDB On AWS Cloud
*  example: sudo ./sqream-install-v1.sh -aws
*  Change the number of workers, recreates configs.
---------------------------------------------------------------------------
* -reaws, Install SQreamDB On AWS Cloud
*  example: sudo ./sqream-install-v1.sh -aws
*  Change the number of workers, recreates configs.
---------------------------------------------------------------------------
* -oci, Install SQreamDB On OCI Cloud 
*  example: sudo ./sqream-install-v1.sh -oci < path to SQreamDB Package>
---------------------------------------------------------------------------
* -metadata, Install SQreamDB METADATA only
*  example: sudo ./sqream-install-v1.sh -metadata
---------------------------------------------------------------------------
* -E, Expert Configuration >  example: sudo ./sqream-install-v1.sh -E
*  Change flags values in existing json files. Does not change amount of workers.
---------------------------------------------------------------------------
* -L, Log File >  path: /tmp/sqream-installV1.log
*  Displays last installation log
---------------------------------------------------------------------------
* -S, Summary Log File >  path: /tmp/sqreamdb-summary.log
*  Displays configuration summary
---------------------------------------------------------------------------

  

