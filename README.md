# 📊 GProfiler

## 📑 Contents

- [Overview Tab](#-overview-tab)
- [Profilers](#-profilers)
	- [Hooks](#-hook-profiler)
	- [Network](#-net-profiler)
	- [Functions](#️-function-profiler)
	- [Commands](#️-commands-profiler)
	- [Timers](#️-timer-profiler)
	- [Entity Variables](#-entity-variables-profiler)
	- [Network Variables](#-network-variables-profiler)
	- [Database](#️-database-profiler)
	- [JIT](#-jit-profiler)
- [Configuration](#-configuration)

---

## 🏠 Overview Tab

<p align="center">
	<img src=".github/images/overview.png" alt="Overview tab" width="800">
</p>

---

## 🔬 Profilers

### 🪝 Hook Profiler

<p align="center">
	<img src=".github/images/hooks.png" alt="Hook profiler" width="800">
</p>

---

### 🌐 Net Profiler

<p align="center">
	<img src=".github/images/network.png" alt="Net profiler" width="800">
</p>

---

### ⚙️ Function Profiler

<p align="center">
	<img src=".github/images/functions.png" alt="Function profiler" width="800">
</p>

#### Call graph

Select any result to view the call tree of a single invocation: which functions it called, in order, with each child's time and share of the parent. This makes it easy to see *where* a slow function actually spends its time.

> [!NOTE]
> The call graph may provide incomplete results, or often none at all. It's an experimental idea I had, and can be a bit janky

#### Focus

You can set a list of functions to limit the profiling results to, making it easy to focus on a small set of functions at a time, while discarding other data

---

### 🖥️ Commands Profiler

<p align="center">
	<img src=".github/images/commands.png" alt="Commands profiler" width="800">
</p>

---

### ⏱️ Timer Profiler

<p align="center">
	<img src=".github/images/timers.png" alt="Timer profiler" width="800">
</p>

---

### 📦 Entity Variables Profiler

<p align="center">
	<img src=".github/images/entvars.png" alt="Entity variables profiler" width="800">
</p>

---

### 🔗 Network Variables Profiler


<p align="center">
	<img src=".github/images/netvars.png" alt="Network variables profiler" width="800">
</p>

---

### 🗄️ Database Profiler


<p align="center">
	<img src=".github/images/database.png" alt="Database profiler" width="800">
</p>

- **EXPLAIN** gives into how the database executes a query: the execution plan, index usage, table scans and other factors, so you can see where inefficiencies lie.
- **PROFILE** gives a detailed execution breakdown showing what the server was doing at each step and how long each step took.

> [!NOTE]
> Both of the above is only available for databases running through MySQL, and all data is provided by MySQL

---

### 🔥 JIT Profiler

<p align="center">
	<img src=".github/images/jitprofiler.png" alt="JIT profiler" width="800">
</p>

> [!NOTE]
> The JIT Profiler requires the `gprofiler` binary module, which you can download here: TODO
> The module is currently only built for windows.

---

## 🔧 Configuration

All configuration lives in `lua/gprofiler/sh_config.lua`, this is where you can configure who can use GProfiler, language, etc. Players whos SteamID's are in `GProfiler.Config.AllowedSteamIDs` can use GProfiler.
