
.PHONY: plan deploy


plan:
	terraform plan -var-file=matrix/credentials.json  matrix
apply:
	terraform apply -var-file=matrix/credentials.json matrix

destroy:
	terraform destroy -var-file=matrix/credentials.json matrix
