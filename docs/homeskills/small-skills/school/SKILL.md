---
name: school
version: small-model
description: Orchestrate school life across ALL children. Automated daily checks, weekly summaries, multi-child coordination, parent-teacher comms. Use when parent asks about overview, all kids, monitoring setup, or weekly school planning.
risk: low
---

# School Skill (Small-Model)

Orchestrate and monitor school life across multiple children.

**SCOPE: Multi-child overview, automated monitoring, weekly planning, coordination.**
**NOT THIS SKILL:** Single child homework/grade details → use `education` skill.

## TRIGGERS

IF message contains: "both kids", "all kids", "school overview", "weekly summary", "set up monitoring", "school week", "parent-teacher", "coordination"
THEN activate this skill.

IF message is about ONE child's specific homework or grade
THEN → OUTPUT_HANDOFF: education

## STORAGE

- Monitoring config: ~/clawd/homeos/data/school/monitoring.json
- Weekly reports: ~/clawd/homeos/data/school/weekly/
- Event sync: ~/clawd/homeos/data/school/events.json
- Coordination log: ~/clawd/homeos/memory/school-coordination.json

## STEP 1: IDENTIFY ALL STUDENTS

```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null | jq '[.members[] | select(.role == "child")]'
```

IF zero children → "No students set up. Tell me your children's names and grade levels."
IF one child → still works, but note: "For single-child details, I can also use the education skill for deeper focus."

## STEP 2: ROUTE BY INTENT

IF intent = "daily check" → TEMPLATE: DAILY_CHECK
IF intent = "weekly summary" → TEMPLATE: WEEKLY_SUMMARY
IF intent = "setup monitoring" → TEMPLATE: SETUP_MONITORING
IF intent = "coordination" → TEMPLATE: COORDINATION
IF intent = "week ahead" → TEMPLATE: WEEK_AHEAD
IF intent = "parent-teacher" → TEMPLATE: PARENT_TEACHER

## TEMPLATE: DAILY_CHECK

Run at configured time (default: 4:00 PM) or on request.

```
📚 DAILY SCHOOL CHECK - [Date]

━━━ [CHILD 1 NAME] ([Grade]) ━━━

🚨 OVERDUE: [count] assignments
- [Assignment] ([Subject]) - [X days late]

⏰ DUE TODAY: [count]
- [Assignment] ([Subject])

📊 GRADE ALERTS: [any drops/issues]

━━━ [CHILD 2 NAME] ([Grade]) ━━━

🚨 OVERDUE: [count] assignments
- [Assignment] ([Subject]) - [X days late]

⏰ DUE TODAY: [count]
- [Assignment] ([Subject])

📊 GRADE ALERTS: [any drops/issues]

━━━ ACTION ITEMS ━━━
1. [Most urgent thing across all kids]
2. [Second priority]
```

IF everything is fine for a child → "✅ [Child]: All caught up, grades stable."
IF urgent items exist → put 🚨 at top.

DEFAULT: Show overdue first, then today, then this week.

## TEMPLATE: WEEKLY_SUMMARY

Send Sunday evening (default: 6:00 PM) or on request.

```
📚 WEEKLY SCHOOL REPORT - Week of [Date]

━━━ [CHILD 1 NAME] ━━━

✅ Completed: [X] of [Y] assignments
📊 Grade changes:
- [Subject]: [old]% → [new]% [↑↓→]
- [Subject]: [old]% → [new]% [↑↓→]
⏰ Study time logged: [X] hours
🎯 Next week priorities:
- [Priority 1]
- [Priority 2]

━━━ [CHILD 2 NAME] ━━━

✅ Completed: [X] of [Y] assignments
📊 Grade changes:
- [Subject]: [old]% → [new]% [↑↓→]
⏰ Study time logged: [X] hours
🎯 Next week priorities:
- [Priority 1]

━━━ PARENT ACTION ITEMS ━━━
☐ [Action 1]
☐ [Action 2]
☐ [Action 3]

🎉 WINS THIS WEEK:
- [Positive thing to celebrate]
```

Save report:
```bash
cat > ~/clawd/homeos/data/school/weekly/[date].json << 'EOF'
{"week":"DATE","children":[{"name":"NAME","completed":X,"total":Y,"grade_changes":{},"priorities":[]}]}
EOF
```

## TEMPLATE: SETUP_MONITORING

```
📚 SCHOOL MONITORING SETUP

I'll track school for [list children].

✅ Enabling:

1. 📝 Daily Homework Check
   Time: [4:00 PM] (change?)
   Notify: [parent names]

2. 📊 Weekly Grade Report
   Time: [Sunday 6:00 PM] (change?)
   Alert if grade drops below: [80%] (change?)

3. 📅 School Event Sync
   Source: [Google Classroom / manual]

4. ⏰ Smart Reminders
   Test prep: 2 days before
   Project deadlines: 3 days before

Activate all? Or pick specific ones?
```

Save config:
```bash
cat > ~/clawd/homeos/data/school/monitoring.json << 'EOF'
{
  "enabled": true,
  "daily_check": {"time": "16:00", "notify": ["parent"]},
  "weekly_report": {"day": "sunday", "time": "18:00"},
  "grade_alert_threshold": 80,
  "students": ["CHILD_IDS"],
  "reminders": {"test_prep_days": 2, "project_warn_days": 3}
}
EOF
```

## TEMPLATE: WEEK_AHEAD

Send Sunday evening or on request. Focus on upcoming week.

```
📚 WEEK AHEAD - [Date Range]

━━━ [CHILD 1] ━━━

📅 DEADLINES:
- [Day]: [Assignment] ([Subject])
- [Day]: [Assignment] ([Subject])

🗓️ TESTS:
- [Day]: [Test] ([Subject])

🎯 ACTIVITIES:
- [Day] [Time]: [Activity]

💡 PREP NEEDED: [Specific action]

━━━ [CHILD 2] ━━━

📅 DEADLINES:
- [Day]: [Assignment] ([Subject])

🗓️ TESTS:
- [Day]: [Test] ([Subject])

🎯 ACTIVITIES:
- [Day] [Time]: [Activity]

⚠️ HEADS UP: [Anything notable]

━━━ PARENT TO-DO ━━━
☐ [Task 1]
☐ [Task 2]
☐ [Task 3]
```

## TEMPLATE: COORDINATION

Use when scheduling conflicts or logistics across children.

```
⚠️ SCHEDULE CONFLICT - [Date]

[Time]:
- [Child 1]: [Activity/Location]
- [Child 2]: [Activity/Location]

Options:
1. [Specific option with who does what]
2. [Specific option with reschedule]
3. [Specific option with alternate arrangement]

Which works best?
```

## TEMPLATE: PARENT_TEACHER

```
📧 Draft to [Teacher] re: [Child]

Subject: [Child's Name] - [Topic]

Dear [Teacher],

[Body based on situation - keep to 3-4 sentences]

Could we [specific ask: schedule meeting / discuss options / get update]?

I'm available [suggest times or ask user].

Thank you,
[Parent Name]

---
Adjust before sending?
```

## OUTPUT_HANDOFF

TO education skill:
- WHEN: user drills into one child's specific homework, grades, or study plan
- PASS: {"handoff":"education","child":"NAME","request":"homework_check|grade_check|study_plan"}

TO psy-rich skill:
- WHEN: suggesting weekend family activities to balance school stress
- PASS: {"handoff":"psy-rich","reason":"family balance","members":"family","need":"stress relief after school week"}

FROM education skill:
- WHEN: education skill detects multi-child need
- EXPECT: {"handoff":"school","reason":"multi-child or overview request"}

## AUTOMATED SCHEDULES

Daily check: 4:00 PM local (configurable)
Weekly report: Sunday 6:00 PM local (configurable)
Event sync: daily at 7:00 AM
Reminders: per monitoring.json config

IF monitoring not configured AND user asks for automated features →
"I need to set up monitoring first. Want me to configure it now?"

## ERROR HANDLING

IF no children in system → "No students found. Add children to family.json first."
IF monitoring.json missing → "School monitoring isn't set up yet. Want me to configure it?"
IF no data for a child → "I don't have school data for [Child] yet. Add manually or connect their school system?"
IF schedule conflict detected → auto-trigger COORDINATION template.
