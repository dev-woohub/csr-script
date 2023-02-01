#!/bin/bash
##################################################################
#                         .__         ___.        .__            #
#    __  _  ______   ____ |  |__  __ _\_ |__      |__| ____      #
#    \ \/ \/ /  _ \ /  _ \|  |  \|  |  \ __ \     |  |/  _ \     #
#     \     (  <_> |  <_> )   Y  \  |  / \_\ \    |  (  <_> )    #
#      \/\_/ \____/ \____/|___|  /____/|___  / /\ |__|\____/     #
#                              \/          \/  \/                #
##################################################################

DATE=$(date "+%Y%m%d")
DATE_TIME=$(date "+%Y%m%d-%H%M%S")
HOME_DIR="root"
CSR_RVS_DIR="HyperCloud"
CSR_RVS_STATUS_BACKUP_DIR="RVS"
RVS_PATH=/$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE
COUNT=0

ESC=`printf "\033"`;

mkdir_backup_dir() {
    echo "[START TASK1] Create CSR-RVS Directory"
    if [ ! -d /$HOME_DIR/$CSR_RVS_DIR ]; then
        mkdir /$HOME_DIR/$CSR_RVS_DIR
        echo "[CREATE TASK1-1] /$HOME_DIR/$CSR_RVS_DIR"
    else
        echo "[PASS TASK1-1] /$HOME_DIR/$CSR_RVS_DIR Directory already exists"
    fi
    if [ ! -d /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR ]; then
        mkdir /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR
        echo "[CREATE TASK1-2] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR"
    else
        echo "[PASS TASK1-2] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR Directory already exists"
    fi
    if [ ! -d /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE ]; then
        mkdir /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE
        echo "[CREATE TASK1-3] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE"
        export RVS_PATH=/$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE
        echo "[FINISH TASK1] $RVS_PATH created"
        ((COUNT+=2))
    else
        echo "[OVERLAP TASK1] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE Directory already exists"
        ((COUNT+=1))
    fi
}

cluster_state_backup() {
    PODMAN_STATUS=$(podman ps -a | grep tmaxcloud | awk '{print $7}')
    NODE_STATUS=$(kubectl get node | awk '{print $2}')
    NODE_NAME=$(kubectl get node | awk '{print $1}')
    POD_STATUS=$(kubectl get pods -A | awk '{print $4}')
    POD_NAMESPACE=$(kubectl get pods -A | awk '{print $1}')
    POD_NAME=$(kubectl get pods -A | awk '{print $2}')

    echo "[START TASK2] Backup the cluster state on the Master1($HOSTNAME) - $RVS_PATH/cluster-history"
    echo "[TASK2-1] Podman Checking"
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Podman Private Registry State" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    podman ps -a | grep tmaxcloud >> $RVS_PATH/cluster-history
    if [[ "$PODMAN_STATUS" == *"Exited"* ]]; then
        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
        echo "Podman Private Registry Issue" >> $RVS_PATH/cluster-issue-history
        date >> $RVS_PATH/cluster-issue-history
        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
        podman ps -a | grep tmaxcloud >> $RVS_PATH/cluster-issue-history
        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
        echo "Podman Private Registry Issue" >> $RVS_PATH/cluster-issue-history
        date >> $RVS_PATH/cluster-issue-history
        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
        podman logs tmaxcloud >> $RVS_PATH/podman-registry-issue.log
        echo "$RVS_PATH/podman-registry-issue.log created"
    fi
    echo "[COMPLETE] Podman Checking"

    echo "[TASK2-2] Node Checking"
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Cluster ALL Node State" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    kubectl get node -A -owide >> $RVS_PATH/cluster-history
    node_name_arr=($NODE_NAME)
    node_status_arr=($NODE_STATUS)
    b=1
    for (( i=1; i<${#node_status_arr[@]}; i++ )); do
        if [ ${node_status_arr[i]} != "Ready" ]
        then  
            if [[ $b -eq 1 ]];
            then
                b=0          
                echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
                echo "Cluster Issue Node List" >> $RVS_PATH/cluster-issue-history
                date >> $RVS_PATH/cluster-issue-history
                echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
            fi
            echo "Comming Soon - all node state task" >> $RVS_PATH/cluster-issue-history
        fi
    done
    echo "[COMPLETE] Node Checking"

    echo "[TASK2-3] Pod Checking"
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Cluster ALL Pod State" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    pod_name_arr=($POD_NAME)
    pod_namespace_arr=($POD_NAMESPACE)
    pod_status_arr=($POD_STATUS)
    kubectl get pod --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,NODE:.status.hostIP >> $RVS_PATH/cluster-history
    b=1
    for (( i=1; i<${#pod_status_arr[@]}; i++ )); do
        if [ ${pod_status_arr[i]} != "Running" ] && [ ${pod_status_arr[i]} != "Completed" ]
        then        
            if [ $b -eq 1 ]
            then
                b=0
                echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
                echo "Cluster Issue Pod List" >> $RVS_PATH/cluster-issue-history
                date >> $RVS_PATH/cluster-issue-history
                echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
            fi
            echo "Comming Soon - all pod state task" >> $RVS_PATH/cluster-issue-history
        fi
    done
    echo "[COMPLETE] Pod Checking"

    echo "[TASK2-4] Node Describe Checking"
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Cluster ALL Node Describe" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    kubectl describe nodes -A >> $RVS_PATH/cluster-history
    b=1
    for (( i=1; i<${#node_status_arr[@]}; i++ )); do
        if [ ${node_status_arr[i]} != "Ready" ]
        then
            if [ $b -eq 1 ]
            then
                b=0
                echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
                echo "Cluster Issue Node Describe" >> $RVS_PATH/cluster-issue-history
                date >> $RVS_PATH/cluster-issue-history
                echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
            fi
            kubectl describe node ${node_name_arr[i]} >> $RVS_PATH/cluster-issue-history
        fi
    done
    echo "[COMPLETE] Node Describe Checking"

    echo "[TASK2-5] Pod Describe Checking"
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Cluster ALL Pod Describe" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    kubectl describe pod --all-namespaces >> $RVS_PATH/cluster-history
    b=1
    for (( i=1; i<${#pod_status_arr[@]}; i++ )); do
        if [ ${pod_status_arr[i]} != "Running" ] && [ ${pod_status_arr[i]} != "Completed" ]
        then
            if [ $b -eq 1 ]
            then
                b=0
                echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
                echo "Cluster Issue Pod Describe" >> $RVS_PATH/cluster-issue-history
                date >> $RVS_PATH/cluster-issue-history
                echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
            fi
            kubectl describe pod -n ${pod_namespace_arr[i]} ${pod_name_arr[i]} >> $RVS_PATH/cluster-issue-history
        fi
    done
    echo "[COMPLETE] Pod Describe Checking"
    
    if [ -d $RVS_PATH/cluster-issue-history ]; then
        echo "[COMPLETE] $RVS_PATH/cluster-issue-history created"
    fi
    echo "[FINISH TASK2] $RVS_PATH/cluster-history created"
}

kube_cert_backup() {
    echo "[START TASK3] Backup the Kubernetes cert file on the Master1($HOSTNAME) - $RVS_PATH/cert-files"
    mkdir -p $RVS_PATH/cert-files
    KUBE_CERT_FILE_PATH=$RVS_PATH/cert-files
    cp -r /etc/kubernetes $KUBE_CERT_FILE_PATH
    kubeadm certs check-expiration > $KUBE_CERT_FILE_PATH/check-expiration
    echo "[FINISH TASK3] $KUBE_CERT_FILE_PATH/check-expiration created"
}

allnode_state_backup() {
    echo "[START TASK4] State backup on all nodes"
    echo "Comming Soon"
    echo "404 Not Found"
    echo "[FAILED TASK4]"
}

input_key() {
    read -s -n3 INPUT;
    echo $INPUT;
}

check_selected() {
    if [ $1 = $2 ];
    then echo " => "
    else echo "    "
    fi
}

select_menu() {
    SELECTED=1;
    INPUT="";
    MIN_MENU=1;
    MAX_MENU=$#;

    while true;
    do
        for (( i=1; i<=$#; i++))
        do
            printf "$ESC[2K$(check_selected $i $SELECTED) $i. ${!i}\n";
        done
        printf "\n$ESC[2K[Copyright] Made by Jinwoo Shin (jinwoo_shin@tmax.co.kr)\n[Version] v1.0-20230131\n";
        INPUT=$(input_key);
        if [[ $INPUT = "" ]];
        then break;
        fi

        if [[ $INPUT = $ESC[A ]];
        then SELECTED=$(expr $SELECTED - 1);
        elif [[ $INPUT = $ESC[B ]];
        then SELECTED=$(expr $SELECTED + 1);
        fi

        if [[ $SELECTED -lt $MIN_MENU ]];
        then SELECTED=${MIN_MENU};
        elif [[ $SELECTED -gt $MAX_MENU ]];
        then SELECTED=${MAX_MENU};
        fi

        printf "$ESC[$(expr $# + 3)A";
    done
    return `expr ${SELECTED}`;
}

select_menu_list() {
    if [ $COUNT -eq 0 ]
        then
        arr_params=("README.md" "Create CSR-RVS Directory")
        echo -e "\nWelmcome! HyperCloud CSR RVS Helper\nChoose your job\n";
        select_menu "${arr_params[@]}";
        local SELECTED=$?;
        SELECTED_MODE=${arr_params[${SELECTED}]};
       
        if [ $SELECTED -eq 1 ]
            then
            cat ./README.md
            select_menu_list
        elif [ $SELECTED -eq 2 ]
            then
            mkdir_backup_dir;
            select_menu_list
        fi
    elif [ $COUNT -eq 1 ]
    then
        arr_params=("Rename an existing Directory" "Use existing Directory");
        echo -e "\n$RVS_PATH Directory already exists\nChoose your job\n";
        select_menu "${arr_params[@]}";
        local SELECTED=$?;
        SELECTED_MODE=${arr_params[${SELECTED}]};
        if [ $SELECTED -eq 1 ]
            then
            mv $RVS_PATH /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE_TIME
            echo "[RENAME] $RVS_PATH -> /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE_TIME"
            mkdir $RVS_PATH
            echo "[CREATE] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE"
            echo "[FINISH TASK1] $RVS_PATH created"
            ((COUNT+=1))
            select_menu_list
        elif [ $SELECTED -eq 2 ]
            then
            ((COUNT+=1))
            echo "[SKIP] Use existing /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE"
            select_menu_list
        fi

    elif [ $COUNT -eq 2 ]
    then
        echo $COUNT
        arr_params=("Backup the cluster state on the Master1($HOSTNAME)" "Backup the Kubernetes cert file on the Master1($HOSTNAME)" "Create ETCD SnapShot on the Master1($HOSTNAME)" "State backup for each physical server");
        echo -e "\nWelmcome! HyperCloud CSR RVS Helper\nChoose your job\n";
        select_menu "${arr_params[@]}";
        local SELECTED=$?;
        SELECTED_MODE=${arr_params[${SELECTED}]};
        if [ $SELECTED -eq 1 ]
            then
            cluster_state_backup;
            select_menu_list
        elif [ $SELECTED -eq 2 ]
            then
            kube_cert_backup;
            select_menu_list
        elif [ $SELECTED -eq 3 ]
            then
            ((COUNT+=2))
            select_menu_list
        elif [ $SELECTED -eq 4 ]
            then
            ((COUNT+=1))
            select_menu_list
        fi
    elif [ $COUNT -eq 3 ]
    then
        arr_params=("Deploy and Run All node state backup script" "Run All node state backup script" "Run $HOSTNAME state backup script");
        echo -e "\nWelmcome! HyperCloud CSR RVS Helper\nChoose your job\n";
        select_menu "${arr_params[@]}";
        local SELECTED=$?;
        SELECTED_MODE=${arr_params[${SELECTED}]};
        if [ $SELECTED -eq 1 ]
        then
            cat commingsoon
            select_menu_list
        elif [ $SELECTED -eq 2 ]
        then
            cat commingsoon
            select_menu_list
        elif [ $SELECTED -eq 3 ]
        then
            cat commingsoon
            select_menu_list
        fi
    fi
}

select_menu_list
