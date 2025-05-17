secrets:
	gcloud secrets versions access latest --secret="tf-production" --project=903589807785 > production.tfvars
	gcloud secrets versions access latest --secret="sa" --project=903589807785 > tf-service-credentials.json

apply:
	terraform apply -var-file=production.tfvars 
