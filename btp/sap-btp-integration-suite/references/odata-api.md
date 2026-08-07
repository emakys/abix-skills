# Integration Content OData API — Programmatic Reference

**Authored by**: ABIX (not synced from upstream `secondsky/sap-skills`)
**Scope**: SAP Cloud Integration public OData v2 API (`/api/v1`) — Cloud Foundry environment
**Documentation**: [https://help.sap.com/docs/integration-suite/sap-integration-suite/integration-content](https://help.sap.com/docs/integration-suite/sap-integration-suite/integration-content)

Use this when you need to **read or change tenant content programmatically** — CI/CD, drift detection, monitoring, or automated deployment. The rest of `references/` documents the Web UI; this documents the API behind it.

---

## Table of Contents

1. [Authentication](#authentication)
2. [Design-Time Entities](#design-time-entities)
3. [Runtime Entities](#runtime-entities)
4. [Message Monitoring](#message-monitoring)
5. [Stores and Queues](#stores-and-queues)
6. [Security Material](#security-material)
7. [Deployment Sequence](#deployment-sequence)
8. [Practical Notes](#practical-notes)

---

## Authentication

OAuth 2.0 **client credentials**, from a service key of the **Process Integration Runtime** instance (plan `integration-flow`).

```bash
curl -X POST "$TOKEN_URL" \
  -u "$CLIENT_ID:$CLIENT_SECRET" \
  -d 'grant_type=client_credentials'
# → { "access_token": "...", "expires_in": 3600 }
```

Every subsequent call carries `Authorization: Bearer <token>`. Tokens last about an hour — cache and renew slightly before expiry rather than requesting one per call.

### Required Roles

| Area | Role |
|------|------|
| Read design-time content | `WorkspacePackagesRead`, `WorkspaceArtifactsRead` |
| Deploy / modify content | `WorkspacePackagesEdit`, `WorkspaceArtifactsDeploy` |
| Message monitoring (MPL) | `MonitoringDataRead` |

A service key limited to the `integration-flow` plan covers design-time and deploy. **Monitoring needs `MonitoringDataRead` explicitly** — its absence is a common cause of `403` on `MessageProcessingLogs` while everything else works.

### Response Format

Append `$format=json` or send `Accept: application/json`. Responses are OData v2, so payloads are wrapped:

```json
{ "d": { "results": [ { ... } ] } }
```

Single entities come back as `{ "d": { ... } }` without `results`. Dates arrive as `/Date(1735689600000)/` (epoch milliseconds).

---

## Design-Time Entities

### IntegrationPackages

```http
GET /api/v1/IntegrationPackages?$format=json&$top=50
```

Fields: `Id`, `Name`, `Description`, `Version`, `Mode` (`EDITABLE` / `READ_ONLY`), `SupportedPlatform`, `Vendor`.

### IntegrationDesigntimeArtifacts

```http
GET /api/v1/IntegrationPackages('<PackageId>')/IntegrationDesigntimeArtifacts?$format=json
GET /api/v1/IntegrationDesigntimeArtifacts(Id='<ArtifactId>',Version='active')?$format=json
```

Fields: `Id`, `Name`, `Version`, `PackageId`, `Description`, `Sender`, `Receiver`, `ArtifactContent`.

`Version='active'` addresses the current draft. A numeric version (`'1.0.3'`) addresses a saved version.

**Download the artifact as a ZIP** — this is how you read what is actually in the tenant:

```http
GET /api/v1/IntegrationDesigntimeArtifacts(Id='<ArtifactId>',Version='active')/$value
```

The response is the binary package with the standard layout (`.project`, `META-INF/MANIFEST.MF`, `metainfo.prop`, `src/main/resources/...`) described in `iflow-package-authoring.md`. Comparing its `.iflw` against version control is the reliable way to detect that someone edited the flow in the Web UI.

**Create** (artifact does not exist yet):

```http
POST /api/v1/IntegrationDesigntimeArtifacts
Content-Type: application/json

{ "Name": "MyFlow", "Id": "MyFlow", "PackageId": "MyPackage", "ArtifactContent": "<base64 of the ZIP>" }
```

**Update** (artifact already exists — using POST here fails with a duplicate-key error):

```http
PUT /api/v1/IntegrationDesigntimeArtifacts(Id='MyFlow',Version='active')
Content-Type: application/json

{ "Name": "MyFlow", "Id": "MyFlow", "ArtifactContent": "<base64 of the ZIP>" }
```

Check existence first with a `HEAD`/`GET` on the entity and branch on `200` vs `404`.

### Other Design-Time Artifacts

| Entity | Content |
|--------|---------|
| `ValueMappingDesigntimeArtifacts` | Value mappings |
| `ScriptCollectionDesigntimeArtifacts` | Shared Groovy/JS collections |
| `MessageMappingDesigntimeArtifacts` | Standalone message mappings |
| `IntegrationDesigntimeArtifacts(...)/Resources` | Individual resources of an artifact (scripts, XSDs, mappings) |

### Configurations (Externalized Parameters)

```http
GET /api/v1/IntegrationDesigntimeArtifacts(Id='<ArtifactId>',Version='active')/Configurations?$format=json
```

Fields: `ParameterKey`, `ParameterValue`, `DataType`. These are the values that legitimately differ per tenant — hosts, directories, credential aliases. Anything hardcoded in the `.iflw` instead of externalized here will not survive promotion between tenants.

Update a single parameter:

```http
PUT /api/v1/IntegrationDesigntimeArtifacts(Id='X',Version='active')/$links/Configurations('ParamName')
```

---

## Runtime Entities

### IntegrationRuntimeArtifacts

What is actually deployed and running — distinct from design-time content:

```http
GET /api/v1/IntegrationRuntimeArtifacts?$format=json
GET /api/v1/IntegrationRuntimeArtifacts('<ArtifactId>')?$format=json
```

Fields: `Id`, `Name`, `Version`, `Type`, `DeployedBy`, `DeployedOn`, `Status`.

| Status | Meaning |
|--------|---------|
| `STARTING` | Deployment in progress |
| `STARTED` | Running |
| `ERROR` | Deployment failed |
| `STOPPED` | Deployed, not running |

Deployment is **asynchronous**: a successful deploy call returns immediately with `STARTING`. Poll this entity until the status settles.

Error detail for a failed deployment:

```http
GET /api/v1/IntegrationRuntimeArtifacts('<ArtifactId>')/ErrorInformation/$value
```

### Deploy

```http
POST /api/v1/DeployIntegrationDesigntimeArtifact?Id='<ArtifactId>'&Version='active'
```

Returns a task ID. Also available: `DeployValueMappingDesigntimeArtifact`, `DeployScriptCollectionDesigntimeArtifact`.

### Undeploy

```http
DELETE /api/v1/IntegrationRuntimeArtifacts('<ArtifactId>')
```

---

## Message Monitoring

### MessageProcessingLogs

The execution record — the closest thing to watching the flow run:

```http
GET /api/v1/MessageProcessingLogs?$format=json
    &$filter=Status eq 'FAILED' and LogStart gt datetime'2026-08-01T00:00:00'
    &$top=25&$orderby=LogStart desc
```

Fields: `MessageGuid`, `CorrelationId`, `ApplicationMessageId`, `IntegrationFlowName`, `Status`, `LogStart`, `LogEnd`, `Sender`, `Receiver`, `CustomStatus`.

Statuses: `COMPLETED`, `FAILED`, `PROCESSING`, `RETRY`, `CANCELLED`, `ESCALATED`, `DISCARDED`.

**Always filter and cap.** An unfiltered query on a busy tenant returns an enormous result set. Filter by `LogStart` window plus `Status` or `IntegrationFlowName`, and set `$top`.

### Error Detail

```http
GET /api/v1/MessageProcessingLogs('<MessageGuid>')/ErrorInformation/$value
```

Returns the full error text, including the stack trace when one exists.

### Related Navigation

| Path | Content |
|------|---------|
| `MessageProcessingLogs('<guid>')/CustomHeaderProperties` | Custom headers set by the flow |
| `MessageProcessingLogs('<guid>')/Attachments` | Payload attachments (only if attachment logging is on) |
| `MessageProcessingLogs('<guid>')/AdapterAttributes` | Adapter-specific attributes |
| `MessageProcessingLogs('<guid>')/Runs` | Individual runs, for trace-level detail |

Trace-level payloads require the flow's log level to be `Trace`, which expires after ten minutes and should never be left on in production.

---

## Stores and Queues

| Entity | Purpose |
|--------|---------|
| `DataStores` | Data stores with `NumberOfMessages`, `NumberOfOverdueMessages` |
| `DataStoreEntries` | Individual entries — filter by `DataStoreName` |
| `MessageQueues` | JMS queues and their occupancy |
| `MessageStoreEntries` | Persisted message store entries |
| `NumberRanges` | Number range objects and current values |
| `Locks` | Idempotent-process locks |

Useful for diagnosing stuck messages: a queue near capacity or a data store with overdue entries usually explains a stalled scenario.

---

## Security Material

```http
GET /api/v1/UserCredentials?$format=json
GET /api/v1/KeystoreEntries?$format=json
```

`UserCredentials` exposes `Name` (the alias), `Kind`, `User`, `Description` — **never the secret**. `KeystoreEntries` exposes `Alias`, `Type`, `ValidNotBefore`, `ValidNotAfter`.

The highest-value check available before deploying: every credential alias and private-key alias referenced by the `.iflw` must exist in the target tenant. A missing alias produces a runtime failure that is hard to read from the message log, and it is trivial to verify here in advance. The same applies to certificates that are about to expire.

---

## Deployment Sequence

```
1. Package the folder as a ZIP (archive root = package root)
2. GET  IntegrationDesigntimeArtifacts(Id='X',Version='active')  → 200 or 404
3. POST (404) or PUT (200) with ArtifactContent as base64
4. POST DeployIntegrationDesigntimeArtifact?Id='X'&Version='active'
5. Poll IntegrationRuntimeArtifacts('X').Status until STARTED or ERROR
6. On ERROR → GET .../ErrorInformation/$value
```

Verify aliases and externalized parameters (steps in [Security Material](#security-material) and [Configurations](#configurations-externalized-parameters)) **before** step 3, not after the deployment fails.

---

## Practical Notes

**The ZIP archive root matters.** Build the archive from inside the package folder so `.project`, `META-INF/`, `metainfo.prop` and `src/` sit at the root. A parent-folder wrapper makes the import fail or produces a malformed package.

**Base64 payloads are large.** Send the request body from a file (`curl -d @payload.json`) rather than inline — a base64-encoded ZIP will exceed command-line length limits.

**CSRF.** Modifying calls may require a CSRF token depending on tenant configuration: issue a `GET` with `X-CSRF-Token: Fetch`, then replay the token and cookies on the write call. Bearer-only authentication often works without it; treat a `403` on an otherwise valid write as a CSRF symptom.

**Drafts cannot be transported.** An artifact with unsaved changes will not move between tenants. Save a version first.

**Do not treat the tenant as the source of truth.** Content downloaded from a tenant reflects whatever was last edited there, including changes made directly in the Web UI. Use it to detect drift against version control — not to overwrite the repository.
