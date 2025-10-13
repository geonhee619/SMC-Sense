# SMC-Sense

This is the [README.md](https://github.com/geonhee619/SMC-Sense/blob/main/README.md) for the repository containing computer code, output files, and figures for the paper:

Han, G., Gelman, A., and Vehtari A. (2025) **"Efficient scenario analysis in real-time Bayesian election forecasting via sequential meta-posterior sampling"**. <arXiv link: TBA>

<!--
```bibtex
@misc{TBA}
```
-->

---

**Table of contents**:
- [Contents](#contents)
- [Instructions (Local JupyterLab on Windows)](#instructions-local-jupyterlab-on-windows)
- [Execution flow](#execution-flow)
- [System notes](#system-notes)

---

## Contents

- `{MCMC, SMC}.ipynb`: Jupyter notebooks to be run in Julia (1.10.4, 4-thread multi-threading) top-to-bottom for baseline MCMC-based posterior computation, the sequential sampling scheme, and figure generation.
- `input/`: Save outputs from `MCMC.ipynb` (as input for `SMC.ipynb`).
  - `.stan` model is from the publicized repo: https://github.com/TheEconomist/us-potus-model.
- `output/`: Save results from `SMC.ipynb`.
- `img/`: Generated figures in the paper.
- `{input, output, img}_[session datetime]/`: Newly generated files will be saved here.

> **Note:** Large outputs are not in [this repository](https://github.com/geonhee619/SMC-Sense) directly due to size: see [here (Google Drive)](https://drive.google.com/drive/folders/1spxia_wttH-xAH6hBw14zQkr_q6QofMK?usp=sharing).

---

## Instructions (Local JupyterLab on Windows)

1. Download [SMC-Sense (Google Drive)](https://drive.google.com/drive/folders/1spxia_wttH-xAH6hBw14zQkr_q6QofMK?usp=sharing) (with large outputs).

2. Download/install **Julia v1.10.4**
   - Link: [https://julialang.org/downloads/oldreleases/](https://julialang.org/downloads/oldreleases/#:~:text=bf8f45f85d7c615f01aa46db427c2435b397ec58f2c7ee6d4b0785481a747d98-,v1.10.4,-%2C%20on%202024%2D06)

3. Setup 4-thread multithreading via Jupyter(Lab).

> **Note:** This is optional but strongly recommended; in the paper we take advantage of parallelizability.

   - Open Julia and install custom kernels:
   ```julia
   using IJulia
   installkernel("Julia (4 Threads)", env=Dict("JULIA_NUM_THREADS" => "4"))
   ```

   - Launch Jupyter:
   ```julia
   using IJulia
   jupyterlab()
   ```

   - Select the desired kernel in JupyterLab on the top right: `"Julia (4 Threads)"`.

4. Confirm thread count:

```julia
using Threads
println("Running on ", Threads.nthreads(), " threads.")
```

5. Enable BridgeStan threading: see [Enabling Parallel Calls of Stan Programs](https://roualdes.us/bridgestan/latest/getting-started.html)

6. Navigate to the repo directory, then run in the order `MCMC.ipynb -> SMC.ipynb`.
```julia
cd("[ your chosen directory ] /SMC-Sense")
```

---

## Execution flow

1. Make sure large input/output files (especially those under `{input, output}/`) have been downloaded from [SMC-Sense (Google Drive)](https://drive.google.com/drive/folders/1spxia_wttH-xAH6hBw14zQkr_q6QofMK?usp=sharing).
2. (Optional: Run `MCMC.ipynb` to (a) generate _baseline_ draws (under `input_[session datetime]/`) and (b) bruteforce draws for reference (under `output_[session datetime]/*/mcmc/`).)
3. Run `SMC.ipynb` to (b') use _baseline_ draws for sequential sampling (under `output_[session datetime]/*/smc/`) and (c) generate figures (under `img_[session datetime]/`).

---

## System notes

- The codes were developed and tested on the following **Windows** environment.

  - **OS**: Windows 11
  - **CPU**: 24-core 12th Gen Intel(R) Core(TM) i9-12900K
  - **RAM**: 32 GB
  - **Julia**: v1.10.4
    - **Multithreading**: `JULIA_NUM_THREADS=4`
  - **BridgeStan**: v2.6.2
  - (**CmdStan**: v2.36.0)
