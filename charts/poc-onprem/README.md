# POC On-Premise RAG Helm Chart

A comprehensive Helm chart for deploying a complete RAG (Retrieval-Augmented Generation) system with Airflow orchestration, LLM services, and document processing capabilities on OpenShift or Kubernetes.

## Overview

This Helm chart deploys a full-stack RAG solution including:

- **Apache Airflow** - Workflow orchestration for document processing
- **Ollama LLM Services** - Embedding and chat models
- **MinIO** - Object storage for documents
- **Qdrant** - Vector database for embeddings
- **PostgreSQL** - Relational databases for Airflow and document metadata
- **Document Processing Services** - PDF extraction, embedding, and chat services
- **Web UI** - Interactive chat interface

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                           │
│                      (Chat Docs UI)                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────┴────────────────────────────────────┐
│                    Application Services                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Chat Docs    │  │  Embedding   │  │ PDF Extractor│         │
│  │   Service    │  │   Service    │  │   Service    │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                             │
┌────────────────────────────┴────────────────────────────────────┐
│                      LLM Services                                │
│  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │  Ollama Embedding    │  │   Ollama Chat        │            │
│  │  (nomic-embed-text)  │  │   (tinyllama)        │            │
│  └──────────────────────┘  └──────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                             │
┌────────────────────────────┴────────────────────────────────────┐
│                    Storage & Databases                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  MinIO   │  │  Qdrant  │  │PostgreSQL│  │PostgreSQL│       │
│  │ (Objects)│  │ (Vectors)│  │(Airflow) │  │  (PDF)   │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────────────┘
                             │
┌────────────────────────────┴────────────────────────────────────┐
│                    Workflow Orchestration                        │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              Apache Airflow                          │       │
│  │  (API Server, Scheduler, DAG Processor)              │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Kubernetes 1.19+ or OpenShift 4.x+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure
- **ReadWriteMany (RWX) storage class** for Airflow logs (e.g., NFS, CephFS, GlusterFS)
- Sufficient cluster resources (see Resource Requirements below)

## Resource Requirements

### Minimum Requirements

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| PostgreSQL (Airflow) | 250m | 256Mi | 10Gi |
| PostgreSQL (PDF) | 500m | 512Mi | 20Gi |
| MinIO | 500m | 512Mi | 50Gi |
| Qdrant | 500m | 1Gi | 30Gi |
| Ollama Embedding | 2000m | 4Gi | 10Gi |
| Ollama Chat | 2000m | 4Gi | 10Gi |
| Airflow (total) | 1250m | 3.5Gi | 10Gi (logs) |
| App Services (total) | 1600m | 2.5Gi | - |
| **Total** | **~9 CPU** | **~19Gi RAM** | **~140Gi Storage** |

### Recommended for Production

- Double the CPU and memory allocations
- Use dedicated storage classes with good I/O performance
- Enable resource quotas and limits
- Implement horizontal pod autoscaling for application services

## Installation

### 1. Prepare Container Images

Build and push all required Docker images to your container registry:

```bash
# Set your registry
export REGISTRY="quay.io/your-org"

# Build and push images
docker build -t $REGISTRY/poc-onprem-airflow-api-server:latest .
docker push $REGISTRY/poc-onprem-airflow-api-server:latest

# Repeat for all services (see openshift/README.md for complete list)
```

### 2. Configure Values

Create a `custom-values.yaml` file:

```yaml
global:
  imageRegistry: "quay.io/your-org"
  namespace: "poc-onprem"

# Change default passwords!
postgresql:
  airflow:
    credentials:
      password: "your-secure-password"
  pdf:
    credentials:
      password: "your-secure-password"

minio:
  credentials:
    rootPassword: "your-secure-password"

airflow:
  secrets:
    fernetKey: "your-generated-fernet-key"
    internalApiSecretKey: "your-generated-secret"
    jwtSecret: "your-generated-jwt-secret"
```

### 3. Install the Chart

```bash
# Install with default values
helm install poc-onprem ./helm/poc-onprem \
  --namespace poc-onprem \
  --create-namespace

# Install with custom values
helm install poc-onprem ./helm/poc-onprem \
  --namespace poc-onprem \
  --create-namespace \
  --values custom-values.yaml
```

### 4. Verify Installation

```bash
# Check pod status
kubectl get pods -n poc-onprem

# Watch deployment progress
kubectl get pods -n poc-onprem -w

# Check all resources
kubectl get all -n poc-onprem
```

## Configuration

### Key Configuration Options

#### Global Settings

```yaml
global:
  namespace: poc-onprem
  imageRegistry: "<your-registry>"
  imagePullPolicy: IfNotPresent
  imagePullSecrets:
    - name: quay-pull-secret
```

#### Database Configuration

```yaml
postgresql:
  airflow:
    enabled: true
    replicas: 1
    persistence:
      size: 10Gi
      storageClassName: ""  # Use default
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "1000m"
```

#### LLM Services

```yaml
ollama:
  embedding:
    enabled: true
    model: "nomic-embed-text"
    persistence:
      size: 10Gi
    resources:
      requests:
        memory: "4Gi"
        cpu: "2000m"
      limits:
        memory: "8Gi"
        cpu: "4000m"
```

#### Routes (OpenShift)

```yaml
routes:
  enabled: true
  tls:
    enabled: true
    termination: edge
```

### Complete Configuration

See `values.yaml` for all available configuration options.

## Upgrading

```bash
# Upgrade with new values
helm upgrade poc-onprem ./helm/poc-onprem \
  --namespace poc-onprem \
  --values custom-values.yaml

# Upgrade with specific values
helm upgrade poc-onprem ./helm/poc-onprem \
  --namespace poc-onprem \
  --set airflow.apiServer.replicas=2
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall poc-onprem --namespace poc-onprem

# Optionally delete the namespace
kubectl delete namespace poc-onprem
```

**Note:** PVCs are not automatically deleted. Delete them manually if needed:

```bash
kubectl delete pvc --all -n poc-onprem
```

## Usage

### Accessing Applications

After installation, get the application URLs:

```bash
# Airflow Web UI
kubectl get route airflow-api-server -n poc-onprem -o jsonpath='{.spec.host}'

# MinIO Console
kubectl get route minio-console -n poc-onprem -o jsonpath='{.spec.host}'

# Chat Docs UI
kubectl get route chat-docs-ui -n poc-onprem -o jsonpath='{.spec.host}'
```

### Creating Airflow Admin User

```bash
kubectl exec -n poc-onprem -it deployment/airflow-api-server -- \
  airflow users create \
  --username admin \
  --password admin \
  --firstname Admin \
  --lastname User \
  --role Admin \
  --email admin@example.com
```

### Uploading Documents

1. Access MinIO Console
2. Create a bucket (e.g., `documents`)
3. Upload PDF files
4. Airflow DAGs will automatically process them

### Monitoring

```bash
# View logs
kubectl logs -f deployment/airflow-api-server -n poc-onprem
kubectl logs -f deployment/ollama-llm-embedding -n poc-onprem
kubectl logs -f deployment/chat-docs-service -n poc-onprem

# Check resource usage
kubectl top pods -n poc-onprem
kubectl top nodes
```

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod to see events
kubectl describe pod <pod-name> -n poc-onprem

# Check logs
kubectl logs <pod-name> -n poc-onprem

# Check previous logs if pod restarted
kubectl logs <pod-name> -n poc-onprem --previous
```

### PVC Not Binding

```bash
# Check PVC status
kubectl get pvc -n poc-onprem

# Describe PVC
kubectl describe pvc <pvc-name> -n poc-onprem

# Check storage classes
kubectl get storageclass
```

### Airflow Logs PVC Issues

The Airflow logs PVC requires ReadWriteMany (RWX) access mode. If you don't have RWX storage:

1. Use a storage class that supports RWX (NFS, CephFS, GlusterFS)
2. Or disable shared logs and use separate PVCs per pod (requires chart modification)

### LLM Services Taking Long to Start

Ollama services download models on first start, which can take 5-10 minutes:

```bash
# Monitor model download
kubectl logs -f deployment/ollama-llm-embedding -n poc-onprem
```

### Database Connection Issues

```bash
# Check if databases are ready
kubectl get pods -n poc-onprem | grep postgres

# Test database connection
kubectl exec -it deployment/pg-airflow-db -n poc-onprem -- \
  psql -U airflow -d airflow -c "SELECT 1;"
```

## Security Considerations

### ⚠️ Important Security Notes

1. **Change Default Passwords**: All default passwords must be changed before production use
2. **Use External Secrets**: Consider using Sealed Secrets, External Secrets Operator, or HashiCorp Vault
3. **Enable RBAC**: Implement proper role-based access control
4. **Network Policies**: Restrict pod-to-pod communication
5. **Image Scanning**: Scan all container images for vulnerabilities
6. **TLS Everywhere**: Enable TLS for all external routes
7. **Resource Quotas**: Implement resource quotas to prevent resource exhaustion
8. **Pod Security**: Enable Pod Security Standards or Pod Security Policies

### Generating Secure Secrets

```bash
# Generate Fernet key for Airflow
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Generate random secret
openssl rand -base64 32
```

## Development

### Testing Changes

```bash
# Lint the chart
helm lint ./helm/poc-onprem

# Dry-run installation
helm install poc-onprem ./helm/poc-onprem \
  --namespace poc-onprem \
  --dry-run --debug

# Template rendering
helm template poc-onprem ./helm/poc-onprem \
  --namespace poc-onprem
```

### Debugging

```bash
# Get rendered manifests
helm get manifest poc-onprem -n poc-onprem

# Get values
helm get values poc-onprem -n poc-onprem

# Get release history
helm history poc-onprem -n poc-onprem
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Your License Here]

## Support

For issues and questions:

- GitHub Issues: https://github.com/your-org/drax-rag-poc-onprem/issues
- Documentation: https://github.com/your-org/drax-rag-poc-onprem/wiki

## Changelog

### Version 1.0.0

- Initial release
- Support for OpenShift and Kubernetes
- Complete RAG stack deployment
- Airflow orchestration
- LLM services with Ollama
- Document processing pipeline
- Web-based chat interface