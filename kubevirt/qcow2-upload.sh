virtctl image-upload \
  --uploadproxy-url=https://10.96.170.253:443 \ # cdi-uploadproxy Cluster IP:443
  --pvc-name=centos-dv \ # pvc name
  --pvc-size=100Gi \ # pvc volume
  --image-path=./images/centos.qcow2 \ # qcow2 file path
  --access-mode=ReadWriteOnce \
  --insecure \
  --storage-class=rook-ceph-block \ # kubectl get sc -A, storageclass name
  --block-volume \ 
  -n dev-woohub # namespace
