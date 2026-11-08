---
name: "game-spec-prompt-architect"
description: "Turn a brief game or interactive WebGL/3D idea into a dense, anti-lazy, multi-file engineering spec prompt (Lamplight Classic style). Use when asked for a high-density spec prompt or a master prompt for coding agents."
---

# Game Spec Prompt Architect

Transform high-level game or interactive WebGL/3D application concepts into dense, industrial-grade engineering specification prompts designed for modular, multi-file project architectures.

## When to Use

- The user provides a brief game idea, prototype concept, or system description and wants a high-density, benchmark-grade prompt (similar to "Lamplight Classic").
- The user asks for a master prompt for AI coding agents or LLMs to build a structured multi-file project rather than a single-file script.
- The user wants to prevent common AI coding shortcuts (placeholder physics, fake stat tracking, broken camera occlusion, spaghetti state machines) through strict specification constraints.

## Core Principles

1. **Modular multi-file architecture (never single-file HTML).** Enforce a clean, production-grade directory structure (modern runtimes and bundlers such as Bun, Vite, TypeScript/ES Modules) with strict separation of concerns between simulation logic, rendering, networking, and UI.
2. **Concrete math and algorithms over adjectives.** Replace vague visual or gameplay words with exact mathematical and algorithmic requirements:
   - Instead of "isometric retro look", specify camera projection, elevation/azimuth angles, render target filtering (NearestFilter), color space quantization (e.g., OKLab palette), and dithering matrices.
   - Instead of "good physics", specify coordinate system handedness (+x east, +z south), world dimensions in meters, fixed timestep (1/60 s with accumulator), and collision structures (BVH, spatial hash, or impulse solvers).
3. **Scar-driven anti-lazy guardrails.** Anticipate where AI models cut corners and block those shortcuts explicitly (deterministic seeded RNGs, cutaway walls for camera occlusion, tone mapping to prevent light blowout, strict stat reconciliation).
4. **Contract-first delivery.** Always instruct the target AI to write the Module Contract (public APIs, TypeScript interfaces, event bus payloads, file tree) before generating implementation files in parallel or sequential batches.

## Steps to Generate the Spec Prompt

Analyze the user's concept and generate a comprehensive specification prompt with these 9 mandatory sections:

1. **PROJECT & ARCHITECTURE** - Project title, core loop, runtime/bundler stack (default: modular multi-file Bun + Vite + Three.js/WebGL unless specified otherwise), directory tree (src/core/, src/sim/, src/render/, src/ai/, src/net/, src/ui/, src/audio/), and allowed dependencies.
2. **SETTING & VISUAL IDENTITY** - World scale, aesthetic direction, color palette (exact hex or color space rules), typography, and UI layout behavior across desktop and mobile viewports.
3. **RENDERING & CAMERA PIPELINE** - Camera projections, angles, orbit/follow modes, occlusion handling (doll's-house wall cutaway or raycast fade), custom shaders, lighting slots, and instancing requirements (InstancedMesh budgets and pose/animation systems).
4. **WORLD, PHYSICS & DETERMINISM** - Coordinate axes, exact measurements, fixed timestep (1/60 s accumulator), time-scale controls, seeded PRNG separation (scenery RNG vs. gameplay/network RNG), and collision mechanics.
5. **GAME AI, NETWORKING & STATE OWNERSHIP** - Decoupled logic modules with explicit state ownership. Specify pathfinding/steering (A*, flow fields), multiplayer synchronization (e.g., PeerJS P2P host-authoritative state + client prediction, or AI bot slot takeover for 2-4 player lobbies), and quantitative calibration targets (expected numeric ranges per match/session).
6. **RULES, FLOW & SCHEDULER** - State machine or coroutine-based scheduler governing pre-game, active play, interruptions, replays (ring buffer), and post-game flows, plus data integrity rules.
7. **PROCEDURAL / SYNTHESISED AUDIO & FX** - How sound and particle effects are generated or managed (WebAudio synthesis graph with oscillators, noise buffers, filters, or structured audio buses), with user-gesture initialization and mute toggles.
8. **QUALITY BAR (ANTI-LAZY VERIFICATION)** - Strict acceptance criteria:
   - Clean state reset (New Match / restart behaves identically to initial boot).
   - Headless simulation capability (decoupled sim step runnable without rendering, zero NaN values, reconciled stats).
   - Performance budget (e.g., sim + view under 3 ms per 1/60 s step).
9. **DELIVERY PROTOCOL** - Instruct the executing model to:
   - Step 1: Output the complete file tree and Module Contract (interfaces, public methods, Event Bus schema).
   - Step 2: Implement the decoupled modules according to the contract.

## Output Formatting Rules

- Output the generated specification prompt inside a clean Markdown code block (or structured copy-ready section) in English, since dense technical English yields the highest adherence across coding models.
- Follow it with a brief Traditional Chinese architectural summary explaining the key anti-lazy mechanisms injected for the user's specific game idea.
- If the user's initial prompt is very brief, do not stall with endless questions. Infer realistic, high-craft technical parameters (dimensions, shaders, physics numbers, module splits) that fit the genre, generate the full spec prompt immediately, and offer to tune specific parameters afterward.

## Gotchas

- Never revert to "single self-contained HTML page" constraints unless the user explicitly overrides this skill's default. Always design for a clean multi-file modular repository.
- Avoid generic fluff like "make the code clean and modular." Name the exact modules (e.g., BK, PLAY, DEF, NET, BALL) and define which module owns which state mutation.