name: school-homework-check
description: Daily homework check across all children — find due/missing assignments, grade alerts, and create action items

steps:
  # Step 1: Load student profiles
  - id: load-students
    command: >
      cat ~/clawd/homeos/data/education/students.json 2>/dev/null || echo '[]'

  # Step 2: Load family data to identify children
  - id: load-family
    command: >
      cat ~/clawd/homeos/data/family.json 2>/dev/null |
      jq '[.members[] | select(.role == "child")]' || echo '[]'

  # Step 3: Check each student's assignments (simulated — real integration would hit LMS API)
  - id: check-assignments
    command: >
      cat ~/clawd/homeos/data/education/assignments.json 2>/dev/null |
      jq --arg today "$(date +%Y-%m-%d)" --arg week "$(date -d '+7 days' +%Y-%m-%d 2>/dev/null || date -v+7d +%Y-%m-%d)" '
        {
          overdue: [.[] | select(.status == "missing" or (.due_date < $today and .status != "completed"))],
          due_today: [.[] | select(.due_date == $today and .status != "completed")],
          due_this_week: [.[] | select(.due_date > $today and .due_date <= $week and .status != "completed")],
          completed_today: [.[] | select(.completed_date == $today)]
        }' || echo '{"overdue":[],"due_today":[],"due_this_week":[],"completed_today":[]}'

  # Step 4: Check grade alerts
  - id: check-grades
    command: >
      cat ~/clawd/homeos/data/education/grade_history.json 2>/dev/null |
      jq '
        [.[] | . as $record |
          .courses[]? |
          select(.current_grade < 75) |
          {student: $record.student_name, course: .name, grade: .current_grade, trend: .trend}
        ]' || echo '[]'

  # Step 5: Compile homework report
  - id: compile-report
    command: >
      echo '{
        "assignments": '$ASSIGNMENTS',
        "grade_alerts": '$GRADES'
      }' | jq -r '
        "📚 DAILY HOMEWORK CHECK - " + (now | strftime("%B %d, %Y")) + "\n\n" +
        
        (if (.assignments.overdue | length) > 0 then
          "🚨 OVERDUE:\n" +
          (.assignments.overdue | map("  • " + .student_name + ": " + .title + " (" + .course + ")\n    Due: " + .due_date + " | Impact: " + (.points // "unknown") + " pts") | join("\n")) + "\n\n"
        else "" end) +
        
        (if (.assignments.due_today | length) > 0 then
          "⏰ DUE TODAY:\n" +
          (.assignments.due_today | map("  • " + .student_name + ": " + .title + " (" + .course + ")\n    Est. time: " + (.est_minutes // 30 | tostring) + " min") | join("\n")) + "\n\n"
        else "✅ Nothing due today!\n\n" end) +
        
        (if (.assignments.due_this_week | length) > 0 then
          "📅 DUE THIS WEEK:\n" +
          (.assignments.due_this_week | map("  • " + .student_name + ": " + .title + " — " + .due_date) | join("\n")) + "\n\n"
        else "" end) +
        
        (if (.grade_alerts | length) > 0 then
          "⚠️ GRADE ALERTS:\n" +
          (.grade_alerts | map("  • " + .student + ": " + .course + " at " + (.grade | tostring) + "% " + .trend) | join("\n")) + "\n\n"
        else "📊 All grades looking good! ✅\n\n" end) +
        
        "━━━━━━━━━━━━━━━━━━━\n" +
        (if (.assignments.overdue | length) > 0 then
          "🎯 ACTION: Address overdue assignments first!"
        else "🎯 Keep up the great work!" end)'
    stdin: $check-assignments.stdout

  # Step 6: Save check-in log
  - id: save-log
    command: >
      cat >> ~/clawd/homeos/logs/education_workflow.log << LOG
      $(date -Iseconds) | HOMEWORK_CHECK | overdue:$(echo '$assignments' | jq '.overdue | length') | due_today:$(echo '$assignments' | jq '.due_today | length') | grade_alerts:$(echo '$grades' | jq 'length')
      LOG
      echo '{"logged": true}'
