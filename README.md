# Bell

This project sets up a VoIP infrastructure on Google Cloud Platform using Terraform.

## Prerequisites

- Google Cloud Platform account
- Terraform installed
- `gcloud` CLI configured

## Quick Setup

1. **Set up credentials**:
   ```bash
   cd iac
   make secrets
   ```

2. **Deploy infrastructure**:
   ```bash
   cd iac
   make apply
   ```

## Infrastructure Components

- **Network**: VPC with firewall rules for SIP, RTP, SSH, and web traffic
- **Storage**: Cloud Storage buckets for voice recordings and other data
- **Database**: PostgreSQL instance on Cloud SQL
- **VoIP Services**:
  - FreeSWITCH VM for call processing
  - Kamailio VM for SIP routing/proxying

## Connecting to VMs

```bash
# Connect to FreeSWITCH VM
make freeswitch

# Connect to Kamailio VM
make kamailio
```

## Terraform Modules

- **blob**: Creates storage buckets for VoIP data
- **sql**: Sets up PostgreSQL database for call routing and user data
- **services**: Provisions VMs for FreeSWITCH and Kamailio with appropriate firewall rules
