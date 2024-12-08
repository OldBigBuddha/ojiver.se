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

3. Create a new bucket via Terraform

Please check [./storage.tf](./storage.tf)

NOTE: if you fail to apply the terraform code, you have to complete [the setup of ADC](https://cloud.google.com/docs/authentication/provide-credentials-adc?hl=ja). And ensure the account (or service account) has been grant the permission to manage Cloud Storage Bucket.

4. migrate the current status with Storage bucket

```bash
$ terraform init -migrate-state
```

Now your tfstate is managed on Cloud Storage.

## setup GitHub Action to apply terraform

ref: https://zenn.dev/ring_belle/articles/gcp-oidc-githubactions

1. create a new service account to manage the storage bucket for tfstate

Add [sa.tf](./sa.tf)

```terraform
resource "google_service_account" "github_actions" {
  project      = var.project_id
  account_id   = "github-actions"
  display_name = "Github Actions"
}
resource "google_project_iam_member" "github_actions" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}
```

After apply new changes, prepare Workload Identity Pool.

file: [workload.tf](./workload.tf)

```terraform
resource "google_iam_workload_identity_pool_provider" "github_actions" {
  project                            = var.project_id
  workload_identity_pool_provider_id = "github-actions-oidc-provider"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  attribute_condition                = "\"${var.github_org_name}/${var.github_org_name}\" == assertion.repository"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
}
```
After created, associate the service account and the workload pool.

2. prepare workflow

After all resources are created, create a new workflow within OIDC authentication like:

```yaml
name: OIDC Actions

on:
  pull_request:
    types:
      - opened
      - synchronize


permissions:
  id-token: write
  contents: read

jobs:
  test:
    name: test
    runs-on: ubuntu-latest
    steps:
      - name: Check out code
        uses: actions/checkout@v3

      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: "projects/${{ secrets.OJIVERSE_GOOGLECLOUD_PROJECT_ID }}/locations/global/workloadIdentityPools/github-actions-oidc/providers/github-actions-oidc-provider"
          service_account: 'github-actions@${{ secrets.OJIVERSE_GOOGLECLOUD_PROJECT_ID }}.iam.gserviceaccount.com'

      - name: Test
        run: gcloud iam service-accounts list
```

Note that this workflow contains the [secrets](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions). Please don't forget to set them to the respository.

```bash
gh secret set OJIVERSE_GOOGLECLOUD_PROJECT_ID
```