---
name: school
description: Comprehensive school management orchestration including daily homework checks, grade monitoring, study plan creation, school event syncing, and parent-teacher communication. Use when managing overall school life for children, coordinating multiple education tasks, or setting up automated school monitoring.
---

# School Workflow Skill

Orchestrate all school-related tasks for seamless education management across multiple children.

## When to Use

- User wants to set up daily homework monitoring
- User needs grade tracking with alerts
- User wants automated school event syncing
- User asks for comprehensive school management
- User has multiple children in school

## Core Workflows

| Workflow | Schedule | Purpose |
|----------|----------|---------|
| Daily Homework Check | 4:00 PM | Review due assignments |
| Grade Monitoring | Weekly | Track academic progress |
| Study Plan Creation | On-demand | Focused study schedule |
| School Event Sync | Daily | Calendar integration |
| Weekly School Summary | Sunday | Week-ahead preparation |

## Daily Homework Check

**Automated 4:00 PM check:**
```
📚 DAILY HOMEWORK CHECK - [Date]

━━━ EMMA (10th Grade) ━━━

🚨 URGENT:
• AP Physics Lab Report - MISSING
  └─ Was due: Yesterday
  └─ Impact: 50 points

⏰ DUE TODAY:
• Algebra II Problem Set - 11:59 PM
  └─ Status: Not started
  └─ Est. time: 45 min

📅 DUE THIS WEEK:
• English Essay - Friday
• History Quiz - Thursday

📊 GRADES: ⚠️ AP Physics dropped to 71%

━━━ JACK (7th Grade) ━━━

✅ All caught up! No homework due today.

📅 DUE THIS WEEK:
• Science Project - Wednesday
• Math Worksheet - Friday

📊 GRADES: All good! ✅

━━━ ACTION ITEMS ━━━

1. 🚨 Talk to Emma about missing lab report
2. 📋 Ensure Algebra problem set gets done tonight
3. 💡 Consider Science tutor for Emma?

Want me to create a study plan for Emma?
```

**Configure homework checks:**
```bash
cat > ~/clawd/homeos/data/education/homework_check.json << 'EOF'
{
  "enabled": true,
  "check_time": "16:00",
  "students": ["member-emma", "member-jack"],
  "notify": ["member-mom", "member-dad"],
  "alerts": {
    "missing_assignments": true,
    "grade_drops": true,
    "due_today": true
  }
}
EOF
```

## Grade Monitoring

**Automated weekly grade report:**
```
📊 WEEKLY GRADE REPORT

Week of [Date]

━━━ EMMA ━━━

| Course | Grade | Change | Status |
|--------|-------|--------|--------|
| Math | 92% A- | +2% ↑ | ✅ |
| English | 85% B | = | ✅ |
| AP Physics | 71% C- | -4% ↓ | ⚠️ |
| History | 88% B+ | +1% ↑ | ✅ |
| Spanish | 90% A- | = | ✅ |

GPA: 3.4

🚨 ALERTS:
• AP Physics needs intervention
• Missing Lab Report is main issue

🎉 WINS:
• Math improved - extra study paid off!

━━━ JACK ━━━

| Course | Grade | Change | Status |
|--------|-------|--------|--------|
| Math | 88% B+ | +3% ↑ | ✅ |
| English | 82% B | +1% ↑ | ✅ |
| Science | 90% A- | = | ✅ |
| Social Studies | 85% B | -2% ↓ | 🟡 |

🎉 WINS:
• Great week overall!
• Math really improved!

━━━ RECOMMENDATIONS ━━━

1. Emma: Schedule physics tutoring
2. Jack: Keep up the good work!
```

**Grade alert thresholds:**
```
🚨 GRADE ALERT SETTINGS

🔴 Urgent Alert (immediate notification):
• Grade drops below 70%
• Missing assignment affects grade 5%+

🟡 Warning (daily summary):
• Grade drops below 80%
• Any missing assignment

🟢 Good News:
• Grade improves 5%+
• All assignments turned in
```

## Study Plan Creation

**On-demand study plan generation:**
```
📚 STUDY PLAN: Emma - AP Physics

Goal: Raise grade from 71% to 80%
Duration: 2 weeks
Time available: 1 hour/day after school

━━━ WEEK 1 ━━━

MONDAY:
│ 4:00 PM - Complete missing Lab Report (1 hr)
│ Focus: Finish data analysis section
└─ If submitted, could raise grade to ~77%

TUESDAY:
│ 4:00 PM - Review Ch. 5: Momentum (30 min)
│ 4:30 PM - Practice problems (30 min)
└─ Material from last quiz

WEDNESDAY:
│ 4:00 PM - Watch Khan Academy videos (30 min)
│ 4:30 PM - Homework (30 min)
└─ Links: [embedded]

THURSDAY:
│ 4:00 PM - Office hours with teacher
│ - Ask about extra credit options
│ - Review quiz mistakes
└─ Prep questions beforehand

FRIDAY:
│ 4:00 PM - Weekly review (45 min)
│ - Summarize key concepts
│ - Create formula sheet
└─ Light day to avoid burnout

━━━ WEEK 2 ━━━
[Similar structure...]

━━━ STUDY TIPS ━━━

• Physics is practice-based - do problems, don't just read
• Use the textbook's worked examples
• Form study group with classmates
• Get good sleep before test days

⏰ REMINDERS SET:
• Daily at 4:00 PM: Study time!
• Thursday 3:30 PM: Prep for office hours

Ready to start this plan?
```

## School Event Sync

**Automated calendar sync:**
```
📅 SCHOOL EVENTS SYNCED

Pulled from: Google Classroom, School Website

━━━ NEXT 30 DAYS ━━━

🎓 TESTS & EXAMS:
📅 Jan 20 - Emma: AP Physics Midterm
📅 Jan 25 - Jack: Science Quiz
📅 Feb 1 - Emma: History Test

📅 DEADLINES:
📅 Jan 18 - Jack: Science Project due
📅 Jan 22 - Emma: English Essay due
📅 Jan 30 - Field trip permission slip

🏢 SCHOOL EVENTS:
📅 Jan 19 - Early Release (12:30 PM)
📅 Jan 25 - Parent-Teacher Conferences
📅 Feb 5 - No School - Professional Day

✅ All synced to family calendar!
⏰ Prep reminders set for tests and projects.
```

## Weekly School Summary

**Sunday evening school prep:**
```
📚 WEEK AHEAD: School Preview

Week of [Date]

━━━ EMMA ━━━

📅 DEADLINES:
• Tuesday - Algebra worksheet
• Friday - English Essay (big one!)

🗓️ TESTS:
• Thursday - History Quiz

🎯 ACTIVITIES:
• Wed 3:30 - Soccer practice
• Sat 10:00 - Soccer game

💡 SUGGESTION:
• Start English Essay by Tuesday
• Study for History Mon/Wed nights

━━━ JACK ━━━

📅 DEADLINES:
• Wednesday - Science Project DUE!

🎯 ACTIVITIES:
• Tue 4:00 - Piano lesson
• Thu 4:00 - Piano lesson

⚠️ HEADS UP:
• Science Project - is it done? Check tonight!

━━━ PARENT TASKS ━━━

☐ Check Emma's English Essay progress (Tue)
☐ Sign Jack's field trip form
☐ Prep for parent-teacher conference (next week)

Pack lunches Sunday night to reduce Monday stress!
```

## Parent-Teacher Communication

**Email drafting for teachers:**
```
📧 TEACHER EMAIL DRAFT

To: Mrs. Johnson (AP Physics)
Subject: Emma's Grade - Discussion Request

---

Dear Mrs. Johnson,

I wanted to reach out regarding Emma's current grade 
in AP Physics. I noticed it has dropped recently 
and she's missing a lab report.

Could we schedule a brief meeting or phone call to:
1. Discuss Emma's progress and challenges
2. Understand options for the missing lab report
3. Learn how we can better support her at home

I'm available [suggested times] for a call or meeting.

Thank you for your time and for teaching Emma.

Sincerely,
[Parent Name]

---

Want me to adjust this before you send?
```

## Multi-Child Coordination

**When both children have conflicts:**
```
⚠️ SCHOOL COORDINATION NEEDED

Tuesday at 4:00 PM:
• Emma - Dentist appointment
• Jack - Piano lesson

Both need pickup/dropoff.

Options:
1. 🚗 Split up: Dad takes Emma, Mom takes Jack
2. 📅 Reschedule: Move dentist to 5:00 PM
3. 🚗 Carpool: Ask if Jack can ride with friend

What works best?
```

**School supply coordination:**
```
📚 SCHOOL SUPPLIES CHECK

📝 FROM SCHOOL LISTS:

👧 Emma:
☐ Graphing calculator (TI-84 - $100)
☐ Lab notebook
☐ Index cards (500 pack)

👦 Jack:
☐ Poster board (science project)
☐ Colored pencils
✅ Binder (already have)

🛒 SHOPPING LIST:
• Combined items to buy
• Estimated total: $130

Add to grocery run or order online?
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   └── education/
│       ├── students.json           # Student profiles
│       ├── homework_check.json     # Check configuration
│       ├── grade_history.json      # Historical grades
│       ├── study_plans.json        # Active study plans
│       └── school_events.json      # Synced events
├── memory/
│   └── learnings/
│       └── education_patterns.json # What works
└── logs/
    └── education_workflow.log    # Automation log
```

## Example Interactions

**User:** "Set up school monitoring for both kids"

**Assistant:**
```
📚 SCHOOL MONITORING SETUP

I'll set up comprehensive tracking for Emma and Jack.

✅ ENABLING:

1. 📝 Daily Homework Check - 4:00 PM
   • Pull assignments from Google Classroom
   • Flag missing/overdue items
   • Notify you of anything urgent

2. 📊 Weekly Grade Report - Sunday 6:00 PM
   • Grade changes and trends
   • Alerts for drops below 80%
   • Celebration for improvements

3. 📅 School Event Sync - Daily
   • Tests, projects, deadlines
   • School calendar events
   • Automatic family calendar updates

4. ⏰ Smart Reminders
   • Study reminders before tests
   • Project deadline warnings
   • Permission slip due dates

Activate all of these?
```

**User:** "Emma's physics grade is really worrying me"

**Assistant:**
```
📊 PHYSICS GRADE ANALYSIS: Emma

Current: 71% (C-)
Previous: 75% two weeks ago
Trend: ↓ Declining

🔍 ROOT CAUSE ANALYSIS:

1. Missing Lab Report: -50 points
   • This is the main issue
   • If completed with 80%: Grade rises to ~77%

2. Quiz 3: 65% (20 points)
   • Topic: Momentum
   • Below her usual performance

3. Test 2: 72% (100 points)
   • Struggled with problem-solving section

━━━ ACTION PLAN ━━━

🚨 IMMEDIATE (This Week):
1. Complete missing lab report
2. Check if late submission accepted
3. Talk to Emma about what's happening

📅 SHORT-TERM (2 Weeks):
1. Create study plan (I can do this)
2. Consider tutoring (I can find options)
3. Schedule teacher meeting

Would you like me to:
1. Generate a 2-week study plan?
2. Draft an email to Mrs. Johnson?
3. Find physics tutors nearby?
```

## Integration Points

- **Education Skill**: Detailed assignment/grade access
- **Calendar**: School events and reminders
- **Family Comms**: Notify parents of issues
- **Hire Helper**: Connect to tutor finding
- **Mental Load**: Part of morning/weekly briefings
