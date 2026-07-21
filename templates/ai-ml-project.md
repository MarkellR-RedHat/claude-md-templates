# CLAUDE.md - AI/ML Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Replace model references with your actual model name (e.g., Llama 3, Granite) -->
<!-- TODO: Set your ML framework (PyTorch, JAX, TensorFlow) -->
<!-- TODO: Set your serving backend (vLLM, TGI, Triton, KServe) -->
<!-- TODO: Set your GPU type (NVIDIA A100, H100, AMD MI300X) -->
<!-- TODO: Update CUDA/ROCm version to match your environment -->

## Project Overview

This is an AI/ML project. It may involve model training, fine-tuning, inference serving, or data pipeline work. The codebase follows standard Python conventions with additional considerations for GPU workloads, model artifacts, reproducibility, and production safety.

## Tech Stack

- **Model Serving**: vLLM, TGI (Text Generation Inference), Triton Inference Server, KServe
- **ML Frameworks**: PyTorch, HuggingFace Transformers, TensorFlow (legacy)
- **Fine-Tuning**: PEFT (LoRA, QLoRA), TRL, Axolotl
- **Data Processing**: Pandas, Polars, Apache Spark
- **Data Versioning**: DVC, LakeFS
- **Feature Store**: Feast, Tecton
- **Vector Databases**: Milvus, Qdrant, pgvector, Weaviate
- **Experiment Tracking**: MLflow, Weights & Biases
- **Model Registry**: MLflow Model Registry, HuggingFace Hub
- **Orchestration**: Kubeflow Pipelines, Airflow, Tekton
- **Container Runtime**: Podman, Docker
- **Platform**: Kubernetes, OpenShift
- **Monitoring**: Prometheus, Grafana, OpenTelemetry

## Code Conventions

### Python Style
- Follow PEP 8. Use `ruff` for linting and formatting.
- Use type hints on all function signatures.
- Use `pathlib.Path` instead of `os.path` for file path operations.
- Prefer `f-strings` over `.format()` or `%` string formatting.

### Model Code Organization
```
src/
  models/
    base.py              # Base model classes and interfaces
    inference.py         # Inference logic
    preprocessing.py     # Input preprocessing and tokenization
    registry.py          # Model registry client (MLflow, HF Hub)
  serving/
    server.py            # Model serving endpoints
    health.py            # Health check endpoints
    guardrails.py        # Input/output filtering and safety checks
    rate_limiter.py      # Rate limiting for inference endpoints
  training/
    trainer.py           # Training loop and distributed setup
    finetuning.py        # LoRA/QLoRA fine-tuning logic
    data_loader.py       # Dataset loading and preprocessing
    callbacks.py         # Training callbacks (checkpointing, logging)
  pipelines/
    training.py          # Training pipeline definitions
    evaluation.py        # Evaluation and benchmarking
    data_pipeline.py     # ETL for training data
  rag/
    retriever.py         # Retrieval logic (vector search, hybrid)
    chunker.py           # Document chunking strategies
    embedder.py          # Embedding model wrapper
    reranker.py          # Reranking retrieved results
  monitoring/
    drift.py             # Model drift detection
    metrics.py           # Custom metrics collection
  utils/
    gpu.py               # GPU detection and configuration
    logging.py           # Structured logging setup
    tokens.py            # Token counting and context management
configs/
  model_config.yaml
  serving_config.yaml
  training_config.yaml
tests/
  unit/
  integration/
  evaluation/             # Model quality benchmarks
  load/                   # Inference load tests
  fixtures/
data/
  raw/                    # Immutable source data (DVC-tracked)
  processed/              # Transformed training data
  eval/                   # Evaluation datasets (versioned)
model_cards/              # Model card documentation
```

### Configuration
- Use YAML for model and serving configuration files.
- Use environment variables for deployment-specific settings (GPU count, batch size, endpoints).
- Never hardcode model paths, API keys, or endpoint URLs.
- Use pydantic `BaseSettings` for configuration validation.
- Keep training hyperparameters in version-controlled YAML files, not in code.

### Model Artifacts
- Do not commit model weights, checkpoints, or large datasets to git.
- Add these entries to `.gitignore`:
  ```text
  *.pt *.pth *.bin *.safetensors *.gguf *.onnx
  checkpoints/ models/
  data/raw/ data/processed/ *.parquet *.arrow
  wandb/ mlruns/ outputs/
  *.nsys-rep *.ncu-rep *.qdrep nsight_reports/
  .ipynb_checkpoints/
  *.dvc /dvc.lock
  .env
  ```
- Store model artifacts in S3-compatible storage (e.g., MinIO on OpenShift) or HuggingFace Hub.
- Document the model source, version, and license in a `MODEL_CARD.md` file.

## Model Lifecycle Management

### Model Versioning

Every model artifact must be traceable back to the code, data, and configuration that produced it.

- Use semantic versioning: `MAJOR.MINOR.PATCH` (e.g., `v2.1.0`).
  - MAJOR: architecture change or training from scratch on new data.
  - MINOR: fine-tuning iteration, new training data, hyperparameter tuning.
  - PATCH: quantization variant, serving optimization, no quality change.
- Tag every model version with the git commit hash of the training code.
- Store model metadata alongside the artifact: training config, evaluation metrics, dataset hash.

### Model Registry

Use MLflow Model Registry or HuggingFace Hub to manage promotion stages.

```python
import mlflow

with mlflow.start_run():
    mlflow.log_params(training_config)
    mlflow.log_metrics(eval_metrics)
    mlflow.pytorch.log_model(model, artifact_path="model", registered_model_name="my-model")

# Promote through stages: Staging -> Production
client = mlflow.tracking.MlflowClient()
client.transition_model_version_stage(name="my-model", version=3, stage="Production")
```

### A/B Testing and Canary Deployments

When rolling out a new model version:

1. Deploy the new model as a canary receiving 5-10% of traffic.
2. Compare key metrics (latency, error rate, task-specific quality) against the baseline for at least 24 hours.
3. If metrics hold, ramp traffic: 25%, 50%, 100%.
4. Keep the previous version available for instant rollback.

On OpenShift, use Knative traffic splitting or Istio virtual services:
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: model-inference
spec:
  traffic:
    - revisionName: model-inference-v2
      percent: 90
    - revisionName: model-inference-v3
      percent: 10
```

### Model Card Requirements

Every model shipped to production must have a `MODEL_CARD.md` containing: model name, version, and architecture; training data summary (sources, size, date range, known biases); evaluation results on standard benchmarks; intended use cases and known limitations; ethical considerations and bias analysis; hardware requirements for inference; license and attribution.

## Training Best Practices

### Distributed Training

**DDP (Distributed Data Parallel)**: Use when the model fits on one GPU but training is slow.
```python
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP

dist.init_process_group(backend="nccl")
local_rank = int(os.environ["LOCAL_RANK"])
model = DDP(model.to(local_rank), device_ids=[local_rank])
```

**FSDP (Fully Sharded Data Parallel)**: Use when the model does not fit on a single GPU.
```python
from torch.distributed.fsdp import FullyShardedDataParallel as FSDP, ShardingStrategy

model = FSDP(model, sharding_strategy=ShardingStrategy.FULL_SHARD,
             mixed_precision=mixed_precision_policy, device_id=local_rank)
```

**DeepSpeed**: Use for large-scale training with ZeRO Stage 2/3 and CPU offloading. Configure via `ds_config.json`:
```json
{
  "zero_optimization": { "stage": 3, "offload_param": { "device": "cpu" } },
  "bf16": { "enabled": true },
  "gradient_accumulation_steps": 4,
  "train_micro_batch_size_per_gpu": 2
}
```

Launch with: `torchrun --nproc_per_node=4 --nnodes=1 train.py --config configs/training_config.yaml`

### Mixed Precision Training

Always use mixed precision unless you have a specific reason not to. Prefer `bfloat16` on Ampere+ GPUs (A100, H100) since it has better numerical range and does not require loss scaling. Use `float16` with `GradScaler` on older GPUs (V100, T4).

```python
from torch.amp import autocast, GradScaler
scaler = GradScaler("cuda")

for batch in dataloader:
    optimizer.zero_grad()
    with autocast("cuda", dtype=torch.bfloat16):
        loss = criterion(model(batch), targets)
    scaler.scale(loss).backward()
    scaler.step(optimizer)
    scaler.update()
```

### Gradient Accumulation

When your effective batch size does not fit in GPU memory:

```python
accumulation_steps = 8
for i, batch in enumerate(dataloader):
    with autocast("cuda", dtype=torch.bfloat16):
        loss = model(batch).loss / accumulation_steps
    loss.backward()
    if (i + 1) % accumulation_steps == 0:
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
        optimizer.step()
        optimizer.zero_grad()
```

### Checkpoint Management

- Save checkpoints at regular intervals, not just at the end of training.
- Include model state, optimizer state, scheduler state, and the current step.
- Keep the last N checkpoints and delete older ones to save disk space.
- Use `safetensors` format for faster, safer serialization.

### Training Reproducibility

Set all random seeds at the start of training:
```python
import random, numpy as np, torch

def set_seed(seed: int = 42):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    # For full determinism (has performance cost):
    # torch.use_deterministic_algorithms(True)
    # torch.backends.cudnn.benchmark = False
    # os.environ["CUBLAS_WORKSPACE_CONFIG"] = ":4096:8"
```

Log the full environment with every experiment: PyTorch version, CUDA version, GPU type, driver version, random seed, and all hyperparameters.

## Fine-Tuning

### LoRA and QLoRA

Use LoRA for parameter-efficient fine-tuning. Use QLoRA when GPU memory is the bottleneck.

```python
from peft import LoraConfig, get_peft_model, TaskType

lora_config = LoraConfig(
    task_type=TaskType.CAUSAL_LM,
    r=16,                          # Rank. Start with 8-16, increase if underfitting.
    lora_alpha=32,                 # Scaling factor. Typically 2x the rank.
    lora_dropout=0.05,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    bias="none",
)
model = get_peft_model(base_model, lora_config)
```

For QLoRA (4-bit quantized base + LoRA adapters):
```python
from transformers import BitsAndBytesConfig

bnb_config = BitsAndBytesConfig(
    load_in_4bit=True, bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16, bnb_4bit_use_double_quant=True,
)
base_model = AutoModelForCausalLM.from_pretrained(
    model_name, quantization_config=bnb_config, device_map="auto",
)
```

### Dataset Preparation for Fine-Tuning

- Format training data according to the model's expected chat template.
- Split into train/validation/test sets before any preprocessing.
- Deduplicate training examples. Near-duplicates cause overfitting.
- For instruction tuning, manually review a random sample (at least 100 examples) for clarity and correctness.
- Log dataset statistics: total examples, token length distribution, label distribution.

### Overfitting Detection

Watch for: validation loss increasing while training loss decreases; performance on held-out benchmarks degrading; model memorizing training examples verbatim.

Mitigations: reduce epochs (1-3 is typical for LLM fine-tuning), increase LoRA dropout, reduce LoRA rank, add more diverse training data, use early stopping based on validation loss.

### Evaluation Metrics

Define task-specific metrics before starting fine-tuning, not after.

- **Classification**: precision, recall, F1, ROC-AUC
- **Generation**: BLEU, ROUGE, BERTScore, human evaluation
- **Instruction following**: MT-Bench, AlpacaEval
- **Domain-specific**: define custom rubrics and have domain experts score outputs

Always compare against the base model (before fine-tuning) and report the delta.

## Inference Optimization

### Quantization Strategies

| Method       | Bits | Quality Loss | Speed Gain | When to Use                          |
|-------------|------|-------------|------------|--------------------------------------|
| BFloat16    | 16   | None        | Baseline   | Default for A100/H100                |
| AWQ         | 4    | Low         | 2-3x       | Production serving, best quality/speed ratio |
| GPTQ        | 4    | Low         | 2-3x       | When AWQ is not available for your model |
| bitsandbytes| 4/8  | Low-Medium  | 1.5-2x     | Quick experimentation, QLoRA training |
| GGUF        | 2-8  | Varies      | Varies     | CPU inference, edge deployment       |

### KV Cache Management

The KV cache is the primary memory bottleneck for long-context inference.

- Set `--gpu-memory-utilization` to control GPU memory reserved for KV cache (0.85-0.95).
- Use `--max-model-len` to cap sequence length and bound KV cache size.
- Enable prefix caching (`--enable-prefix-caching`) for workloads with shared system prompts. This avoids recomputing KV entries for common prefixes.
- Monitor KV cache utilization. If it consistently hits 100%, you need more GPU memory or a shorter max sequence length.

### Continuous Batching

vLLM and TGI use continuous batching by default, which is far more efficient than static batching for variable-length generation.

- `--max-num-seqs`: Maximum concurrent sequences. Higher values improve throughput at the cost of latency.
- `--max-num-batched-tokens`: Controls memory allocation per batch step.
- If the request queue is consistently deep, scale horizontally.

### Tensor Parallelism vs Pipeline Parallelism

- **Tensor parallelism** (TP): Splits each layer across GPUs. Lower latency per request. Use for latency-sensitive serving. Requires NVLink.
- **Pipeline parallelism** (PP): Assigns different layers to different GPUs. Higher throughput. Works over PCIe.
- For serving, prefer TP. For training very large models, combine TP and PP.
- TP degree should divide the number of attention heads evenly.

```bash
# TP across 4 GPUs
vllm serve /path/to/model --tensor-parallel-size 4
# Combined TP + PP
vllm serve /path/to/model --tensor-parallel-size 2 --pipeline-parallel-size 2
```

### Speculative Decoding

A small draft model proposes tokens that the large model verifies in parallel, reducing latency without changing output quality.

```bash
vllm serve /path/to/large-model \
    --speculative-model /path/to/draft-model --num-speculative-tokens 5
```

The draft model should be 5-10x smaller than the target but trained on similar data. Works best when the draft model has a high acceptance rate (> 70%).

## Security

### Prompt Injection Prevention

Never trust user input. Treat all prompts as potentially adversarial.

- Separate system instructions from user input using the model's designated roles (system, user, assistant).
- Do not concatenate user input directly into system prompts.
- Implement input validation to reject known injection patterns (role override attempts, instruction leaking probes).
- Set maximum input length limits at the API layer, before tokenization.
- Log suspicious inputs for security review.

### Output Filtering

- Filter model outputs before returning them to users.
- Check for PII leakage (SSNs, emails, phone numbers) in generated text using regex patterns. Redact matches.
- Apply content safety classifiers for public-facing applications.
- Log filtered outputs for monitoring and policy tuning.

### Model Access Control

- Authenticate all inference API requests. Use API keys or OAuth tokens.
- Implement role-based access control for model management operations (deploy, rollback, delete).
- Restrict model download access. Not every service that can call the model should be able to download its weights.
- Audit log all model registry operations (promotion, rollback, deletion).

### Data Privacy in Training Data

- Screen training data for PII before training. Use automated PII detection tools.
- Document data retention policies. Know when training data must be deleted.
- For models trained on user data, implement mechanisms for data removal requests.
- Never log full training examples in production monitoring.

### Rate Limiting

- Implement per-user and per-API-key rate limits.
- Use token-based rate limiting, not just request-count limiting. A single request can consume vastly different compute depending on input/output length.
- Return HTTP 429 with a `Retry-After` header when limits are exceeded.

### Adversarial Input Handling

- Reject inputs with excessive repetition (e.g., the same token repeated 1000 times), which can cause degenerate behavior.
- Implement timeout limits for inference. Kill requests that exceed the timeout.
- Monitor for inputs that consistently cause high latency or errors.

## GPU-Aware Development

### Local Development
- Always check for GPU availability:
  ```python
  device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
  ```
- Support CPU-only execution for development and testing. GPU should never be required to run the test suite.
- Use `CUDA_VISIBLE_DEVICES=0,1 python serve.py` to control GPU allocation.

### Testing on GPU
- Unit tests must run on CPU. Do not require a GPU for unit tests.
- Mark GPU integration tests with `@pytest.mark.gpu` and skip when no GPU is available.
- Use small model variants (tiny random-weight models) to keep test execution fast.

### Memory Management
- Monitor GPU memory usage, especially when loading large models.
- Use `torch.cuda.empty_cache()` judiciously, not as a fix for memory leaks.
- Profile with `torch.cuda.memory_summary()` during development.
- For multi-GPU setups, be explicit about tensor placement and parallelism strategy.

## Inference Serving

### API Design
- Expose health check endpoints at `/health` and `/ready`.
- Use `/v1/completions` or `/v1/chat/completions` for OpenAI-compatible APIs.
- Return structured error responses with meaningful error codes.
- Include request ID in all responses for tracing.

### vLLM Serving Configuration

```bash
python -m vllm.entrypoints.openai.api_server \
    --model /path/to/model \
    --tensor-parallel-size 2 \
    --max-model-len 4096 \
    --gpu-memory-utilization 0.90 \
    --enable-prefix-caching \
    --port 8000
```

| Parameter                  | Description                                    | Typical value |
|----------------------------|------------------------------------------------|---------------|
| `--tensor-parallel-size`   | Number of GPUs for tensor parallelism          | 1, 2, 4, or 8|
| `--max-model-len`          | Maximum sequence length                         | 4096 or 8192  |
| `--gpu-memory-utilization` | Fraction of GPU memory to use for KV cache     | 0.85 to 0.95  |
| `--enforce-eager`          | Disable CUDA graph capture (for debugging)      | off by default|
| `--max-num-seqs`           | Maximum concurrent sequences                   | 256           |
| `--enable-prefix-caching`  | Cache KV for shared prefixes                   | on for shared prompts |

For Kubernetes deployments, set these as container args in your Deployment manifest and expose port 8000 via a Service.

### Container Images
- Use a slim, well-maintained base image (the official CUDA runtime images for GPU workloads).
- Pin CUDA and cuDNN versions in the Dockerfile.
- Use multi-stage builds to keep the final image size reasonable.
- Include a non-root user in the container for security.

## Monitoring in Production

### Model Drift Detection

Model quality degrades over time as input distributions shift.

- **Data drift**: Compare incoming request distributions against training data using statistical tests (KS test, PSI) or distance metrics (KL divergence).
- **Prediction drift**: Track output distributions over time. A sudden shift in predicted class probabilities or generation patterns signals a problem.
- **Concept drift**: Monitor downstream task metrics (accuracy, user satisfaction) as ground truth becomes available.

Set up automated alerts when drift exceeds thresholds. Do not wait for user complaints.

### Data Quality Monitoring

- Validate inputs at serving time: check for missing fields, unexpected types, out-of-range values.
- Track input token length distributions. Sudden changes may indicate a new usage pattern or an attack.
- Monitor the fraction of requests that fail input validation. A spike means something changed upstream.

### Latency and Throughput Dashboards

Track these metrics and alert on regressions:

| Metric                        | Target           | Alert Threshold    |
|-------------------------------|------------------|--------------------|
| Time to first token (TTFT)    | < 200ms          | > 500ms            |
| Inter-token latency           | < 30ms/token     | > 50ms/token       |
| End-to-end latency (p95)      | < 2s             | > 5s               |
| Throughput (tokens/sec)       | GPU-dependent    | < 70% of baseline  |
| Request error rate            | < 0.1%           | > 1%               |
| Queue depth                   | < 10             | > 50               |

Export metrics via Prometheus:
```python
from prometheus_client import Histogram, Counter, Gauge

INFERENCE_LATENCY = Histogram("model_inference_latency_seconds", "Inference latency",
                              buckets=[0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0])
TOKENS_GENERATED = Counter("model_tokens_generated_total", "Total tokens generated")
GPU_MEMORY_USED = Gauge("gpu_memory_used_bytes", "GPU memory used", labelnames=["device"])
```

### GPU Utilization Tracking

- Monitor GPU utilization, memory usage, and temperature per device.
- Low GPU utilization (< 50%) during inference means your batching is not aggressive enough or your model is too small for the hardware.
- For production, use DCGM (Data Center GPU Manager) to export GPU metrics to Prometheus.

### Cost Optimization

- Track cost per 1000 tokens (input and output separately).
- Compare cost across quantization levels. A 4-bit model on fewer GPUs often beats full-precision on more GPUs.
- Use autoscaling based on queue depth, not just CPU utilization. Scale to zero during off-peak hours if traffic allows.
- Profile whether your workload is compute-bound or memory-bound to choose the right hardware.

## RAG Patterns

### Vector Database Selection

| Database  | Managed Option | Scale        | Best For                         |
|-----------|---------------|-------------|----------------------------------|
| pgvector  | Yes (RDS)     | ~10M vectors | Small-medium, existing Postgres  |
| Qdrant    | Yes (Cloud)   | Billions     | High performance, filtering      |
| Milvus    | Yes (Zilliz)  | Billions     | Large-scale, GPU-accelerated     |
| Weaviate  | Yes (Cloud)   | Billions     | Multi-modal, hybrid search       |

For OpenShift deployments, Qdrant and Milvus both have Helm charts and operators.

### Chunking Strategies

How you chunk documents matters more than which embedding model you use.

- **Fixed-size**: 256-512 tokens with 10-20% overlap. Good default.
- **Semantic**: Split on paragraph or section boundaries. Better quality, more complex.
- **Recursive**: Try large chunks first, split further if they exceed the limit.
- Always preserve metadata (source document, page number, section title) with each chunk.
- Test retrieval quality with different chunk sizes. Smaller chunks are more precise; larger chunks provide more context.

### Embedding Model Selection

- English: `sentence-transformers/all-MiniLM-L6-v2` (fast, 384 dims) or `BAAI/bge-large-en-v1.5` (better quality, 1024 dims).
- Multilingual: `BAAI/bge-m3` or `intfloat/multilingual-e5-large`.
- Match the embedding model's max token length to your chunk size. Tokens beyond the limit are silently truncated.
- When you change the embedding model, you must re-embed all existing documents. Plan for this.

### Retrieval Evaluation

Measure retrieval quality before blaming the generation model.

- **Recall@k**: Fraction of relevant documents in the top-k results.
- **MRR**: How high does the first relevant result rank?
- **NDCG**: Ranking quality considering position.

Build a golden evaluation set: 50-100 questions with known relevant documents. Run retrieval against this set whenever you change chunking, embedding model, or search parameters.

### Hybrid Search

Combine vector search with keyword search. Pure vector search misses exact matches; pure keyword search misses semantic similarity.

- Use reciprocal rank fusion to merge results from both search types.
- Start with 70% vector, 30% keyword weighting and tune from there.
- Add a reranker (e.g., `BAAI/bge-reranker-v2-m3`) after initial retrieval to improve final precision.

## LLM-Specific Patterns

### Token Counting

Always count tokens before sending requests. Going over the context window causes silent truncation or errors.

```python
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained(model_name)

def fits_in_context(messages: list[dict], max_tokens: int = 4096, reserved_for_output: int = 512) -> bool:
    total = sum(len(tokenizer.encode(m["content"])) for m in messages)
    return total + reserved_for_output <= max_tokens
```

### Context Window Management

- Reserve tokens for the output. Do not fill the entire context window with input.
- When context is tight, summarize older messages rather than truncating them.
- For RAG, dynamically adjust the number of retrieved chunks based on query length and available context.
- Track context window usage per request. If most requests use > 80%, you need a longer context model or better compression.

### Structured Output Parsing

Prefer models that support guided/constrained generation (e.g., vLLM's `guided_json` parameter) over parsing free-form text. When parsing is necessary, use Pydantic models to validate extracted JSON and implement retry logic for malformed outputs.

### Function Calling Patterns

- Define tools with clear, unambiguous descriptions. The model picks tools based on the description, not the function name.
- Validate all tool call arguments before execution. The model may hallucinate parameter values.
- Implement timeouts and error handling for tool execution. Return errors to the model so it can retry.
- Log every tool call with inputs, outputs, and latency for debugging and auditing.

### Guardrails

Implement guardrails as middleware, not as part of the model prompt.

- **Input guardrails**: topic filtering, language detection, length limits, PII detection.
- **Output guardrails**: content safety classification, factuality checking, PII filtering, format validation.
- Run guardrails asynchronously where possible to minimize latency impact.
- Make guardrails configurable per deployment. Internal tools have different safety requirements than public-facing products.

## Data Pipeline Integration

### Feature Stores

Use a feature store (Feast, Tecton) when multiple models share the same features, or when training and serving need consistent feature computation.

- Define features once. Reuse them across training and inference.
- Use point-in-time correct joins for training data to prevent data leakage.
- Cache frequently accessed features for low-latency serving.

### Data Versioning with DVC

Track datasets and model artifacts alongside code:

```bash
dvc init
dvc add data/training_data.parquet
dvc remote add -d myremote s3://my-bucket/dvc-store
dvc push
```

- Every experiment should be reproducible by checking out the git commit and running `dvc pull`.
- Use DVC pipelines (`dvc.yaml`) to define the full training workflow: data processing, training, evaluation.

### ETL Patterns for Training Data

- Separate extraction, transformation, and loading into distinct pipeline stages.
- Validate data at each stage boundary. Catch schema drift early.
- Make transformations idempotent. Running the same transform twice should produce the same result.
- Log data quality metrics at each stage: row counts, null rates, distribution statistics.
- Use Spark or Polars for large-scale data processing. Pandas is fine for datasets that fit in memory.

## Testing

### Model Evaluation Framework

Structure model evaluation as automated tests that run in CI:

```python
class TestModelQuality:
    @pytest.fixture(scope="session")
    def model(self):
        return load_model("path/to/model")

    def test_accuracy_above_threshold(self, model, eval_dataset):
        accuracy = evaluate_accuracy(model, eval_dataset)
        assert accuracy >= 0.85, f"Accuracy {accuracy:.3f} below threshold 0.85"

    def test_no_regression_vs_baseline(self, model, eval_dataset):
        current = evaluate_accuracy(model, eval_dataset)
        baseline = load_baseline_score()
        assert current >= baseline - 0.02, f"Regression: {current:.3f} vs baseline {baseline:.3f}"
```

### Benchmark Suites

- Maintain a curated benchmark suite that covers your model's key capabilities.
- Run benchmarks on every model version before promotion to production.
- Track benchmark results over time to catch gradual degradation.
- Include adversarial and edge-case examples.

### Regression Testing for Model Quality

- Store baseline metrics for the production model.
- Block deployment if the new model regresses on any key metric beyond a defined tolerance (e.g., 2%).
- Test on slices of data, not just aggregate metrics. A model can maintain overall accuracy while degrading on a specific subgroup.

### Load Testing Inference Endpoints

Before deploying a new model or configuration, verify it handles production load:

```bash
# Load test with vegeta
echo 'POST http://localhost:8000/v1/chat/completions' | vegeta attack \
    -body request.json -rate 50/s -duration 60s | vegeta report

# Or use locust for complex scenarios
locust -f load_test.py --host http://localhost:8000 --users 100 --spawn-rate 10
```

Report: throughput at target latency, latency percentiles (p50/p95/p99), error rate under load, GPU memory under load, max concurrent users before degradation.

## Data Handling

- Never log or print PII, even during debugging.
- Validate input data before passing it to the model. Reject malformed inputs early.
- Document the expected input format and output schema.
- For training data, track provenance and licensing.

## Common Commands

```bash
# Install dependencies
pip install -e ".[dev]"

# Run linting
ruff check src/ tests/

# Run unit tests (no GPU required)
pytest tests/unit/ -v

# Run integration tests (GPU required)
pytest tests/integration/ -v -m gpu

# Run model evaluation suite
pytest tests/evaluation/ -v --tb=short

# Run load tests
locust -f tests/load/locustfile.py --host http://localhost:8000

# Start local inference server
python -m src.serving.server --config configs/serving_config.yaml

# Build container image
podman build -t model-server:latest .

# Track data with DVC
dvc add data/training_data.parquet && dvc push

# Launch distributed training
torchrun --nproc_per_node=4 train.py --config configs/training_config.yaml
```

## Profiling

### GPU Profiling

```bash
# NVIDIA Nsight Systems
nsys profile --output=training_profile python train.py
nsys profile --gpu-metrics-device=all --output=detailed_profile python train.py
nsys stats training_profile.nsys-rep
```

PyTorch Profiler for framework-level analysis:
```python
from torch.profiler import profile, record_function, ProfilerActivity

with profile(activities=[ProfilerActivity.CPU, ProfilerActivity.CUDA],
             schedule=torch.profiler.schedule(wait=1, warmup=1, active=3),
             on_trace_ready=torch.profiler.tensorboard_trace_handler("./profiler_logs"),
             record_shapes=True, profile_memory=True) as prof:
    for step, batch in enumerate(dataloader):
        with record_function("forward"):
            output = model(batch)
        with record_function("backward"):
            loss.backward()
        prof.step()
```

### Memory Profiling

```python
print(torch.cuda.memory_summary(device="cuda:0", abbreviated=True))
torch.cuda.memory._record_memory_history()
# ... run your code ...
torch.cuda.memory._dump_snapshot("memory_snapshot.pickle")
```

### Inference Latency Benchmarking

```python
import time, numpy as np

latencies = []
for _ in range(100):
    start = time.perf_counter()
    model.generate(input_tokens)
    latencies.append(time.perf_counter() - start)

print(f"p50={np.percentile(latencies, 50):.3f}s "
      f"p95={np.percentile(latencies, 95):.3f}s "
      f"p99={np.percentile(latencies, 99):.3f}s")
```

## Environment Variables

| Variable              | Description                      | Default       |
|-----------------------|----------------------------------|---------------|
| `MODEL_PATH`          | Path to model weights            | (required)    |
| `CUDA_VISIBLE_DEVICES`| GPU device IDs to use           | all available |
| `BATCH_SIZE`          | Inference batch size             | 32            |
| `MAX_SEQ_LENGTH`      | Maximum input sequence length    | 2048          |
| `LOG_LEVEL`           | Logging verbosity                | INFO          |
| `PORT`                | Server port                      | 8080          |
| `MLFLOW_TRACKING_URI` | MLflow server URL                | (optional)    |
| `DVC_REMOTE`          | DVC remote storage URL           | (optional)    |
| `HF_TOKEN`            | HuggingFace Hub access token     | (optional)    |
| `WANDB_API_KEY`       | Weights and Biases API key       | (optional)    |

## Common Mistakes Claude Makes

**Committing model weights to git.** Claude adds model files, checkpoints, or large datasets to the repository. These files should be tracked with DVC or stored in S3/HuggingFace Hub. Add `*.pt *.pth *.bin *.safetensors *.gguf *.onnx` to `.gitignore`.

**Hardcoding model paths.** Claude writes `model = load("/models/llama-7b")` with an absolute path. Use configuration objects or environment variables (`MODEL_PATH`) for all model paths.

**Using `torch.cuda.is_available()` without a CPU fallback.** Claude writes code that fails on machines without GPUs. Always provide a CPU fallback path. Unit tests must run on CPU.

**Ignoring GPU memory management.** Claude loads models without considering GPU memory limits. Use `device_map="auto"` for large models, set `max_memory` constraints, and monitor with `torch.cuda.memory_summary()`.

**Concatenating user input into system prompts.** Claude builds prompts by string concatenation: `prompt = system_prompt + user_input`. This enables prompt injection. Use the model's role-based message format to separate system instructions from user input.

**Not setting random seeds for reproducibility.** Claude runs training or evaluation without setting seeds. Set `random.seed()`, `np.random.seed()`, `torch.manual_seed()`, and `torch.cuda.manual_seed_all()` at the start of every experiment.

**Using `float32` when `bfloat16` is available.** Claude defaults to full precision on GPUs that support bfloat16 (A100, H100). Use `torch.bfloat16` for training and inference on Ampere+ GPUs. It has better numerical range than float16 and does not require loss scaling.

**Creating evaluation metrics after seeing results.** Claude defines evaluation criteria post-hoc to justify results. Define task-specific metrics before starting training or fine-tuning. Compare against the base model and report the delta.

## Related Templates and Commands

If your project spans multiple domains, use these tools to extend this CLAUDE.md:

- **`/suggest-template`**: Run this command in your project directory to auto-detect the project type and get a tailored template recommendation. Use `/suggest-template deep` to detect ML framework imports (torch, transformers, vllm) and model-serving patterns.
- **`/compose-template ai-ml + [other]`**: Merge this template with another. Common combinations:
  - `ai-ml + fastapi` for ML model serving behind a FastAPI HTTP layer (adds Pydantic v2 request/response models, async API patterns, dependency injection)
  - `ai-ml + kubernetes` for ML workloads on Kubernetes or OpenShift AI (adds pod security, GPU scheduling, node affinity, RBAC)
  - `ai-ml + data-pipeline` for end-to-end ML systems with data ingestion, feature engineering, and model training
- **`fastapi-project` template**: If your inference service uses FastAPI, that template provides deeper coverage of API routing, middleware, authentication, and Alembic migrations.
- **`kubernetes-project` template**: If your ML workloads run on Kubernetes, that template adds deployment manifests, resource limits for GPU requests, and monitoring with Prometheus and Grafana.
- **`data-pipeline` template**: If your project includes data preprocessing, feature pipelines, or ETL work feeding into model training, that template covers Spark, Beam, schema evolution, and data quality frameworks.
- **`python-project` template**: This AI/ML template assumes Python foundations. The `python-project` template has deeper coverage of ruff, mypy strict mode, and general Python testing patterns that apply to all Python-based ML work.

## Review Checklist

Before merging changes:

- [ ] All unit tests pass on CPU
- [ ] Model evaluation benchmarks show no regression
- [ ] No hardcoded paths, keys, or credentials
- [ ] Model artifacts are not committed to git
- [ ] GPU code has CPU fallback for testing
- [ ] Type hints are present on all public functions
- [ ] Configuration changes are documented
- [ ] Container image builds successfully
- [ ] Memory usage has been profiled for model-loading changes
- [ ] Input validation handles adversarial and edge-case inputs
- [ ] Output filtering is in place for user-facing endpoints
- [ ] Monitoring metrics are exported for new endpoints
- [ ] Model card is updated for model changes
- [ ] Load test results are acceptable for serving changes
