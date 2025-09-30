# Deployment Process

To ensure minimal dependency between application and infrastructure deployments a few key choices have
been made. Notably, the ECS services are initially wired to a "template" task definition family that is managed by
Terraform, but which contains no application-specific details. During normal application deployments, a new task
definition is created based on the latest version of the "template" family, but including the docker image and other
non-infrastructure related environment variables (like app version). In this setup any application deployment can
proceed without affecting any resources tracked by Terraform, and infrastructure deployments can be done
without requiring any application deployments.

# Deployment illustrations:

As can be well illustrated in the below diagrams there is now a dependency of application deployment on infrastructure
components (ECS Service, Task definition template, etc.) but not vice versa. This allows for independent deployment cycles
for infrastructure and application changes.

## Generic deployments

```mermaid
flowchart TD

    subgraph Infrastructure["Infrastructure Deployment "]
        Terraform["Terraform Apply"] --> TDV["Template Task Definition<br/>(myapp-template)"]
        Terraform --> OtherComponents["Other Infrastructure Components"]
    end

    subgraph Application["Application Deployment"]
        AppDeploy --> |2. Create new Task Definition| NewTD["App-Specific Task Definition<br/>(myapp)<br/>- Docker image<br/>- App env vars"]
    end

    AppDeploy("Application Deployment") -.-> |1. Get latest template| TDV["Template Task Definition<br/>(myapp-template)"]
    Application --> |3. Update task definition| ECSService
    Infrastructure --> |Non-task definition changes| ECSService["ECS Service<br/>(myapp-template)"]
    ECSService -.-> |New reference| NewTD


    classDef infra fill:#e1f5fe,stroke:#03a9f4;
    classDef app fill:#e8f5e9,stroke:#4caf50;
    class Terraform,TDFamily,TDV,ECSService,OtherComponents infra
    class AppDeploy,NewTD,UpdateECS app
```

## Application deployment:

```mermaid
flowchart TD
    AppDeploy("Application Deployment") -.-> |1. Get latest template| TDV["Template Task Definition<br/>(myapp-template)"]
    AppDeploy --> |2. Create new Task Definition| NewTD["App-Specific Task Definition<br/>(myapp)<br/>- Docker image<br/>- App env vars"]
    AppDeploy --> |3. Update task definition| ECSService
    ECSService -.-> |New reference| NewTD

    classDef infra fill:#e1f5fe,stroke:#03a9f4;
    classDef app fill:#e8f5e9,stroke:#4caf50;
    class Terraform,TDFamily,TDV,ECSService infra
    class AppDeploy,NewTD,UpdateECS app
```

## Infrastructure deployment:

```mermaid
flowchart TD
    Terraform["Terraform Apply"] --> TDV[("Template Task Definition Family")]
    Terraform --> ECSService["ECS Service<br/>(initial template reference)"]
    ECSService -.-> |Initial reference| TDV
    Terraform --> OtherComponents["Other Infrastructure Components"]

    classDef infra fill:#e1f1fe,stroke:#03a9f4;
    classDef app fill:#e8f5e9,stroke:#4caf50;
    class Terraform,TDFamily,TDV,ECSService,OtherComponents infra
    class AppDeploy,NewTD,UpdateECS app
```
