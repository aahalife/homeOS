---
name: education
version: small-model
description: Track homework, grades, and study plans for ONE student at a time. Use when parent mentions homework, assignments, grades, studying, or a specific child's schoolwork.
risk: low
---

# Education Skill (Small-Model)

Track individual student homework, monitor grades, create study plans.

**SCOPE: One student, one task at a time.**
**NOT THIS SKILL:** Multi-child overviews, weekly summaries, automated monitoring → use `school` skill.

## TRIGGERS

IF message contains: homework, assignment, grades, test, exam, study, quiz, tutor, GPA
AND refers to ONE child or a specific subject
THEN activate this skill.

IF message asks about "all kids" or "school overview" or "weekly report"
THEN → OUTPUT_HANDOFF: school

## STORAGE

- Student data: ~/clawd/homeos/data/education/students.json
- Grade history: ~/clawd/homeos/data/education/grades.json
- Active reminders: ~/clawd/homeos/data/education/reminders.json
- Study plans: ~/clawd/homeos/data/education/plans.json
- Weekly logs: ~/clawd/homeos/memory/education-log.json

## STEP 1: IDENTIFY STUDENT

```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null | jq '.members[] | select(.role == "child")'
```

IF one child exists → use that child automatically.
IF multiple children exist AND user didn't specify → ask:
"Which child? [list names]"

IF no children in family.json → ask:
"I don't have any students set up yet. What's your child's name and grade level?"

## STEP 2: ROUTE BY INTENT

IF intent = "check homework" → TEMPLATE: HOMEWORK_CHECK
IF intent = "check grades" → TEMPLATE: GRADE_CHECK
IF intent = "create study plan" → TEMPLATE: STUDY_PLAN
IF intent = "missing assignment" → TEMPLATE: MISSING_ASSIGNMENT
IF intent = "set reminder" → TEMPLATE: REMINDER
IF intent = "mark done" → update status in students.json, confirm with "✅ Marked [assignment] as done for [child]."

## TEMPLATE: HOMEWORK_CHECK

```
📚 [Child Name] - Homework Check - [Date]

🚨 OVERDUE:
- [Assignment] ([Subject]) - was due [Date]

⏰ DUE TODAY:
- [Assignment] ([Subject]) - [Time]
  Status: [not started / in progress / done]

📅 DUE THIS WEEK:
- [Assignment] ([Subject]) - due [Day]
  Est. time: [X min]

💡 Priority: [Most urgent item and why]
```

IF no assignments found → "✅ [Child] is all caught up! Nothing due right now."

DEFAULT values when data is incomplete:
- Status: "not started"
- Est. time: "30 min"
- Priority: earliest due date first

## TEMPLATE: GRADE_CHECK

```
📊 [Child Name] - Grades

[Subject]: [Percent]% [Letter] [↑↓→]
[Subject]: [Percent]% [Letter] [↑↓→]
[Subject]: [Percent]% [Letter] [↑↓→]

⚠️ NEEDS ATTENTION:
- [Subject] dropped [X]% this [week/month]
- [Missing work details if any]

💡 SUGGESTION: [One specific action]
```

RISK LEVELS for grades:
- Below 70% → 🚨 URGENT: "This needs immediate attention."
- Below 80% → ⚠️ WARNING: "Worth monitoring."
- Dropped 5+ points → 📉 ALERT: "Noticeable drop."
- Improved 5+ points → 🎉 CELEBRATE: "Great improvement!"

## TEMPLATE: STUDY_PLAN

Ask if not provided:
1. "What subject?"
2. "Any test or deadline coming up? When?"
3. "How much time per day? (default: 45 min)"

```
📚 Study Plan: [Child] - [Subject]

Goal: [Raise grade / prepare for test / catch up]
Duration: [X days]
Daily time: [X min]

DAY 1 ([Date]):
- [Activity] ([X min])
- [Activity] ([X min])

DAY 2 ([Date]):
- [Activity] ([X min])
- [Activity] ([X min])

[Continue for each day]

📌 Tips:
- 25 min work, 5 min break (Pomodoro)
- Practice problems > re-reading
- Review before bed helps retention

⏰ Reminder set: daily at [Time]
```

DEFAULT study plan values:
- Duration: 7 days
- Daily time: 45 min
- Time of day: 4:00 PM
- Method: alternate review + practice

Save plan:
```bash
cat > ~/clawd/homeos/data/education/plans/[child]-[subject]-[date].json << 'EOF'
{"child":"NAME","subject":"SUBJ","start":"DATE","days":7,"daily_min":45,"goal":"GOAL"}
EOF
```

## TEMPLATE: MISSING_ASSIGNMENT

```
🚨 Missing Assignment: [Child]

📝 [Assignment Title]
📚 [Subject] - [Teacher if known]
📅 Was due: [Date] ([X days ago])
📊 Impact: ~[X]% grade effect

Options:
1. Draft email to teacher asking about late policy
2. Create plan to finish it today
3. Add to priority list

What would you like to do?
```

IF user picks "draft email":
```
📧 Draft to [Teacher]:

Subject: Late [Assignment] - [Child's Name]

Dear [Teacher],

I'm writing about the [Assignment] that was due [Date]. [Child] is working to complete it.

Could you let us know if late submission is accepted and if there's a deadline?

Thank you,
[Parent Name]

---
Want me to adjust this?
```

## TEMPLATE: REMINDER

```
⏰ Reminder Set

[Assignment] - [Subject]
Due: [Date/Time]
Reminder: [Day before at 4 PM] and [due date at 8 AM]
```

Save:
```bash
cat >> ~/clawd/homeos/data/education/reminders.json << 'EOF'
{"child":"NAME","assignment":"TITLE","due":"DATE","reminders":["DAY_BEFORE_16:00","DUE_DAY_08:00"]}
EOF
```

## OUTPUT_HANDOFF

TO school skill:
- WHEN: user asks about multiple children, weekly summaries, or automated monitoring
- PASS: {"handoff":"school","reason":"multi-child or overview request","student_context":"CHILD_ID"}

TO psy-rich skill:
- WHEN: child is stressed/burned out from studying
- PASS: {"handoff":"psy-rich","reason":"student burnout","member":"CHILD_NAME","need":"low-stress enrichment"}

FROM school skill:
- WHEN: school skill needs individual assignment details
- EXPECT: {"child":"NAME","request":"homework_check|grade_check|study_plan"}

## ERROR HANDLING

IF no data available → "I don't have [Child]'s school data yet. Would you like to add assignments manually or connect a school system?"
IF LMS token expired → "The connection to [Child]'s school system needs refreshing. Can you re-authorize?"
IF unclear child → "Which child are you asking about?"
IF unclear subject → "Which subject?"
