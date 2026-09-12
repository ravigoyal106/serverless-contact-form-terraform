# Serverless Contact Form on AWS - Terraform Edition

[![Terraform](https://img.shields.io/badge/Terraform-1.10%2B-844FBA?logo=terraform)]()
[![AWS](https://img.shields.io/badge/AWS-Serverless-orange?logo=amazonaws)]()
[![CI/CD](https://github.com/<you>/serverless-contact-form-terraform/actions/workflows/terraform-ci.yml/badge.svg)](../../actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)]()
# Serverless Contact Form on AWS - Terraform Edition

A production-minded serverless contact-form backend built on AWS and provisioned entirely with Terraform.

The project demonstrates how a relatively small application can be designed using managed AWS services instead of maintaining an always-running server. The architecture is intentionally simple, but it follows several practices that are important in real-world cloud environments:

* Infrastructure as Code with Terraform
* Serverless, event-driven application architecture
* Least-privilege IAM
* Remote Terraform state
* Automated CI/CD
* Centralized logging and monitoring
* Failure alerting
* Input validation
* Reproducible infrastructure

The goal is not simply to make a contact form work. The goal is to demonstrate **how to design, deploy, secure, monitor, and maintain a small AWS workload in a way that can be understood and extended by another engineer.**

---

# 1. Project Overview

## 1.1 What does this project do?

The application provides a simple contact form for a website.

A visitor enters information such as their name, email address, and message and submits the form.

The request follows this path:

```text
User's Browser
      |
      | HTTPS POST
      v
API Gateway
      |
      | Lambda invocation
      v
AWS Lambda
      |
      +--------------------+
      |                    |
      v                    v
DynamoDB                 Amazon SES
      |                    |
      |                    |
      v                    v
Store submission       Send email notification
```

At the same time, Lambda execution information is automatically written to Amazon CloudWatch.

If Lambda starts failing or becomes throttled, CloudWatch detects the problem and publishes an alert through SNS.

The important architectural characteristic is that **there is no continuously running application server**.

The application only consumes compute resources when someone actually submits the form.

---

# 2. Why Serverless?

A traditional implementation might use an EC2 instance running a web server and application process.

That approach can certainly work, but for a small contact form it introduces infrastructure that provides little value:

* A server has to remain running.
* The operating system needs patching.
* The application runtime needs maintenance.
* Capacity needs to be considered.
* Monitoring needs to be configured.
* The server continues consuming resources even when nobody is using the form.

For this workload, traffic is normally unpredictable but very small.

A serverless architecture is therefore a better fit.

With Lambda, the application code runs only when an event occurs. API Gateway provides the public API endpoint, DynamoDB stores the data without requiring a database server, and SES handles email delivery.

This gives the project the following characteristics:

| Requirement               | Serverless approach |
| ------------------------- | ------------------- |
| Application compute       | Lambda              |
| API endpoint              | API Gateway         |
| Database                  | DynamoDB            |
| Email                     | SES                 |
| Logging                   | CloudWatch          |
| Alerting                  | SNS                 |
| Permissions               | IAM                 |
| Infrastructure management | Terraform           |
| Deployment automation     | GitHub Actions      |

The result is a small infrastructure footprint with very little operational overhead.

---

# 3. Architecture

## 3.1 High-Level Architecture

The application consists of two major paths:

### User request path

This is the path followed by an actual form submission:

```text
Browser
   |
   | POST /contact
   v
API Gateway
   |
   | Lambda event
   v
Lambda
   |
   +----> DynamoDB
   |
   +----> SES
   |
   v
API Gateway
   |
   | HTTP response
   v
Browser
```

### Operational path

AWS also produces operational information while the application is running:

```text
Lambda
   |
   v
CloudWatch Logs
   |
   +----> CloudWatch Alarms
               |
               v
             SNS
               |
               v
        Email notification
```

This separation is useful because the **application request path** and the **monitoring path** have different responsibilities.

The application handles customer requests.

The monitoring infrastructure tells the operator when the application is unhealthy.

---

# 4. Runtime Request Flow

Understanding the request flow is one of the most important parts of understanding this architecture.

## Step 1 - The browser loads the website

The frontend consists of static HTML, CSS, and JavaScript.

Amazon S3 hosts these static assets.

The browser downloads the page directly from S3.

There is no application server involved in serving the static content.

```text
Browser
   |
   | GET website
   v
S3
   |
   v
HTML / CSS / JavaScript
```

For a small static frontend, this is considerably simpler than running a web server purely to return static files.

---

## Step 2 - The visitor submits the form

When the visitor clicks **Submit**, the JavaScript frontend sends an HTTP POST request to the API Gateway endpoint.

Conceptually:

```http
POST /contact
Content-Type: application/json
```

The request contains the form information.

For example:

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "message": "Hello, I would like to contact you."
}
```

The browser waits for the API to return a response.

---

# 5. API Gateway

Amazon API Gateway acts as the public entry point for the backend.

The browser does not communicate directly with Lambda.

Instead:

```text
Browser
   |
   v
API Gateway
   |
   v
Lambda
```

This provides a clean separation between the public HTTP interface and the application implementation.

## Why HTTP API?

This project uses an **API Gateway HTTP API** rather than a REST API.

For this workload, only a small number of HTTP operations are required and there is no need for the additional functionality associated with a more complex REST API configuration.

The HTTP API therefore provides a simpler and generally more cost-effective API layer for this use case.

The important principle is not that HTTP APIs are always better than REST APIs.

The principle is:

> Choose the simplest AWS service configuration that satisfies the actual requirements of the application.

If the application later required advanced API Gateway features, the architecture could be revisited.

---

# 6. AWS Lambda

AWS Lambda contains the application's backend logic.

When API Gateway receives the request, Lambda is invoked.

The function is responsible for three primary operations:

1. Validate the incoming request.
2. Store the submission in DynamoDB.
3. Send an email notification through SES.

Conceptually:

```text
API Gateway
      |
      v
    Lambda
      |
      +---- Validate request
      |
      +---- Save submission
      |
      +---- Send notification
      |
      v
   HTTP response
```

Lambda is a good fit because contact-form traffic is normally sporadic.

There is no reason to maintain an EC2 instance simply waiting for somebody to submit a form.

Lambda automatically provides the compute environment when an invocation occurs.

---

# 7. DynamoDB

Amazon DynamoDB is used as the application's database.

Every successful contact-form submission is stored as an item in the DynamoDB table.

A conceptual record might look like:

```json
{
  "id": "unique-submission-id",
  "name": "John Doe",
  "email": "john@example.com",
  "message": "Hello",
  "createdAt": "2026-09-12T12:00:00Z"
}
```

The exact schema depends on the implementation, but the important architectural point is that Lambda writes directly to DynamoDB.

## Why DynamoDB?

A relational database such as Amazon RDS would introduce additional infrastructure considerations.

For a simple workload consisting primarily of individual submissions, DynamoDB provides:

* Managed database infrastructure
* No database server to operate
* Automatic scaling characteristics
* Simple integration with Lambda
* On-demand capacity for unpredictable traffic

The project uses on-demand billing because the workload is small and unpredictable.

There is no need to provision database capacity for traffic that may never occur.

---

# 8. Amazon SES

Amazon Simple Email Service (SES) is responsible for sending the email notification after a form submission.

The application therefore has two separate responsibilities:

```text
DynamoDB
    |
    +---- Permanent application record

SES
    |
    +---- Human notification
```

This distinction is important.

The database is the system of record.

The email is a notification mechanism.

If the email is intended for operational notification rather than being the permanent source of truth, the stored DynamoDB record remains valuable even if email delivery experiences a problem.

## Why SES?

SES is designed specifically for sending email from applications.

It is more appropriate for this use case than a messaging service such as SNS when the actual requirement is transactional email delivery.

SES also provides AWS-native integration with Lambda and IAM.

---

# 9. IAM and Least Privilege

Security is not something added after the application is deployed.

The Lambda function is deliberately given only the permissions it requires.

Its role is restricted to operations such as:

* Writing to the specific DynamoDB table
* Sending email through SES
* Writing logs to CloudWatch

It does **not** receive broad permissions such as:

```text
AdministratorAccess
```

or:

```text
dynamodb:*
```

across the entire AWS account.

Instead, permissions are scoped to the specific resources required by the application.

Conceptually:

```text
Lambda
   |
   +---- DynamoDB: PutItem
   |       |
   |       +---- Specific table only
   |
   +---- SES: SendEmail
   |       |
   |       +---- Required email identity
   |
   +---- CloudWatch Logs
           |
           +---- Function log group
```

This follows the principle of **least privilege**.

If the Lambda function were compromised, its IAM permissions would limit what an attacker could do through that function.

That is a much stronger security posture than giving the function broad access to the AWS account.

---

# 10. API Gateway → Lambda Permission

IAM is also used to control which service can invoke the Lambda function.

API Gateway is granted permission to invoke this specific Lambda function.

The permission is scoped to the relevant API rather than broadly allowing arbitrary API Gateway resources to invoke the function.

This creates an explicit trust relationship:

```text
API Gateway
     |
     | allowed to invoke
     v
Lambda
```

Rather than:

```text
Any API Gateway
     |
     | allowed to invoke
     v
Lambda
```

That distinction is important in larger AWS environments where many applications and APIs may exist within the same account.

---

# 11. S3 Frontend

The frontend is intentionally static.

The website consists of:

* HTML
* CSS
* JavaScript

Amazon S3 stores these files.

The frontend JavaScript knows the API Gateway endpoint and sends form submissions to it.

The deployment process injects the live API URL into the frontend during deployment.

This means the same application structure can be reused across environments.

For example:

```text
Development
    |
    +---- dev API Gateway URL

Production
    |
    +---- prod API Gateway URL
```

The frontend does not need to contain a hard-coded production endpoint.

---

# 12. Observability

A system is not truly production-ready simply because it works.

An important question is:

> How do we know when it stops working?

This project therefore treats observability as part of the architecture rather than an optional add-on.

---

## 12.1 CloudWatch Logs

Lambda automatically integrates with Amazon CloudWatch Logs.

Each invocation can produce log entries that help explain what happened during execution.

The project explicitly configures log retention rather than allowing logs to remain indefinitely.

A 30-day retention period is used.

This is important because logs that are never deleted can accumulate over time and create unnecessary storage and operational overhead.

The retention period should ultimately be chosen according to the application's operational and compliance requirements.

---

## 12.2 Lambda Error Alarm

A CloudWatch alarm monitors Lambda errors.

If Lambda starts producing errors, the alarm enters an alerting state.

For a contact form, this is a meaningful operational signal.

An error can mean:

* A submission failed.
* DynamoDB access failed.
* SES failed.
* Application code encountered an exception.
* Another runtime problem occurred.

The purpose of the alarm is not to monitor a metric simply because it exists.

It monitors a condition that represents a potential user-facing failure.

---

## 12.3 Lambda Throttling Alarm

A second alarm monitors Lambda throttling.

Throttling means Lambda could not execute an invocation because an applicable concurrency limit was reached.

For a small contact form, throttling would be unusual.

If it starts occurring, however, it could indicate:

* Unexpected traffic
* A concurrency configuration problem
* An account-level limit
* A sudden traffic spike
* Another scaling-related issue

That makes throttling a useful operational signal.

---

# 13. SNS Notifications

CloudWatch alarms publish notifications to an Amazon SNS topic.

The flow is:

```text
Lambda
   |
   v
CloudWatch Alarm
   |
   v
SNS Topic
   |
   v
Email notification
```

The advantage is that the operator does not have to continuously monitor CloudWatch manually.

Instead, the monitoring system tells the operator when something important happens.

This is a simple but important operational principle:

> Monitoring is useful only when somebody can act on the information.

---

# 14. Request Validation

Incoming form data is treated as untrusted input.

The Lambda function validates the request before attempting to store it or send an email.

Validation includes checks such as:

* Required fields are present.
* Values are not unexpectedly empty.
* Email addresses follow the expected format.
* Malformed requests are rejected.

The intended flow is:

```text
Incoming request
       |
       v
Validation
       |
       +---- Invalid ---> Error response
       |
       v
Valid request
       |
       +---- DynamoDB
       |
       +---- SES
```

This prevents obviously invalid data from reaching downstream services.

It also makes debugging easier because validation failures can be logged with an explanation of why the request was rejected.

---

# 15. Repository Structure

The repository is organized around infrastructure boundaries and application responsibilities.

```text
.
├── .github/
│   └── workflows/
│       └── terraform-ci.yml
│
├── backend-bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── modules/
│   ├── s3/
│   ├── api-gateway/
│   ├── lambda/
│   ├── dynamodb/
│   ├── ses/
│   ├── iam/
│   └── monitoring/
│
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── backend.tf
│       └── terraform.tfvars.example
│
├── src/
│   └── lambda/
│       └── ...
│
├── frontend/
│   └── ...
│
├── docs/
│   ├── architecture.md
│   ├── runbook.md
│   └── adr/
│
└── README.md
```

The exact module contents may evolve, but the organizational principle is important.

---

# 16. Terraform Module Design

Each AWS service is represented through a reusable Terraform module.

For example:

```text
modules/
├── dynamodb/
├── lambda/
├── api-gateway/
└── monitoring/
```

The purpose of this structure is to avoid creating one enormous Terraform configuration containing every resource.

A module should have a clearly defined responsibility.

For example:

```text
DynamoDB module
    |
    +---- Creates table
    +---- Configures billing
    +---- Configures required attributes
    +---- Exposes table ARN/name
```

The Lambda module can then consume the values it needs.

---

# 17. Environment Layer

The environment configuration is responsible for connecting the modules together.

For example:

```text
environments/dev
        |
        +---- DynamoDB module
        |
        +---- Lambda module
        |
        +---- API Gateway module
        |
        +---- S3 module
        |
        +---- SES module
        |
        +---- Monitoring module
```

This separation makes future environments easier to introduce.

For example:

```text
environments/
├── dev/
└── prod/
```

Both environments can reuse the same underlying modules while supplying different configuration values.

This is preferable to duplicating the entire Terraform implementation.

---

# 18. Terraform Dependency Management

The infrastructure is deliberately built in dependency order.

The logical sequence is:

```text
1. Terraform backend
        |
        v
2. DynamoDB + IAM
        |
        v
3. Lambda + SES
        |
        v
4. API Gateway + S3 frontend
        |
        v
5. Monitoring + CI/CD
```

The reason for this order is straightforward.

For example:

* IAM needs to know the DynamoDB table ARN.
* Lambda needs the IAM role.
* API Gateway needs the Lambda function.
* Monitoring needs the Lambda function and its metrics.

Terraform handles these relationships through its dependency graph.

The engineer does not normally need to manually orchestrate every resource creation step.

Terraform determines the required order from resource references.

This is one of the major advantages of Infrastructure as Code over manually clicking through the AWS console.

---

# 19. Terraform Remote State

Terraform needs to maintain state describing the infrastructure it manages.

This project stores that state remotely in Amazon S3.

The architecture is:

```text
Developer / CI
       |
       v
Terraform
       |
       v
S3 Remote State
```

Remote state is important when infrastructure is managed by more than one person or from more than one machine.

Without remote state, different engineers or CI jobs could end up working with different local state files.

That creates a risk of conflicting changes.

The project therefore creates the state bucket through a separate bootstrap configuration.

---

# 20. Bootstrap Layer

The `backend-bootstrap` directory exists specifically to create the infrastructure required for Terraform itself.

This creates a small dependency problem:

> Terraform needs a backend to store its state, but Terraform also needs to create that backend.

The solution is to bootstrap the backend separately.

```text
backend-bootstrap/
        |
        v
S3 state bucket
        |
        v
Main Terraform configuration
```

The bootstrap configuration is run once when establishing the environment.

After the bucket exists, the main Terraform configuration can use it as its remote backend.

---

# 21. Important Terraform Backend Detail

Terraform backend configuration has an important limitation:

Backend configuration cannot normally reference Terraform variables in the same way that regular resources can.

Therefore, the backend bucket name needs to be supplied as backend configuration rather than dynamically calculated from Terraform variables.

This is why the deployment instructions explicitly require updating the backend configuration with the bucket name created during bootstrap.

This is an example of a small Terraform detail that can be confusing when first working with remote state.

---

# 22. Deployment Process

Deployment is intentionally divided into two stages.

## Stage 1 - Bootstrap the backend

```bash
cd backend-bootstrap

cp terraform.tfvars.example terraform.tfvars

terraform init

terraform apply
```

This creates the S3 bucket used for Terraform remote state.

The output provides the bucket name.

---

## Stage 2 - Configure the environment

The generated state bucket name is placed into:

```text
environments/dev/backend.tf
```

The backend configuration then knows where Terraform state should be stored.

---

## Stage 3 - Deploy application infrastructure

```bash
cd environments/dev

cp terraform.tfvars.example terraform.tfvars

terraform init

terraform plan

terraform apply
```

The commands have different purposes.

### `terraform init`

Initializes Terraform and downloads the required providers and modules.

### `terraform plan`

Calculates the changes Terraform intends to make.

This is an important safety step because it allows an engineer to review infrastructure changes before applying them.

### `terraform apply`

Actually creates or changes the AWS resources described by the Terraform configuration.

---

# 23. AWS Service Verification

Some AWS services require account or identity verification before they can be used.

For this project, SES requires the relevant email identity to be verified.

SNS email subscriptions also require confirmation.

Therefore, after deployment, the engineer must check the verification email and complete the verification process.

Without completing these steps, the infrastructure may exist correctly while email functionality still does not work.

This distinction is important:

> Infrastructure being successfully deployed does not necessarily mean that every external service dependency is operational.

---

# 24. Testing the Application

After deployment, Terraform exposes the website URL through an output.

For example:

```bash
terraform output site_url
```

Open the resulting URL in a browser.

Then test:

1. Load the contact form.
2. Submit a valid form.
3. Confirm the browser receives a success response.
4. Confirm the item appears in DynamoDB.
5. Confirm the email notification arrives.
6. Check CloudWatch logs.
7. Test invalid input.
8. Confirm invalid requests are rejected.

Testing all of these layers is more useful than simply checking whether the webpage loads.

---

# 25. CI/CD

The project uses GitHub Actions for Terraform automation.

The pipeline provides an automated validation mechanism around infrastructure changes.

A simplified flow is:

```text
Developer
    |
    | Pull Request
    v
GitHub
    |
    v
Terraform Plan
    |
    v
Review
    |
    v
Merge
    |
    v
Deployment
```

The key principle is that infrastructure changes should be reviewed before they are applied.

---

# 26. OpenID Connect Authentication

The CI/CD pipeline does not store long-lived AWS access keys.

Instead, GitHub Actions authenticates to AWS using OpenID Connect (OIDC).

The conceptual flow is:

```text
GitHub Actions
      |
      | OIDC token
      v
AWS IAM
      |
      | temporary credentials
      v
Terraform
```

This is preferable to storing permanent AWS access keys in GitHub secrets.

The credentials used by the workflow are temporary rather than long-lived.

The trust relationship can also be restricted to the intended repository.

This reduces the risk associated with leaked or forgotten permanent credentials.

---

# 27. Pull Request Deployment Gate

Every pull request runs Terraform planning before infrastructure changes are deployed.

This provides an opportunity to inspect:

```text
What Terraform wants to change
```

before allowing:

```text
Terraform to change AWS
```

The production-style workflow therefore becomes:

```text
Pull Request
     |
     v
terraform plan
     |
     v
Review
     |
     v
Merge
     |
     v
Approval
     |
     v
terraform apply
```

The manual approval step is particularly useful for environments where an infrastructure change should never reach AWS without human review.

---

# 28. Security Model

The security design is based on several principles.

## 28.1 Least privilege

Lambda receives only the permissions it requires.

## 28.2 Resource-level permissions

Where possible, IAM permissions reference specific AWS resources rather than entire services.

## 28.3 No long-lived CI credentials

GitHub Actions uses OIDC instead of permanent AWS access keys.

## 28.4 Input validation

User-provided data is validated before it reaches downstream services.

## 28.5 Controlled deployment

Terraform changes are reviewed through the CI/CD workflow before they are applied.

Together, these controls provide a significantly stronger security baseline than simply deploying the application with broad permissions and manually managed credentials.

---

# 29. Cost Model

The architecture is designed for a low-volume workload.

There are no permanently running EC2 instances or database servers.

The main services involved are:

* S3
* API Gateway
* Lambda
* DynamoDB
* SES
* CloudWatch
* SNS

For occasional portfolio-project traffic, the expected cost is very low.

However, it is important not to describe the architecture as universally "free."

AWS pricing and free-tier eligibility can change, and usage beyond included allowances can generate charges.

The more accurate architectural statement is:

> The architecture has no major always-on compute or database cost and is well suited to very low-volume workloads.

This is a more reliable way of discussing cloud cost than assuming that every component will always cost exactly zero.

---

# 30. Failure Scenarios

A useful architecture document should also explain what happens when something goes wrong.

## Lambda failure

If Lambda throws an exception:

```text
Lambda
   |
   v
CloudWatch
   |
   v
Error alarm
   |
   v
SNS
   |
   v
Operator notification
```

The failed invocation is also recorded in CloudWatch logs.

---

## Invalid request

If a visitor submits invalid data:

```text
Browser
   |
   v
API Gateway
   |
   v
Lambda
   |
   v
Validation
   |
   +---- Invalid
           |
           v
      Error response
```

The request should not be written to DynamoDB or sent through SES.

---

## DynamoDB failure

If the Lambda function cannot write the submission to DynamoDB, the application should return an appropriate error rather than pretending the submission succeeded.

The error should also be visible through application logs and monitoring.

---

## SES failure

If email delivery fails, the application needs to handle that failure explicitly.

The DynamoDB record is particularly valuable here because the submission can remain stored even if notification delivery fails.

This highlights why storing the submission and notifying the owner are two separate responsibilities.

---

# 31. Lessons Learned During Development

One of the strongest parts of this project is the record of problems encountered during implementation.

Real infrastructure work rarely goes from:

```text
terraform apply
```

to:

```text
everything works perfectly
```

on the first attempt.

Documenting the failures makes the project more useful because it demonstrates how infrastructure problems are diagnosed and resolved.

---

## 31.1 Terraform module escaped its boundary

An early implementation allowed a module to use `templatefile()` with a relative path that reached outside its own directory.

It happened to work in the original calling context, but the module was no longer truly self-contained.

The problem was architectural rather than simply syntactical.

A reusable module should not depend on knowing where it happens to be called from.

The solution was to pass the already-rendered content into the module as an input.

The lesson is:

> Terraform modules should have explicit inputs and outputs and should not depend on hidden filesystem relationships outside their own boundary.

This makes modules easier to reuse and test.

---

# 32. Stale Terraform State Lock

During one deployment, an AWS resource creation became stuck because of a network problem.

The Terraform process was interrupted.

As a result, the Terraform state lock remained.

A subsequent deployment then failed because Terraform believed another operation was still in progress.

The lock exists for a good reason.

Terraform state represents the desired relationship between configuration and real infrastructure.

Allowing two Terraform processes to modify the same state simultaneously could result in corruption or inconsistent infrastructure.

Therefore, state locking should be viewed as a safety mechanism.

The problem was resolved using the Terraform unlock procedure with the lock ID reported by Terraform.

The lesson is:

> A state-lock error is inconvenient, but the lock is protecting the infrastructure from potentially much worse problems.

---

# 33. Duplicate and Orphaned Resources

Repeated deployment attempts during network problems resulted in a mismatch between AWS resources and Terraform state.

Some resources existed in AWS but were not correctly represented in Terraform state.

This is commonly described as **configuration drift or state inconsistency**, depending on the exact circumstances.

The infrastructure was manually audited and cleaned up.

The environment was then rebuilt from Terraform.

The rebuild was particularly valuable because it demonstrated that the infrastructure could actually be recreated from code.

That is one of the core promises of Infrastructure as Code.

The desired end state should not depend on:

```text
"I created something manually a few months ago and I hope nobody deletes it."
```

Instead, it should be possible to say:

```text
"The infrastructure is defined in code and can be recreated."
```

---

# 34. `EntityAlreadyExists` During Rebuild

After the cleanup, an IAM role remained from an earlier deployment.

The next Terraform deployment failed with an `EntityAlreadyExists` error.

The cause was not that Terraform had become confused.

A resource still existed in AWS.

Once that leftover resource was removed, Terraform could create the role normally.

The general lesson is:

> When Terraform reports that a resource already exists during an apparently clean deployment, first check whether an old manually created or previously orphaned resource remains in AWS.

This is particularly useful when recovering from failed or partially completed deployments.

---

# 35. Why These Failures Matter

These failures are valuable because they demonstrate practical infrastructure engineering rather than only following a deployment tutorial.

The important skills demonstrated are:

* Understanding Terraform state
* Understanding state locking
* Debugging failed deployments
* Identifying resources outside Terraform state
* Designing reusable modules
* Recovering from partially completed infrastructure changes
* Rebuilding infrastructure from code

Infrastructure engineering is not only about creating resources.

It is also about understanding what happens when those resources do not behave as expected.

---

# 36. Documentation Strategy

The project keeps architectural decisions separate from implementation details.

The documentation structure includes:

```text
docs/
├── architecture.md
├── runbook.md
└── adr/
```

## `architecture.md`

Explains how the system is designed and how the components interact.

## `adr/`

Contains Architecture Decision Records.

An ADR should answer:

> Why did we make this decision?

For example:

* Why HTTP API instead of REST API?
* Why DynamoDB?
* Why on-demand billing?
* Why OIDC instead of AWS access keys?
* Why separate Terraform modules?

The purpose of an ADR is not to explain how something works.

It explains **why the team chose one option over another**.

---

## `runbook.md`

The runbook is intended for operational tasks.

It should explain things such as:

* How to verify a deployment
* How to check logs
* How to troubleshoot Lambda failures
* How to check alarms
* How to safely destroy the environment
* How to rebuild the infrastructure

This is particularly useful when somebody other than the original author needs to operate the system.

---

# 37. Future Production Improvements

The current architecture is appropriate for a small project, but a production system could be extended.

## 37.1 Production environment

Add:

```text
environments/prod/
```

The production environment can reuse the same Terraform modules while using production-specific configuration.

This provides a clean separation between development and production infrastructure.

---

## 37.2 CloudFront and ACM

For a production website, the static frontend could be placed behind Amazon CloudFront.

A custom domain could then be configured with AWS Certificate Manager (ACM) for HTTPS.

The conceptual architecture would become:

```text
User
  |
  v
CloudFront
  |
  v
S3
```

This would provide a more production-oriented frontend delivery architecture than directly exposing the S3 website endpoint.

---

## 37.3 Automated Terraform security scanning

The CI pipeline could include tools such as:

```text
tfsec
```

or:

```text
Checkov
```

These tools can inspect Terraform configurations for common security and configuration problems before infrastructure changes are deployed.

The pipeline could therefore become:

```text
Pull Request
      |
      +---- Terraform formatting
      |
      +---- Terraform validation
      |
      +---- Security scanning
      |
      +---- Terraform plan
      |
      v
Human review
```

---

# 38. Distributed Tracing

For a larger application, AWS X-Ray could be introduced.

The current request passes through multiple managed services:

```text
Browser
   |
   v
API Gateway
   |
   v
Lambda
   |
   +---- DynamoDB
   |
   +---- SES
```

If a request becomes slow, logs alone may not immediately show where the time was spent.

Distributed tracing can provide visibility into individual requests and their downstream operations.

For this small project, tracing may be unnecessary overhead.

For a larger production system, however, it becomes much more valuable.

---

# 39. Operational Dashboard

The current monitoring model focuses primarily on failures.

A production environment could additionally provide a CloudWatch dashboard showing:

* Number of form submissions
* Lambda invocations
* Lambda errors
* Lambda duration
* Lambda throttles
* API request volume
* Successful versus failed requests

This would provide both:

```text
Reactive monitoring
```

and:

```text
Operational visibility
```

An alarm tells you:

> Something is wrong.

A dashboard helps you understand:

> What is happening across the system?

---

# 40. Recommended Production Architecture

With the proposed future improvements, the architecture could eventually look like this:

```text
                         +----------------+
                         |      User      |
                         +-------+--------+
                                 |
                                 v
                         +---------------+
                         |  CloudFront   |
                         +-------+-------+
                                 |
                                 v
                         +---------------+
                         |      S3       |
                         |   Frontend    |
                         +---------------+

User submits form
        |
        v
+-------------------+
|   API Gateway     |
|    HTTP API       |
+---------+---------+
          |
          v
+-------------------+
|      Lambda       |
+----+---------+----+
     |         |
     |         |
     v         v
+---------+  +---------+
|DynamoDB |  |   SES   |
+---------+  +---------+

          Lambda
             |
             v
       CloudWatch Logs
             |
       +-----+------+
       |            |
       v            v
    Alarms      Dashboard
       |
       v
      SNS
       |
       v
    Operator
```

Terraform manages the infrastructure, while GitHub Actions handles the deployment workflow.

---

# 41. Design Principles Demonstrated

This project demonstrates several cloud architecture principles.

## Managed services over self-managed infrastructure

Use AWS-managed services when they provide the required functionality without unnecessary operational overhead.

## Serverless for sporadic workloads

Lambda and DynamoDB on-demand capacity are well suited to applications with unpredictable, low-volume traffic.

## Least privilege

Give workloads only the permissions they actually need.

## Infrastructure as Code

Infrastructure should be reproducible and reviewable.

## Automation

Infrastructure changes should move through an automated CI/CD process.

## Observability from the beginning

Logging and alerting should be part of the initial design rather than added only after the application fails.

## Separation of responsibilities

Each AWS service has a focused role:

```text
S3          -> Frontend
API Gateway -> API entry point
Lambda      -> Business logic
DynamoDB    -> Data storage
SES         -> Email
CloudWatch  -> Monitoring
SNS         -> Notifications
IAM         -> Authorization
Terraform   -> Infrastructure management
GitHub      -> Source control and CI/CD
```

This makes the architecture easier to reason about and maintain.

---

# 42. Deployment Checklist

Before considering the environment complete, verify the following.

### Infrastructure

* [ ] Terraform initializes successfully.
* [ ] Remote state is configured.
* [ ] DynamoDB table exists.
* [ ] Lambda function exists.
* [ ] IAM role exists with expected permissions.
* [ ] API Gateway endpoint exists.
* [ ] S3 frontend is deployed.
* [ ] SES identity is verified.
* [ ] SNS subscription is confirmed.
* [ ] CloudWatch log group exists.
* [ ] CloudWatch alarms exist.

### Application

* [ ] Website loads successfully.
* [ ] Valid form submissions succeed.
* [ ] Invalid submissions are rejected.
* [ ] Submission is written to DynamoDB.
* [ ] Email notification is received.
* [ ] Lambda logs are visible.

### CI/CD

* [ ] Pull request runs Terraform checks.
* [ ] Terraform plan is generated.
* [ ] AWS authentication uses OIDC.
* [ ] No long-lived AWS access keys are stored in the repository.
* [ ] Deployment requires the expected approval.

---

# 43. Final Takeaway

This project is intentionally small, but the engineering principles behind it are not.

A contact form is a simple business requirement.

The interesting part is how the requirement is implemented.

Instead of deploying an always-running server, the application uses managed AWS services that map naturally to each responsibility:

```text
Static content       -> S3
HTTP interface       -> API Gateway
Application logic    -> Lambda
Persistent data      -> DynamoDB
Email notification   -> SES
Logging              -> CloudWatch
Alerting             -> SNS
Access control       -> IAM
Infrastructure       -> Terraform
Deployment automation -> GitHub Actions
```

The architecture therefore demonstrates more than AWS service knowledge.

It demonstrates an approach to cloud engineering:

**keep components focused, minimize operational overhead, restrict permissions, automate infrastructure, make failures visible, and make the environment reproducible.**

That is the real value of this project.

---

# License

MIT License - see `LICENSE` for details.
