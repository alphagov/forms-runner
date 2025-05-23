# Review apps

The Terraform code in this directory is used to deploy a review copy of `forms-runner`.

It constructs a minimal, ephemeral version of a GOV.UK Forms environment in AWS ECS that can be used for reviews, then freely destroyed. This includes: 

* a copy of `forms-runner` at the commit in question
* a copy of the version of `forms-api` currently in production
* a copy of the version of `forms-admin` currently in production
* a local PostgreSQL database with seed data for both `forms-api` and `forms-admin`
* a local Redis instance of session storage

Review apps rely on a set of underlying infrastructure managed and deployed in `forms-deploy`. The Terraform will require you to be targeting the `integration` AWS account (where the `review` environment lives), and you should not override this.

### State files
Each review app uses its own Terraform state file, stored in an S3 bucket. The bucket itself is created and managed by `forms-deploy` and its name is safely assumed.

### `forms-runer` container image
The `forms-runner` container image to deploy is supplied under the `forms_runner_container_image` variable. Terraform does not build the container. It is assumed to be built and stored ahead of time.


