Working Lab Steps:


start multipass 
multipass start k3s-vm

start localstack 
localstack start -d
terraform init
terraform apply

  kubectl logs -n kafka kafka-0
 kubectl get svc -n kafka

 ❯ kubectl get statefulsets -n kafka

 awslocal s3 ls
 kubectl apply -f testclient.yaml
 kubectl get pods -n kafka
 chmod 777 createTopic.sh
 ./createTopic.sh
 chmod 777 *.sh
 ./2producemessage.sh
 chmod 777 *.sh
 ./3consumemessage.sh
 ./2producemessage.sh



 Clean Up
 terraform destroy
 multipass stop k3s-vm
 localstack stop -d

kubectl get all -n kafka
kubectl get namespaces
aws --endpoint-url=http://localhost:4566 s3 ls


------------

Why Use StatefulSet for Kafka?
Kafka is a stateful application—it requires stable network identities (e.g., kafka-0) and persistent storage for its logs. A StatefulSet is ideal because:
It assigns predictable pod names (e.g., kafka-0, kafka-1) used in Kafka’s configuration (e.g., KAFKA_CFG_ADVERTISED_LISTENERS and KAFKA_CFG_CONTROLLER_QUORUM_VOTERS).
It ensures pods are created and terminated in order, preserving state.
It pairs well with a headless service (cluster_ip = "None") for direct pod access via DNS (e.g., kafka-0.kafka-svc.kafka.svc.cluster.local).
A Deployment, by contrast, is stateless and doesn’t guarantee pod identity or order, making it unsuitable for Kafka.
