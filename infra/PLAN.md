# Portfolio Deployment Plan

## Goal
Deploy a static Vite portfolio to AWS with CI/CD and IaC. Keep it simple, but do it properly so the pattern scales to future projects as subdomains.

---

## Architecture

```
GitHub (push to main)
        │
        ▼
GitHub Actions (build Vite → upload to S3 → invalidate CloudFront cache)
        │
        ▼
┌──────────────────────────────────────────────────┐
│  AWS                                             │
│                                                  │
│  Route53 (DNS)                                   │
│    ├── yourdomain.com      → CloudFront dist A   │
│    ├── projecta.yourdomain.com → CloudFront B    │
│    └── projectb.yourdomain.com → CloudFront C    │
│                                                  │
│  ACM (SSL cert — one wildcard cert covers all)   │
│    └── *.yourdomain.com + yourdomain.com         │
│                                                  │
│  CloudFront (CDN)                                │
│    └── serves from S3 with HTTPS + caching       │
│                                                  │
│  S3 (storage)                                    │
│    ├── yourdomain.com bucket                     │
│    ├── projecta.yourdomain.com bucket            │
│    └── projectb.yourdomain.com bucket            │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## What Gets Built (in order)

### Step 0: Prerequisites (manual, one-time)
- [ ] Buy a domain (Route53, Namecheap, wherever — can be transferred to Route53 later)
- [ ] Create an AWS account
- [ ] Install AWS CLI + Terraform locally
- [ ] Create an IAM user for Terraform with appropriate permissions
- [ ] Create an S3 bucket + DynamoDB table for Terraform state (the one bootstrap step)

### Step 1: Terraform — Core Infrastructure
All defined in `infra/`:
- [ ] **S3 bucket** — holds the built site files (private, not publicly accessible)
- [ ] **CloudFront distribution** — CDN in front of S3, handles HTTPS
- [ ] **Route53 hosted zone** — DNS records
- [ ] **ACM certificate** — wildcard SSL cert (`*.yourdomain.com` + `yourdomain.com`)
- [ ] **Origin Access Control** — lets CloudFront read from the private S3 bucket

### Step 2: GitHub Actions — CI/CD Pipeline
Defined in `.github/workflows/deploy.yml`:
- [ ] On push to `main`: build → sync to S3 → invalidate CloudFront
- [ ] AWS credentials stored as GitHub repo secrets
- [ ] That's it. No staging, no approval gates. Keep it simple.

### Step 3: Verify
- [ ] Push a change, watch it deploy
- [ ] Confirm HTTPS works
- [ ] Confirm cache invalidation works (changes show up within ~30s)

---

## Terraform File Layout

```
infra/
├── main.tf          # Provider config, S3 bucket, CloudFront
├── dns.tf           # Route53 zone, DNS records, ACM cert
├── variables.tf     # domain_name, environment, etc.
├── outputs.tf       # CloudFront URL, S3 bucket name (used by CI/CD)
├── backend.tf       # S3 backend for Terraform state
└── terraform.tfvars # Actual values (gitignored)
```

---

## Adding a Future Project as a Subdomain

When you want to deploy `projectx.yourdomain.com`:

1. New repo for the project
2. Copy the Terraform pattern (or extract a reusable module later)
3. Change `variables.tf` to point to `projectx.yourdomain.com`
4. `terraform apply` → creates S3 bucket + CloudFront + DNS record
5. Add GitHub Actions workflow (same pattern)
6. Push to main → deployed

The wildcard SSL cert already covers it. No cert changes needed.

---

## Cost Estimate

| Resource | Monthly Cost |
|---|---|
| Route53 hosted zone | $0.50 |
| S3 storage | ~$0.01 (a few MB) |
| CloudFront | ~$0.00-0.50 (depends on traffic) |
| ACM certificate | Free |
| **Total** | **~$0.50-1.00/mo** + domain registration (~$10/yr) |

---

## What This Doesn't Include (intentionally)

- **No staging environment** — overkill for a portfolio
- **No Docker/containers** — not needed for static sites
- **No monitoring/alerting** — add later if you want (CloudWatch is free tier)
- **No WAF** — add later if you get bot traffic
- **No Terraform modules** — keep it flat and readable for now, extract modules when you have 3+ projects

---

## Decisions Made

| Decision | Choice | Why |
|---|---|---|
| IaC tool | Terraform | Industry standard, cloud-agnostic, huge community |
| CI/CD | GitHub Actions | Code already on GitHub, free for public repos |
| State backend | S3 + DynamoDB | Standard Terraform pattern for AWS |
| CDN | CloudFront | Native AWS integration, free tier |
| SSL | ACM wildcard | One cert covers all subdomains forever |
| S3 access | Private + OAC | Best practice — S3 is never publicly exposed |
