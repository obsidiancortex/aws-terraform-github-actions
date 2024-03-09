# Lambda functions using ECR 

resource "aws_iam_role" "test_service_lambda_role" {
  name = "${var.environment}-test_service_lambda_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

## Aws Lambda

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_service_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
}


# Error: error creating Lambda Function (1): InvalidParameterValueException: Source image 801295807338.dkr.ecr.eu-west-1.amazonaws.com/dev-test_service_ecr_repo:latest does not exist. Provide a valid source image.
# solution : https://stackoverflow.com/questions/74257294/aws-error-describing-ecr-images-when-deploying-lambda-in-terraform

data "aws_caller_identity" "current" {}


resource "aws_lambda_function" "test_service_lambda_function" {
  function_name = "${var.environment}-test_service_lambda"
  role          = aws_iam_role.test_service_lambda_role.arn
  # image_uri = "${aws_ecr_repository.test_service_ecr_repo.repository_url}:latest"
  image_uri    = "${aws_ecr_repository.test_service_ecr_repo.repository_url}:${local.ecr_image_tag}"
  package_type = "Image"
  timeout      = 60
}

resource "aws_lambda_function" "test_service_lambda_function" {
  depends_on = [
    null_resource.ecr_image
  ]
  function_name = "${var.environment}-test_service_lambda"
  architectures = ["arm64"]
  role          = aws_iam_role.test_service_lambda_role.arn
  timeout       = 180
  memory_size   = 10240
  image_uri     = "${aws_ecr_repository.test_service_ecr_repo.repository_url}:latest"
  package_type  = "Image"

}
resource "aws_cloudwatch_log_group" "example_service" {
  name              = "/aws/lambda/example_service"
  retention_in_days = 14
}

# resource "aws_lambda_function" "rankings_lambda" {
#   filename      = var.path_to_artifact
#   function_name = var.function_name
#   role          = var.lambda_iam_role_arn
#   handler       = var.function_handler

#   memory_size = var.memory_size
#   timeout     = var.timeout

#   source_code_hash = filebase64sha256(var.path_to_artifact)

#   runtime = var.runtime

#   layers = var.lambda_layer_arns
# }


locals {
  # prefix              = "mycompany"
  account_id          = data.aws_caller_identity.current.account_id
  ecr_repository_name = "${var.environment}-test_service_ecr_repo"
  ecr_image_tag       = "latest"
}

## Aws Ecr image 

resource "null_resource" "ecr_image" {
  triggers = {
    python_file = md5(file("../../../src/app.py"))
    docker_file = md5(file("../../../src/Dockerfile"))
  }

  provisioner "local-exec" {
    command = <<EOF
            aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.eu-west-1.amazonaws.com
            docker build -t ${local.ecr_repository_name} .
            docker tag ${local.ecr_repository_name}:${local.ecr_image_tag} ${aws_ecr_repository.test_service_ecr_repo.repository_url}:${local.ecr_image_tag} 
            docker push ${aws_ecr_repository.test_service_ecr_repo.repository_url}:${local.ecr_image_tag}
        EOF
    # interpreter = ["pwsh", "-Command"] # For Windows 
    interpreter = ["bash", "-c"] # For Linux/MacOS
    working_dir = "../../../src/"
  }
}

resource "aws_ecr_repository" "test_service_ecr_repo" {
  #name                 = "${var.environment}-test_service_ecr_repo"
  name                 = local.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  tags = {
    "project" : "Mercury Project"
  }
}



data "aws_ecr_image" "lambda_image" {
  depends_on = [
    null_resource.ecr_image
  ]
  repository_name = local.ecr_repository_name
  image_tag       = local.ecr_image_tag
}

# zip file 

data "archive_file" "scrape" {
  type        = "zip"
  source_file = var.path_to_source_file
  output_path = var.path_to_artifact
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "CreateCloudWatchLogs"
  }
}
resource "aws_iam_policy" "lambda" {
  name   = "example-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
}