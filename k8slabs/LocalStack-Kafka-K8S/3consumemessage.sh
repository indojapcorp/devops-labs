kubectl exec -n kafka -it kafka-testclient -- kafka-console-consumer.sh --topic test-topic --bootstrap-server kafka-svc.kafka.svc.cluster.local:9092 --from-beginning