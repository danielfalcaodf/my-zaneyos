# LLM Optimized Configuration for i7-12700KF + RTX 3060 12GB + 64GB RAM
# Hardware: 12th Gen Intel Core i7-12700KF (20 threads, 12 cores: 8 P-cores + 4 E-cores)
# GPU: NVIDIA RTX 3060 12GB (Ampere, CUDA 8.6, 3584 CUDA cores)
# RAM: 64GB DDR4/DDR5
#
# Otimizações:
# - Offload máximo para GPU (12GB VRAM)
# - Context window otimizado (8k-32k dependendo do modelo)
# - Paralelismo CPU: 12 threads (P-cores) para pré-processamento
# - Quantização: Q4_K_M/Q5_K_M para equilíbrio velocidade/qualidade
# - Flash Attention / xFormers quando disponível
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ai-tools.llm;
in {
  options.ai-tools.llm = {
    enable = lib.mkEnableOption "Enable optimized LLM configuration";

    # Ollama service optimization
    ollama = {
      enable = lib.mkEnableOption "Enable optimized Ollama service";

      # Models to pre-load (adjust based on VRAM)
      models = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "qwen2.5-coder:7b-instruct-q4_k_m"
          "llama3.1:8b-instruct-q4_k_m"
          "nomic-embed-text:v1.5"
        ];
        description = "Models to load at startup";
      };

      # GPU layers to offload (99 = max for RTX 3060 12GB)
      gpuLayers = lib.mkOption {
        type = lib.types.int;
        default = 99;
        description = "Number of layers to offload to GPU (99 = all)";
      };

      # Context window size
      contextSize = lib.mkOption {
        type = lib.types.int;
        default = 8192;
        description = "Context window size (tokens)";
      };

      # Number of parallel requests
      numParallel = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Parallel request handling";
      };

      # CPU threads for inference (use P-cores: 8)
      numThreads = lib.mkOption {
        type = lib.types.int;
        default = 12;
        description = "CPU threads for inference";
      };

      # Flash attention (requires compatible model + CUDA 11.8+)
      flashAttention = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable flash attention for faster inference";
      };

      # KV cache quantization
      kvCacheQuant = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Quantize KV cache to save VRAM";
      };
    };

    # llama.cpp optimization (for CLI usage)
    llamaCpp = {
      enable = lib.mkEnableOption "Enable optimized llama.cpp";

      # Default model path
      modelPath = lib.mkOption {
        type = lib.types.path;
        default = "/home/devdaniel/models";
        description = "Path to GGUF models";
      };

      # Default GPU layers
      gpuLayers = lib.mkOption {
        type = lib.types.int;
        default = 99;
        description = "GPU layers to offload";
      };

      # Threads (P-cores: 8, but can use all 12 for batch)
      threads = lib.mkOption {
        type = lib.types.int;
        default = 12;
        description = "CPU threads";
      };

      # Batch size for prompt processing
      batchSize = lib.mkOption {
        type = lib.types.int;
        default = 512;
        description = "Batch size for prompt processing";
      };

      # Use MMap for faster loading
      useMmap = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use mmap for model loading";
      };

      # Use MLocker to keep model in RAM
      useMlock = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Lock model in RAM";
      };
    };

    # LM Studio optimization (AppImage/Flatpak)
    lmStudio = {
      enable = lib.mkEnableOption "Enable LM Studio with GPU acceleration";

      # AppImage path (auto-detected)
      appImagePath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to LM Studio AppImage";
      };

      # GPU acceleration flags
      gpuFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "--enable-gpu"
          "--use-gl=angle"
          "--angle-backend=vulkan"
        ];
        description = "GPU acceleration flags for LM Studio";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Ollama optimized service
    services.ollama = lib.mkIf cfg.ollama.enable {
      enable = true;
      package = pkgs.ollama-cuda;
      loadModels = cfg.ollama.models;
      syncModels = true;

      # Environment variables for optimization
      environmentVariables = {
        # GPU offload
        OLLAMA_NUM_GPU = "${toString cfg.ollama.gpuLayers}";
        # Context window
        OLLAMA_CONTEXT_SIZE = "${toString cfg.ollama.contextSize}";
        # Parallel requests
        OLLAMA_NUM_PARALLEL = "${toString cfg.ollama.numParallel}";
        # CPU threads
        OLLAMA_NUM_THREAD = "${toString cfg.ollama.numThreads}";
        # Flash attention
        OLLAMA_FLASH_ATTENTION =
          if cfg.ollama.flashAttention
          then "1"
          else "0";
        # KV cache quantization
        OLLAMA_KV_CACHE_QUANT =
          if cfg.ollama.kvCacheQuant
          then "1"
          else "0";
        # GPU memory fraction (leave 1GB for system)
        OLLAMA_GPU_MEMORY_FRACTION = "0.9";
        # Disable mmap for faster loading (trade-off: more RAM)
        OLLAMA_DISABLE_MMAP = "0";
        # Keep model in VRAM
        OLLAMA_KEEP_ALIVE = "24h";
      };
    };

    # Combined packages for LLM tools
    environment.systemPackages = lib.concatLists [
      (lib.optional (cfg.llamaCpp.enable or false) (with pkgs; [
        (llama-cpp.override {
          cudaSupport = true;
          blasSupport = true;
          metalSupport = false;
        })
        (pkgs.writeShellScriptBin "llama-optimized" ''
          #!/usr/bin/env bash
          # Optimized llama.cpp for i7-12700KF + RTX 3060 12GB
          exec ${pkgs.llama-cpp}/bin/llama-cli \
            -ngl ${toString cfg.llamaCpp.gpuLayers} \
            -t ${toString cfg.llamaCpp.threads} \
            -b ${toString cfg.llamaCpp.batchSize} \
            ${lib.mkIf cfg.llamaCpp.useMmap "--mmap"} \
            ${lib.mkIf cfg.llamaCpp.useMlock "--mlock"} \
            --flash-attn \
            "$@"
        '')
        (pkgs.writeShellScriptBin "llama-server-optimized" ''
          #!/usr/bin/env bash
          # Optimized llama.cpp server for RTX 3060
          exec ${pkgs.llama-cpp}/bin/llama-server \
            -ngl ${toString cfg.llamaCpp.gpuLayers} \
            -t ${toString cfg.llamaCpp.threads} \
            -b ${toString cfg.llamaCpp.batchSize} \
            -c ${toString cfg.ollama.contextSize} \
            --parallel ${toString cfg.ollama.numParallel} \
            ${lib.mkIf cfg.llamaCpp.useMmap "--mmap"} \
            ${lib.mkIf cfg.llamaCpp.useMlock "--mlock"} \
            --flash-attn \
            --host 0.0.0.0 \
            --port 8080 \
            "$@"
        '')
      ]))
      (lib.optional (cfg.lmStudio.enable or false) (with pkgs; [
        (pkgs.writeShellScriptBin "lm-studio-gpu" ''
          #!/usr/bin/env bash
          # LM Studio with GPU acceleration for RTX 3060
          # Requires LM Studio AppImage at ~/Applications/LM-Studio-*.AppImage
          APPIMAGE="${cfg.lmStudio.appImagePath or "$HOME/Applications/LM-Studio-*.AppImage"}"
          # Find latest AppImage
          APPIMAGE_PATH=$(ls -t $APPIMAGE 2>/dev/null | head -1)
          if [[ -z "$APPIMAGE_PATH" ]]; then
            echo "LM Studio AppImage not found in ~/Applications/"
            exit 1
          fi
          # GPU flags for NVIDIA on Wayland
          export QT_QPA_PLATFORM=xcb
          export __GL_GSYNC_ALLOWED=0
          export __GL_VRR_ALLOWED=0
          exec "$APPIMAGE_PATH" ${lib.concatStringsSep " " cfg.lmStudio.gpuFlags} "$@"
        '')
      ]))
    ];

    # Model storage directory
    systemd.tmpfiles.rules = [
      {
        path = "/home/devdaniel/models";
        type = "d";
        mode = "0755";
        user = "devdaniel";
        group = "devdaniel";
      }
    ];

    # Optimize NVIDIA settings for LLM workloads
    systemd.services.ollama.environment = {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      CUDA_VISIBLE_DEVICES = "0";
    };
  };
}
