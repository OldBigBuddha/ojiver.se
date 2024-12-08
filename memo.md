# working memo

## setup Google Cloud Storage for Terraform

ref: https://cloud.google.com/docs/terraform/resource-management/store-state

1. create a new project

```bash
$ gcloud projects create ojiverse
```

Project name: `ojiverse`
Project number: 56226728303

Then, link the billing account on Web console befor enabling services.

2. Enable services

```bash
$ gcloud services enable storage.googleapis.com
```

3. Create a service account to manage Google Cloud Storage Bucket

```bash
$ gcloudgcloud iam service-accounts create tfstate-manager \
  --description="manage the tfstate for Cloudflare DNS Records IaC" \
  --display-name="tfstate manager"
```

Then, binding the pre-defined IAM Polocy to the new service account.

```bash
gcloud projects add-iam-policy-binding ojiverse \
  --member="serviceAccount:tfstate-manager@ojiverse.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

`storage/admin` is too strong policy just to manage tfstatus on the bucket. So I MUST update the policy later.

4. Create a new bucket via Terraform

Please check [./storage.tf](./storage.tf)

5. migrate the current status with Storage bucket

```bash
$ terraform init -migrate-state
```