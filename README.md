# How to use AWS CodeBuild just like Google Cloud Build

## Common

It's assumed that you set aws credentials via environment variables:

```sh
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=...
```

## Setup

Edit `terraform/terraform.tfvars` just as you like.

```sh
cd terraform
docker-compose run --rm terraform init
docker-compose run --rm terraform apply
```

You'll get

```
Outputs:

codebuild_project = "codebuildtest"
log_group = "codebuild-codebuildtest"
s3_result = "xxxxxxxxxxxx-codebuildtest-result"
s3_source = "xxxxxxxxxxxx-codebuildtest-source"
```

## Manual execution

* Create a source zip file

    ```sh
    zip -r source.zip buildspec.yaml docker-compose.yaml demo go.mod go.sum
    ```

* Put it to s3

    ```sh
    docker-compose run --rm aws s3 cp ./source.zip s3://xxxxxxxxxxxx-codebuildtest-source/source-test.zip
    ```

* Execute build

    ```sh
    docker-compose run --rm aws codebuild start-build --project-name codebuildtest --source-location-override xxxxxxxxxxxx-codebuildtest-source/source-test.zip
    ```

    * You can specify the path in the zip file to buildspec file with `--buildspec-override`, if the path is not `./buildspec.yml` nor `./buildspec.yaml`.
    * You will get output like:

        ```json
        {
            "build": {
                "id": "codebuildtest:2a2c2299-b273-4b7c-a984-16b92d0d2362",
                ...
            }
        }
        ```

* Watch log

    ```sh
    docker-compose run --rm aws logs tail codebuild-codebuildtest --follow --log-stream-names 2a2c2299-b273-4b7c-a984-16b92d0d2362
    ```

    * This doesn't exit even after the build completes, and you sould exit with Ctrl+C.


## TODOs

* Use Jenkins

* Upload artifacts to S3

* Use `public.ecr.aws` as tranparent proxy
    * I believe it can be done with setting `repository-mirrors` for dockerd: https://docs.docker.com/registry/recipes/mirror/#configure-the-docker-daemon
