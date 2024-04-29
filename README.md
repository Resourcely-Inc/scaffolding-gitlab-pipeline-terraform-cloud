# Scaffolding GitLab CI/CD Pipeline (Terraform Cloud)

This repository demonstrates how to integrate the [Resourcely guardrail validation](https://github.com/Resourcely-Inc/resourcely-gitLab-template) job into a repository using GitLab CI/CD and Terrafom Cloud. It runs Terraform using the official [Hashicorp Terraform Cloud Docker Images](https://github.com/hashicorp/tfc-workflows-gitlab).

## Assumption

This repository uses GitLab CI/CD + Terraform Cloud to generate a Terraform plan. Once a plan is downloaded to a specified directory, the Resourcely guardrail validation job runs on the configured path. If you use a different runner, see the scaffolding repository for that runner:

- [GitHub Actions](https://github.com/Resourcely-Inc/scaffolding-github-actions)
- [GitHub Actions + Terraform Cloud](https://github.com/Resourcely-Inc/scaffolding-github-terraform-cloud)
- [GitLab CI/CD](https://github.com/Resourcely-Inc/scaffolding-gitlab-pipeline)

## Prerequisites

1. [A Resourcely Account](https://docs.resourcely.io/resourcely-terms/user-management/resourcely-account)
2. [Resourcely GitLab SCM Configured](https://docs.resourcely.io/integrations/source-code-management/gitlab)
3. [GitLab Premium or Ultimate subscription](https://about.gitlab.com/pricing/)
4. [Maintainer Role or Higher](https://docs.gitlab.com/ee/user/permissions.html#roles) in the GitLab project
5. [A Terraform Cloud Instance configured with Resourcely](https://docs.resourcely.io/integrations/terraform-integration/terraform-cloud)
6. [AWS Provider Credentials configured in Terraform Cloud](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

## Setup

1. [Import this project to your GitLab group by URL](https://docs.gitlab.com/ee/user/project/import/repo_by_url.html)  
    a. On the left sidebar, at the top, select **Create new (+)** and **New project/repository**  
    b. Select **Import project**  
    c. Select **Repository by URL**  
    d. Enter the **Git repository URL**: https://github.com/Resourcely-Inc/scaffolding-gitlab-pipeline-terraform-cloud.git  
    e. Complete the remaining fields  
    f. Select **Create project**  
2. [Generate a Resourcely API Token](https://docs.resourcely.io/onboarding/api-access-token-generation) and save it in a safe place
3. Add your Resourcely API Token to your [GitLab project CI/CD variables](https://docs.gitlab.com/ee/ci/variables/)  
    a. Go to the GitLab project that Resourcely will validate  
    b. In the side tab, navigate to **Settings > CI/CD**  
    c. Expand the **Variables** tab  
    d. Click the **Add variable** button  
    e. Add the `RESOURCELY_API_TOKEN` as the key and the token as the value  
    f. Evaluate whether to unselect **Protect variable**, depending on the need to use the token in un-protected branches, while considering security implications  
    g. Select the **Mask variable** to protect sensitive data from being seen in job logs  
    h. Unselect **Expand variable reference**  
    i. Press the **Add variable** button  
4. [Generate a Terraform Cloud Team Token](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens#team-api-tokens)
5. Add the Terraform Cloud Team token `TF_API_TOKEN` to GitLab following the same process in step 3
6. Configure Terraform Cloud Credentials
    a. Edit `.gitlab-ci.yml`  
    b. Edit the value of **TF_CLOUD_ORGANIZATION** to match your Terraform Cloud Organization  
    c. Edit the value of **TF_WORKSPACE** to match your Terraform Cloud Workspace  
    d. Edit the value of **TF_CLOUD_HOSTNAME** to match your Terraform Cloud Hostname  
    e. Commit the `.gitlab-ci.yml` file to your main branch  
7. [Provision Infrastructure using Resourcely](https://docs.resourcely.io/using-resourcely)  

Once a new Resource has been created via Merge-Request, the Resourcely job will automatically kick-off. It runs in the **test** stage by default.

## How it works

When a merge-request is created using Resourcely:

1. GitLab CI kicks off the `plan` stage
    a. The `mjyocca/tfci:latest` container image is loaded for multiple jobs via the remote import of [tfc-workflows-gitlab](https://github.com/hashicorp/tfc-workflows-gitlab/tree/main) template that is included in this project's `.gitlab-ci.yml`  
    b. `upload_configuration` job is run to create and upload a configuration version to terraform-cloud.variables  
    c. `create_run` job is run to create a Terraform Cloud run  
    d. `plan_output` job is run to output the Terraform Plan details  
    e. The `alpine/curl` container image is loaded for the `download_plan` job  
    f. Call to the [terraform API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs/plans#retrieve-the-json-execution-plan) is peformed in order to download the Terraform plan json  
2. After the `plan` stage completes, GitLab CI kicks off the `test` stage
    a. The `test` stage is loaded by the [Resourcely template](https://gitlab.com/fern-inc/resourcely/resourcely-gitlab-guardrails) that is included in this project's `.gitlab-ci.yml`  
    b. The `ghcr.io/resourcely-inc/resourcely-cli:$RESOURCELY_IMAGE` container image is loaded  
    c. The `resourcely_guardrails` job runs `resourcely-cli evaluate` scanning the Terraform plan json(s)  
    d. The resources generated with resourcely within the merge-request are validated against your Resourcely guardrails  
4. The `test` stage completes
    a. If guardrail violations are found, Resourcely will assign a reviewer to the merge-request and require approval before it can be merged  