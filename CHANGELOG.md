<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Changelog

All notable changes to the Kaldor Community Manufacturing Platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-12

### Changed
- **firmware-zig**: Migrated to Zig 0.15.2 API (`root_module` + `b.createModule()`, `b.graph.host`)
- **firmware-zig**: Renamed `OtaUpdater.error` field to `last_error` (`error` is a Zig keyword)
- **firmware-zig**: `calculateQuality` signature `*Self` → `*const Self` (does not mutate)
- **firmware-zig**: Block comment `/** */` → `//` line comments (Zig has no block comments)

### Added
- **firmware-zig**: `src/all_tests.zig` — dedicated host-side test root that imports all
  submodules with tests (buffer, sensors, mqtt, ota, wifi) while skipping `main.zig`'s
  freestanding-only `extern fn` stubs
- `.gitignore`: `**/.zig-cache/` and `**/zig-out/` patterns
- `.machine_readable/6a2/`: Full content expansion for STATE, META, ECOSYSTEM, PLAYBOOK,
  NEUROSYM — all previously stub-only

### Fixed
- **firmware-zig**: All 10 host unit tests now pass on Zig 0.15.2 (previously failed to compile)
- **NEUROSYM.a2ml**: Removed stale `report-format = "logtalk"` (Logtalk removed from Hypatia 2026-04-12)



### Added
- RSR Framework compliance (targeting Platinum level)
- Tri-Perimeter Contribution Framework (TPCF)
- Deno backend with WASM acceleration
- ReScript frontend with sound type system
- Matter protocol integration for IoT devices
- RISC-V firmware support (ESP32-C6)
- SCADA/DCS interoperability (OPC UA, Modbus)
- CRDT-based offline-first architecture
- CURP consensus protocol for community governance
- Comprehensive security policy (RFC 9116)
- .well-known/ directory (security.txt, ai.txt, humans.txt)
- Code of Conduct with Emotional Safety (CCCP)
- Quadratic voting system
- Kaldor's Law 2 economic integration

### Changed
- Architecture v2.0: Deno + ReScript + WASM (from Node.js + TypeScript)
- Licensing: Palimpsest v0.8 (from MIT only)
- Governance: TPCF perimeters (from flat model)

### Security
- Implemented RFC 9116 security.txt
- Added responsible disclosure policy
- Enabled signed commits requirement
- Added dependency scanning (Dependabot)

## [2.0.0] - 2025-11-22

### Breaking Changes
- Complete rewrite from Node.js to Deno runtime
- Frontend migrated from React+TypeScript to ReScript
- Database schema redesigned for offline-first CRDTs
- API v2.0 with Matter protocol support

### Added
- **Backend**: Deno 1.40+ with Oak framework
- **Frontend**: ReScript 11+ with type-safe React bindings
- **WASM**: Rust-compiled modules for pattern generation and scheduling
- **Firmware**: ESP32-C6 RISC-V support with Matter/Thread
- **Protocols**: Matter, OPC UA, Modbus TCP/RTU
- **Database**: TimescaleDB + Automerge CRDTs
- **Governance**: CURP consensus + quadratic voting
- **Documentation**: White paper, wiki, 3D-weave specification

### Improved
- Offline-first operation (works air-gapped)
- Type safety (ReScript + Rust + Deno strict mode)
- Memory safety (zero unsafe blocks in Rust)
- Build reproducibility (Nix flake)
- Test coverage (>80% target)
- Security (OWASP Top 10 compliance)

## [1.0.0] - 2025-11-22 (Legacy)

### Added
- Initial IIoT platform implementation
- Node.js backend with Express.js
- React frontend with Material-UI
- ESP32 firmware (C++)
- TimescaleDB time-series database
- MQTT broker (Mosquitto)
- Docker Compose deployment
- Prometheus + Grafana monitoring

### Deprecated
- Node.js backend (replaced by Deno in v2.0)
- TypeScript frontend (replaced by ReScript in v2.0)
- C++ firmware (replaced by Rust in v2.0)

---

## Version History

| Version | Date | Description | RSR Level |
|---------|------|-------------|-----------|
| 2.0.0 | 2025-11-22 | Complete rewrite for community manufacturing | Platinum (target) |
| 1.0.0 | 2025-11-22 | Initial IIoT platform | Bronze |

## Upgrade Guide

### From 1.0.x to 2.0.0

**⚠️ Breaking Changes - Major Migration Required**

1. **Backend Migration**:
   ```bash
   # Remove Node.js dependencies
   rm -rf backend/api/node_modules

   # Install Deno
   curl -fsSL https://deno.land/install.sh | sh

   # Run new backend
   cd backend-deno
   deno task dev
   ```

2. **Frontend Migration**:
   ```bash
   # Install ReScript
   cd frontend-rescript
   npm install
   npm start
   ```

3. **Database Migration**:
   ```sql
   -- Run CRDT migration
   \i database/migrations/002_crdt_support.sql
   ```

4. **Firmware Migration**:
   ```bash
   # Flash new RISC-V firmware
   cd firmware-riscv
   idf.py flash monitor
   ```

**Data Migration**: Automatic migration tool included:
```bash
deno run --allow-all scripts/migrate-v1-to-v2.ts
```

## Support Policy

| Version | Status | End of Life | Security Fixes |
|---------|--------|-------------|----------------|
| 2.x | ✅ Active | TBD | Yes |
| 1.x | ❌ Deprecated | 2025-11-22 | Critical only (90 days) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for changelog guidelines.

**Changelog Entry Format**:
```markdown
### Added
- New feature description (#123)

### Changed
- Modified behavior description (#124)

### Deprecated
- Soon-to-be-removed feature (#125)

### Removed
- Deleted feature description (#126)

### Fixed
- Bug fix description (#127)

### Security
- Vulnerability fix (CVE-YYYY-XXXXX) (#128)
```

## Links

- **Repository**: https://github.com/hyperpolymath/kaldor-iiot
- **Releases**: https://github.com/hyperpolymath/kaldor-iiot/releases
- **Security Advisories**: https://github.com/hyperpolymath/kaldor-iiot/security/advisories
- **Issue Tracker**: https://github.com/hyperpolymath/kaldor-iiot/issues

---

**Maintained by**: Kaldor Community
**Format**: Keep a Changelog v1.1.0
**Versioning**: Semantic Versioning v2.0.0
