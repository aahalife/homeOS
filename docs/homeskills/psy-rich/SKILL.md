---
name: psy-rich
description: Generate psychologically rich experience suggestions based on research about living a fulfilling life. Use when the user asks for activity suggestions, wants meaningful experiences, seeks personal growth activities, asks what to do, or wants life enrichment ideas tailored to their personality and preferences.
---

# Psychologically Rich Experiences Skill

Suggest experiences that cultivate psychological richness - a life of interesting, varied, and perspective-changing experiences.

## Philosophy

Beyond happiness and meaning, research identifies a third dimension of a good life: **psychological richness**. This involves:

- **Novel experiences** - Encountering the unfamiliar
- **Perspective shifts** - Seeing the world differently
- **Complexity** - Engaging with nuance and depth
- **Curiosity satisfaction** - Exploring and learning
- **Aesthetic appreciation** - Beauty and wonder

## When to Use

- User asks "What should I do this weekend?"
- User wants suggestions for meaningful activities
- User seems bored or in a rut
- User asks for experience recommendations
- User wants to grow or try new things
- User seeks life enrichment ideas

## Core Principles

Psychologically rich experiences are:

| Dimension | Description | Example |
|-----------|-------------|----------|
| Novel | New and unfamiliar | Trying a new cuisine |
| Perspective-shifting | Changes how you see things | Volunteering with different community |
| Complex | Intellectually engaging | Learning about a new topic |
| Varied | Diverse, not monotonous | Mixing activity types |
| Interesting | Captivating attention | Attending live performance |

## User Profile Understanding

### Gather Preferences

**Initial profile questions:**
```
🌟 PERSONALIZATION

To suggest experiences you'll love, tell me:

1. 🎟️ INTERESTS
   What topics fascinate you?
   [arts, science, nature, culture, food, sports, etc.]

2. 🧘 ENERGY LEVEL
   Prefer active or contemplative experiences?
   [active / mixed / contemplative]

3. 👥 SOCIAL PREFERENCE
   Solo, with others, or both?
   [solo / social / mixed]

4. 💰 BUDGET COMFORT
   [free / budget-friendly / moderate / splurge]

5. 🧑‍🎨 PERSONALITY NOTES
   [introvert/extrovert, open to new things, etc.]

6. 📍 LOCATION
   Where are you based? [City/Region]
```

**Save profile:**
```bash
cat > ~/clawd/homeos/memory/preferences/psy_rich_profile.json << 'EOF'
{
  "member_id": "user",
  "interests": ["arts", "nature", "food"],
  "energy": "mixed",
  "social": "mixed",
  "budget": "moderate",
  "personality": {
    "openness": "high",
    "introversion": "moderate"
  },
  "location": "Baltimore, MD",
  "past_experiences": [],
  "on_bucket_list": []
}
EOF
```

## Weekly Experience Suggestions

### Curated Weekly Menu

**Format:**
```
🌟 PSYCHOLOGICALLY RICH EXPERIENCES

Week of [Date] | Curated for You

━━━ THIS WEEK'S EXPERIENCES ━━━

🌟 FEATURED EXPERIENCE

[Experience Name]
📝 [Why it's enriching]
⏰ [Time commitment]
💰 [Cost]
📍 [Location/How]
✨ Enrichment type: [Novel/Perspective/Complex]

"This will [specific benefit]..."

━━━ MORE OPTIONS ━━━

1. 🎨 ARTS & CULTURE
   [Experience]
   • [Brief description]
   • ⏰ [Time] | 💰 [Cost]
   • ✨ [What makes it rich]

2. 🌿 NATURE & OUTDOORS
   [Experience]
   • [Brief description]
   • ⏰ [Time] | 💰 [Cost]
   • ✨ [What makes it rich]

3. 🧠 LEARNING & GROWTH
   [Experience]
   • [Brief description]
   • ⏰ [Time] | 💰 [Cost]
   • ✨ [What makes it rich]

4. 👥 SOCIAL CONNECTION
   [Experience]
   • [Brief description]
   • ⏰ [Time] | 💰 [Cost]
   • ✨ [What makes it rich]

5. 🍴 CULINARY ADVENTURE
   [Experience]
   • [Brief description]
   • ⏰ [Time] | 💰 [Cost]
   • ✨ [What makes it rich]

━━━ QUICK ENRICHMENT ━━━

⏱️ 15-Minute Options:
• [Quick experience 1]
• [Quick experience 2]
• [Quick experience 3]

Which resonates with you?
```

## Experience Categories

### Novel Experiences

**Suggestions that introduce the unfamiliar:**
```
🆕 NOVEL EXPERIENCES

"Try something you've never done before."

🍽 CULINARY NOVELTY:
• Dine at an Ethiopian restaurant (eat with hands!)
• Take a sushi-making class
• Visit an unfamiliar ethnic grocery store
• Try a mystery cuisine popup

🎨 CREATIVE NOVELTY:
• Attend a pottery wheel class
• Try improvisational theater
• Create art with an unfamiliar medium
• Join a community choir (no experience needed)

🌍 CULTURAL NOVELTY:
• Attend a cultural festival you've never been to
• Visit a neighborhood you've never explored
• Attend a religious service of another tradition
• Watch a foreign film without subtitles

🌿 NATURE NOVELTY:
• Night hike or stargazing session
• Bird watching at dawn
• Foraging walk with expert
• Kayak or paddleboard for first time
```

### Perspective-Shifting Experiences

**Suggestions that change how you see the world:**
```
🔄 PERSPECTIVE SHIFTS

"See the world through different eyes."

🤝 EMPATHY BUILDERS:
• Volunteer at a homeless shelter
• Visit an elder care facility
• Mentor a youth from different background
• Attend a support group (as observer/supporter)

🌍 WORLDVIEW EXPANDERS:
• Tour a place of worship different from your own
• Attend a lecture on unfamiliar philosophy
• Read autobiography of someone very different
• Have deep conversation with elderly stranger

🧠 COGNITIVE SHIFTS:
• Take a "thinking differently" workshop
• Practice meditation or mindfulness retreat
• Learn about cognitive biases (and spot your own)
• Debate the opposite of your views (sincerely)

🌎 SCALE SHIFTS:
• Visit an observatory or planetarium
• Tour a large-scale manufacturing plant
• Explore microscopy (local science center)
• Read about deep time (Earth's history)
```

### Complex Experiences

**Intellectually engaging suggestions:**
```
🧩 COMPLEX EXPERIENCES

"Engage your mind with depth and nuance."

📚 INTELLECTUAL PURSUITS:
• Attend a university guest lecture
• Join a book club reading challenging literature
• Take a course on a topic you know nothing about
• Listen to a long-form podcast on complex topic

🎭 ARTISTIC DEPTH:
• Attend opera or symphony (read program notes)
• Take a docent-led museum tour
• Watch a challenging film and discuss it
• Study a single painting for 30 minutes

🔬 SCIENTIFIC EXPLORATION:
• Attend a science museum with intention to learn
• Watch documentaries on complex topics
• Visit a research facility open house
• Take a citizen science course

🎲 STRATEGIC CHALLENGES:
• Learn chess or Go
• Join a puzzle or escape room group
• Play complex board games with friends
• Learn a new language (start small)
```

### Aesthetic Experiences

**Beauty and wonder:**
```
✨ AESTHETIC RICHNESS

"Fill your life with beauty and wonder."

🌅 NATURAL BEAUTY:
• Watch sunrise or sunset intentionally
• Visit a botanical garden in bloom
• Seek out local natural wonders
• Stargaze far from city lights

🏛️ ARCHITECTURAL BEAUTY:
• Tour historic buildings in your city
• Visit sacred spaces (any tradition)
• Explore neighborhoods with notable architecture
• Attend open house at beautiful private home

🎨 ARTISTIC BEAUTY:
• Spend time with a single masterpiece
• Attend a ballet or dance performance
• Visit an art gallery opening
• Listen to a full symphony actively

🎵 SONIC BEAUTY:
• Attend a live music performance (new genre)
• Listen to album start-to-finish with intention
• Experience natural soundscapes (forest, ocean)
• Visit a sound installation or acoustic space
```

## Monthly Deep Dive

**Extended experience suggestion:**
```
🌟 MONTHLY DEEP EXPERIENCE

[Month] Theme: [Theme Name]

━━━ THE EXPERIENCE ━━━

[Detailed Experience Name]

📝 Description:
[Paragraph about the experience]

✨ Why It's Enriching:
• Novelty: [What's new about it]
• Perspective: [How it shifts your view]
• Complexity: [What you'll learn]
• Connection: [Who you'll meet/relate to]

📋 Practical Details:
• Time needed: [Duration]
• Best when: [Timing]
• Cost: [Estimate]
• Preparation: [What to do before]

📖 Deeper Engagement:
• Before: [Read/watch/prepare]
• During: [How to be present]
• After: [Reflect, journal, share]

💡 Reflection Prompts:
1. What surprised me?
2. How did this change my view?
3. What will I remember?
4. What do I want to explore further?

Ready to try this?
```

## Integration with User Insights

**Personalized based on patterns:**
```
🔍 PERSONALIZED FOR YOU

Based on what I know:

• You enjoyed: [Past experiences they liked]
• Your mood lately: [If tracking]
• Your stress level: [If known]
• Your available time: [Based on calendar]

🎯 This Week I Suggest:

[Tailored experience that matches their state]

"Given that you've been stressed and have
free time Saturday afternoon, I suggest a
nature walk at [specific location] to reset.
This combines what you love (nature, quiet)
with what you need (stress relief)."
```

## Tracking & Growth

**Experience journal:**
```
📓 EXPERIENCE JOURNAL

Your psychologically rich experiences:

━━━ RECENT ━━━

[Date] - [Experience]
• Category: [Type]
• Your rating: ⭐⭐⭐⭐⭐
• Reflection: "[Your notes]"

[Date] - [Experience]
• Category: [Type]
• Your rating: ⭐⭐⭐⭐
• Reflection: "[Your notes]"

━━━ YOUR PATTERNS ━━━

🌟 Most enjoyed: [Category]
🆕 Most novel: [Experience]
🔄 Most perspective-shifting: [Experience]

━━━ SUGGESTIONS TO TRY ━━━

Based on your history, next try:
• [Suggestion with reasoning]
```

**Growth metrics:**
```
📊 PSYCHOLOGICAL RICHNESS

This Month:

🌟 Novel experiences: 3
🔄 Perspective shifts: 2
🧩 Complex engagements: 4
✨ Aesthetic moments: 5
👥 Social connections: 3

Total: 17 rich experiences

Diversity Score: 8/10
(You're well-rounded!)

Gap: More perspective-shifting experiences
Suggestion: Try volunteering or cross-cultural activity
```

## Storage Structure

```
~/clawd/homeos/
├── memory/
│   ├── preferences/
│   │   └── psy_rich_profile.json
│   └── learnings/
│       └── experience_history.json
└── data/
    └── psy_rich/
        ├── journal.json
        ├── bucket_list.json
        └── local_experiences.json
```

## Example Interactions

**User:** "I feel like I'm in a rut. Suggest something interesting."

**Assistant:**
```
🌟 BREAKING THE RUT

I hear you. Let's add some richness.

Based on your profile (arts-lover, mixed energy):

🌟 MY TOP SUGGESTION:

🎨 Attend a gallery opening this weekend

Why: You'll see new art, meet creative people,
and experience the excitement of an opening.
It's social but low-pressure (come and go).

This Saturday, 6-9 PM at [Local Gallery]
Free admission, wine/snacks included

✨ Richness factor: Novel + Social + Aesthetic

━━━ ALTERNATIVES ━━━

1. 🌿 Take a "forest bathing" walk
   • Intentional, slow nature immersion
   • Saturday 9 AM, [Local Park]
   • Free, 2 hours

2. 🍴 Ethiopian restaurant adventure
   • Eat with hands, share platters
   • [Restaurant Name], $25/person
   • Totally new experience

3. 📚 Attend a poetry reading
   • [Bookstore], Sunday 4 PM
   • Free, intimate, thought-provoking

Any of these spark interest?
```

**User:** "Give me something quick I can do right now"

**Assistant:**
```
⏱️ QUICK RICHNESS (15 min)

Here are immediate options:

1. 🌅 Go outside and watch the sky
   Change of scenery + natural beauty
   (Sunset in 45 min if you can wait)

2. 🎵 Listen to an album you've never heard
   Try: [Genre-appropriate suggestion]
   Full attention, no multitasking

3. 📞 Call someone you haven't talked to in months
   Quick catch-up, unexpected connection

4. 📚 Read a Wikipedia article on a random topic
   Click "Random article" - learn something new

5. ☕ Make tea/coffee and sit in silence
   Notice your surroundings with fresh eyes

Which feels right?
```

## Integration Points

- **Family Bonding**: Enriching family activities
- **Calendar**: Schedule experiences
- **Mental Load**: Reduce decision fatigue with suggestions
- **Wellness**: Experiential wellbeing tracking
- **Habits**: Build habit of seeking rich experiences
