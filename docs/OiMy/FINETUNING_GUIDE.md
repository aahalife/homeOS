# OiMy FunctionGemma Fine-Tuning Guide

This guide walks through fine-tuning Gemma models for OiMy's on-device intent classification and function calling capabilities.

## Overview

OiMy uses two fine-tuned models:

| Model | Base | Purpose | Size |
|-------|------|---------|------|
| **OiMy-Intent** | gemma-2-2b-it | Classify user messages → skill routing | ~1.5GB |
| **OiMy-Functions** | codegemma-2b | Generate structured function calls | ~1.5GB |

Why fine-tune?
- **Better accuracy** on family/household domain vs. general models
- **Faster inference** with domain-specific patterns baked in
- **Smaller context** needed (no few-shot examples required)

## Prerequisites

### Software
- Google Colab Pro (for A100/V100 GPU access)
- Python 3.10+
- Hugging Face account with model access

### Access Tokens
```bash
# Get from https://huggingface.co/settings/tokens
export HF_TOKEN="hf_..."

# Accept model licenses:
# - https://huggingface.co/google/gemma-2-2b-it
# - https://huggingface.co/google/codegemma-2b
```

### Training Data
From this repo:
- `training-data/intent-classification.jsonl` (500+ examples)
- `training-data/function-calling.jsonl` (300+ examples)
- `training-data/multi-turn.jsonl` (100+ examples)

## Google Colab Setup

Create a new Colab notebook with GPU runtime (A100 recommended):

```python
# Cell 1: Install dependencies
!pip install -q transformers datasets peft accelerate bitsandbytes trl

# Cell 2: Login to Hugging Face
from huggingface_hub import login
login(token="hf_YOUR_TOKEN")

# Cell 3: Clone training data
!git clone https://github.com/aahalife/homeOS.git
%cd homeOS/docs/OiMy/training-data
```

## Part 1: Intent Classification Model

### Load and Prepare Data

```python
# Cell 4: Load intent classification data
import json
from datasets import Dataset

def load_jsonl(path):
    with open(path, 'r') as f:
        return [json.loads(line) for line in f]

intent_data = load_jsonl('intent-classification.jsonl')

# Format for instruction tuning
def format_intent_example(example):
    return {
        "text": f"""<start_of_turn>user
Classify this message into one of the OiMy skills: {example['input']}<end_of_turn>
<start_of_turn>model
{example['output']}<end_of_turn>"""
    }

intent_dataset = Dataset.from_list([format_intent_example(ex) for ex in intent_data])

# Train/val split
intent_dataset = intent_dataset.train_test_split(test_size=0.1, seed=42)
print(f"Train: {len(intent_dataset['train'])}, Val: {len(intent_dataset['test'])}")
```

### Configure LoRA Fine-Tuning

```python
# Cell 5: Load base model with 4-bit quantization
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig

model_id = "google/gemma-2-2b-it"

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True,
)

tokenizer = AutoTokenizer.from_pretrained(model_id)
tokenizer.pad_token = tokenizer.eos_token

model = AutoModelForCausalLM.from_pretrained(
    model_id,
    quantization_config=bnb_config,
    device_map="auto",
    torch_dtype=torch.bfloat16,
)

# Cell 6: Configure LoRA
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training

model = prepare_model_for_kbit_training(model)

lora_config = LoraConfig(
    r=16,                      # LoRA rank
    lora_alpha=32,             # LoRA alpha
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
)

model = get_peft_model(model, lora_config)
model.print_trainable_parameters()
# Expected: ~0.5% trainable parameters
```

### Train Intent Model

```python
# Cell 7: Training configuration
from transformers import TrainingArguments
from trl import SFTTrainer

training_args = TrainingArguments(
    output_dir="./oimy-intent-lora",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    weight_decay=0.01,
    warmup_ratio=0.03,
    lr_scheduler_type="cosine",
    logging_steps=10,
    save_strategy="epoch",
    evaluation_strategy="epoch",
    bf16=True,
    gradient_checkpointing=True,
    optim="paged_adamw_8bit",
    report_to="none",
)

# Cell 8: Train
trainer = SFTTrainer(
    model=model,
    args=training_args,
    train_dataset=intent_dataset['train'],
    eval_dataset=intent_dataset['test'],
    tokenizer=tokenizer,
    dataset_text_field="text",
    max_seq_length=256,
    packing=False,
)

trainer.train()

# Cell 9: Save LoRA weights
trainer.save_model("./oimy-intent-lora")
```

## Part 2: Function Calling Model

### Load and Prepare Data

```python
# Cell 10: Load function calling data
function_data = load_jsonl('function-calling.jsonl')

def format_function_example(example):
    return {
        "text": f"""<start_of_turn>user
Generate a function call for: {example['input']}<end_of_turn>
<start_of_turn>model
{{"function": "{example['function']}", "arguments": {json.dumps(example['arguments'])}}}<end_of_turn>"""
    }

function_dataset = Dataset.from_list([format_function_example(ex) for ex in function_data])
function_dataset = function_dataset.train_test_split(test_size=0.1, seed=42)
```

### Train Function Model

```python
# Cell 11: Load CodeGemma for function calling
model_id = "google/codegemma-2b"

# Same quantization and LoRA config as above
model = AutoModelForCausalLM.from_pretrained(
    model_id,
    quantization_config=bnb_config,
    device_map="auto",
    torch_dtype=torch.bfloat16,
)

model = prepare_model_for_kbit_training(model)
model = get_peft_model(model, lora_config)

# Cell 12: Train
training_args.output_dir = "./oimy-functions-lora"

trainer = SFTTrainer(
    model=model,
    args=training_args,
    train_dataset=function_dataset['train'],
    eval_dataset=function_dataset['test'],
    tokenizer=tokenizer,
    dataset_text_field="text",
    max_seq_length=512,  # Longer for function args
    packing=False,
)

trainer.train()
trainer.save_model("./oimy-functions-lora")
```

## Evaluation

### Intent Classification Accuracy

```python
# Cell 13: Evaluate intent model
from tqdm import tqdm

model.eval()
correct = 0
total = 0

# Load test data
test_data = load_jsonl('intent-classification.jsonl')[-50:]  # Last 50 as test

for example in tqdm(test_data):
    prompt = f"<start_of_turn>user\nClassify this message into one of the OiMy skills: {example['input']}<end_of_turn>\n<start_of_turn>model\n"
    
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    outputs = model.generate(**inputs, max_new_tokens=20, do_sample=False)
    prediction = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    # Extract predicted skill
    predicted_skill = prediction.split("<start_of_turn>model\n")[-1].strip().split()[0]
    
    if predicted_skill == example['output']:
        correct += 1
    total += 1

print(f"Intent Accuracy: {correct/total*100:.1f}%")
# Target: >95%
```

### Function Calling Evaluation

```python
# Cell 14: Evaluate function calling
import json

def evaluate_function_call(predicted, expected):
    """Returns (exact_match, partial_match)"""
    try:
        pred = json.loads(predicted)
        exp = expected
        
        # Exact match
        if pred == exp:
            return (1, 1)
        
        # Partial match: correct function name
        if pred.get('function') == exp['function']:
            return (0, 1)
        
        return (0, 0)
    except:
        return (0, 0)

# Run evaluation on test set
exact_matches = 0
partial_matches = 0
total = 0

for example in function_data[-30:]:  # Last 30 as test
    prompt = f"<start_of_turn>user\nGenerate a function call for: {example['input']}<end_of_turn>\n<start_of_turn>model\n"
    
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    outputs = model.generate(**inputs, max_new_tokens=200, do_sample=False)
    prediction = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    # Extract JSON
    pred_json = prediction.split("<start_of_turn>model\n")[-1].strip()
    
    exact, partial = evaluate_function_call(pred_json, {"function": example['function'], "arguments": example['arguments']})
    exact_matches += exact
    partial_matches += partial
    total += 1

print(f"Exact Match: {exact_matches/total*100:.1f}%")
print(f"Partial Match (correct function): {partial_matches/total*100:.1f}%")
# Target: >80% exact, >90% partial
```

## Export for iOS

### Merge LoRA Weights

```python
# Cell 15: Merge and save full model
from peft import PeftModel

# Intent model
base_model = AutoModelForCausalLM.from_pretrained(
    "google/gemma-2-2b-it",
    torch_dtype=torch.float16,
    device_map="cpu",
)
lora_model = PeftModel.from_pretrained(base_model, "./oimy-intent-lora")
merged_model = lora_model.merge_and_unload()

merged_model.save_pretrained("./oimy-intent-merged")
tokenizer.save_pretrained("./oimy-intent-merged")
```

### Convert to MediaPipe Format

For iOS deployment via MediaPipe LLM Inference:

```bash
# Cell 16: Convert to TFLite
!pip install -q ai-edge-torch

# Note: Actual conversion requires additional steps specific to MediaPipe
# See: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference
```

Alternative: Use GGUF format with llama.cpp bindings:

```bash
# Convert to GGUF
!pip install -q llama-cpp-python

# Quantize for mobile (Q4_K_M is good balance of size/quality)
!python -m llama_cpp.convert ./oimy-intent-merged --outtype q4_k_m --outfile oimy-intent.gguf
```

### Model File Sizes

| Model | Format | Size | Notes |
|-------|--------|------|-------|
| OiMy-Intent | GGUF Q4_K_M | ~1.5GB | Good quality/size balance |
| OiMy-Intent | GGUF Q4_0 | ~1.2GB | Smaller, slight quality loss |
| OiMy-Functions | GGUF Q4_K_M | ~1.5GB | Good for structured output |

## Deployment to iOS

### Model Files Location

```
HomeOS.app/
└── Resources/
    └── Models/
        ├── oimy-intent.gguf      # Intent classification
        └── oimy-functions.gguf   # Function calling
```

### Swift Integration

```swift
// In LLMBridge implementation
class OiMyLLMBridge: LLMBridge {
    private let intentModel: LlamaModel
    private let functionsModel: LlamaModel
    
    init() throws {
        let bundle = Bundle.main
        
        // Load models from bundle
        guard let intentPath = bundle.path(forResource: "oimy-intent", ofType: "gguf"),
              let functionsPath = bundle.path(forResource: "oimy-functions", ofType: "gguf") else {
            throw LLMError.modelNotFound
        }
        
        self.intentModel = try LlamaModel(path: intentPath)
        self.functionsModel = try LlamaModel(path: functionsPath)
    }
    
    func classifyIntent(_ message: String) async throws -> String {
        let prompt = "<start_of_turn>user\nClassify this message into one of the OiMy skills: \(message)<end_of_turn>\n<start_of_turn>model\n"
        return try await intentModel.generate(prompt: prompt, maxTokens: 20)
    }
    
    func generateFunctionCall(_ message: String) async throws -> FunctionCall {
        let prompt = "<start_of_turn>user\nGenerate a function call for: \(message)<end_of_turn>\n<start_of_turn>model\n"
        let json = try await functionsModel.generate(prompt: prompt, maxTokens: 200)
        return try JSONDecoder().decode(FunctionCall.self, from: json.data(using: .utf8)!)
    }
}
```

### OTA Model Updates

For updating models without app store release:

```swift
class ModelUpdater {
    private let modelURL = URL(string: "https://storage.googleapis.com/oimy-models/")!
    
    func checkForUpdates() async throws -> Bool {
        // Check version manifest
        let manifest = try await fetchManifest()
        return manifest.version > currentVersion
    }
    
    func downloadUpdate() async throws {
        // Download to app's Documents directory
        // Verify checksum
        // Swap model files atomically
    }
}
```

## A/B Testing New Models

```swift
class ModelABTest {
    enum Variant { case control, treatment }
    
    func selectVariant(userId: String) -> Variant {
        // Consistent hashing for user
        let hash = userId.hash % 100
        return hash < 10 ? .treatment : .control  // 10% in treatment
    }
    
    func logResult(variant: Variant, intent: String, correct: Bool) {
        // Log to analytics
        Analytics.log(event: "intent_classification", params: [
            "variant": variant.rawValue,
            "intent": intent,
            "correct": correct
        ])
    }
}
```

## Continuous Improvement

### Training Data Pipeline

1. **Collect** — Log anonymized user interactions (with consent)
2. **Label** — Use cloud LLM (Opus) to label edge cases
3. **Augment** — Add labeled data to training set
4. **Retrain** — Weekly fine-tuning runs
5. **Evaluate** — Compare metrics to previous model
6. **Deploy** — Roll out via OTA if improved

### Monitoring

Track these metrics in production:
- Intent classification accuracy (via user corrections)
- Function call success rate
- Fallback to cloud rate (should decrease over time)
- Latency p50/p95

## Troubleshooting

### Out of Memory on Colab
- Use gradient checkpointing (enabled above)
- Reduce batch size to 2
- Use Colab Pro for more RAM

### Poor Intent Accuracy
- Check for class imbalance in training data
- Add more examples for underperforming skills
- Increase training epochs

### Function Calls Missing Arguments
- Add more examples with optional arguments
- Explicitly list required vs. optional in prompts
- Consider separate model for argument extraction

---

## Quick Reference

| Task | Command |
|------|---------|
| Start training | `trainer.train()` |
| Save checkpoint | `trainer.save_model("./checkpoint")` |
| Resume training | `trainer.train(resume_from_checkpoint="./checkpoint")` |
| Convert to GGUF | `python -m llama_cpp.convert ... --outtype q4_k_m` |
| Evaluate | Run cells 13-14 above |

## Resources

- [Gemma Fine-Tuning Guide](https://ai.google.dev/gemma/docs/fine_tuning)
- [LoRA Paper](https://arxiv.org/abs/2106.09685)
- [QLoRA Paper](https://arxiv.org/abs/2305.14314)
- [MediaPipe LLM Inference](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference)
- [llama.cpp iOS Guide](https://github.com/ggerganov/llama.cpp/tree/master/examples/llama.swiftui)
