#!/bin/bash
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
        echo "[TASK1-1 CREATE] /$HOME_DIR/$CSR_RVS_DIR"
    else
        echo "[TASK1-1 PASS] /$HOME_DIR/$CSR_RVS_DIR Directory already exists"
    fi
    if [ ! -d /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR ]; then
        mkdir /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR
        echo "[TASK1-2 CREATE] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR"
    else
        echo "[TASK1-2 PASS] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR Directory already exists"
    fi
    if [ ! -d /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE ]; then
        mkdir /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE
        echo "[TASK1-3 CREATE] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE"
        export RVS_PATH=/$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE
        echo "[COMPLETE TASK1] $RVS_PATH created"
        ((COUNT+=2))
    else
        echo "[TASK1-3 PASS] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE Directory already exists"
        ((COUNT+=1))
    fi
}

cluster_state_backup() {
    echo "[START TASK2] Backup the cluster state on the Master1($HOSTNAME) - $RVS_PATH/cluster-history"
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Podman Private Registry State" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    podman ps -a | grep tmaxcloud >> $RVS_PATH/cluster-history
#    if [이슈 있을 시, 수집]
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        echo "Podman Private Registry Issue" >> $RVS_PATH/cluster-issue-history
#        date >> $RVS_PATH/cluster-issue-history
#        echo "---------------------------------------" >> $RVS_PATH/cluster-history
#        podman ps -a | grep tmaxcloud | grep Exited >> $RVS_PATH/cluster-issue-history
#        podman logs tmaxcloud >> $RVS_PATH/cluster-issue-podman-log

    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Cluster ALL Node State" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    kubectl get node -A -owide >> $RVS_PATH/cluster-history
#    if [이슈 있을 시, 수집]
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        echo "Cluster Issue Node List" >> $RVS_PATH/cluster-issue-history
#        date >> $RVS_PATH/cluster-issue-history
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        Comming Soon >> $RVS_PATH/cluster-issue-history

    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Cluster ALL Pod State" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    kubectl get pod --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,NODE:.status.hostIP >> $RVS_PATH/cluster-history
#    if [이슈 있을 시, 수집]
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        echo "Cluster Issue Pod List" >> $RVS_PATH/cluster-issue-history
#        date >> $RVS_PATH/cluster-issue-history
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        Comming Soon >> $RVS_PATH/cluster-issue-history

    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Cluster ALL Node Describe" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    kubectl describe nodes -A >> $RVS_PATH/cluster-history
#    if [이슈 있을 시, 수집]
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        echo "Cluster Issue Node Describe" >> $RVS_PATH/cluster-issue-history
#        date >> $RVS_PATH/cluster-issue-history
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        Comming Soon >> $RVS_PATH/cluster-issue-history

    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    echo "Cluster ALL Pod Describe" >> $RVS_PATH/cluster-history
    date >> $RVS_PATH/cluster-history
    echo "---------------------------------------" >> $RVS_PATH/cluster-history
    kubectl describe pod --all-namespaces >> $RVS_PATH/cluster-history
#    if [이슈 있을 시, 조회]
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        echo "Cluster Issue Pod Describe" >> $RVS_PATH/cluster-issue-history
#        date >> $RVS_PATH/cluster-issue-history
#        echo "---------------------------------------" >> $RVS_PATH/cluster-issue-history
#        Comming Soon >> $RVS_PATH/cluster-issue-history

    echo "[COMPLETE TASK2] $RVS_PATH/cluster-history created"
    if [ ! -d $RVS_PATH/cluster-issue-history ]; then
        echo "[COMPLETE TASK2] $RVS_PATH/cluster-issue-history created"
    fi
}

kube_cert_backup() {
    echo "[START TASK3] Backup the Kubernetes cert file on the Master1($HOSTNAME) - $RVS_PATH/cert-files"
    mkdir -p $RVS_PATH/cert-files
    KUBE_CERT_FILE_PATH=$RVS_PATH/cert-files
    cp -r /etc/kubernetes $KUBE_CERT_FILE_PATH
    kubeadm certs check-expiration > $KUBE_CERT_FILE_PATH/check-expiration
    echo "[COMPLETE TASK3] $KUBE_CERT_FILE_PATH/check-expiration created"
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
            echo "[TASK1-3 RENAME] $RVS_PATH -> /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE_TIME"
            mkdir $RVS_PATH
            echo "[TASK1-3 CREATE] /$HOME_DIR/$CSR_RVS_DIR/$CSR_RVS_STATUS_BACKUP_DIR/$DATE"
            echo "[COMPLETE TASK1] $RVS_PATH created"
            ((COUNT+=1))
            echo $COUNT
            select_menu_list
        elif [ $SELECTED -eq 2 ]
            then
            ((COUNT+=1))
            echo $COUNT
            select_menu_list
        fi

    elif [ $COUNT -eq 2 ]
        then
        arr_params=("Backup the cluster state on the Master1($HOSTNAME)" "Backup the Kubernetes cert file on the Master1($HOSTNAME)" "State backup on all nodes");
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
            allnode_state_backup;
            select_menu_list
        fi
    fi
}
select_menu_list
