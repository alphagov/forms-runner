output "review_app_url" {
  description = "The full URL of the review app"
  value       = "https://${local.runner_review_app_hostname}/"
}

output "admin_app_url" {
  description = "The full URL of the admin app that accompanies the review version of forms-runner"
  value       = "https://${local.admin_app_hostname}"
}

output "review_app_ecs_cluster_id" {
  description = "The id of the AWS ECS cluster into which the review app is deployed "
  value       = data.terraform_remote_state.review.outputs.ecs_cluster_id
}

output "review_app_ecs_service_name" {
  description = "The name of the AWS ECS service for this review app"
  value       = aws_ecs_service.app.name
}
