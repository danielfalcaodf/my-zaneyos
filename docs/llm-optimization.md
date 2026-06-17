# LLM Optimization para i7-12700KF + RTX 3060 12GB + 64GB RAM

## Hardware Especificado

| Componente | Especificação | Relevância para LLM |
|------------|---------------|---------------------|
| CPU | Intel Core i7-12700KF (12C/20T: 8 P-cores + 4 E-cores) | Pré-processamento, tokenização, inferência CPU fallback |
| GPU | NVIDIA RTX 3060 12GB (Ampere, 3584 CUDA cores, 12GB GDDR6) | **Principal**: Offload de camadas do modelo (weights + KV cache) |
| RAM | 64GB DDR4/DDR5 | Modelos grandes, KV cache, context window, multi-modelo |

## Configuração Aplicada

### NVIDIA Drivers (`modules/drivers/nvidia-drivers.nix`)
```nix
openKernelModule = true;  # Open kernel module para Ampere+
driverVersion = "stable";
powerManagement.enable = false;  # Manter GPU ativa
services.nvidia-persistenced.enable = true;  # Inicialização rápida
```

### Ollama Otimizado (`modules/ai-tools/llm-optimized.nix`)
```nix
OLLAMA_NUM_GPU = 99;           # Todas as camadas na GPU
OLLAMA_CONTEXT_SIZE = 8192;    # Context window 8k
OLLAMA_NUM_PARALLEL = 2;       # 2 requisições paralelas
OLLAMA_NUM_THREAD = 12;        # 12 threads CPU (P-cores)
OLLAMA_FLASH_ATTENTION = 1;    # Flash Attention habilitado
OLLAMA_KV_CACHE_QUANT = 1;     # KV cache quantizado
OLLAMA_GPU_MEMORY_FRACTION = 0.9;  # 90% VRAM (10.8GB)
OLLAMA_KEEP_ALIVE = "24h";     # Manter modelo na VRAM
```

### llama.cpp Otimizado
```bash
llama-optimized -m modelo.gguf -p "prompt"
# Flags: -ngl 99 -t 12 -b 512 --mmap --mlock --flash-attn
```

## Modelos Recomendados para 12GB VRAM

| Modelo | Tamanho (Q4_K_M) | VRAM Estimada | Use Case |
|--------|------------------|---------------|----------|
| qwen2.5-coder:7b | ~4.2 GB | ~5 GB | **Coding** (recomendado) |
| llama3.1:8b | ~4.7 GB | ~5.5 GB | Generalista |
| phi3:14b | ~8.2 GB | ~9 GB | Qualidade superior |
| codellama:13b | ~7.8 GB | ~8.5 GB | Coding avançado |
| deepseek-coder:6.7b | ~4.0 GB | ~4.8 GB | Coding leve |

**Dica**: Com 12GB VRAM, você pode rodar **um modelo 7b-8b + embeddings** simultaneamente, ou **um modelo 13b-14b** sozinho.

## Quantização Recomendada

| Quantização | VRAM (7b) | Qualidade | Velocidade | Recomendação |
|-------------|-----------|-----------|------------|--------------|
| Q2_K | ~2.8 GB | Baixa | Muito rápida | ❌ |
| Q3_K_M | ~3.3 GB | Média | Rápida | Para testes |
| **Q4_K_M** | **~4.2 GB** | **Boa** | **Rápida** | ✅ **Padrão** |
| Q5_K_M | ~5.0 GB | Muito boa | Média | Qualidade > Velocidade |
| Q6_K | ~5.8 GB | Excelente | Lenta | Máquina potente |
| Q8_0 | ~7.2 GB | Quase FP16 | Lenta | ❌ |

## Comandos Úteis

```bash
# Ver modelos instalados
ollama list

# Pull modelo otimizado
ollama pull qwen2.5-coder:7b-instruct-q4_k_m

# Rodar com parâmetros customizados
ollama run qwen2.5-coder:7b-instruct-q4_k_m --verbose

# Servidor API otimizado
llama-server-optimized -m /home/devdaniel/models/qwen2.5-coder-7b-q4_k_m.gguf

# Benchmark
llama-optimized -m modelo.gguf -p "Benchmark prompt" -n 100 --benchmark

# Ver uso GPU
watch -n 1 nvidia-smi
```

## Monitoramento GPU na Waybar

O módulo `custom/nvidia` no Waybar (`modules/home/waybar/waybar-mangowc-jak-catppuccin.nix`) mostra:
- GPU Utilization (%)
- VRAM Used / Total
- Temperatura

## Troubleshooting

### GPU não detectada
```bash
# Verificar driver
nvidia-smi
# Deve mostrar RTX 3060 e CUDA Version

# Verificar ollama usa CUDA
ollama run qwen2.5-coder:7b --verbose 2>&1 | grep -i gpu
```

### OOM (Out of Memory) na GPU
```nix
# Reduzir em llm-optimized.nix:
OLLAMA_GPU_MEMORY_FRACTION = "0.8";  # 80% = 9.6GB
OLLAMA_NUM_GPU = 80;  # Não offload todas as camadas
```

### Lento na primeira execução
```bash
# nvidia-persistenced deve estar ativo
systemctl status nvidia-persistenced

# Warm-up
ollama run qwen2.5-coder:7b "warm up" && ollama run qwen2.5-coder:7b "real prompt"
```

### Flash Attention não funciona
```bash
# Requer CUDA 11.8+ e modelo compatível
# Verificar:
nvidia-smi | grep CUDA
# Se < 11.8, desabilitar:
OLLAMA_FLASH_ATTENTION = 0
```

## Referências

- [Ollama GPU Offload](https://github.com/ollama/ollama/blob/main/docs/gpu.md)
- [llama.cpp Performance](https://github.com/ggerganov/llama.cpp/blob/master/docs/perf.md)
- [NVIDIA Open Kernel Module](https://github.com/NVIDIA/open-gpu-kernel-modules)
- [Quantization Guide](https://github.com/ggml-org/llama.cpp/blob/master/docs/quantization.md)