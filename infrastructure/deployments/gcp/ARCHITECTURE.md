# LegendForge on GCP - Architecture & Design

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet Users                            │
│                   (Players accessing Foundry)                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
                  ┌────────────────┐
                  │   Cloudflare   │
                  │  Tunnel Router │
                  │  (DDoS Guard)  │
                  └────────┬───────┘
                           │
                           ↓
    ┌─────────────────────────────────────────────────────────────┐
    │                  GCP Project                                │
    │                                                             │
    │  ┌──────────────────────────────────────────────────────┐  │
    │  │              Cloud Load Balancer                     │  │
    │  │  - Global HTTPS routing                             │  │
    │  │  - SSL/TLS termination                              │  │
    │  │  - Cloud CDN (static assets)                        │  │
    │  │  - Cloud Armor (DDoS/WAF)                           │  │
    │  │  - Multi-region support                            │  │
    │  └──────────────┬───────────────────────────────────────┘  │
    │                │                                            │
    │                ↓                                            │
    │  ┌──────────────────────────────────────────────────────┐  │
    │  │            VPC Network                              │  │
    │  │  ┌───────────────────────────────────────────────┐  │  │
    │  │  │     Primary Region (us-central1)            │  │  │
    │  │  │  ┌─────────────────────────────────────┐   │  │  │
    │  │  │  │  Cloud NAT (Outbound Internet)    │   │  │  │
    │  │  │  └─────────────────────────────────────┘   │  │  │
    │  │  │                                            │  │  │
    │  │  │  ┌─────────────────────────────────────┐   │  │  │
    │  │  │  │     Managed Instance Group         │   │  │  │
    │  │  │  │  ┌──────────────────────────────┐  │   │  │  │
    │  │  │  │  │  Compute Instance Zone A    │  │   │  │  │
    │  │  │  │  │  ├─ Docker Engine           │  │   │  │  │
    │  │  │  │  │  ├─ Foundry VTT Container  │  │   │  │  │
    │  │  │  │  │  ├─ Cloudflare Tunnel      │  │   │  │  │
    │  │  │  │  │  └─ Monitoring Agent       │  │   │  │  │
    │  │  │  │  └──────────────────────────────┘  │   │  │  │
    │  │  │  │  ┌──────────────────────────────┐  │   │  │  │
    │  │  │  │  │  Compute Instance Zone B    │  │   │  │  │
    │  │  │  │  │  └─ Same as Zone A          │  │   │  │  │
    │  │  │  │  └──────────────────────────────┘  │   │  │  │
    │  │  │  │  ┌──────────────────────────────┐  │   │  │  │
    │  │  │  │  │  Compute Instance Zone C    │  │   │  │  │
    │  │  │  │  │  └─ Same as Zone A          │  │   │  │  │
    │  │  │  │  └──────────────────────────────┘  │   │  │  │
    │  │  │  │     (Auto-scales 2-5 replicas)    │   │  │  │
    │  │  │  └─────────────────────────────────────┘   │  │  │
    │  │  │         ↓                                  │  │  │
    │  │  │  ┌──────────────────────────────────────┐  │  │  │
    │  │  │  │   Cloud SQL Database (HA)           │  │  │  │
    │  │  │  │   ├─ PostgreSQL (Primary)           │  │  │  │
    │  │  │  │   ├─ Standby Replica (auto-failover)│  │  │  │
    │  │  │  │   ├─ Daily Backups (30-day retention)│  │  │  │
    │  │  │  │   └─ Point-in-time recovery (7 days)│  │  │  │
    │  │  │  └──────────────────────────────────────┘  │  │  │
    │  │  │                                            │  │  │
    │  │  │  ┌──────────────────────────────────────┐  │  │  │
    │  │  │  │   Cloud Storage Buckets             │  │  │  │
    │  │  │  │   ├─ Foundry Data (versioned)      │  │  │  │
    │  │  │  │   ├─ Media Assets (versioned)      │  │  │  │
    │  │  │  │   ├─ Backups (lifecycle: cold/arch)│  │  │  │
    │  │  │  │   └─ Logs (30-day retention)       │  │  │  │
    │  │  │  └──────────────────────────────────────┘  │  │  │
    │  │  └───────────────────────────────────────────┘  │  │
    │  └──────────────────────────────────────────────────┘  │
    │                                                        │  │
    │  ┌──────────────────────────────────────────────────┐  │
    │  │  Monitoring & Logging                           │  │
    │  │  ├─ Cloud Monitoring (dashboards, metrics)      │  │
    │  │  ├─ Cloud Logging (centralized logs)            │  │
    │  │  ├─ Error Reporting (error tracking)            │  │
    │  │  ├─ Uptime Checks (external monitoring)         │  │
    │  │  └─ Alert Policies (email/Slack/PagerDuty)     │  │
    │  └──────────────────────────────────────────────────┘  │
    │                                                        │
    │  ┌──────────────────────────────────────────────────┐  │
    │  │  Security & Compliance                          │  │
    │  │  ├─ Secret Manager (encrypted secrets)          │  │
    │  │  ├─ Cloud KMS (key management)                  │  │
    │  │  ├─ VPC (private networking)                    │  │
    │  │  ├─ Firewall Rules (least privilege)            │  │
    │  │  ├─ IAM Roles & Service Accounts (RBAC)         │  │
    │  │  └─ Cloud Armor (DDoS/WAF)                      │  │
    │  └──────────────────────────────────────────────────┘  │
    │                                                        │
    └────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Network Layer (VPC)

**Purpose**: Isolated network environment for all resources

**Components**:
- **VPC Network**: `legendforge-vpc`
  - Regional routing
  - Private by default (no public IPs except load balancer)
  
- **Subnets**:
  - Primary: `10.0.0.0/20` (us-central1)
  - Secondary: `10.16.0.0/20` (us-east1, optional for DR)
  
- **Cloud NAT**: Enables outbound internet for Docker pulls, package updates
  
- **Firewall Rules**:
  - SSH: Only from admin IP ranges (least privilege)
  - Internal: All traffic within subnet
  - Health checks: From GCP infrastructure (35.191.0.0/16, 130.211.0.0/22)
  - Load balancer: Port 30030 from 0.0.0.0/0
  - Deny all: Default deny with logging

### 2. Compute Layer

**Purpose**: Run Foundry VTT application with high availability

**Components**:
- **Instance Template**:
  - Ubuntu 24.04 LTS
  - 2 vCPU, 8GB RAM (configurable)
  - 100GB boot disk (pd-standard)
  - 500GB data disk (pd-ssd, persistent, not auto-deleted)
  - Shielded VM enabled (secure boot, vTPM, integrity monitoring)
  - Service account with minimal permissions

- **Managed Instance Group**:
  - Multi-zone (3 zones in us-central1: a, b, c)
  - Rolling update policy (1 surge, 0 unavailable)
  - Auto-healing with health checks
  - Named port: 30030 (Foundry port)
  
- **Auto-Scaling**:
  - Min replicas: 2
  - Max replicas: 5
  - CPU target: 70%
  - Optional: Memory-based scaling
  
- **Health Checks**:
  - HTTP GET to port 30030, path /
  - Interval: 30s
  - Timeout: 10s
  - Healthy: 2 checks
  - Unhealthy: 3 checks

### 3. Database Layer

**Purpose**: Persistent data storage with HA and backups

**Components**:
- **Cloud SQL PostgreSQL**:
  - Version: 15.x (configurable)
  - Machine: db-custom-2-7680 (2vCPU, 7.5GB RAM)
  - Tier: REGIONAL (HA with automatic failover)
  - Private IP only (inside VPC)
  
- **High Availability**:
  - Primary + standby replica in different zones
  - Automatic failover (< 1 minute)
  
- **Backups**:
  - Automated daily backups
  - Retention: 30 days
  - Point-in-time recovery: 7 days
  - Manual on-demand backups
  
- **Databases**:
  - `foundry`: Main application database
  - Users: `foundry_app` (application), `foundry_backup` (backups)
  
- **SSL/TLS**:
  - All connections encrypted
  - Public IP disabled (private connection only)
  
- **Optimization**:
  - Query Insights enabled
  - Performance tuning params:
    - max_connections: 200
    - shared_buffers: 2048 MB
    - effective_cache_size: 6144 MB

### 4. Storage Layer

**Purpose**: Persistent file storage with versioning and lifecycle management

**Components**:
- **Foundry Data Bucket** (`foundry-data-*`)
  - Worlds, user data, system files
  - Versioning: Keep 5 versions
  - Lifecycle: Move to NEARLINE after 90 days
  - Encryption: Cloud KMS (optional)
  
- **Media Assets Bucket** (`foundry-media-*`)
  - Images, sounds, videos, art
  - Versioning: Keep 3 versions
  - Lifecycle: Move to NEARLINE after 90 days
  - Encryption: Cloud KMS (optional)
  
- **Backups Bucket** (`foundry-backups-*`)
  - Database dumps, config exports
  - Multi-region location (for disaster recovery)
  - Versioning: Enabled
  - Lifecycle:
    - 0-30 days: STANDARD
    - 30-90 days: COLDLINE (cheaper)
    - 90-365 days: ARCHIVE (cheapest)
    - 365+ days: Deleted
  
- **Logs Bucket** (`foundry-logs-*`)
  - Audit trails and access logs
  - Lifecycle: COLDLINE after 30 days, delete after 90 days
  
**Access Control**:
- Uniform bucket-level access (no object ACLs)
- Public access prevention enabled
- Only service accounts can access (via IAM)

### 5. Load Balancing Layer

**Purpose**: Distribute traffic, SSL termination, DDoS protection, CDN

**Components**:
- **Global HTTPS Load Balancer**:
  - Global anycast IP (optimized routing)
  - Distributes across all instance group zones
  
- **Backend Service**:
  - Protocol: HTTP (backends are in private VPC)
  - Health checks: HTTP to port 30030
  - Session affinity: CLIENT_IP (sticky sessions for Foundry)
  - Cloud CDN enabled
  - Circuit breaker:
    - Max connections: 1000
    - Max pending requests: 100
    - Max requests: 1000
  - Outlier detection: Automatic unhealthy instance removal
  
- **URL Map**:
  - Routes all paths to Foundry backend
  - Configurable for future expansions
  
- **SSL Certificate**:
  - Google-managed SSL certificate
  - Auto-provisions for configured domain
  - HTTPS only (HTTP redirects to HTTPS)
  
- **SSL Policy**:
  - Profile: RESTRICTED
  - Min TLS: 1.2
  - Modern ciphers only
  
- **Cloud CDN**:
  - Caches static assets
  - TTL: 1 hour (default)
  - Bypasses cache for Authorization headers
  - Automatic compression
  
- **Cloud Armor**:
  - Rate limiting: 100 req/min per IP
  - SQL injection detection
  - XSS detection
  - Optional: DDoS adaptive protection (beta)
  - Optional: Geo-blocking rules

### 6. Monitoring & Observability

**Purpose**: Real-time visibility into system health and performance

**Components**:
- **Cloud Monitoring Dashboard**:
  - CPU utilization (instances)
  - Memory utilization (instances)
  - Network in/out (instances)
  - Backend health (load balancer)
  - Cloud SQL CPU and connections
  - Custom metrics
  
- **Alert Policies**:
  - High CPU (> 80% for 5 min) → Alert
  - High Memory (> 85% for 5 min) → Alert
  - Backend unhealthy → Alert
  - Cloud SQL high CPU (> 75%) → Alert
  - Uptime check failed → Alert
  - Error spike detected → Alert
  
- **Notification Channels**:
  - Email
  - Slack (optional)
  - PagerDuty (optional)
  
- **Uptime Checks**:
  - External monitoring from 3 regions (USA, Europe, Asia)
  - HTTPS health check every 60 seconds
  - Alert if any check fails
  
- **Cloud Logging**:
  - Centralized log aggregation
  - Filter by resource, severity, pattern
  - Log retention: Configurable (default 30 days)
  
- **Error Reporting**:
  - Automatic error grouping
  - Error rate tracking
  - Alert on error spikes

### 7. Security & IAM

**Purpose**: Least-privilege access control and secrets management

**Components**:
- **Service Accounts** (5 total):
  - `foundry-compute`: Instances (compute, logging, monitoring, secrets)
  - `foundry-cloudsql`: Database operations
  - `foundry-storage`: Cloud Storage access
  - `foundry-monitoring`: Monitoring dashboards
  - `foundry-secrets`: Secret Manager access
  
- **IAM Roles**:
  - Custom `foundry_compute_role` with minimal permissions
  - Pre-defined roles for each service account
  - Binding per resource (bucket, etc)
  
- **Secret Manager**:
  - Encrypted at rest (Cloud KMS)
  - Access controlled via IAM
  - Automatic rotation (optional)
  - Secrets:
    - Database password
    - Foundry license key
    - Foundry admin key
    - Cloudflare tunnel token
  
- **Cloud KMS**:
  - Key ring in primary region
  - Encryption key for secrets
  - 90-day key rotation
  - Audit logging on all operations
  
- **VPC Service Controls**:
  - Optional: Perimeter for preventing data exfiltration
  - Ingress/egress policies

---

## Data Flow

### User Accessing Foundry

```
1. User opens https://foundry.example.com
   ↓
2. DNS resolves to Load Balancer IP (anycast)
   ↓
3. Load Balancer routes HTTPS request to nearest region
   ↓
4. SSL/TLS termination at load balancer
   ↓
5. Load balancer forwards HTTP to healthy instance
   ↓
6. Instance Docker container (Foundry VTT)
   ├─ Serves web UI (cached by CDN)
   ├─ WebSocket connections for live updates
   ├─ Reads/writes to Cloud SQL database
   └─ Stores uploaded files in Cloud Storage
   ↓
7. Response sent back through load balancer
   ↓
8. Browser renders Foundry VTT
```

### Database Backup Flow

```
1. Cloud SQL automated backup (daily at 02:00 UTC)
   ↓
2. Backup stored in Cloud Storage (backups bucket)
   ↓
3. Lifecycle policy moves old backups to COLDLINE/ARCHIVE
   ↓
4. Retention: ARCHIVE indefinitely, delete after 365 days
```

### Monitoring Flow

```
1. Instance sends metrics to Cloud Monitoring
   ├─ CPU, memory, network
   ├─ Application logs
   └─ Custom metrics
   ↓
2. Alert policies evaluate metrics
   ↓
3. If threshold exceeded: Send notification
   ├─ Email
   ├─ Slack
   └─ SMS/PagerDuty
   ↓
4. Dashboard visualizes in real-time
```

---

## High Availability & Disaster Recovery

### HA Features

1. **Compute**:
   - Multi-zone instances (3 zones)
   - Auto-healing: Unhealthy instances replaced automatically
   - Auto-scaling: Handles traffic spikes
   - Rolling updates: Zero-downtime deployments

2. **Database**:
   - Regional cluster (primary + standby)
   - Automatic failover (< 1 minute)
   - Daily backups (30-day retention)
   - Point-in-time recovery (7 days)

3. **Load Balancer**:
   - Global distribution
   - Automatic routing to healthy backends
   - SSL certificate auto-renewal

### Disaster Recovery Options

**Option 1: Single-Region HA (Current)**
- Recovery Time Objective (RTO): < 5 minutes
- Recovery Point Objective (RPO): < 1 hour
- Cost: $350-400/month
- Suitable for: Most campaigns

**Option 2: Multi-Region (Optional)**
- Set `enable_multi_region = true`
- Cloud SQL read replica in secondary region
- Cross-region load balancing (requires extra setup)
- Recovery Time Objective (RTO): < 1 minute
- Recovery Point Objective (RPO): Near zero
- Cost: 1.5x single region
- Suitable for: Critical campaigns, international play

**Option 3: Manual Backup & Restore**
- Export database to Cloud Storage
- Download backups locally
- Can restore to new GCP region or on-premises
- RTO: 30+ minutes
- RPO: Last backup
- Cost: Storage only
- Suitable for: Long-term archival

---

## Performance Characteristics

### Latency

- **Global Load Balancer**: < 50ms (anycast routing)
- **Instance to Database**: < 5ms (private connection, same zone)
- **Instance to Storage**: < 10ms (same region)
- **Cloudflare Tunnel**: < 100ms (optimized routes)

### Throughput

- **Per Instance**: ~1000-2000 concurrent WebSocket connections
- **Database**: ~200 connections, ~1000s queries/sec (configurable)
- **Storage**: ~100 MB/s per instance
- **Load Balancer**: 1000+ Mbps

### Capacity

- **2-5 instances**: 50-250 concurrent players
- **Database**: 2 vCPU, 7.5GB RAM supports 500+ concurrent users
- **Storage**: 500GB instance disk, unlimited cloud storage

---

## Cost Optimization

### Resource Sizing

| Component | Small (5-10 players) | Medium (25 players) | Large (50+ players) |
|-----------|---------------------|---------------------|---------------------|
| Compute | n2-standard-2 | n2-standard-4 | n2-standard-8 |
| Instances | 2-3 | 2-5 | 3-10 |
| Database | db-custom-2-7680 | db-custom-4-16384 | db-custom-8-32768 |
| Storage | 500 GB | 2 TB | 5 TB |
| Est. Cost | $350/mo | $700/mo | $1500/mo |

### Cost Reduction

1. **Committed Use Discounts (CUDs)**:
   - 1-year: 25% savings
   - 3-year: 50% savings
   - Recommended for stable workloads

2. **Instance Types**:
   - E2 machines: Cheaper but lower performance
   - N2 machines: Balanced (recommended)
   - C2 machines: Compute-optimized (expensive)

3. **Storage Tiers**:
   - Keep 5-30 versions (automatic cleanup)
   - Archive old backups to COLDLINE/ARCHIVE
   - Delete after 365 days

4. **Database Downsizing**:
   - Start with db-custom-2-7680
   - Monitor utilization
   - Scale up only if needed

---

## Scalability Roadmap

### Short Term (Weeks 1-4)

- ✓ Single instance group (2-5 replicas)
- ✓ Cloud SQL regional HA
- ✓ Cloud Storage for backups
- ✓ Cloud Monitoring dashboards

### Medium Term (Months 2-6)

- Optimize instance sizing based on metrics
- Enable Cloud CDN for popular modules
- Implement advanced Cloud Armor rules
- Add multi-region read replicas (optional)

### Long Term (6+ Months)

- Consider GKE (Kubernetes) for better orchestration
- Implement service mesh for microservices
- Add caching layers (Cloud Memcache)
- Implement advanced database sharding

---

## References

- GCP Load Balancing: https://cloud.google.com/load-balancing/docs
- Cloud SQL Best Practices: https://cloud.google.com/sql/docs/mysql/best-practices
- Cloud Armor: https://cloud.google.com/armor/docs
- Terraform GCP Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs

