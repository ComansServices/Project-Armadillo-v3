# 🛡️ Project Armadillo v3 — Agent-Readable Specification Document

Modern, Queue-Driven Network Discovery & Security Visibility Platform

63 User Stories (per-section) | 58 Unique Story IDs | 11 INFRA Items | 69 Total Deliverables | 26 Sections

> Scope note for ACP agents: This spec lists 63 user stories across Sections 8–16. Five stories are cross-listed in both a Phase section and a Theme section. Unique deliverable items = 69 (11 INFRA + 58 US). See BUILD_PLAN.md for the authoritative reconciliation.

|Field |Value |
|------------------|---------------------------------------------------|
|**Version** |3.3 — Full Spec + Architecture + Security Hardening|
|**Date** |28 February 2026 |
|**Author** |Jason Coman, CEO |
|**Company** |Comans Services Pty Ltd |
|**ABN** |46 615 007 862 |
|**Classification**|CONFIDENTIAL |

-----
## Table of Contents
1. Executive Summary
1. System Architecture
1. Current State — What Exists Today
1. Phase Completion Status
1. API Reference
1. Data Model
1. Future Roadmap
Core Phase Stories
1. User Stories — Sprint 7.3 (Operator Usability) — 10 stories
1. User Stories — Phase 8 (MSP Integration & Scale) — 10 stories
1. User Stories — Phase 9 (Host Telemetry & Endpoints) — 7 stories
Feature Theme Stories
1. Theme: Intelligence Enrichment — 5 stories
1. Theme: Client-Facing & Revenue — 5 stories
1. Theme: Compliance & Frameworks — 5 stories
1. Theme: AI & Automation — 5 stories
1. Theme: Integrations & Ecosystem — 5 stories
1. Theme: Operational Excellence — 6 stories
Architecture & Data Systems
1. User Story Summary Matrix
1. Complete Prisma Data Model
1. External Data Sources & APIs
1. Infrastructure Architecture
1. BullMQ Job Definitions & Caching Strategy
1. New packages/ Modules Required
Requirements & Appendices
1. Non-Functional Requirements
1. Acceptance Criteria & Definition of Done
1. Technical Constraints & Decisions
1. Appendix: Glossary

-----
-----
## 1. Executive Summary
Project Armadillo v3 is a modern, queue-driven network discovery and security visibility platform built by Comans Services. It bridges the gap between enterprise-grade SIEMs (which cost $50K–$500K/year and require dedicated teams) and fragmented open-source scanners (which require manual stitching and tribal knowledge).

Armadillo is designed specifically for small-to-mid MSPs with 10–50 employees who need to offer security-as-a-service to their clients without hiring a dedicated security team. It provides exploitability-first vulnerability prioritisation, attack path simulation, remediation workflow tracking, automated reporting, and multi-tenant project scoping.

The platform is self-hosted via Docker (5-minute deploy), free at the core with support tiers, and designed to reduce manual report assembly from 4 hours to 10 minutes while enabling junior staff to run security operations without constant senior oversight.

This specification contains 63 user stories across 9 sections, covering the immediate sprint backlog, three major roadmap phases, and six cross-cutting feature themes that position Armadillo as a competitive, market-ready MSP security platform. The document includes a complete Prisma data model with 20+ entities, PostgreSQL Row-Level Security for multi-tenant isolation, formal RBAC with User and ProjectMembership models, encrypted scan credential vault, and mandatory Zod validation across all API boundaries.

### 1.1 Target Users
- MSP owners who want to offer security-as-a-service without building a SOC
- IT managers proving security posture to auditors and boards
- Security analysts tired of spreadsheet-driven vulnerability management
- Compliance officers needing evidence of continuous monitoring

### 1.2 Core Value Propositions
- Exploitability-first prioritisation: Fix 20% of vulns that prevent