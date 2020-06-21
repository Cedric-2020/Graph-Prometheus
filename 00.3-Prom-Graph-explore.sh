kubectl get svc -n monitoring
kubectl port-forward -n monitoring svc/prometheus-operator-1592780393-grafana 8000:80
