#!/bin/bash

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health | grep -q '"status":"green"\|"status":"yellow"'; do
  echo "Elasticsearch not ready yet, waiting..."
  sleep 10
done

echo "Elasticsearch is ready!"

# Create cadrart user
echo "Creating cadrart user..."
curl -X POST -u elastic:${ELASTIC_PASSWORD} \
  -H "Content-Type: application/json" \
  -d '{
    "password": "'${CADRART_PASSWORD}'",
    "roles": ["kibana_user", "monitoring_user"],
    "full_name": "Cadrart Application User",
    "email": "cadrart@example.com"
  }' \
  http://localhost:9200/_security/user/${CADRART_USER}

# Create cadrart index pattern
echo "Creating cadrart index..."
curl -X PUT -u elastic:${ELASTIC_PASSWORD} \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    }
  }' \
  http://localhost:9200/cadrart

echo "Elasticsearch setup complete!" 