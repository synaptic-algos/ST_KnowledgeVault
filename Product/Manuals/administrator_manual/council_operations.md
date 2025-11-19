# Prioritisation Council Operations

**Last Updated**: SPRINT-20251118-epic007 (2025-11-19)
**Audience**: Council Secretary, Portfolio Manager, Operations Administrators

---

## Overview

This page documents operational procedures for administering the Prioritisation Council, including meeting management, decision logging, notification workflows, and system maintenance.

---

## Roles & Responsibilities

### Council Secretary (Primary Administrator)

**Weekly Time Commitment**: 6-8 hours

**Core Responsibilities**:
1. Meeting management (scheduling, materials distribution, minutes)
2. Decision logging (create/update decision logs for all decisions)
3. Notifications (send decision emails to researchers)
4. Action item tracking
5. Appeals process management

**See**: [Council Operations Guide](../governance/COUNCIL_OPERATIONS_GUIDE.md) for detailed workflows

---

### Portfolio Manager (Council Chair)

**Weekly Time Commitment**: 8-12 hours

**Core Responsibilities**:
1. Score all strategy submissions using the rubric
2. Lead council meetings
3. Maintain scoring model documentation
4. Provide researcher support (office hours, consultations, workshops)
5. Coordinate capital allocation for approved strategies

---

## System Architecture

### Decision Logging System

**Components**:
- **Schema**: `src/strategy_lifecycle/governance/schemas/decision_log_schema.yaml`
- **Logger Module**: `src/strategy_lifecycle/governance/decision_logger.py`
- **CLI Tool**: `src/strategy_lifecycle/governance/decision_log_cli.py`

**Storage**:
- Location: `strategies/<strategy-id>/governance/decision_log.yaml`
- Format: YAML (human-readable, version-controlled)
- Retention: 7 years (regulatory requirement)

**Key Operations**:
```bash
# Get decision log
python src/strategy_lifecycle/governance/decision_log_cli.py get STRAT-20251115-001

# Search decisions
python src/strategy_lifecycle/governance/decision_log_cli.py search --outcome approved --date-from 2025-11-01

# Generate statistics
python src/strategy_lifecycle/governance/decision_log_cli.py stats
python src/strategy_lifecycle/governance/decision_log_cli.py stats --by-researcher

# Log appeal
python src/strategy_lifecycle/governance/decision_log_cli.py appeal STRAT-20251115-001 "Scoring inconsistent with rubric"

# Update appeal decision
python src/strategy_lifecycle/governance/decision_log_cli.py update-appeal STRAT-20251115-001 dismissed "No procedural error found"
```

---

### Templates and Documents

**Governance Documents** (Read-only for researchers):
- `documentation/governance/PRIORITISATION_COUNCIL_CHARTER.md`
- `documentation/governance/SCORING_GOVERNANCE_AND_FEEDBACK_LOOP.md`
- `documentation/templates/governance/STRATEGY_SCORING_MODEL_v1.md`
- `documentation/governance/scoring_dry_run_results.md`

**Templates** (Used by Council Secretary):
- `documentation/governance/templates/COUNCIL_MEETING_AGENDA_TEMPLATE.md`
- `documentation/governance/templates/SPECIAL_REVIEW_MEETING_AGENDA_TEMPLATE.md`
- `documentation/governance/templates/COUNCIL_MEETING_MINUTES_TEMPLATE.md`
- `documentation/governance/templates/COUNCIL_EMAIL_TEMPLATES.md`

**Operations Guide**:
- `documentation/governance/COUNCIL_OPERATIONS_GUIDE.md` (Complete operational procedures)

---

## Weekly Operational Checklist

### Monday (Meeting Week - 2 days before Wednesday meeting)

**Council Secretary**:
- [ ] Prepare meeting agenda from template
- [ ] Identify strategies for council review (6.0-6.9 scores)
- [ ] Collect pre-meeting materials:
  - [ ] Strategy submission packages
  - [ ] Scoring summaries from Portfolio Manager
  - [ ] Previous meeting minutes
  - [ ] Live strategy performance reports
- [ ] Distribute meeting invitation with materials (48 hours before meeting)
- [ ] Confirm attendance from all 4 voting members
- [ ] Check for conflicts of interest

**Portfolio Manager**:
- [ ] Complete scoring for all strategies in council review range
- [ ] Prepare scoring summaries and key discussion points
- [ ] Flag any strategies for special review (5.0-5.9)
- [ ] Prepare live strategy performance data

---

### Wednesday (Meeting Day)

**Before Meeting**:
- [ ] Set up meeting room or Zoom
- [ ] Prepare attendance sheet
- [ ] Bring copies of agenda and materials
- [ ] Test recording equipment (if applicable)

**During Meeting** (10:00-11:30 AM):
- [ ] Record attendance and recusals
- [ ] Take detailed notes on all discussions
- [ ] Record vote tallies for each decision
- [ ] Capture action items with owners and due dates
- [ ] Note follow-up items or concerns

**See**: [Council Meeting Agenda Template](../governance/templates/COUNCIL_MEETING_AGENDA_TEMPLATE.md)

---

### Thursday (Meeting + 1 day) - CRITICAL 24-HOUR WINDOW

**Council Secretary** (Priority Tasks):

1. **Finalize Meeting Minutes** (2-3 hours):
   ```bash
   # Use template
   cp documentation/governance/templates/COUNCIL_MEETING_MINUTES_TEMPLATE.md \
      documentation/governance/meetings/2025-11-20_council_minutes.md

   # Edit with meeting details
   vim documentation/governance/meetings/2025-11-20_council_minutes.md

   # Distribute to council for review
   mail -s "Council Minutes 2025-11-20" prioritisation-council@synaptic.com < minutes.md
   ```

2. **Update Decision Logs** (1-2 hours):
   ```python
   from src.strategy_lifecycle.governance.decision_logger import DecisionLogger
   from datetime import date

   logger = DecisionLogger(strategies_dir="strategies")

   # For each strategy decided in meeting
   decision_id = logger.log_decision(
       strategy_id="STRAT-20251115-001",
       strategy_name="Mean Reversion NSE Options",
       researcher="john.doe@synaptic.com",
       submission_date=date(2025, 11, 15),
       final_score=6.75,
       score_breakdown={ ... },  # Complete scores
       decision_type="council_approve",
       decision_outcome="approved",
       council_review={
           "meeting_date": date(2025, 11, 20),
           "meeting_type": "regular",
           "attendees": [ ... ],
           "quorum_met": True,
           "vote_tally": {"yes": 3, "no": 0},
           "rationale": "Council approved based on strong alpha potential...",
           "meeting_minutes_ref": "documentation/governance/meetings/2025-11-20_council_minutes.md",
       },
       capital_allocation={
           "amount_usd": 40000,
           "portfolio_percentage": 8.0,
           "allocation_tier": "medium",
           "deployment_timeline": "Within 2 weeks",
       },
   )
   ```

3. **Send Notification Emails** (1-2 hours):
   ```bash
   # Use email templates
   # For approved strategy:
   cat documentation/governance/templates/COUNCIL_EMAIL_TEMPLATES.md
   # Copy "Strategy Approved - Council Review" template
   # Customize with strategy details
   # Send to researcher

   # Update decision log to track notification sent
   python src/strategy_lifecycle/governance/decision_log_cli.py update \
       STRAT-20251115-001 \
       notifications.decision_email_sent \
       true

   python src/strategy_lifecycle/governance/decision_log_cli.py update \
       STRAT-20251115-001 \
       notifications.email_sent_timestamp \
       "2025-11-20T14:30:00Z"
   ```

4. **Schedule Special Reviews** (if applicable):
   - Identify researchers for special review (5.0-5.9 scores)
   - Schedule meetings within 1 week
   - Send special review invitations
   - Distribute materials 3 days before

---

### Friday (Meeting + 2 days)

**Council Secretary**:
- [ ] Follow up on action items (remind owners)
- [ ] Update action items tracker
- [ ] Archive meeting materials
- [ ] Prepare for next meeting (2 weeks out)

**Portfolio Manager**:
- [ ] Office hours for researchers (Fridays 2-4 PM)
- [ ] Consultations with rejected strategy submitters
- [ ] Review decision log statistics (monthly)

---

## Special Review Procedures

**Trigger**: Strategy scores 5.0-5.9

**Timeline**: Within 1 week of scoring

### Setup (Day 1)

**Council Secretary**:
1. Schedule 60-minute special review meeting within 1 week
2. Send invitation to all 4 council members (ALL required)
3. Invite researcher to present
4. Distribute materials 3 days before:
   - Full strategy submission package
   - Complete scoring breakdown
   - PM's detailed assessment
   - Researcher's responses to preliminary feedback (if any)

**Agenda**: Use [Special Review Meeting Template](../governance/templates/SPECIAL_REVIEW_MEETING_AGENDA_TEMPLATE.md)

### Meeting Day

**Before Meeting**:
- [ ] Verify ALL 4 voting members can attend (reschedule if not)
- [ ] Confirm researcher presentation is ready
- [ ] Set up meeting room/Zoom

**Meeting Structure** (60 min total):
1. PM scoring summary (10 min)
2. Researcher presentation (15 min)
3. Council Q&A (15 min)
4. Council deliberation, researcher excused (25 min)
5. Unanimous vote + decision communication (5 min)

**Recording**:
- Take detailed notes on researcher presentation
- Record council questions and researcher responses
- Document conditional approval terms discussed (if applicable)
- Record unanimous vote (4 YES required for approval)

### Post-Meeting (24 hours)

**Council Secretary**:
1. Update decision log with conditional approval terms or rejection
2. Send notification email:
   - **If approved conditionally**: Include all probationary terms, exit/scaling criteria, review schedule
   - **If rejected**: Include detailed feedback, improvement suggestions, resubmission timeline
3. Schedule probationary reviews (if conditional approval)

---

## Appeals Management

### Appeal Submission (Researcher Initiates)

**Timeline**: Within 2 weeks of decision

**Researcher Action**: Email prioritisation-council@synaptic.com with appeal

**Council Secretary Action** (Within 24 hours):
1. Acknowledge appeal receipt:
   ```bash
   python src/strategy_lifecycle/governance/decision_log_cli.py appeal \
       STRAT-20251115-001 \
       "Researcher claims scoring inconsistent with rubric for risk profile dimension"
   ```
2. Send acknowledgment email (use template: "Appeal Acknowledgment")
3. Forward to Portfolio Manager for review

---

### Appeal Review (Portfolio Manager)

**Timeline**: 1 week

**PM Actions**:
1. Review appeal grounds
2. Check for:
   - Procedural errors in scoring
   - Overlooked critical information
   - New evidence
3. Decision:
   - **Dismiss**: No valid grounds
   - **Re-score**: New information warrants re-evaluation
   - **Council Hearing**: Present to full council

4. Update appeal decision:
   ```bash
   python src/strategy_lifecycle/governance/decision_log_cli.py update-appeal \
       STRAT-20251115-001 \
       dismissed \
       "Scoring was consistent with rubric. No procedural error found. Researcher's claim that max drawdown was incorrectly calculated is not supported by evidence."
   ```

**Council Secretary Action**:
- Send appeal decision email (use appropriate template)

---

### Appeal Hearing (If Granted)

**Timeline**: Within 2 weeks of appeal decision

**Council Secretary**:
1. Schedule 30-minute council hearing
2. Invite researcher to present
3. Distribute appeal materials
4. Use regular meeting procedures

**Post-Hearing**:
- Update decision log with final appeal outcome
- Send final decision email (FINAL, no further appeals)

---

## Monthly Maintenance Tasks

### First Week of Month

**Council Secretary**:
- [ ] Generate monthly statistics report:
  ```bash
  python src/strategy_lifecycle/governance/decision_log_cli.py stats > monthly_stats_$(date +%Y%m).txt
  python src/strategy_lifecycle/governance/decision_log_cli.py stats --by-researcher > monthly_researcher_stats_$(date +%Y%m).txt
  ```
- [ ] Review SLA compliance:
  - Auto-approve/reject: 3 days
  - Council review: 2 weeks
  - Special review: 1 week
  - Appeal review: 2 weeks
- [ ] Escalate any SLA breaches to Portfolio Manager
- [ ] Update action items tracker (close completed, escalate overdue)

**Portfolio Manager**:
- [ ] Host monthly scoring workshop (First Tuesday, 3-4 PM)
- [ ] Review scoring model feedback from researchers
- [ ] Identify potential model improvements
- [ ] Review live strategy performance vs. projections

---

### Quarterly Tasks

**Council (All Members)**:
- [ ] Quarterly model review meeting (Last Friday of quarter)
  - Performance analysis (approved vs. rejected strategies)
  - Feedback summary
  - Model adjustments discussion
  - Approve minor changes or table major changes

**Council Secretary**:
- [ ] Prepare quarterly report:
  - Total decisions made
  - Approval/rejection rates
  - Average decision time
  - Appeal statistics
  - SLA compliance
  - By-researcher statistics
- [ ] Archive quarterly meeting materials
- [ ] Update council charter if amendments approved

**Portfolio Manager**:
- [ ] Publish quarterly performance report
- [ ] Update scoring model documentation (if changes approved)
- [ ] Communicate changes to research team

---

## Audit and Compliance

### Decision Log Audit

**Frequency**: Quarterly (Internal), Annual (External)

**Audit Checklist**:
- [ ] All decisions have complete decision logs (no missing entries)
- [ ] Decision logs match meeting minutes
- [ ] Email notifications sent and tracked
- [ ] SLA compliance verified
- [ ] Appeal process followed correctly
- [ ] Documentation completeness (scoring breakdowns, rationales)

**Tools**:
```bash
# Check for missing decision logs
find strategies -name "intake.yaml" -print0 | while read -d $'\0' file; do
    dir=$(dirname "$file")
    if [ ! -f "$dir/governance/decision_log.yaml" ]; then
        echo "Missing decision log: $dir"
    fi
done

# Verify decision log completeness
python scripts/audit_decision_logs.py --check-completeness --check-sla
```

---

### Backup and Archival

**Daily Backups**:
- All decision logs backed up to cloud storage
- Meeting minutes backed up
- Governance documents versioned in Git

**Retention**:
- Decision logs: 7 years (regulatory requirement)
- Meeting minutes: 7 years
- Email notifications: 3 years

**Archival Process** (Quarterly):
```bash
# Archive decision logs to offline storage
tar -czf decision_logs_$(date +%Y_Q%q).tar.gz strategies/*/governance/decision_log.yaml

# Archive meeting minutes
tar -czf meeting_minutes_$(date +%Y_Q%q).tar.gz documentation/governance/meetings/*.md

# Verify archive integrity
tar -tzf decision_logs_$(date +%Y_Q%q).tar.gz | wc -l
```

---

## Troubleshooting

### Issue: Decision Log Not Created

**Symptoms**: Researcher reports no decision received, `decision_log_cli get` returns "not found"

**Diagnosis**:
```bash
# Check if strategy exists
ls strategies/STRAT-20251115-001/

# Check if scoring is complete
cat strategies/STRAT-20251115-001/intake.yaml | grep score

# Check if decision log exists
ls strategies/STRAT-20251115-001/governance/decision_log.yaml
```

**Resolution**:
1. If scoring incomplete: Wait for PM to complete scoring
2. If scoring complete but no decision log: Manually create using `decision_logger.py`
3. If decision log exists but query fails: Check file permissions, YAML syntax

---

### Issue: Email Notification Not Sent

**Symptoms**: Decision log exists, but researcher didn't receive email

**Diagnosis**:
```bash
# Check notification tracking
python src/strategy_lifecycle/governance/decision_log_cli.py get STRAT-20251115-001 | grep "decision_email_sent"
```

**Resolution**:
1. If `decision_email_sent: false`: Email not sent, resend using template
2. If `decision_email_sent: true` but researcher claims not received: Check spam folder, verify email address
3. Update decision log after resending:
   ```bash
   python src/strategy_lifecycle/governance/decision_log_cli.py update STRAT-20251115-001 notifications.decision_email_sent true
   ```

---

### Issue: Meeting Quorum Not Met

**Symptoms**: Council meeting scheduled, but only 2 of 4 members can attend

**For Regular Meeting**:
- **Quorum**: 3 of 4 members
- **Action**: Proceed if 3 present, reschedule if only 2

**For Special Review**:
- **Quorum**: ALL 4 members (no exceptions)
- **Action**: Immediately reschedule, notify researcher of delay

---

### Issue: SLA Breach

**Symptoms**: Decision not made within SLA (3 days for auto, 2 weeks for council, 1 week for special)

**Escalation**:
1. Council Secretary notifies Portfolio Manager
2. PM investigates cause (backlog, resource constraints, etc.)
3. Researcher notified of delay with new expected timeline
4. Chronic breaches escalated to executive leadership

**Prevention**:
- Monitor decision queue daily
- Flag strategies approaching SLA deadline
- Prioritize overdue decisions

---

## System Integration (Future)

### Workflow Engine Integration

**Planned Features**:
- Automatic decision log creation when scoring completes
- Automated email notifications based on decision type
- SLA tracking and alerts
- Calendar integration for meeting scheduling

**Integration Points**:
- `workflow_engine.py` calls `DecisionLogger.log_decision()` on state transitions
- Notification system triggers emails based on decision logs
- Dashboard displays decision log statistics

---

## Emergency Procedures

### Emergency Meeting

**Trigger**: Urgent strategy approval needed, live strategy risk event, regulatory inquiry

**Timeline**: 24 hours notice (if possible)

**Quorum**: 3 of 4 voting members

**Procedure**:
1. Portfolio Manager declares emergency
2. Council Secretary schedules emergency meeting within 24 hours
3. Abbreviated agenda (focus on urgent item only)
4. Decision logged and communicated immediately

---

### Council Member Absence

**Permanent Member (PM, Risk, Compliance)**:
- Temporary substitution by designated alternate (same qualifications)
- Alternate has full voting rights during absence

**Rotating Researcher**:
- If unable to complete quarterly term, replacement nominated
- Outgoing member briefs replacement

---

## Resources

**Documents**:
- [Council Charter](../governance/PRIORITISATION_COUNCIL_CHARTER.md)
- [Council Operations Guide](../governance/COUNCIL_OPERATIONS_GUIDE.md)
- [Scoring Model](../templates/governance/STRATEGY_SCORING_MODEL_v1.md)
- [Governance & Feedback Loop](../governance/SCORING_GOVERNANCE_AND_FEEDBACK_LOOP.md)

**Templates**:
- [Meeting Agenda](../governance/templates/COUNCIL_MEETING_AGENDA_TEMPLATE.md)
- [Special Review Agenda](../governance/templates/SPECIAL_REVIEW_MEETING_AGENDA_TEMPLATE.md)
- [Meeting Minutes](../governance/templates/COUNCIL_MEETING_MINUTES_TEMPLATE.md)
- [Email Templates](../governance/templates/COUNCIL_EMAIL_TEMPLATES.md)

**Tools**:
- Decision Logger: `src/strategy_lifecycle/governance/decision_logger.py`
- Decision Log CLI: `src/strategy_lifecycle/governance/decision_log_cli.py`

**Contacts**:
- Portfolio Manager: portfolio-manager@synaptic.com
- Council Secretary: council-secretary@synaptic.com
- Prioritisation Council: prioritisation-council@synaptic.com

---

**Document Status**: Administrator Manual Section
**Sprint**: SPRINT-20251118-epic007 (STORY-007-02-02)
**Last Updated**: 2025-11-19
