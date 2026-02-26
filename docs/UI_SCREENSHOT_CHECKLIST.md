# Armadillo UI Visual Tour Checklist

**Purpose:** Ensure the README visual tour stays current with every major UI release.

## When to Update Screenshots

Update the visual tour when any of the following change:

- [ ] New page/feature added (new screenshot section required)
- [ ] Major layout changes (overview cards, navigation, tables)
- [ ] New UI components (badges, filters, modals, search)
- [ ] Color scheme or branding updates
- [ ] Mobile/responsive layout improvements
- [ ] Phase completion (e.g., Phase 7 → Phase 8)

## Screenshot Update Process

1. **Ensure app is running locally:**
   ```bash
   make up
   ```

2. **Run screenshot script:**
   ```bash
   node scripts/take-screenshots.js
   ```

3. **Verify screenshots captured:**
   - Check `docs/assets/screenshots/` for all 7 images
   - Open each PNG to ensure it shows the expected UI
   - Confirm no broken/missing data in views

4. **Move to docs folder:**
   ```bash
   mv screenshots/*.png docs/assets/screenshots/
   rmdir screenshots
   ```

5. **Update README if needed:**
   - Add new section for new pages
   - Update feature descriptions if functionality changed
   - Update the "Last updated" date in the maintenance note

6. **Commit and push:**
   ```bash
   git add docs/assets/screenshots/ README.md
   git commit -m "docs: Update visual tour screenshots for [PHASE/FEATURE]"
   git push origin main
   ```

## Screenshot Standards

| Standard | Requirement |
|----------|-------------|
| **Resolution** | 1440×900 minimum (desktop) |
| **Full page** | Capture entire scrollable area |
| **Data quality** | Use demo dataset (480 assets, 720 vulns) for consistency |
| **Clean state** | No error states, no loading spinners visible |
| **File naming** | `01-overview.png`, `02-vulnerabilities.png`, etc. |
| **Location** | `docs/assets/screenshots/` |

## Current Screenshot Inventory

| # | Page | File | Key Features Shown |
|---|------|------|-------------------|
| 1 | Overview | `01-overview.png` | Status counters, scan history, quick actions |
| 2 | Vulnerabilities | `02-vulnerabilities.png` | Exploitability tabs, blast radius, remediation |
| 3 | Assets | `03-assets.png` | Change badges, risk heatmap, search |
| 4 | Network | `04-network.png` | Topology graph, attack paths |
| 5 | Imports | `05-imports.png` | Quality pipeline, XML upload |
| 6 | Schedules | `06-schedules.png` | Cron management, conflict detection |
| 7 | Reports | `07-reports.png` | PDF exports, delivery tracking |

## Future Additions (Planned)

As new features ship, add to this list:

- [ ] **Agents page** — When Phase 9 host agents launch
- [ ] **Compliance dashboard** — CIS benchmarks, pass/fail trends
- [ ] **Attack path visualization** — Network graph with lateral movement
- [ ] **Global search modal** — Cmd+K search overlay
- [ ] **Mobile view** — Responsive layout on phone/tablet

## Automation Options

Consider adding to CI/CD:
- Playwright screenshot job on every PR that touches `apps/web/`
- Auto-compare screenshots (visual diff) to catch unintended changes
- Notify if README screenshots are >30 days old

---

**Owner:** Leo / Comans Dev Team  
**Last Updated:** 2026-02-27  
**Next Review:** When Phase 7 Sprint 3 ships (runbooks, evidence collection)
