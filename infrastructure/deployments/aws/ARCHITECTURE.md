# AWS Infrastructure Architecture for Foundry VTT

## High-Level Architecture

```
                          INTERNET
                            │
                    ┌───────┴───────┐
                    │  Route 53     │
                    │  DNS & Health │
                    └───────┬───────┘
                            │
                ┌───────────┴───────────┐
                │                       │
        ┌───────▼────────────┐   ┌─────▼────────────┐
        │   CloudFront CDN   │   │  ACM Certificate │
        │  (Static Assets)   │   │   (HTTPS/TLS)    │
        └───────┬────────────┘   └──────────────────┘
                │
        ┌───────┴──────────┐
        │                  │
    ┌───▼───┐         ┌────▼──────┐
    │ S3    │         │ ALB        │
    │Assets │         │Multi-AZ    │
    └───┬───┘         └────┬───────┘
        │                  │
        │         ┌────────┴─────────┐
        │         │                  │
        │    ┌────▼─────┐       ┌───▼─────┐
        │    │EC2 AZ-1  │       │EC2 AZ-2 │
        │    │Foundry   │       │Foundry  │
        │    │Docker    │       │Docker   │
        │    └────┬─────┘       └───┬─────┘
        │         │                  │
        │         └──────────┬───────┘
        │                    │
        │         ┌──────────▼──────────┐
        │         │                     │
        │    ┌────▼──┐           ┌─────▼──────┐
        │    │S3     │           │ RDS        │
        │    │Foundry│           │PostgreSQL  │
        │    │Data   │           │Multi-AZ    │
        │    └───────┘           └────────────┘
        │
        └─────────────────────────────┐
                                      │
                            ┌─────────▼────────┐
                            │   S3 Logs        │
                            │   Bucket         │
                            └──────────────────┘
```

## Detailed Component Layout

### 1. Network Layer (VPC)

```
VPC: 10.0.0.0/16
├── Public Subnets (10.0.0.0/20 each AZ)
│   ├── AZ-1: 10.0.0.0/20
│   │   └── NAT Gateway (EIP)
│   │       └── Route to 0.0.0.0/0 → IGW
│   └── AZ-2: 10.0.1.0/20
│       └── NAT Gateway (EIP)
│           └── Route to 0.0.0.0/0 → IGW
├── Private Subnets (10.0.2.0/20 each AZ)
│   ├── AZ-1: 10.0.2.0/20
│   │   ├── EC2 Instance (Foundry)
│   │   └── Route to 0.0.0.0/0 → NAT Gateway (AZ-1)
│   └── AZ-2: 10.0.3.0/20
│       ├── EC2 Instance (Foundry)
│       └── Route to 0.0.0.0/0 → NAT Gateway (AZ-2)
└── Database Subnets (10.0.4.0/20 each AZ)
    ├── AZ-1: 10.0.4.0/20
    │   └── RDS Subnet
    └── AZ-2: 10.0.5.0/20
        └── RDS Subnet

VPC Endpoints (Private, no NAT costs):
├── S3 Gateway Endpoint
│   └── Routes: public/private/database subnets
├── Secrets Manager Interface Endpoint
│   └── Private DNS: secretsmanager.region.amazonaws.com
└── Security Group: Allow 443 from 10.0.0.0/16
```

### 2. Compute Layer (EC2 & ASG)

```
Auto Scaling Group: prod-foundry-asg
├── Min Size: 2
├── Max Size: 4
├── Desired: 2
├── Health Check: ELB (300s grace period)
├── Launch Template: prod-foundry-lt
│   ├── AMI: Ubuntu 22.04 LTS (latest)
│   ├── Instance Type: t3.medium (2 vCPU, 4GB RAM)
│   ├── IAM Profile: prod-foundry-instance-profile
│   ├── Security Group: prod-asg-sg
│   ├── Root Volume: 20 GB gp3
│   ├── Data Volume: 50 GB gp3 (persistent, EBS-backed)
│   ├── Monitoring: Detailed CloudWatch (1-min intervals)
│   ├── IMDSv2: Required (security hardening)
│   └── User Data: cloud-init.yaml
│       ├── Install Docker & docker-compose
│       ├── Setup EBS data volume (/opt/foundry/data)
│       ├── Pull Foundry container (felddy/foundryvtt)
│       ├── Pull Cloudflare tunnel container
│       ├── Configure environment variables
│       ├── Start containers via docker-compose
│       └── Configure CloudWatch agent
└── Scaling Policies:
    ├── Scale Up: CPU > 70% (2 consecutive periods of 5 min)
    └── Scale Down: CPU < 30% (5 consecutive periods of 5 min)
```

### 3. Database Layer (RDS)

```
RDS Instance: prod-foundry-db
├── Engine: PostgreSQL 15.3
├── Instance Class: db.t3.medium
├── Storage: 100 GB gp3
│   ├── IOPS: 3000
│   └── Throughput: 125 MB/s
├── High Availability:
│   ├── Multi-AZ: Enabled
│   ├── Primary: AZ-1 (10.0.4.0/20)
│   ├── Standby: AZ-2 (10.0.5.0/20)
│   └── Failover Time: <1 minute
├── Backup:
│   ├── Retention: 30 days
│   ├── Window: 03:00-04:00 UTC
│   └── Copy to Snapshot: Yes
├── Maintenance:
│   ├── Window: Mon 04:00-05:00 UTC
│   └── Multi-AZ: Applied to standby first
├── Monitoring:
│   ├── Enhanced Monitoring: 60s interval
│   ├── Performance Insights: 7-day retention
│   ├── Log Export: PostgreSQL (to CloudWatch)
│   └── Metrics: CPU, Memory, Disk, Connections
├── Security:
│   ├── Encryption: At-rest (AES-256)
│   ├── Network: Private subnet only
│   ├── Security Group: Allow 5432 from EC2 only
│   └── IAM Auth: Optional (can enable later)
└── Parameter Group:
    ├── max_connections: 200
    ├── shared_buffers: DBInstanceClassMemory/32768
    ├── effective_cache_size: DBInstanceClassMemory/4096
    └── Foundry-optimized tuning
```

### 4. Storage Layer (S3)

```
S3 Buckets:
├── prod-foundry-data-123456789
│   ├── Purpose: Foundry world data, journals, actors
│   ├── Versioning: Enabled (30-day rollback)
│   ├── Encryption: AES-256 (AWS managed)
│   ├── Lifecycle:
│   │   ├── Days 0-30: STANDARD ($0.023/GB)
│   │   ├── Days 30-90: STANDARD_IA ($0.0125/GB)
│   │   ├── Days 90-180: GLACIER ($0.004/GB)
│   │   └── Days 180+: Deleted
│   ├── Logging: prod-foundry-logs-123456789
│   ├── Block Public: All public access blocked
│   └── Bucket Policy: Deny unencrypted uploads/transport
├── prod-foundry-assets-123456789
│   ├── Purpose: Module assets, maps, sounds
│   ├── Versioning: Enabled
│   ├── Encryption: AES-256
│   ├── CloudFront: Origin Access Control (OAC)
│   └── Bucket Policy: Allow CloudFront only
└── prod-foundry-logs-123456789
    ├── Purpose: ALB & S3 access logs
    ├── Encryption: AES-256
    ├── Lifecycle: Expire after 365 days
    └── Block Public: All public access blocked
```

### 5. Load Balancing Layer (ALB)

```
Application Load Balancer: prod-foundry-alb
├── Type: Application (Layer 7)
├── Scheme: Internet-facing
├── Subnets: Public subnets (AZ-1, AZ-2)
├── Security Group: prod-alb-sg
│   ├── Inbound:
│   │   ├── 80/tcp (HTTP) ← 0.0.0.0/0
│   │   └── 443/tcp (HTTPS) ← 0.0.0.0/0
│   └── Outbound: All traffic
├── HTTP Listener (80)
│   └── Action: Redirect to 443
├── HTTPS Listener (443)
│   ├── Certificate: ACM (auto-created)
│   ├── SSL Policy: ELBSecurityPolicy-TLS-1-2-2017-01
│   └── Default Action: Forward to Target Group
├── Target Group: prod-foundry-tg
│   ├── Protocol: HTTP
│   ├── Port: 30000 (Foundry native)
│   ├── Health Check:
│   │   ├── Path: /api/health
│   │   ├── Interval: 30s
│   │   ├── Healthy Threshold: 2
│   │   ├── Unhealthy Threshold: 3
│   │   └── Timeout: 5s
│   ├── Deregistration Delay: 30s
│   └── Stickiness: Disabled (stateless)
└── Monitoring:
    ├── Request Count
    ├── Target Response Time
    ├── HTTP 2xx/4xx/5xx Counts
    ├── Unhealthy Host Count
    └── Alarms: Threshold-based alerts
```

### 6. CDN Layer (CloudFront)

```
CloudFront Distribution: prod-foundry
├── Enabled: Yes
├── HTTP Version: HTTP/2 and HTTP/3
├── Origins:
│   ├── S3 (Assets)
│   │   ├── Domain: prod-foundry-assets-123456789.s3.region.amazonaws.com
│   │   ├── Origin Access Control (OAC): Enabled
│   │   └── Signing: SigV4
│   └── ALB (Application)
│       ├── Domain: prod-foundry-alb-123456789.elb.region.amazonaws.com
│       ├── Protocol: HTTPS-only
│       └── TLS v1.2+
├── Cache Behaviors:
│   ├── Default: ALB (no cache, forward all)
│   ├── /assets/*: S3 (1-year cache)
│   ├── /maps/*: S3 (1-year cache)
│   └── /: ALB (no cache)
├── Security:
│   ├── HTTPS Only: Yes
│   ├── Redirect HTTP → HTTPS: Yes
│   ├── Compression: Enabled (gzip)
│   ├── Security Headers (CloudFront Function):
│   │   ├── HSTS: max-age=63072000
│   │   ├── X-Content-Type-Options: nosniff
│   │   ├── X-Frame-Options: SAMEORIGIN
│   │   ├── X-XSS-Protection: 1; mode=block
│   │   └── Referrer-Policy: strict-origin-when-cross-origin
│   └── Custom Headers: Sent to all requests
└── Monitoring:
    ├── Cache Hit Rate
    ├── Origin Latency
    ├── 4xx/5xx Error Rates
    └── CloudWatch Metrics
```

### 7. DNS & Certificate Layer (Route53)

```
Route53 Hosted Zone: example.com
├── Zone ID: Z1234567890ABC
├── Record: vtt.example.com
│   ├── Type: A (Alias)
│   ├── Target: ALB DNS name
│   ├── Evaluate Target Health: Yes
│   └── TTL: N/A (Alias)
├── Health Check: HTTPS to /api/health
│   ├── Interval: 30s
│   ├── Failure Threshold: 3
│   └── CloudWatch Alarm: Triggers on failure
└── ACM Certificate: vtt.example.com
    ├── Type: Public
    ├── Validation: DNS (auto via Route53)
    ├── Renewal: Automatic (90 days)
    └── Attached to: ALB, CloudFront
```

### 8. Monitoring & Logging Layer

```
CloudWatch:
├── Log Groups:
│   ├── /foundry/prod/application (app logs)
│   ├── /foundry/prod/docker (container logs)
│   ├── /rds/prod/postgresql (database logs)
│   └── /aws/vpc/flowlogs/prod (network traffic)
├── Dashboards:
│   ├── Main Dashboard: ALB, EC2, RDS, Application metrics
│   └── Custom Views: Cost, performance, errors
├── Metric Filters:
│   ├── ERROR logs → Error metric
│   └── Exception patterns
├── Alarms (Auto-created):
│   ├── ALB Alarms:
│   │   ├── Unhealthy Hosts
│   │   ├── High Response Time
│   │   ├── High 4xx Count
│   │   └── High 5xx Count
│   ├── EC2 Alarms:
│   │   ├── High CPU (scale up trigger)
│   │   ├── Low CPU (scale down trigger)
│   │   ├── High Disk Usage
│   │   └── High Memory Usage
│   ├── RDS Alarms:
│   │   ├── High CPU
│   │   ├── Low Free Memory
│   │   ├── Low Disk Space
│   │   └── High Connection Count
│   └── Application Alarms:
│       ├── High Error Count
│       └── Failed Health Checks
└── VPC Flow Logs:
    ├── Traffic Type: ALL
    ├── Destination: CloudWatch Logs
    ├── Retention: 30 days
    └── Format: Standard VPC format
```

### 9. Security Groups

```
sg-alb (Application Load Balancer):
├── Ingress:
│   ├── 80/tcp from 0.0.0.0/0 (HTTP)
│   └── 443/tcp from 0.0.0.0/0 (HTTPS)
└── Egress: All traffic

sg-asg (EC2 Instances):
├── Ingress:
│   ├── 30000/tcp from sg-alb (Foundry)
│   ├── 22/tcp from admin_ssh_cidr (SSH, optional)
│   └── All from sg-asg (inter-instance communication)
└── Egress: All traffic

sg-rds (RDS Database):
├── Ingress:
│   └── 5432/tcp from sg-asg (PostgreSQL)
└── Egress: All traffic

sg-vpc-endpoints (VPC Endpoints):
├── Ingress:
│   └── 443/tcp from 10.0.0.0/16 (VPC CIDR)
└── Egress: All traffic
```

### 10. IAM Permissions Model

```
Role: prod-foundry-ec2-role
├── AssumeRoleTrust:
│   └── Principal: ec2.amazonaws.com
├── Inline Policies:
│   ├── S3 Access (Foundry & Assets buckets)
│   │   ├── ListBucket, GetObject, PutObject, DeleteObject
│   │   └── Resources: s3://prod-foundry-data-*, s3://prod-foundry-assets-*
│   ├── CloudWatch Logs
│   │   ├── CreateLogGroup, CreateLogStream, PutLogEvents
│   │   └── Resources: /foundry/prod/*
│   └── Secrets Manager
│       ├── GetSecretValue, DescribeSecret
│       └── Resources: prod/foundry/database*
└── Managed Policies:
    ├── AmazonSSMManagedInstanceCore (Systems Manager)
    └── CloudWatchAgentServerPolicy (CloudWatch agent)

Instance Profile: prod-foundry-instance-profile
└── Role: prod-foundry-ec2-role
```

## Traffic Flow

### New User Request

```
1. Browser makes request to vtt.example.com:443
   ↓
2. Route53 resolves to ALB IP
   ↓
3. CloudFront intercepts (optional, can bypass)
   ↓
4. ALB terminates TLS (certificate validation)
   ↓
5. ALB routes to healthy EC2 instance (30000/tcp)
   ↓
6. Foundry application serves response
   ↓
7. Static assets cached by CloudFront
   ↓
8. WebSocket connection established (sticky session optional)
```

### WebSocket Connection

```
Browser → CloudFront → ALB → EC2 (Foundry)
  (HTTP/2)    (HTTP/3)  (HTTP)   (WebSocket)
  ↓                      ↓         ↓
  └─────────────────────────────────┘
        Real-time game data
```

### Database Query

```
EC2 (Foundry) → VPC Endpoint (Secrets Manager) → Retrieve DB password
                                                    ↓
EC2 (Foundry) → RDS (PostgreSQL) [same VPC]
  (Private)       (Private Subnet, Multi-AZ)
  ↓               ↓
  Query executed  Replicated to standby (synchronous)
  ↓               ↓
  Result cached   Backup logs written
```

### S3 Sync

```
EC2 (Foundry) → VPC Endpoint (S3) → S3 Bucket
  (Private)      (no NAT cost)       (encrypted)
  ↓                                   ↓
  Upload world data                   Versioned
  ↓                                   ↓
  CloudFront invalidation         Lifecycle rules
                                      ↓
                                 Archive after 30/90d
```

## Cost Breakdown

| Component | Hours/Month | Unit Price | Total |
|-----------|------------|-----------|-------|
| EC2 t3.medium | 720 | $0.0416/hr | $30/instance |
| RDS db.t3.medium | 720 | $0.0556/hr | $40 |
| ALB | 720 | $0.0225/hr | $16 + data |
| Data Transfer | - | $0.02/GB | $5-20 |
| S3 (100GB) | - | $0.023/GB | $2.30 |
| CloudFront | - | $0.085/GB | ~$5 |
| NAT Gateway | - | $0.045/hr | $32 |
| VPC Endpoints | 2 | $7.20/mo | $14.40 |
| CloudWatch | - | Varies | $2 |
| Route53 | - | $0.50/zone | $0.50 |
| **Total (2 instances)** | - | - | **~$150-200** |

