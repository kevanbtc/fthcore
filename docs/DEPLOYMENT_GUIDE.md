# 🚀 FTH Core Production Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying FTH Core to production environments. The deployment process covers smart contracts, frontend dashboard, monitoring infrastructure, and operational procedures.

## 📋 Prerequisites

### Infrastructure Requirements
- **Ethereum Node**: Geth or Parity full node (recommended: Alchemy/Infura)
- **Database**: PostgreSQL 14+ for transaction indexing
- **Cache**: Redis 6+ for real-time data caching  
- **CDN**: CloudFlare or AWS CloudFront for frontend delivery
- **Monitoring**: Prometheus + Grafana for system monitoring
- **Backup**: S3-compatible storage for data backup

### Security Requirements
- **Hardware Security Module (HSM)**: For key management
- **Multi-Signature Wallet**: Gnosis Safe for contract administration
- **SSL Certificates**: Let's Encrypt or commercial certificates
- **WAF**: Web Application Firewall (CloudFlare/AWS)
- **DDoS Protection**: Layer 3/4 and Layer 7 protection

## 🏗️ Architecture Overview

```mermaid
graph TB
    subgraph "Frontend Layer"
        FE[React Dashboard]
        CDN[CloudFlare CDN]
        WAF[Web Application Firewall]
    end
    
    subgraph "Application Layer"
        API[Node.js API Server]
        WS[WebSocket Server]
        WORKER[Background Workers]
    end
    
    subgraph "Blockchain Layer"
        ETH[Ethereum Mainnet]
        BSC[BSC Mainnet]
        POLY[Polygon Mainnet]
    end
    
    subgraph "Data Layer"
        PG[PostgreSQL]
        REDIS[Redis Cache]
        IPFS[IPFS Storage]
    end
    
    subgraph "External Services"
        CHAINLINK[Chainlink Oracles]
        CUSTODY[Vault Custody APIs]
        COMPLIANCE[AML/KYC APIs]
    end
    
    FE --> CDN --> WAF --> API
    API --> PG
    API --> REDIS
    API --> ETH
    API --> BSC
    API --> POLY
    WS --> REDIS
    WORKER --> CHAINLINK
    WORKER --> CUSTODY
    WORKER --> COMPLIANCE
```

## 🌐 Environment Setup

### Production Environment Variables

```bash
# Network Configuration
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
BSC_RPC_URL=https://bsc-dataseed.binance.org
POLYGON_RPC_URL=https://polygon-rpc.com

# Contract Addresses (Mainnet)
FTHCORE_CONTRACT=0x...
STAKING_CONTRACT=0x...
GOVERNANCE_CONTRACT=0x...
ORACLE_CONTRACT=0x...
MULTISIG_CONTRACT=0x...

# Database Configuration
DATABASE_URL=postgresql://user:pass@localhost:5432/fthcore_prod
REDIS_URL=redis://localhost:6379/0

# Security Configuration
JWT_SECRET=your-super-secure-jwt-secret
ENCRYPTION_KEY=your-256-bit-encryption-key
PRIVATE_KEY_ENCRYPTED=your-encrypted-private-key

# Third-Party APIs
CHAINLINK_API_KEY=your-chainlink-api-key
CUSTODY_API_KEY=your-custody-api-key
COMPLIANCE_API_KEY=your-aml-kyc-api-key

# Monitoring
SENTRY_DSN=https://your-sentry-dsn
GRAFANA_API_KEY=your-grafana-api-key

# CDN and Storage
CLOUDFLARE_API_TOKEN=your-cloudflare-token
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
S3_BUCKET=fthcore-backups
```

## 📦 Smart Contract Deployment

### 1. Deploy Core Contracts

```bash
# Clone repository
git clone https://github.com/kevanbtc/fthcore.git
cd fthcore

# Install dependencies
forge install

# Compile contracts
forge build

# Deploy to mainnet (requires private key in .env)
forge script script/DeployEcosystem.s.sol \
    --rpc-url $ETHEREUM_RPC_URL \
    --broadcast \
    --verify \
    --slow

# Deploy to BSC
forge script script/DeployEcosystem.s.sol \
    --rpc-url $BSC_RPC_URL \
    --broadcast \
    --verify \
    --slow

# Deploy to Polygon
forge script script/DeployEcosystem.s.sol \
    --rpc-url $POLYGON_RPC_URL \
    --broadcast \
    --verify \
    --slow
```

### 2. Contract Verification

```bash
# Verify on Etherscan
forge verify-contract \
    --chain-id 1 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor()") \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    0xYOUR_CONTRACT_ADDRESS \
    src/FTHCore.sol:FTHCore

# Verify on BSCScan
forge verify-contract \
    --chain-id 56 \
    --num-of-optimizations 200 \
    --watch \
    --verifier-url https://api.bscscan.com/api \
    --etherscan-api-key $BSCSCAN_API_KEY \
    0xYOUR_CONTRACT_ADDRESS \
    src/FTHCore.sol:FTHCore
```

### 3. Multi-Sig Setup

```bash
# Create Gnosis Safe multi-sig wallet
# Navigate to: https://gnosis-safe.io/

# Configuration:
# - 3-of-5 signatures for normal operations
# - 2-of-3 signatures for emergency operations
# - Signers: CEO, CTO, CFO, External Auditor, Emergency Contact

# Transfer contract ownership to multi-sig
cast send $FTHCORE_CONTRACT \
    "transferOwnership(address)" \
    $MULTISIG_ADDRESS \
    --rpc-url $ETHEREUM_RPC_URL \
    --private-key $PRIVATE_KEY
```

## 🌍 Frontend Deployment

### 1. Build Production Frontend

```bash
cd frontend

# Install dependencies
npm install

# Build for production
npm run build

# Optimize images
npm run optimize-images

# Generate service worker
npm run generate-sw
```

### 2. Deploy to CDN

#### Option A: CloudFlare Pages
```bash
# Install Wrangler CLI
npm install -g wrangler

# Authenticate
wrangler auth

# Deploy
wrangler pages publish dist/ --project-name fthcore-dashboard
```

#### Option B: AWS S3 + CloudFront
```bash
# Install AWS CLI
pip install awscli

# Configure AWS credentials
aws configure

# Create S3 bucket
aws s3 mb s3://fthcore-dashboard-prod

# Enable static website hosting
aws s3 website s3://fthcore-dashboard-prod \
    --index-document index.html \
    --error-document error.html

# Upload files
aws s3 sync dist/ s3://fthcore-dashboard-prod/ \
    --delete \
    --cache-control "max-age=31536000"

# Create CloudFront distribution
aws cloudfront create-distribution \
    --distribution-config file://cloudfront-config.json
```

#### Option C: Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

### 3. Configure Domain and SSL

```bash
# CloudFlare DNS Configuration
# A record: app.fthcore.com -> CloudFlare IP
# CNAME record: www.app.fthcore.com -> app.fthcore.com

# SSL Certificate (automatic with CloudFlare)
# Enable "Always Use HTTPS"
# Enable "HSTS"
# Set Security Level to "Medium"
```

## 🗄️ Database Setup

### 1. PostgreSQL Installation and Configuration

```sql
-- Create database
CREATE DATABASE fthcore_prod;

-- Create user
CREATE USER fthcore_user WITH PASSWORD 'secure_password';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE fthcore_prod TO fthcore_user;

-- Connect to database
\c fthcore_prod;

-- Create tables
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    tx_hash VARCHAR(66) UNIQUE NOT NULL,
    block_number BIGINT NOT NULL,
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42) NOT NULL,
    value DECIMAL(78,0) NOT NULL,
    gas_used BIGINT NOT NULL,
    gas_price DECIMAL(78,0) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    status INTEGER NOT NULL,
    contract_address VARCHAR(42),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE reserves (
    id SERIAL PRIMARY KEY,
    gold_grams DECIMAL(20,8) NOT NULL,
    total_supply DECIMAL(20,8) NOT NULL,
    backing_ratio DECIMAL(10,4) NOT NULL,
    oracle_price DECIMAL(20,8) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE user_stakes (
    id SERIAL PRIMARY KEY,
    user_address VARCHAR(42) NOT NULL,
    amount DECIMAL(20,8) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    rewards_claimed DECIMAL(20,8) DEFAULT 0,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_transactions_hash ON transactions(tx_hash);
CREATE INDEX idx_transactions_address ON transactions(from_address, to_address);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp);
CREATE INDEX idx_reserves_timestamp ON reserves(timestamp);
CREATE INDEX idx_user_stakes_address ON user_stakes(user_address);
```

### 2. Redis Configuration

```bash
# Install Redis
sudo apt-get install redis-server

# Configure Redis
sudo nano /etc/redis/redis.conf

# Key configurations:
# maxmemory 2gb
# maxmemory-policy allkeys-lru
# save 900 1
# save 300 10
# save 60 10000

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

## 📊 Monitoring Setup

### 1. Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'fthcore-api'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'
    scrape_interval: 10s

  - job_name: 'fthcore-contracts'
    static_configs:
      - targets: ['localhost:3001']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'redis'
    static_configs:
      - targets: ['localhost:9121']

  - job_name: 'postgresql'
    static_configs:
      - targets: ['localhost:9187']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

### 2. Grafana Dashboard

```json
{
  "dashboard": {
    "title": "FTH Core Production Monitoring",
    "panels": [
      {
        "title": "Total Supply",
        "type": "stat",
        "targets": [
          {
            "expr": "fthcore_total_supply",
            "refId": "A"
          }
        ]
      },
      {
        "title": "Backing Ratio",
        "type": "gauge",
        "targets": [
          {
            "expr": "fthcore_backing_ratio",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 200,
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 100},
                {"color": "green", "value": 110}
              ]
            }
          }
        }
      },
      {
        "title": "Transaction Volume (24h)",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(fthcore_transactions_total[24h])",
            "refId": "A"
          }
        ]
      }
    ]
  }
}
```

### 3. Alerting Rules

```yaml
# alerts.yml
groups:
  - name: fthcore_alerts
    rules:
      - alert: BackingRatioLow
        expr: fthcore_backing_ratio < 105
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "FTH Core backing ratio is below 105%"
          description: "Current backing ratio is {{ $value }}%"

      - alert: BackingRatioCritical
        expr: fthcore_backing_ratio < 100
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "FTH Core backing ratio is below 100%"
          description: "CRITICAL: Backing ratio is {{ $value }}%"

      - alert: OracleFailure
        expr: fthcore_oracle_health < 3
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Less than 3 oracles are functioning"
          description: "Only {{ $value }} oracles are active"

      - alert: HighTransactionFailure
        expr: rate(fthcore_failed_transactions[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High transaction failure rate"
          description: "{{ $value }} transactions failing per second"
```

## 🔒 Security Hardening

### 1. Server Security

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Install fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban

# Configure SSH
sudo nano /etc/ssh/sshd_config
# PasswordAuthentication no
# PermitRootLogin no
# AllowUsers deploy

# Restart SSH
sudo systemctl restart ssh
```

### 2. Application Security

```bash
# Environment variables security
sudo chmod 600 .env
sudo chown app:app .env

# Log rotation
sudo nano /etc/logrotate.d/fthcore
# /var/log/fthcore/*.log {
#     daily
#     missingok
#     rotate 30
#     compress
#     delaycompress
#     notifempty
# }

# Process monitoring
sudo apt install supervisor
sudo nano /etc/supervisor/conf.d/fthcore.conf
```

### 3. Database Security

```sql
-- Create read-only user for monitoring
CREATE USER monitor WITH PASSWORD 'monitor_password';
GRANT CONNECT ON DATABASE fthcore_prod TO monitor;
GRANT USAGE ON SCHEMA public TO monitor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO monitor;

-- Enable SSL
-- Edit postgresql.conf:
-- ssl = on
-- ssl_cert_file = 'server.crt'
-- ssl_key_file = 'server.key'
```

## 🚀 Deployment Process

### 1. Pre-deployment Checklist

```bash
# Health checks
curl -f http://localhost:3000/health
curl -f http://localhost:3000/metrics

# Database connectivity
psql $DATABASE_URL -c "SELECT 1;"

# Redis connectivity
redis-cli ping

# Contract verification
cast call $FTHCORE_CONTRACT "owner()" --rpc-url $ETHEREUM_RPC_URL

# SSL certificate validity
openssl s_client -connect app.fthcore.com:443 -servername app.fthcore.com
```

### 2. Deployment Script

```bash
#!/bin/bash
# deploy.sh

set -e

echo "Starting FTH Core production deployment..."

# Pull latest code
git pull origin main

# Install dependencies
npm ci --production

# Run database migrations
npm run migrate

# Build frontend
cd frontend && npm run build && cd ..

# Restart services
sudo systemctl restart fthcore-api
sudo systemctl restart fthcore-worker
sudo systemctl restart nginx

# Health check
sleep 10
curl -f http://localhost:3000/health

echo "Deployment completed successfully!"
```

### 3. Rollback Procedure

```bash
#!/bin/bash
# rollback.sh

set -e

echo "Starting rollback procedure..."

# Revert to previous git commit
git reset --hard HEAD~1

# Rebuild frontend
cd frontend && npm run build && cd ..

# Restart services
sudo systemctl restart fthcore-api
sudo systemctl restart fthcore-worker

# Verify rollback
curl -f http://localhost:3000/health

echo "Rollback completed successfully!"
```

## 📋 Operational Procedures

### 1. Daily Operations

```bash
# Morning health check
./scripts/health-check.sh

# Check backing ratio
./scripts/check-backing-ratio.sh

# Verify oracle status
./scripts/check-oracles.sh

# Database backup
./scripts/backup-database.sh
```

### 2. Weekly Maintenance

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Log cleanup
./scripts/cleanup-logs.sh

# Performance review
./scripts/performance-report.sh

# Security scan
./scripts/security-scan.sh
```

### 3. Monthly Reviews

```bash
# Full system audit
./scripts/monthly-audit.sh

# Capacity planning
./scripts/capacity-review.sh

# Disaster recovery test
./scripts/dr-test.sh

# Compliance report
./scripts/compliance-report.sh
```

## 📞 Support and Maintenance

### Emergency Contacts
- **Technical Lead**: tech@fthcore.com (+1-xxx-xxx-xxxx)
- **DevOps Team**: devops@fthcore.com (+1-xxx-xxx-xxxx)
- **Compliance Officer**: compliance@fthcore.com (+971-xxx-xxx-xxxx)

### Escalation Procedures
1. **Level 1**: Automated alerts → On-call engineer
2. **Level 2**: Critical issues → Technical lead + DevOps manager
3. **Level 3**: System-wide failure → CTO + Executive team
4. **Level 4**: Regulatory issues → CEO + Legal counsel

### Documentation Updates
This deployment guide should be reviewed and updated quarterly or after any major system changes.

---

**Document Control**
- Version: 1.0
- Last Updated: January 2024
- Next Review: April 2024
- Owner: DevOps Team
- Approver: Chief Technology Officer