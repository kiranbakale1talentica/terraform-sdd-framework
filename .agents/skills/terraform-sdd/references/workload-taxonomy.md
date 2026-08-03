# Workload Taxonomy — Cloud Provider Mapping Reference

> **Used by:** `/spec` phase of the Terraform SDD skill  
> **Purpose:** Map abstract workload types to concrete cloud services per provider

---

## Design Principle

Think in **workload capabilities first**, cloud services second.

This prevents cloud-specific tunnel vision and keeps modules reusable across providers.

```
WRONG thinking:       RIGHT thinking:
"I need AWS ECS"  →   "I have a containerized HTTP service" → then → "ECS on AWS / Container Apps on Azure / Cloud Run on GCP"
```

---

## Workload Types

### 1. Containerized Service (Stateless HTTP)

A Docker container serving HTTP/gRPC traffic. No persistent local state.

| Provider | Managed Service | When to Use |
|----------|----------------|-------------|
| AWS | ECS Fargate | No cluster management needed; simpler ops |
| AWS | ECS on EC2 | Need GPU, custom AMIs, or cost optimization at scale |
| Azure | Azure Container Apps | Serverless container hosting; KEDA-based scaling |
| Azure | Azure Container Instances | Short-lived, single-container tasks |
| GCP | Cloud Run | Fully managed, scales to zero, per-request billing |

**Infrastructure considerations:**
- Load balancer (ALB / App Gateway / GLB)
- Container registry (ECR / ACR / Artifact Registry)
- Service discovery (Cloud Map / DNS / Consul)
- Health checks and readiness probes
- Log aggregation

---

### 2. Kubernetes Workload

Workloads requiring full Kubernetes orchestration (multiple pods, CRDs, custom operators, service mesh).

| Provider | Managed Service | Notes |
|----------|----------------|-------|
| AWS | EKS (Elastic Kubernetes Service) | Managed control plane; worker nodes on EC2 or Fargate |
| Azure | AKS (Azure Kubernetes Service) | AAD integration; Azure CNI or kubenet |
| GCP | GKE (Google Kubernetes Engine) | Autopilot or Standard mode |

**Infrastructure considerations:**
- Node pool design (instance types, autoscaling groups)
- Network plugin (AWS VPC CNI / Azure CNI / VPC-native)
- Ingress controller (NGINX, ALB Ingress, Istio Gateway)
- Persistent volume storage class
- RBAC and IAM integration (IRSA on EKS, Workload Identity on GKE)
- Secrets integration (External Secrets Operator, CSI driver)

---

### 3. Serverless / Functions

Event-driven, short-lived compute. No server management.

| Provider | Service | Trigger Types |
|----------|---------|--------------|
| AWS | Lambda | HTTP (API Gateway), S3 events, SQS, EventBridge, DynamoDB Streams |
| Azure | Azure Functions | HTTP, Timer, Queue, Event Hub, Service Bus, Cosmos DB |
| GCP | Cloud Functions | HTTP, Pub/Sub, Cloud Storage, Firestore |
| GCP | Cloud Run (Jobs) | Scheduled, event-driven batch |

**Infrastructure considerations:**
- API Gateway / Function URL for HTTP triggers
- Event source (queue, topic, bucket)
- VPC connectivity (for private resource access)
- Concurrency and timeout limits
- Cold start mitigation (provisioned concurrency, min instances)
- Dead-letter queue for failure handling

---

### 4. VM-Based Workload

Traditional virtual machine compute. Used when containers are not suitable or when specific OS/kernel control is needed.

| Provider | Service | Notes |
|----------|---------|-------|
| AWS | EC2 (with Auto Scaling Group) | Full OS control; wide instance variety |
| Azure | Virtual Machine Scale Sets | Windows or Linux; custom images |
| GCP | Compute Engine (Managed Instance Groups) | Custom machine types; sustained use discounts |

**Infrastructure considerations:**
- Instance type selection (CPU/memory/GPU)
- AMI / custom image management
- Auto Scaling Group with launch template
- Placement groups (for latency-sensitive clusters)
- Disk type and size (SSD vs HDD, IOPS)
- SSH key management / bastion host
- OS patch management

---

### 5. Data Pipeline / Batch Processing

Data transformation, ETL, analytics workloads.

| Provider | Service | Use Case |
|----------|---------|----------|
| AWS | AWS Glue | Serverless ETL; Spark |
| AWS | AWS Step Functions + Lambda | Orchestrated workflows |
| AWS | AWS Batch | Large-scale batch compute |
| AWS | Amazon EMR | Hadoop/Spark clusters |
| Azure | Azure Data Factory | Visual ETL; 100+ connectors |
| Azure | Azure Databricks | Spark analytics |
| Azure | Azure Synapse Analytics | Analytics + ETL |
| GCP | Cloud Dataflow | Managed Apache Beam |
| GCP | Cloud Composer | Managed Airflow |
| GCP | Dataproc | Managed Hadoop/Spark |

**Infrastructure considerations:**
- Source and sink data stores
- Orchestration / scheduling (cron, event-triggered)
- Compute scaling (on-demand vs reserved)
- Data partitioning strategy
- Failure and retry handling
- Monitoring of pipeline runs and data quality

---

### 6. Frontend Hosting (Static / SPA / CDN)

Static sites, single-page applications, or server-side rendered sites.

| Provider | Service | Notes |
|----------|---------|-------|
| AWS | S3 + CloudFront | Static hosting with global CDN; WAF integration |
| AWS | Amplify Hosting | Git-integrated; CI/CD built-in |
| Azure | Azure Static Web Apps | Global CDN; free tier; Functions integration |
| Azure | Azure Blob Storage + CDN | Lower cost static hosting |
| GCP | Cloud Storage + Cloud CDN | Globally distributed static hosting |
| GCP | Firebase Hosting | SPA-optimized; Firestore integration |

**Infrastructure considerations:**
- Origin access control (S3 OAI / OAC)
- Cache-control headers and invalidation
- Custom domain + TLS certificate (ACM / App Service Certificate / Google-managed)
- WAF rules for DDoS / bot protection
- Geo-restriction if required

---

### 7. Backend API

HTTP API services (REST, GraphQL, gRPC). May be containerized, serverless, or VM-based.

| Provider | API Management | Compute |
|----------|---------------|---------|
| AWS | API Gateway (REST/HTTP/WebSocket) | Lambda, ECS, ALB |
| Azure | API Management | Functions, Container Apps, AKS |
| GCP | API Gateway / Apigee | Cloud Run, GKE, Compute Engine |

**Infrastructure considerations:**
- API Gateway vs direct ALB exposure
- Authentication: API key, OAuth 2.0, mTLS
- Rate limiting and throttling
- Request/response transformation
- API versioning strategy
- Developer portal (if external-facing)

---

### 8. AI/ML Workload

Training, inference, feature engineering, and model serving.

| Provider | Service | Use Case |
|----------|---------|----------|
| AWS | SageMaker | Full ML platform (training + inference + pipelines) |
| AWS | Bedrock | Managed foundation models |
| AWS | Rekognition / Textract | Specialized ML APIs |
| Azure | Azure Machine Learning | Enterprise MLOps platform |
| Azure | Azure OpenAI | GPT models (OpenAI on Azure) |
| Azure | Cognitive Services | Specialized ML APIs |
| GCP | Vertex AI | Unified ML platform |
| GCP | Cloud TPU | Custom TPU hardware for training |

**Infrastructure considerations:**
- GPU instance availability and quotas
- Model artifact storage (S3 / Blob / GCS)
- Feature store
- Model registry
- Inference endpoint (real-time vs batch)
- Training job compute (spot/preemptible for cost)
- Data pipeline for training data

---

### 9. Database / Data Store

| Type | AWS | Azure | GCP |
|------|-----|-------|-----|
| Relational (PostgreSQL) | RDS / Aurora | Azure Database for PostgreSQL | Cloud SQL |
| Relational (MySQL) | RDS / Aurora | Azure Database for MySQL | Cloud SQL |
| Relational (SQL Server) | RDS | Azure SQL Database | Cloud SQL |
| NoSQL (Document) | DynamoDB | Cosmos DB | Firestore |
| NoSQL (Wide-Column) | Keyspaces | Cosmos DB (Cassandra API) | Bigtable |
| In-Memory Cache | ElastiCache (Redis/Memcached) | Azure Cache for Redis | Memorystore |
| Search | OpenSearch Service | Azure Cognitive Search | Vertex AI Search |
| Time Series | Timestream | Azure Data Explorer | BigQuery |
| Data Warehouse | Redshift | Azure Synapse | BigQuery |
| Object Storage | S3 | Azure Blob Storage | Cloud Storage |

**Infrastructure considerations:**
- Multi-AZ / zone redundancy
- Read replicas
- Automated backups and PITR
- Encryption at rest (CMK vs provider-managed)
- Private endpoint / VPC endpoint
- Parameter groups / server configuration
- Database proxy (RDS Proxy / PgBouncer)
- Connection pooling

---

### 10. Message Queue / Event Streaming

| Type | AWS | Azure | GCP |
|------|-----|-------|-----|
| Simple Queue | SQS | Azure Queue Storage / Service Bus | Cloud Tasks / Pub/Sub |
| Pub/Sub | SNS + SQS | Event Grid / Service Bus | Pub/Sub |
| Streaming | Kinesis Data Streams | Event Hubs | Pub/Sub (streaming) |
| Managed Kafka | MSK (Amazon Managed Streaming for Kafka) | Event Hubs (Kafka-compatible) | Confluent on GCP / Pub/Sub Lite |

---

## Networking Primitives

### Virtual Network Equivalents

| Concept | AWS | Azure | GCP |
|---------|-----|-------|-----|
| Virtual network | VPC | Virtual Network (VNet) | VPC |
| Subnet | Subnet | Subnet | Subnet |
| Route table | Route table | Route table | Route |
| Internet gateway | Internet Gateway | No separate resource | Cloud Router |
| NAT | NAT Gateway | NAT Gateway | Cloud NAT |
| Private endpoint | VPC Endpoint (Interface) | Private Endpoint | Private Service Connect |
| Peering | VPC Peering | VNet Peering | VPC Peering |
| Hub-spoke | Transit Gateway | Azure Virtual WAN | Shared VPC |
| Load balancer (L7) | ALB | Application Gateway | Google Load Balancer |
| Load balancer (L4) | NLB | Azure Load Balancer | Network Load Balancer |

---

## Security Primitives

| Concept | AWS | Azure | GCP |
|---------|-----|-------|-----|
| Identity/access | IAM | Azure AD / Entra ID | Cloud IAM |
| Service identity | IAM Role + IRSA | Managed Identity | Service Account |
| Secrets | Secrets Manager / Parameter Store | Key Vault | Secret Manager |
| Encryption keys | KMS | Key Vault | Cloud KMS |
| Certificates | ACM | App Service Certificate / Key Vault | Google-managed / Certificate Manager |
| Firewall (network) | Security Group / NACL | NSG | VPC Firewall Rules |
| WAF | WAF (on ALB/CloudFront) | Azure WAF | Cloud Armor |
| DDoS | Shield | DDoS Protection | Cloud Armor |
| Audit logs | CloudTrail | Activity Log | Cloud Audit Logs |
| SIEM | GuardDuty + Security Hub | Microsoft Sentinel | Security Command Center |
