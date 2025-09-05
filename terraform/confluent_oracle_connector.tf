resource "confluent_connector" "RiverHotel_Oracle" {
  environment {
    id = confluent_environment.staging.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }

  config_sensitive = {}

  config_nonsensitive = {
    "name"                                      = "RiverHotel_Oracle"
    "connector.class"                           = "OracleXStreamSource"
    "kafka.auth.mode"                           = "SERVICE_ACCOUNT"
    "kafka.service.account.id"                  = confluent_service_account.app-manager.id
    "database.hostname"                         = aws_instance.oracle_instance.public_dns
    "database.port"                             = var.oracle_db_port
    "database.user"                             = var.oracle_xstream_user_username
    "database.password"                         = var.oracle_xstream_user_password
    "database.dbname"                           = var.oracle_db_name
    "database.service.name"                     = var.oracle_db_name
    "database.pdb.name"                         = var.oracle_pdb_name
    "database.out.server.name"                  = var.oracle_xstream_outbound_server_name

    "database.processor.licenses"               = "1"
    "tasks.max"                                 = "1"
   
    # 데이터 포맷 및 스키마 레지스트리 설정 (AVRO 사용 권장)
    "output.key.format"                         = "AVRO"
    "output.data.format"                        = "AVRO"
    "csfle.enabled"                             = "false"
    "topic.prefix"                              = "riverhotel"
    "table.include.list"                        = "SAMPLE[.](HOTEL|CUSTOMER)"
    "snapshot.mode"                             = "initial"
    "schema.history.internal.skip.unparseable.ddl" = "false"
    "snapshot.database.errors.max.retries"      = "0"
    "tombstones.on.delete"                      = "true"
    "skipped.operations"                        = "t"
    "schema.name.adjustment.mode"               = "none"
    "field.name.adjustment.mode"                = "none"
    "heartbeat.interval.ms"                     = "0"
    "database.os.timezone"                      = "UTC"
    "unavailable.value.placeholder"             = "__cflt_unavailable_value"
    "lob.oversize.threshold"                    = "-1"
    "lob.oversize.handling.mode"                = "fail"
    "skip.value.placeholder"                    = "__cflt_skipped_value"
    "decimal.handling.mode"                     = "double"
    "binary.handling.mode"                      = "bytes"
    "time.precision.mode"                       = "connect"
    "value.converter.decimal.format"            = "numeric"

  }

    # "connector.class": "OracleXStreamSource",
    # "name": "RaviHotel_Oracle",
    # "kafka.auth.mode": "SERVICE_ACCOUNT",
    # "kafka.service.account.id": "sa-nvxmmwz",
    # "csfle.enabled": "false",
    # "schema.context.name": "default",
    # "database.hostname": "ec2-35-168-16-171.compute-1.amazonaws.com",
    # "database.port": "1521",
    # "database.user": "c##cfltuser",
    # "database.password": "********",
    # "database.dbname": "XE",
    # "database.service.name": "XE",
    # "database.pdb.name": "XEPDB1",
    # "database.out.server.name": "XOUT",
    # "database.tls.mode": "disable",
    # "database.processor.licenses": "1",
    # "output.key.format": "AVRO",
    # "output.data.format": "AVRO",
    # "topic.prefix": "ravihotel",
    # "table.include.list": "SAMPLE[.](HOTEL|CUSTOMER)",
    # "snapshot.mode": "initial",
    # "schema.history.internal.skip.unparseable.ddl": "false",
    # "snapshot.database.errors.max.retries": "0",
    # "tombstones.on.delete": "true",
    # "skipped.operations": "t",
    # "schema.name.adjustment.mode": "none",
    # "field.name.adjustment.mode": "none",
    # "heartbeat.interval.ms": "0",
    # "database.os.timezone": "UTC",
    # "unavailable.value.placeholder": "__cflt_unavailable_value",
    # "lob.oversize.threshold": "-1",
    # "lob.oversize.handling.mode": "fail",
    # "skip.value.placeholder": "__cflt_skipped_value",
    # "decimal.handling.mode": "precise",
    # "binary.handling.mode": "bytes",
    # "time.precision.mode": "adaptive",
    # "tasks.max": "1",
    # "value.converter.decimal.format": "BASE64",
    # "value.converter.reference.subject.name.strategy": "DefaultReferenceSubjectNameStrategy",
    # "errors.tolerance": "none",
    # "value.converter.value.subject.name.strategy": "TopicNameStrategy",
    # "key.converter.key.subject.name.strategy": "TopicNameStrategy",
    # "auto.restart.on.user.error": "true"

  depends_on = [
    null_resource.db_listener_checker,
    confluent_service_account.app-manager,
    confluent_kafka_cluster.standard
  ]

}