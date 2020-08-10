SHELL = /usr/bin/env bash -xeuo pipefail

stack_name:=ffxiv-item-name-database-layer
template_path:=template.yml

build:
	@for requirements in $$(find layers -maxdepth 2 -type f -name requirements.txt); do \
		layer_dir=$$(dirname $$requirements); \
		pwd_dir=$$PWD; \
		docker_name=layer-$$(basename $$layer_dir); \
		cd $$layer_dir; \
		docker image build --tag $$docker_name -f ../../Dockerfile .; \
		docker container run -it --name $$docker_name $$docker_name; \
		docker container cp $$docker_name:/workdir/python .; \
		docker container rm $$docker_name; \
		docker image rm $$docker_name; \
		cd $$pwd_dir; \
	done

package:
	poetry run sam package --s3-bucket $$SAM_ARTIFACT_BUCKET --output-template-file $(template_path) --template-file sam.yml

deploy: package
	poetry run sam deploy \
		--stack-name $(stack_name) \
		--template-file $(template_path) \
		--capabilities CAPABILITY_IAM \
		--role-arn $$CLOUDFORMATION_DEPLOY_ROLE_ARN \
		--no-fail-on-empty-changeset
	poetry run aws cloudformation describe-stacks \
		--stack-name $(stack_name) \
		--query Stacks[0].Outputs

describe:
	poetry run aws cloudformation describe-stacks \
		--stack-name $(stack_name) \
		--query Stacks[0].Outputs
