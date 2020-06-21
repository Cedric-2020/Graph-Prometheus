##Cedric Dessennes script 2020-05##
##
#!/bin/bash
#install HELM
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
#Add good Repo Helm
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
