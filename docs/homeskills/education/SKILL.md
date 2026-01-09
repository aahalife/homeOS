---
name: education
description: Manage school and education tasks including homework tracking, grade monitoring, study plans, and LMS integration. Use when the user mentions homework, assignments, grades, school, studying, tutoring, Google Classroom, Canvas, courses, or academic performance. Supports multiple children with different schools.
---

# Education Skill

Track homework, monitor grades, create study plans, and integrate with learning management systems (Google Classroom, Canvas) to reduce the cognitive burden of managing children's education.

## When to Use

- User asks about homework status or assignments due
- User wants to check grades or academic progress
- User needs help creating a study plan
- User mentions missing assignments or grade concerns
- User wants school calendar/events synced
- User asks about their child's courses

## Workflow Overview

```
1. Identify Student → 2. Check LMS Connection → 3. Gather Data
→ 4. Present Summary → 5. Take Action → 6. Set Reminders
```

## Step 1: Identify the Student

**Check family profiles for students:**
```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null | jq '.members[] | select(.role == "child")'
```

**If multiple children, ask which:**
```
I can help with school stuff! Which child are you asking about?

1. [Child 1 name]
2. [Child 2 name]
3. All of them
```

**Store student context for session:**
```bash
echo '{"active_student": "STUDENT_ID", "timestamp": "DATE"}' > ~/clawd/homeos/memory/conversations/education_context.json
```

## Step 2: Check LMS Connection

**Supported Learning Management Systems:**

| LMS | Status Check | Data Available |
|-----|--------------|----------------|
| Google Classroom | Check OAuth token | Courses, assignments, grades |
| Canvas | Check API token | Full gradebook, calendar |
| Manual Entry | Always available | User-provided data |

**Connection status response:**
```
📚 Education Dashboard for [Child Name]

✅ Google Classroom: Connected
⚠️ Canvas: Not configured

I can pull assignments and grades from Google Classroom.
Want me to check what's due?
```

**If no LMS connected:**
```
I don't have access to [Child]'s school system yet.

Options:
1. 📱 Connect Google Classroom (if school uses it)
2. 📱 Connect Canvas (if school uses it)
3. ✏️ Track assignments manually

Which would you prefer?
```

## Step 3: Get Homework Summary

**Daily homework check format:**
```
📚 HOMEWORK CHECK: [Child Name] - [Date]

🚨 MISSING (needs immediate attention):
• [Assignment] - [Course] - was due [Date]
  └─ Points at risk: [X]

⏰ DUE TODAY:
• [Assignment] - [Course] - [Time]
  └─ Status: [not started / in progress]

📅 DUE TOMORROW:
• [Assignment] - [Course]
  └─ Estimated time: [X min]

📆 DUE THIS WEEK:
• [Assignment] - [Course] - Due [Day]
• [Assignment] - [Course] - Due [Day]

💡 Today's Priority: [Most urgent item]

Need help with any of these?
```

**Action options to offer:**
```
What would you like to do?

1. 📝 Get details on a specific assignment
2. ⏰ Set a homework reminder
3. 📊 Check [Child]'s grades
4. 📅 Create a study plan
5. ✅ Mark something as done
```

## Step 4: Grade Monitoring

**Grade summary format:**
```
📊 GRADES: [Child Name]

Last updated: [Time]

| Course | Grade | Trend | Status |
|--------|-------|-------|--------|
| Math | 92% A- | ↑ | ✅ Good |
| English | 85% B | → | ✅ OK |
| Science | 71% C- | ↓ | ⚠️ Needs attention |
| History | 88% B+ | ↑ | ✅ Good |

⚠️ ALERTS:
• Science dropped 4 points this week
• Missing Lab Report affecting grade

💡 RECOMMENDATIONS:
• Focus extra study time on Science
• Complete missing Lab Report ASAP
• Consider tutoring if trend continues

Want me to create a study plan for Science?
```

**Grade alert thresholds:**
- Below 70%: URGENT - immediate parent notification
- Below 80%: WARNING - suggest intervention
- Dropped 5+ points: ALERT - monitor closely
- Improved 5+ points: CELEBRATE - positive reinforcement

## Step 5: Create Study Plan

**Gather study plan requirements:**
```
📚 Study Plan Setup

Let me create a personalized plan. Quick questions:

1. What subject(s) need focus?
2. Any upcoming tests or exams?
3. How many hours per day can [Child] study?
4. Best study time? (after school / evening / morning)
```

**Study plan format:**
```
📚 STUDY PLAN: [Child Name]
Focus: [Subject] | Duration: 7 days

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MONDAY - [Date]
┌─────────────────────────────────────┐
│ 4:00 PM - Review Chapter 5 (30 min) │
│ 4:30 PM - Practice problems (30 min)│
│ 5:00 PM - Break                     │
│ 5:15 PM - Vocabulary review (15 min)│
└─────────────────────────────────────┘
Goal: Complete worksheet + review notes

TUESDAY - [Date]
... [continues for week]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 STUDY TIPS:
• Use Pomodoro: 25 min work, 5 min break
• Review before bed for better retention
• Practice > re-reading for math/science

⏰ REMINDERS SET:
• Daily at 4:00 PM: "Study time!"
• Night before test: "Review session"

Ready to start? I'll send reminders!
```

## Step 6: Assignment Reminders

**Create homework reminder:**
```
⏰ REMINDER SET

Assignment: [Title]
Due: [Date/Time]

Reminders scheduled:
• 📱 Day before at 4:00 PM
• 📱 Due date at 8:00 AM

I'll also check in during the daily homework review.
```

**Save reminder:**
```bash
cat >> ~/clawd/homeos/tasks/active/homework-reminder-$(date +%s).json << 'EOF'
{
  "type": "homework_reminder",
  "student": "STUDENT_ID",
  "assignment": "ASSIGNMENT_TITLE",
  "course": "COURSE_NAME",
  "due": "DUE_DATE",
  "reminders": [
    {"time": "DAY_BEFORE_4PM", "sent": false},
    {"time": "DUE_DAY_8AM", "sent": false}
  ]
}
EOF
```

## Handling Missing Assignments

**When missing assignments detected:**
```
🚨 MISSING ASSIGNMENT ALERT

[Child] has a missing assignment:

📝 [Assignment Title]
📚 [Course Name]
📅 Was due: [Date] ([X] days ago)
📊 Impact: Could affect grade by [X]%

⚠️ IMPORTANT: Many teachers accept late work with penalty.

Options:
1. 📧 Help draft email to teacher (ask about late policy)
2. 📝 Create plan to complete ASAP
3. 🗓️ Add to today's priority list
4. 📞 Remind me to discuss with [Child]

What would you like to do?
```

**Draft teacher email:**
```
📧 DRAFT EMAIL

To: [Teacher Name]
Subject: [Assignment] - [Child's Name]

Dear [Teacher Name],

I wanted to reach out regarding the [Assignment Name] that was due on [Date]. [Child] is working on completing it.

Could you let us know:
1. Is late submission accepted?
2. Is there any grade penalty for late work?
3. What is the final deadline to submit?

Thank you for your understanding.

[Parent Name]

---
Want me to adjust this before you send?
```

## School Events Tracking

**Sync and display school events:**
```
📅 UPCOMING SCHOOL EVENTS

[Child Name] - Next 30 days

🎓 EXAMS & TESTS:
• [Date] - Math Midterm
• [Date] - Science Quiz

📋 DEADLINES:
• [Date] - Essay due
• [Date] - Project presentation

📅 SCHOOL EVENTS:
• [Date] - Parent-Teacher Conference
• [Date] - Early Release Day
• [Date] - No School - Holiday

📱 Added to family calendar.
Want me to set prep reminders for the tests?
```

## Progress Tracking

**Weekly education summary:**
```
📚 WEEKLY EDUCATION REPORT

[Child Name] - Week of [Date]

✅ COMPLETED:
• [X] assignments turned in
• All deadlines met: [Yes/No]

📊 GRADES:
• Improved: [Subject] ↑[X]%
• Stable: [Subject], [Subject]
• Needs attention: [Subject] ↓[X]%

⏰ STUDY TIME:
• Logged: [X] hours this week
• Goal: [Y] hours

🎯 NEXT WEEK PRIORITIES:
• [Priority 1]
• [Priority 2]

💬 Suggest: Check in with [Child] about [Subject]
```

**Save weekly summary:**
```bash
cat >> ~/clawd/homeos/memory/learnings/education_weekly.json << 'EOF'
{
  "week_of": "DATE",
  "student": "STUDENT_ID",
  "assignments_completed": X,
  "grade_changes": {...},
  "study_hours": X,
  "notes": "..."
}
EOF
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   ├── education/
│   │   ├── students.json          # Student profiles
│   │   ├── lms_config.json        # LMS connection settings
│   │   └── grade_history.json     # Historical grade data
│   └── family.json                # Family members with children
├── tasks/
│   ├── active/
│   │   └── homework-reminder-*.json
│   └── completed/
│       └── education-*.json
└── memory/
    └── learnings/
        └── education_weekly.json
```

## Example Interactions

**User:** "What homework does Emma have?"

**Assistant:**
```
📚 HOMEWORK CHECK: Emma - January 15

⏰ DUE TODAY:
• Chapter 5 Problem Set - Algebra II - 11:59 PM
  └─ Status: Not started | Est. time: 45 min

📅 DUE TOMORROW:
• Essay: The Great Gatsby - English - 11:59 PM  
  └─ Status: In progress | Est. time: 1 hour

📆 DUE THIS WEEK:
• Lab Report: Momentum - AP Physics - Friday
  └─ Est. time: 2 hours

💡 Priority: Start with the Math problem set - it's due today!

Want me to set a reminder or help with anything?
```

**User:** "Her science grade dropped. Can you help?"

**Assistant:**
```
📊 Let me check Emma's Science grades...

AP Physics - Current: 71% C-

📉 RECENT GRADE HISTORY:
• 2 weeks ago: 75%
• Last week: 73%
• Now: 71% (↓4% in 2 weeks)

🔍 WHAT'S CAUSING THE DROP:
• Lab Report: Momentum - MISSING (50 pts)
• Quiz 3: 65% (20 pts)
• Test 2: 72% (100 pts)

💡 RECOMMENDED ACTION PLAN:

1. IMMEDIATE: Complete missing Lab Report
   → Could raise grade to ~77% if scored well
   → I can help create a plan to finish it

2. THIS WEEK: Review Quiz 3 material
   → Identify gaps in understanding
   → May be able to do test corrections

3. ONGOING: Consider tutoring
   → I can help find a physics tutor

Should I:
1. Create a study plan for the lab report?
2. Help find a tutor?
3. Draft an email to the teacher?
```

## Integration Points

- **Calendar**: Sync exam dates and school events
- **Reminders**: Automated homework and study reminders
- **Family Comms**: Alert parents about grade changes
- **Hire Helper**: Connect to tutor finding skill
