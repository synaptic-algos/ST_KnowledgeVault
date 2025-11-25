---
artifact_type: story
created_at: '2025-11-25T16:23:21.786899Z'
id: AUTO-strategy_governance
manual_update: true
owner: Auto-assigned
related_epic: TBD
related_feature: TBD
related_story: TBD
requirement_coverage: TBD
seq: 1
status: pending
title: Auto-generated title for strategy_governance
updated_at: '2025-11-25T16:23:21.786902Z'
---

## Submission to Decision Process

### 1. Submit Your Strategy

Use the strategy intake workflow to submit your research:

```bash
python src/strategy_lifecycle/intake/intake_cli.py submit
```

**Required Information**:
- Strategy name and description
- Asset class and instruments
- Expected returns and risk metrics (Sharpe, max drawdown)
- Backtesting results and validation
- Capital requirements
- Research documentation

**Timeline**: You can submit anytime (no submission deadlines).

---

### 2. Compliance Gate Check

**What Happens**: Compliance Officer reviews your submission for regulatory compliance and data licensing.

**Timeline**: 48 hours (2 business days)

**Possible Outcomes**:
- ✅ **PASS** → Your strategy moves to scoring
- ❌ **FAIL** → You receive feedback on compliance issues and can resubmit after addressing them

**Common Reasons for Failure**:
- Unlicensed data sources
- Regulatory non-compliance (SEBI, RBI rules)
- Incomplete governance approvals
- Missing required documentation

---

### 3. Scoring

**What Happens**: Portfolio Manager scores your strategy across 6 dimensions using a standardized rubric.

**Timeline**: 3 business days (for auto-approve/reject), up to 2 weeks (for council review)

**Scoring Dimensions** (weighted):
1. **Alpha Potential** (25%): Expected returns, Sharpe ratio, strategic fit
2. **Confidence & Quality** (20%): Research rigor, validation, data quality
3. **Risk Profile** (20%): Max drawdown, volatility, leverage, tail risk
4. **Capital Efficiency** (15%): Return per dollar, capacity, transaction costs
5. **Liquidity & Execution** (10%): Asset liquidity, execution complexity
6. **Diversification Benefit** (10%): Correlation with existing strategies, uniqueness

**Total Score**: 0.0 to 10.0 (weighted average)

**Scoring Model**: See [Scoring Model Documentation](../templates/governance/STRATEGY_SCORING_MODEL_v1.md) for complete rubric and examples.

---

### 4. Decision

Your decision depends on your final score:

| Score Range | Decision | Timeline | What Happens |
|-------------|----------|----------|--------------|
| **9.0-10.0** | ✅ Auto-Approve (Immediate Priority) | 3 days | You get approval email with capital allocation ($75k-100k, 15-20% of portfolio). Strategy moves to implementation immediately. |
| **7.0-8.9** | ✅ Auto-Approve (High Priority) | 3 days | Approval email with capital allocation ($50k-75k, 10-15% of portfolio). Standard deployment timeline. |
| **6.0-6.9** | 🟡 Council Review | 2 weeks | Council discusses your strategy in their bi-weekly meeting and votes. Majority approval required. If approved, you get $25k-50k (5-10% of portfolio). |
| **5.0-5.9** | 🟡 Special Review (Marginal) | 1 week | You present your strategy to the full council (15 min presentation + Q&A). Unanimous approval required for conditional approval with probationary terms. |
| **< 5.0** | ❌ Auto-Reject | 3 days | Rejection email with detailed feedback on how to improve. You can resubmit after addressing issues (minimum 2-4 weeks). |

---

## Understanding Your Decision

### If Approved ✅

**What You Receive**:
- Approval email with score breakdown
- Capital allocation amount and percentage
- Deployment timeline (typically within 2 weeks)
- Next steps for implementation

**Performance Reviews**:
- **1 month**: Initial performance review
- **3 months**: Comprehensive review vs. projections
- **6 months**: Rescoring (if significant deviation)

**Expectations**:
- Your strategy should perform close to projections
- Proactive communication if performance deviates
- Monthly performance reports required

---

### If Approved Conditionally (5.0-5.9) ⚠️

**Probationary Terms**:
- **Reduced Capital**: $10k-25k (2-5% of portfolio) during probation
- **Probationary Period**: Typically 3 months
- **Enhanced Monitoring**: Weekly/monthly performance reviews
- **Exit Criteria**: Defined performance thresholds (e.g., "If Sharpe < 1.0 for 2 months, strategy exits")
- **Scaling Criteria**: If you meet performance goals, capital scales to standard allocation

**What You Need to Do**:
- Accept probationary conditions (reply to approval email)
- Meet enhanced reporting requirements
- Demonstrate value during probationary period
- Escalate immediately if performance issues arise

---

### If Rejected ❌

**What You Receive**:
- Rejection email with complete score breakdown
- Specific dimensions that scored poorly
- Concrete improvement suggestions for each concern
- Timeline for resubmission (minimum 2-4 weeks)

**Example Rejection Feedback**:
```
Primary Issues:
1. Confidence & Quality (3.0/10) - Insufficient validation
   Action: Extend backtest to 5+ years, add walk-forward analysis
2. Capital Efficiency (4.0/10) - High transaction costs
   Target: Reduce costs from 3.5% to <2.0% annually
```

**What You Should Do**:
1. Review detailed feedback carefully
2. Prioritize improvements (Priority 1 items first)
3. Schedule consultation with Portfolio Manager (office hours: Fridays 2-4 PM)
4. Improve your strategy based on feedback
5. Resubmit when ready (minimum 2-4 weeks)

---

## How to Improve Your Score

### Before Submitting

**1. Review the Scoring Model**:
- Read [Scoring Model v1.0](../templates/governance/STRATEGY_SCORING_MODEL_v1.md)
- Review [Dry-Run Examples](../governance/scoring_dry_run_results.md) to see what gets approved/rejected
- Understand what council looks for in each dimension

**2. Attend Workshops**:
- **Monthly Scoring Workshop**: First Tuesday, 3-4 PM
  - Learn how to improve scores
  - Ask questions about rubric
  - See example scorings
- **Office Hours**: Portfolio Manager, Fridays 2-4 PM
  - One-on-one consultations
  - Pre-submission reviews (optional)

**3. Strengthen Weak Areas**:

**Alpha Potential**:
- Aim for Sharpe ratio ≥ 1.5
- Target expected returns ≥ 15% annually
- Demonstrate strategic fit with portfolio

**Confidence & Quality**:
- Extend backtest to 5+ years (minimum)
- Include out-of-sample testing (minimum 1 year)
- Run walk-forward analysis
- Use high-quality, licensed data
- Document methodology rigorously

**Risk Profile**:
- Keep max drawdown ≤ 15% (ideal) or ≤ 20% (acceptable)
- Minimize leverage (ideally no leverage, max 2x)
- Run stress tests and tail risk analysis

**Capital Efficiency**:
- Reduce transaction costs (aim for <2% annually)
- Demonstrate scalability (capacity for growth)
- Optimize turnover

**Liquidity & Execution**:
- Focus on liquid instruments
- Ensure simple execution (avoid complex orders)
- Demonstrate ability to enter/exit quickly

**Diversification**:
- Show low correlation with existing strategies (<0.4 ideal)
- Identify unique alpha source
- Explain how your strategy differs from existing ones

---

## Council Review Process (6.0-6.9 Scores)

If your strategy scores 6.0-6.9, it goes to council review:

**What Happens**:
1. Portfolio Manager presents your strategy to the council (15-20 min discussion)
2. Council members (PM, Risk Officer, Compliance Officer, Senior Researcher) discuss:
   - Strengths and weaknesses
   - Concerns and risks
   - Strategic value
3. Council votes (majority approval: 2 of 3 or 3 of 4)
4. You receive email with decision + rationale

**Timeline**: Next bi-weekly council meeting (up to 2 weeks)

**You Are Not Present**: Council deliberates without you, but you can provide additional context via email to Portfolio Manager before the meeting.

**Decision Rationale**: You'll receive 2-3 paragraphs explaining why the council approved or rejected, and any conditions or expectations.

---

## Special Review Process (5.0-5.9 Scores)

If your strategy scores 5.0-5.9 (marginal range), you get a chance to present:

**What Happens**:
1. You're invited to a special meeting (60 min total)
2. Portfolio Manager presents scoring summary (10 min)
3. **You present** (15 min):
   - Strategy overview (3 min)
   - Addressing key concerns from scoring (8 min)
   - Why your strategy deserves approval (3 min)
4. Council Q&A with you (15 min)
5. You're excused, council deliberates (25 min)
6. Council votes (**unanimous** approval required: all 4 members must vote YES)
7. You're invited back for decision communication

**Timeline**: Within 1 week of scoring

**Preparation Tips**:
- Focus presentation on addressing scoring concerns (not general overview)
- Use data and evidence to support claims
- Be honest about weaknesses and explain mitigation
- Be prepared to discuss conditional approval (probationary terms)

**Possible Outcomes**:
- ✅ **Approved Unconditionally** (rare): Standard capital allocation
- ✅ **Approved Conditionally**: Probationary terms with reduced capital, exit/scaling criteria
- ❌ **Rejected**: Not unanimous approval, detailed feedback provided

---

## Appeals Process

You can appeal a decision within **2 weeks** if:
- Scoring was inconsistent with the rubric
- Critical information was overlooked
- New evidence has emerged since submission

**Invalid Appeal Reasons**:
- ❌ "I disagree with the weights" (weights are fixed)
- ❌ "My backtest shows better returns" (if already considered)
- ❌ "This is unfair" (without specific rubric violations)

**How to Appeal**:
1. Email prioritisation-council@synaptic.com within 2 weeks
2. Subject: "Appeal: STRAT-[ID]"
3. Include:
   - Original score breakdown
   - Specific rubric items you believe were scored incorrectly
   - New evidence or information
   - Requested outcome

**Appeal Review** (1-2 weeks):
- Portfolio Manager reviews your appeal
- Possible outcomes:
  - **Dismiss**: No grounds for appeal (email explanation)
  - **Re-score**: New information warrants re-evaluation
  - **Council Hearing**: Present to full council (30 min hearing, **final decision**)

**Important**: Council hearing decisions are **FINAL** with no further appeals.

---

## Performance Tracking (After Approval)

### 1-Month Review

**What's Reviewed**:
- Actual vs. projected returns
- Actual vs. projected Sharpe ratio
- Actual vs. projected max drawdown
- Number of trades executed vs. expected

**Outcome**: Feedback on performance, early warning of issues

---

### 3-Month Comprehensive Review

**What's Reviewed**:
- Full performance analysis vs. projections
- Trend analysis (improving/stable/declining)
- Variance explanation (why actual differs from projected)

**Possible Decisions**:
- **Increase Allocation**: Outperforming, scale up capital
- **Continue As Is**: Performing as expected
- **Reduce Allocation**: Underperforming, reduce capital or enhance monitoring
- **Exit Strategy**: Significantly underperforming or breach of exit criteria

**If Probationary**: GO/NO-GO decision (graduate from probation or exit)

---

### 6-Month Rescoring (If Needed)

If performance deviates significantly from projections, strategy may be rescored.

---

## Key Contacts & Resources

**Portfolio Manager** (Scoring Model Owner):
- Email: portfolio-manager@synaptic.com
- Office Hours: Fridays 2-4 PM
- Use for: Consultations, scoring questions, pre-submission reviews

**Prioritisation Council**:
- Email: prioritisation-council@synaptic.com
- Use for: Appeals, general council inquiries

**Council Secretary**:
- Email: council-secretary@synaptic.com
- Use for: Meeting schedules, administrative questions

**Workshops**:
- **Monthly Scoring Workshop**: First Tuesday, 3-4 PM
- **Research Onboarding**: Contact Portfolio Manager to schedule

**Documentation**:
- [Complete Scoring Model](../templates/governance/STRATEGY_SCORING_MODEL_v1.md)
- [Scoring Criteria](../../DESIGN-007-02-StrategyScoringCriteria.md)
- [Dry-Run Examples](../governance/scoring_dry_run_results.md)
- [Governance & Feedback Loop](../governance/SCORING_GOVERNANCE_AND_FEEDBACK_LOOP.md)

---

## Tips for Success

✅ **Do**:
- Review scoring model before submitting
- Attend monthly workshops to learn best practices
- Provide complete, high-quality data in your submission
- Accept feedback constructively
- Use office hours for pre-submission consultations
- Resubmit after addressing rejection feedback

❌ **Don't**:
- Submit incomplete or rushed strategies
- Ignore dimensions with low scores
- Appeal without valid grounds (wastes time)
- Over-promise in backtests (be conservative and realistic)
- Skip validation steps (out-of-sample, walk-forward)

---

**Good luck with your strategy submissions!** The council is committed to supporting high-quality research and providing transparent, constructive feedback.

---

**Document Status**: User Manual Section
**Sprint**: SPRINT-20251118-epic007 (STORY-007-02-02)
**Last Updated**: 2025-11-19
