resource "aws_mwaa_environment" "mwaa" {
  dag_s3_path        = "dags/"
  execution_role_arn = aws_iam_role.example.arn

  logging_configuration {
    dag_processing_logs {
      enabled   = false
      log_level = "DEBUG"
    }


    scheduler_logs {
      enabled   = false
      log_level = "INFO"
    }

    task_logs {
      enabled   = false
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = false
      log_level = "INFO"
    }

    worker_logs {
      enabled   = false
      log_level = "INFO"
    }
  }

  name = "mwaa"

  network_configuration {
    security_group_ids = [aws_security_group.example.id]
    subnet_ids         = aws_subnet.private[*].id
  }

  source_bucket_arn = aws_s3_bucket.example.arn
}
