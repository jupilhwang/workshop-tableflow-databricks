resource "local_file" "oracle_connection_config" {
  content = jsonencode({
    kind : "oracle"
    tablePolicy : "dropAndCreate"
    connectionConfigs : {
      host : "${aws_instance.oracle_instance.public_ip}"
      port : "${var.oracle_db_port}"
      username : "${var.oracle_db_username}"
      password : "${var.oracle_db_password}"
      db : "XEPDB1"
    }
  })
  filename = "../data/connections/oracle.json"
}

resource "local_file" "kafka_connection_config" {
  content = jsonencode({
    kind : "kafka"
    logLevel : "ERROR",
    producerConfigs : {
      "bootstrap.servers" : "${local.bootstrap_endpoint_url_only}",
      "schema.registry.url" : "${data.confluent_schema_registry_cluster.sr-cluster.rest_endpoint}",
      "basic.auth.user.info" : "${confluent_api_key.app-manager-schema-registry-api-key.id}:${confluent_api_key.app-manager-schema-registry-api-key.secret}",
      "basic.auth.credentials.source" : "USER_INFO",
      "key.serializer" : "io.shadowtraffic.kafka.serdes.JsonSerializer",
      "value.serializer" : "io.confluent.kafka.serializers.KafkaAvroSerializer",
      "sasl.jaas.config" : "org.apache.kafka.common.security.plain.PlainLoginModule required username='${confluent_api_key.app-manager-kafka-api-key.id}' password='${confluent_api_key.app-manager-kafka-api-key.secret}';",
      "sasl.mechanism" : "PLAIN",
      "security.protocol" : "SASL_SSL"
    }
  })
  filename = "../data/connections/confluent.json"
}

# Download ShadowTraffic license from GitHub and create local file
data "http" "shadow_traffic_license" {
  url = "https://raw.githubusercontent.com/ShadowTraffic/shadowtraffic-examples/refs/heads/master/free-trial-license-docker.env"
}

resource "local_file" "shadow_traffic_license" {
  content  = data.http.shadow_traffic_license.response_body
  filename = "../data/shadow-traffic-license.env"
}
resource "null_resource" "run_data_generator_on_oracle_instance" {
  depends_on = [ local_file.shadow_traffic_license, local_file.oracle_connection_config, local_file.kafka_connection_config, null_resource.db_listener_checker, confluent_kafka_cluster.standard ]
 provisioner "local-exec" {
    command = <<EOT
      scp -i ${"sshkey-${aws_key_pair.tf_key.key_name}.pem"} -o "StrictHostKeyChecking=no" -r ../data ec2-user@${aws_instance.oracle_instance.public_dns}:~/
    EOT
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
  
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${path.module}/sshkey-${aws_key_pair.tf_key.key_name}.pem")
      host        = aws_instance.oracle_instance.public_dns
    }

    inline = [
      " echo 'docker run -d --env-file ./data/shadow-traffic-license.env -v $(pwd)/data/:/home/data shadowtraffic/shadowtraffic:1.1.1 --config /home/data/shadow-traffic-configuration.json' > run_data_generator.sh ",
      " chmod +x run_data_generator.sh ",
      "docker run -d --env-file ./data/shadow-traffic-license.env -v $(pwd)/data/:/home/data shadowtraffic/shadowtraffic:1.1.1 --config /home/data/shadow-traffic-configuration.json"
    ]
  }
}