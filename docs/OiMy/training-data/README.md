# OiMy FunctionGemma Training Dataset

This directory contains training data for fine-tuning Google's FunctionGemma model to power OiMy's on-device intent classification and function calling.

## Overview

OiMy (HomeOS) is a family assistant that handles 20+ skill domains. These datasets train a small language model (Gemma 3n / FunctionGemma) to:

1. **Classify user intent** → Route to the correct skill
2. **Generate function calls** → Execute specific actions with structured arguments
3. **Handle multi-turn conversations** → Gather information and maintain context

## Dataset Files

### 1. `intent-classification.jsonl`
**Purpose:** Train the model to classify user messages into one of 20 skill categories.

**Format:**
```json
{"input": "What should we have for dinner?", "output": "meal-planning"}
{"input": "Emma has a fever", "output": "healthcare"}
```

**Statistics:**
- 500+ examples
- 20 skill categories
- 25+ examples per skill
- Includes direct, indirect, and edge-case phrasings

**Skills covered:**
| Skill | ID | Example Trigger |
|-------|-----|-----------------|
| Meal Planning | `meal-planning` | "What's for dinner?" |
| Healthcare | `healthcare` | "I have a headache" |
| Transportation | `transportation` | "How long to work?" |
| Restaurant Reservation | `restaurant-reservation` | "Book a table for 4" |
| Elder Care | `elder-care` | "Check on mom" |
| Mental Load | `mental-load` | "I'm overwhelmed" |
| Tools (Calendar/Reminders) | `tools` | "Remind me at 5pm" |
| Habits | `habits` | "I want to build a habit" |
| Family Bonding | `family-bonding` | "What should we do this weekend?" |
| Family Communications | `family-comms` | "Tell everyone dinner is ready" |
| School | `school` | "How are the kids doing in school?" |
| Education | `education` | "Help Emma with homework" |
| Wellness | `wellness` | "How much water have I had?" |
| Home Maintenance | `home-maintenance` | "The dishwasher is broken" |
| Hire Helper | `hire-helper` | "Find a babysitter" |
| Marketplace Sell | `marketplace-sell` | "Sell my old couch" |
| Telephony | `telephony` | "Call the dentist office" |
| Note to Actions | `note-to-actions` | "Turn this article into habits" |
| Psy Rich | `psy-rich` | "We need something meaningful to do" |
| Infrastructure | `infrastructure` | (System routing) |

### 2. `function-calling.jsonl`
**Purpose:** Train the model to generate structured function calls with appropriate arguments.

**Format:**
```json
{"input": "Book a table at an Italian restaurant for Saturday 7pm, 4 people", "function": "restaurant_search", "arguments": {"cuisine": "italian", "date": "Saturday", "time": "19:00", "party_size": 4}}
```

**Statistics:**
- 300+ examples
- 20+ function types
- Various argument combinations

**Key Functions:**
| Function | Description | Key Arguments |
|----------|-------------|---------------|
| `calendar_create` | Create calendar event | title, date, time, duration, location |
| `calendar_read` | View calendar | date, range |
| `calendar_delete` | Delete event | event_id, title |
| `reminder_create` | Set a reminder | task, time, recurring |
| `medication_reminder` | Med reminder | member, medication, time |
| `medication_refill` | Request refill | medication, pharmacy |
| `meal_suggest` | Suggest meals | dietary, time_available, servings |
| `grocery_list` | Generate shopping list | meal_plan, store |
| `symptom_triage` | Assess symptoms | symptoms, member, severity |
| `phone_call` | Make AI call | business, number, purpose, requires_approval |
| `family_announcement` | Send announcement | message, recipients, priority |
| `activity_suggest` | Suggest activities | participants, budget, indoor |
| `habit_checkin` | Check habit status | habit_name, member |
| `school_check` | Check school status | child, scope |
| `elder_checkin` | Check on elder | parent, type |
| `listing_create` | Create marketplace listing | item, price, condition |
| `web_search` | Search the web | query |
| `weather_check` | Get weather | location |

### 3. `multi-turn.jsonl`
**Purpose:** Train the model to handle conversations that span multiple turns, including information gathering, skill handoffs, and approval flows.

**Format:**
```json
{
  "conversation": [
    {"role": "user", "content": "I want to make a dinner reservation"},
    {"role": "assistant", "content": "I'd be happy to help! A few details needed:\n1. Date and time?\n2. How many people?\n3. Any cuisine preference?"},
    {"role": "user", "content": "Saturday at 7, party of 4, somewhere Italian"},
    {"role": "assistant", "content": "...", "function_call": {"name": "restaurant_search", "arguments": {...}}}
  ],
  "skills_used": ["restaurant-reservation"]
}
```

**Statistics:**
- 100+ conversations
- Average 4-6 turns per conversation
- Covers approval flows, clarifications, and skill handoffs

## Usage

### For Fine-Tuning

1. **Load the data:**
```python
import json

def load_jsonl(path):
    with open(path, 'r') as f:
        return [json.loads(line) for line in f]

intent_data = load_jsonl('intent-classification.jsonl')
function_data = load_jsonl('function-calling.jsonl')
multi_turn_data = load_jsonl('multi-turn.jsonl')
```

2. **Convert to training format:**
```python
# For intent classification
def format_intent_example(ex):
    return {
        "prompt": f"Classify the user intent: {ex['input']}\n\nIntent:",
        "completion": f" {ex['output']}"
    }

# For function calling
def format_function_example(ex):
    return {
        "prompt": f"User: {ex['input']}\n\nGenerate function call:",
        "completion": f" {ex['function']}({json.dumps(ex['arguments'])})"
    }
```

3. **Train with Hugging Face Transformers:**
```python
from transformers import AutoModelForCausalLM, AutoTokenizer, Trainer

model = AutoModelForCausalLM.from_pretrained("google/gemma-3n-E2B-it")
# See FINETUNING_GUIDE.md for full instructions
```

### For Evaluation

Split the data 80/20 for train/test:
```python
from sklearn.model_selection import train_test_split

train, test = train_test_split(data, test_size=0.2, random_state=42)
```

### Data Augmentation

To expand the dataset:
1. Paraphrase existing examples using an LLM
2. Generate variations with different names/dates
3. Add typos and informal language for robustness

## Design Principles

### 1. Family Context
Examples assume a family context with:
- Parents (often working, managing household)
- Children of various ages (toddlers to teens)
- Possibly elderly parents requiring care
- Dietary restrictions, allergies, schedules

### 2. Natural Language Variation
Each skill includes:
- **Direct triggers:** "Set a reminder" → tools
- **Indirect triggers:** "Don't let me forget" → tools
- **Conversational:** "You know what, I should probably..." → tools
- **Urgent:** "ASAP!" / "Emergency!" → appropriate skill

### 3. Safety-Aware
- High-risk actions (phone calls, purchases) are flagged with `requires_approval: true`
- Medical queries include appropriate disclaimers
- Child safety is prioritized

### 4. Edge Cases
- Ambiguous intents that could match multiple skills
- Multi-intent messages (labeled with primary intent)
- Incomplete information requiring follow-up

## File Integrity

Validate the JSONL files:
```bash
# Check each line is valid JSON
python -c "import json; [json.loads(l) for l in open('intent-classification.jsonl')]"
python -c "import json; [json.loads(l) for l in open('function-calling.jsonl')]"
python -c "import json; [json.loads(l) for l in open('multi-turn.jsonl')]"
```

## Contributing

When adding new examples:
1. Ensure diverse phrasing (don't repeat patterns)
2. Cover edge cases and ambiguous inputs
3. Match real family scenarios
4. Test that JSON is valid before committing

## License

This dataset is provided for training OiMy/HomeOS models. See the main repository LICENSE for terms.
