---
name: psy-rich
version: small-model
description: Suggest CONCRETE psychologically rich experiences with specific activities, times, costs, and locations. Use when user asks "what should we do", wants activity suggestions, seems bored, or wants meaningful family experiences.
risk: low
---

# Psy-Rich Skill (Small-Model)

Suggest specific, concrete enriching experiences. Not vague. Not generic.

**SCOPE: Produce actionable experience suggestions with real details.**
**RULE: Every suggestion MUST include: activity name, duration, cost estimate, location type, and why it's enriching.**

## TRIGGERS

IF message contains: "what should we do", "bored", "activity ideas", "weekend plans", "something fun", "family activity", "date night", "something different", "in a rut"
THEN activate this skill.

## STORAGE

- Profile: ~/clawd/homeos/data/psy-rich/profile.json
- Experience log: ~/clawd/homeos/data/psy-rich/journal.json
- Local favorites: ~/clawd/homeos/data/psy-rich/local.json
- Patterns: ~/clawd/homeos/memory/psy-rich-patterns.json

## ENRICHMENT TYPES

Five types of psychologically rich experiences:
- NOVEL: New and unfamiliar → breaks routine
- PERSPECTIVE: Changes how you see things → builds empathy
- COMPLEX: Intellectually engaging → satisfies curiosity
- AESTHETIC: Beauty and wonder → elevates mood
- SOCIAL: Meaningful connection → deepens relationships

## STEP 1: GATHER CONTEXT

IF profile.json exists → use stored preferences.
IF no profile → ask (ONLY on first use):

```
🌟 Quick setup (one time only):

1. Kids ages? [e.g., 7 and 10]
2. Your area? [city/region]
3. Budget comfort? [free / under $25 / under $50 / flexible]
4. Family energy: [active / chill / mix]
5. Any interests? [arts, nature, food, science, sports]
```

Save:
```bash
cat > ~/clawd/homeos/data/psy-rich/profile.json << 'EOF'
{"kids_ages":[7,10],"location":"CITY","budget":"under_50","energy":"mix","interests":["nature","food"]}
EOF
```

IF profile exists AND user gives context (mood, time, energy) → adapt.
IF no context given → use defaults from profile.

## STEP 2: DETERMINE FILTERS

From request, determine:
- WHO: solo parent / couple / family with kids / one parent + kids
- WHEN: today, this weekend, this evening, general
- ENERGY: high / low / medium (default: medium)
- BUDGET: from profile or request (default: under $25)
- DURATION: quick (under 1hr) / half-day / full-day (default: half-day)

IF not specified, use defaults. Do NOT ask more than one clarifying question.

## STEP 3: GENERATE SUGGESTIONS

Produce exactly 3 suggestions plus 1 quick option. Each MUST be concrete.

```
🌟 EXPERIENCES FOR [WHO] - [WHEN]

1. 🎯 [SPECIFIC ACTIVITY NAME]
   📍 Where: [Location type + example: "Local pottery studio (check [City] Ceramics Co)"]
   ⏰ Time: [Specific duration: "2 hours, Saturday morning 10am-12pm"]
   💰 Cost: [$X per person / free / $X total for family]
   ✨ Why enriching: [One sentence — which type: NOVEL/PERSPECTIVE/COMPLEX/AESTHETIC/SOCIAL]
   👶 Kid-friendly: [Yes, ages X+ / adapt for younger kids by... / adults only]

2. 🎯 [SPECIFIC ACTIVITY NAME]
   📍 Where: [Location type + example]
   ⏰ Time: [Duration + suggested time slot]
   💰 Cost: [$X]
   ✨ Why enriching: [One sentence]
   👶 Kid-friendly: [Details]

3. 🎯 [SPECIFIC ACTIVITY NAME]
   📍 Where: [Location type + example]
   ⏰ Time: [Duration + suggested time slot]
   💰 Cost: [$X]
   ✨ Why enriching: [One sentence]
   👶 Kid-friendly: [Details]

⚡ QUICK OPTION (under 30 min, free):
🎯 [Activity]
📍 [Where]
✨ [Why enriching]

Which sounds good? I can help plan details.
```

## SUGGESTION RULES

ALWAYS be specific:
- ❌ "Visit a museum" → ✅ "Visit the natural history museum — go straight to the dinosaur hall, kids love the T-Rex cast. Budget 2 hours."
- ❌ "Try new food" → ✅ "Ethiopian dinner at a local restaurant — you eat with injera bread (no utensils!), great for adventurous eaters. $15-20/person."
- ❌ "Go outside" → ✅ "Sunrise hike at a local nature trail — arrive 30 min before sunrise, bring hot cocoa in a thermos. Free, 1.5 hours."
- ❌ "Do something creative" → ✅ "Family watercolor session at home — get a $12 watercolor set from craft store, paint the same object and compare. 1 hour, Sunday afternoon."

ALWAYS include at least one FREE option.
ALWAYS include at least one NOVEL experience (something they likely haven't done).
IF kids are involved → every suggestion must be kid-appropriate for their ages.
IF evening/low energy → bias toward AESTHETIC and calm SOCIAL.
IF weekend/high energy → bias toward NOVEL and active COMPLEX.

## CONCRETE SUGGESTION BANK

Use these as templates. Adapt to location and family profile.

NOVEL experiences:
- Blindfolded taste test at home (buy 5 unusual fruits: dragon fruit, rambutan, star fruit). 30 min, $10-15, kitchen. Ages 4+.
- "Tourist in your own city" — pick 3 landmarks you've never actually visited. Half day, free-$20, your city. Ages 6+.
- Cook a meal from a country you can't find on a map. Research together first. 2 hours, $15-25, kitchen. Ages 5+.
- Night walk with flashlights in a familiar park. Everything looks different in the dark. 1 hour, free, local park. Ages 6+.
- Visit an ethnic grocery store and buy 3 things you've never tried. 1 hour, $10-15, local. Ages 4+.

PERSPECTIVE experiences:
- Volunteer at a community food bank together. 2-3 hours, free, local food bank. Ages 8+.
- Visit a place of worship different from your own (many welcome visitors). 1 hour, free, local. Ages 7+.
- Interview a grandparent or elderly neighbor about their childhood. Record it. 1 hour, free, their home. Ages 6+.
- "Swap day" — kid plans the family schedule, parent follows. Half day, varies, home/out. Ages 8+.

COMPLEX experiences:
- Family escape room. 1 hour, $25-35/person, escape room venue. Ages 10+.
- Build something from a YouTube tutorial (birdhouse, simple circuit, origami). 2 hours, $5-20, home. Ages 6+.
- Attend a free public lecture at a local university or library. 1-2 hours, free. Ages 10+.
- Learn 10 phrases in a new language together using a free app. 30 min, free, anywhere. Ages 5+.

AESTHETIC experiences:
- Sunrise or sunset picnic at highest point nearby. 1.5 hours, $5-10 (snacks), park/hill. Ages 3+.
- Visit a botanical garden — focus on one section deeply instead of rushing through. 2 hours, $5-15, botanical garden. Ages 4+.
- "Art gallery at home" — each family member creates one piece, hang them up, do a gallery walk with fancy snacks. 2 hours, $5-10, home. Ages 3+.
- Lie on blankets and stargaze. Use a free app to identify constellations. 1 hour, free, backyard or park. Ages 5+.

SOCIAL experiences:
- Board game tournament night with a twist: losers pick the next game. 2-3 hours, free (use owned games), home. Ages 5+.
- "Question jar" dinner — everyone writes 3 questions, draw and answer over dinner. 1 hour, free, home. Ages 6+.
- Neighborhood scavenger hunt — make a list of 15 things to find on a walk. 1 hour, free, neighborhood. Ages 4+.

## STEP 4: AFTER USER PICKS

IF user picks a suggestion:
```
🗓️ Let's plan it!

[Activity Name]
📅 When: [Suggest specific date/time based on context]
📋 What to prep:
- [Item 1]
- [Item 2]
📍 Getting there: [Brief logistics]

⏰ Reminder set for [time before].

After you do it, tell me how it went! I'll log it.
```

IF user says "how was [activity]" or reports back:
```
📓 Logged!

[Activity] - [Date]
Rating: [ask or infer]
✨ Type: [NOVEL/PERSPECTIVE/etc.]

You've done [X] enriching experiences this month.
[Pattern observation if enough data, e.g., "You love nature activities — want more of those or time to try something new?"]
```

Save:
```bash
cat >> ~/clawd/homeos/data/psy-rich/journal.json << 'EOF'
{"date":"DATE","activity":"NAME","type":"TYPE","who":"WHO","rating":null,"notes":""}
EOF
```

## OUTPUT_HANDOFF

TO note-to-actions skill:
- WHEN: user wants to make enriching experiences a regular habit
- PASS: {"handoff":"note-to-actions","content":"regular enrichment habit","context":"wants to do psy-rich activities weekly"}

TO education skill:
- WHEN: suggestion involves educational content for a child
- PASS: {"handoff":"education","reason":"educational enrichment","child":"NAME","activity":"DESCRIPTION"}

TO school skill:
- WHEN: enrichment activities need to fit around school schedule
- PASS: {"handoff":"school","reason":"schedule check","request":"free_time_windows"}

FROM education/school skills:
- WHEN: child is stressed or burned out
- EXPECT: {"handoff":"psy-rich","reason":"stress relief","member":"NAME","need":"DESCRIPTION"}
- RESPONSE: Bias toward AESTHETIC and low-energy NOVEL experiences.

## ERROR HANDLING

IF no profile and user won't answer setup → use defaults: budget=free, energy=medium, interests=general, suggest broad options.
IF user rejects all 3 suggestions → ask: "What's not clicking? Too active? Too costly? Wrong vibe?" Then regenerate.
IF user wants something for a specific mood → map: stressed→AESTHETIC, bored→NOVEL, lonely→SOCIAL, curious→COMPLEX, stuck→PERSPECTIVE.
IF location unknown → suggest home-based and "local [type]" options without specific venue names.
