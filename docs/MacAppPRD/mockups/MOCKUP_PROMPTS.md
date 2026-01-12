# Hearth Mockup Generation Prompts

## Design System

**Style:** macOS Tahoe 26.1 "Liquid Glass" design language
- Frosted glass transparency effects
- Subtle depth and layering
- Soft shadows and highlights
- Rounded corners (12-16px radius)
- SF Pro font family
- SF Symbols for icons

**Colors:**
- Primary: Warm Orange #F5A623
- Background: Adaptive (light/dark mode)
- Success: Green #4CAF50
- Attention: Amber #FFC107
- Urgent: Red #F44336

---

## Mockup List

### 1. Menu Bar States
- 1a. Menu bar icon - Normal state (house icon)
- 1b. Menu bar icon - Attention state (orange dot)
- 1c. Menu bar icon - Urgent state (red badge)

### 2. Menu Bar Dropdown
- 2a. Today dashboard - Morning view
- 2b. Today dashboard - With alerts
- 2c. Quick actions panel

### 3. Full Window Views
- 3a. Family Overview dashboard
- 3b. Elder Care Hub
- 3c. Education Command Center
- 3d. Meal Planning view
- 3e. Settings panel

### 4. Dialogs & Notifications
- 4a. Morning briefing notification
- 4b. Elder check-in approval
- 4c. Elder check-in summary
- 4d. Bill alert notification
- 4e. Homework reminder

### 5. Onboarding
- 5a. Welcome screen
- 5b. Family setup
- 5c. Calendar connection
- 5d. Elder care setup
- 5e. Ready screen

---

## Detailed Prompts

### Prompt 1: Menu Bar Dropdown - Today Dashboard

```
A macOS Tahoe menu bar dropdown panel for a family assistant app called "Hearth". 

Liquid glass frosted translucent design with subtle depth. The panel drops down from a menu bar icon.

Content:
- Header: "Good morning, Sarah!" with a warm sun icon
- Weather: "72°F Sunny" with weather icon
- Section "TODAY" with schedule:
  - 8:00 School drop-off
  - 3:30 Emma → Soccer (with person icon)
  - 5:00 Jack → Piano
  - 6:30 Family dinner
- Alert section with amber background: "2 items need attention"
  - Emma: Math homework due
  - Grandma check-in at 10am
- Two action buttons at bottom: "What's for dinner?" and "Call Mom"

Apple-quality design, SF Pro font, warm orange accent color #F5A623, 
clean minimal aesthetic, professional yet friendly.

High fidelity UI mockup, 2x Retina resolution, light mode.
```

### Prompt 2: Full Window - Family Overview

```
A macOS Tahoe full application window for "Hearth" family assistant app.

Liquid glass design with sidebar navigation and main content area.

Left sidebar (dark frosted glass):
- App icon and "Hearth" title
- Navigation items with icons:
  - Today (calendar icon) - selected
  - Elders (heart icon)
  - School (book icon)
  - Meals (utensils icon)
  - Home (house icon)
  - Settings (gear icon)

Main content area:
- Header: "FAMILY OVERVIEW"
- Grid of family member cards (3 across, 2 rows):
  - Dad card: photo placeholder, "At work", "Until 5pm"
  - Mom card: "Working from home"
  - Emma card: "School", "Soccer 3pm"
  - Jack card: "School", "Piano 5pm"
  - Grandma card: green checkmark, "Called", "Feeling good!"
  - Grandpa card: clock icon, "10am check-in"

Each card has frosted glass effect with subtle shadow.
Warm, friendly but professional Apple-quality design.
SF Pro font, orange accent #F5A623.

High fidelity UI mockup, 1440x900px, 2x Retina, light mode.
```

### Prompt 3: Elder Care Hub

```
A macOS Tahoe application window showing the Elder Care Hub for "Hearth" app.

Liquid glass frosted design.

Header: "Grandma Rose" with a warm photo placeholder and heart icon.

Main content sections:

1. "TODAY'S CHECK-INS" card:
   - Morning 9:00 AM - Green checkmark, "Completed"
   - Summary: "Slept well, had breakfast"
   - Medications: "Taken ✓"
   - Mood: "Good 😊"
   - Evening 7:00 PM - Clock icon, "Scheduled in 6 hours"

2. "THIS WEEK" progress bar:
   Mon ✓  Tue ✓  Wed ✓  Thu ○  Fri ○  Sat ○

3. "WELLNESS TRENDS" section:
   - Sleep: progress bar 80% "Good"
   - Mood: progress bar 90% "Excellent"
   - Meds: progress bar 100%

Bottom action buttons:
- "📞 Call Now" (orange primary button)
- "🎵 Play Music" (secondary)
- "📝 Add Note" (secondary)

Apple-quality design, warm and caring aesthetic.
SF Pro font, orange accent #F5A623.

High fidelity UI mockup, 2x Retina resolution, light mode.
```

### Prompt 4: Elder Check-In Approval Dialog

```
A macOS Tahoe modal dialog for approving an elder check-in call.

Centered dialog with liquid glass frosted background.
Subtle shadow and rounded corners.

Content:
- Phone icon at top (orange color)
- Title: "Call Grandma Rose?"
- Subtitle: "Morning check-in scheduled for 9:00 AM"
- Checkbox: "Always allow morning calls to Rose"
- Two buttons:
  - "Not Today" (secondary, gray)
  - "Call Now" (primary, orange #F5A623)

Clean, minimal Apple-style dialog.
SF Pro font, centered text.
The dialog floats over a blurred background.

High fidelity UI mockup, 2x Retina resolution.
```

### Prompt 5: Morning Briefing Notification

```
A macOS notification banner for the Hearth family assistant app.

Standard macOS notification style with app icon on left.

App icon: Warm orange house/hearth icon.

Content:
- Title: "Hearth"
- Message: "Good morning! Your briefing is ready."
- Action button: "View"

Clean macOS notification design.
Appears in top-right corner of screen.

High fidelity mockup, 2x Retina resolution.
```

### Prompt 6: Education Command Center

```
A macOS Tahoe application window showing Education tracking for "Hearth" app.

Liquid glass frosted design with sidebar.

Main content:
- Header: "EDUCATION" with book icon
- Tabs: "Emma" (selected) | "Jack"

Emma's dashboard:

1. "GRADES" card:
   Table showing:
   - Math: 92% A- (green up arrow)
   - English: 85% B (gray dash)
   - Science: 78% C+ (red down arrow)
   - History: 88% B+ (green up arrow)

2. "HOMEWORK DUE" card:
   - TODAY (red badge):
     • Math: Chapter 5 problems
   - TOMORROW:
     • English: Book report draft
   - THIS WEEK:
     • Science: Lab write-up (Friday)

3. Alert banner at bottom:
   "⚠️ Science grade dropped 5 points this week"
   Button: "Create Study Plan"

Apple-quality design, SF Pro font.
Orange accent #F5A623, clean minimal aesthetic.

High fidelity UI mockup, 2x Retina resolution, light mode.
```

### Prompt 7: Check-In Summary

```
A macOS Tahoe panel showing elder check-in results for "Hearth" app.

Liquid glass frosted card design.

Header: Green checkmark icon, "Grandma Rose - Doing well"

Content:
- Quote: "Slept great, having lunch with Dorothy. Took medications."
- Mood indicator: "😊 Good"
- Music note: "We listened to Frank Sinatra - Fly Me to the Moon"
- Next check-in: "7:00 PM"

Bottom buttons:
- "View Details"
- "Call Now"

Warm, reassuring design with soft colors.
Green success accents.
SF Pro font.

High fidelity UI mockup, 2x Retina resolution.
```

---

## Generation Notes

- All mockups should be 2x Retina resolution
- Light mode as default, dark mode variants if possible
- Ensure text is legible and correctly spelled
- Use placeholder avatars (circles with initials) for family members
- Maintain consistent spacing and alignment
- Follow Apple Human Interface Guidelines
