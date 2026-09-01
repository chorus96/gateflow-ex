# GateFlow 플러그인 상세 분석 (plugin.md)

> 이 문서는 [GateFlow 플러그인](https://github.com/codejunkie99/Gateflow-Plugin)
> (`gateflow` v2.5.3)을 소스 코드 수준에서 분석해 한국어로 정리한 참고 문서입니다.
> `gateflow-ex` 저장소는 이 플러그인을 사용하도록 구성된 예제 프로젝트이며,
> 이 문서는 플러그인이 "무엇을, 어떻게" 제공하는지 이해하기 위한 레퍼런스입니다.

---

## 목차

1. [한눈에 보기](#1-한눈에-보기)
2. [플러그인이란 / 설계 철학](#2-플러그인이란--설계-철학)
3. [저장소 구조](#3-저장소-구조)
4. [동작 원리 — 오케스트레이션 흐름](#4-동작-원리--오케스트레이션-흐름)
5. [에이전트 (20개)](#5-에이전트-20개)
6. [스킬 (27개)](#6-스킬-27개)
7. [슬래시 커맨드 (21개)](#7-슬래시-커맨드-21개)
8. [IP 블록 라이브러리 (8개)](#8-ip-블록-라이브러리-8개)
9. [보드 데이터베이스 (4개)](#9-보드-데이터베이스-4개)
10. [Hooks (자동화 훅)](#10-hooks-자동화-훅)
11. [외부 도구 통합 / 툴체인](#11-외부-도구-통합--툴체인)
12. [설정 방법](#12-설정-방법)
13. [gateflow-ex 에서의 활용](#13-gateflow-ex-에서의-활용)

---

## 1. 한눈에 보기

GateFlow는 **자연어로 하드웨어(RTL)를 설계·검증·합성·배포**할 수 있게 해주는
Claude Code 플러그인입니다. SystemVerilog / Verilog / VHDL을 지원하며,
오픈소스 FPGA 툴체인 전체(Verilator, Yosys, nextpnr, SymbiYosys 등)를 감쌉니다.

| 구성 요소 | 개수 | 설명 |
|-----------|------|------|
| **에이전트(Agents)** | 20 | 코드 생성·디버그·검증·합성 등 전문 서브에이전트 |
| **스킬(Skills)** | 27 | 자동 활성화되는 작업 단위(lint/sim/formal/plan 등) |
| **커맨드(Commands)** | 21 | `/gf-*` 슬래시 커맨드 |
| **IP 블록** | 8 | 검증된 드롭인 하드웨어 블록(FIFO, UART, SPI 등) |
| **보드** | 4 | FPGA 보드 정의 + 핀 제약 파일 |
| **Hooks** | 5종 | SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / Stop |

- **버전**: 2.5.3
- **마켓플레이스 이름**: `gateflow`
- **플러그인 이름**: `gateflow` (설치 식별자: `gateflow@gateflow`)
- **라이선스**: BSL-1.1 (Business Source License)
- **제작자**: codejunkie99 (Avid)

---

## 2. 플러그인이란 / 설계 철학

### Claude Code 플러그인의 개념

Claude Code 플러그인은 **에이전트 + 스킬 + 커맨드 + 훅**을 하나로 묶어 배포하는
패키지입니다. 마켓플레이스(`marketplace.json`)에 등록되고, 각 플러그인은
`plugin.json` 매니페스트로 정의됩니다. 설치하면 해당 컴포넌트들이 Claude Code
세션에 자동으로 로드됩니다.

### GateFlow의 핵심 설계 원칙

플러그인의 `CLAUDE.md`에 명시된 동작 규칙:

1. **듀얼 에이전트 사고(Dual-Agent Thinking)** — 생성 작업 시 "설계자"와
   "검증자" 두 관점을 병행. *"동작하는 코드"가 아니라 "동작이 검증된 코드"* 를 목표로 함.
2. **항상 위임(Always Delegate)** — 오케스트레이터는 RTL 작업을 직접 처리하지 않고
   반드시 전문 에이전트로 라우팅.
3. **계획 우선(Plan First)** — 생성 작업 전 반드시 명확화 질문 → 아키텍처 계획.
4. **검증 루프(Verification Loop)** — lint → sim → (formal/synth)를 돌려
   실패 시 에러를 3계층으로 번역해 자동 수정 반복.
5. **합성 검증 패턴 우선** — `always_ff`/`always_comb`, `logic`, active-low 비동기
   리셋, 완전한 case/if(래치 방지) 등 합성 안전 패턴을 강제.

---

## 3. 저장소 구조

```
Gateflow-Plugin/
├── .claude-plugin/
│   └── marketplace.json        # 마켓플레이스 정의 (플러그인 목록)
├── plugins/gateflow/           # 플러그인 본체
│   ├── .claude-plugin/
│   │   └── plugin.json         # 플러그인 매니페스트 (버전/메타)
│   ├── agents/                 # 20개 전문 에이전트 (.md)
│   ├── commands/               # 21개 슬래시 커맨드 (.md)
│   ├── skills/                 # 27개 스킬 (각 폴더의 SKILL.md)
│   ├── hooks/                  # 자동화 훅 (hooks.json + scripts/)
│   ├── ip/                     # 8개 검증된 IP 블록 (rtl/tb/formal/block.yaml)
│   ├── boards/                 # 4개 FPGA 보드 정의 + 제약 파일
│   ├── integrations/           # 외부 툴 통합 문서 (openlane/f4pga 등)
│   ├── community/              # 기여 가이드 (보드/IP/CI 템플릿)
│   ├── assets/                 # 이미지 등
│   └── CLAUDE.md               # SV 레퍼런스 + 오케스트레이션 규칙
├── agents/ , skills/           # 루트 미러 (심볼릭 진입점)
├── docs/                       # 압축 문서 인덱스
├── CLAUDE.md                   # SV 레퍼런스 (저장소 레벨)
└── AGENTS.md                   # 비-Claude 에이전트용 문서 인덱스
```

### 주요 매니페스트 파일

| 파일 | 역할 |
|------|------|
| `.claude-plugin/marketplace.json` | 마켓플레이스 `gateflow` + 포함 플러그인 목록 |
| `plugins/gateflow/.claude-plugin/plugin.json` | 이름/버전(2.5.3)/저자/키워드/라이선스 |
| `plugins/gateflow/CLAUDE.md` | 세션에 항상 로드되는 SV 스타일·라우팅 규칙 |
| `AGENTS.md` | Cursor/Copilot 등 타 도구용 문서 인덱스 |

---

## 4. 동작 원리 — 오케스트레이션 흐름

GateFlow의 중심은 **`gf` 오케스트레이터 스킬**입니다. 사용자가 RTL 관련 요청을 하면
다음 흐름을 따릅니다(플러그인 `CLAUDE.md`의 Intent Routing Protocol):

```
사용자 요청
   │
   ▼
[1] SystemVerilog 작업인지 감지
   │
   ▼
[2] 명확화 질문 (MANDATORY)  ── 폭/깊이/리셋/프로토콜/보드 등
   │
   ▼
[3] 계획 (생성 작업)         ── sv-planner / gf-plan
   │
   ▼
[4] 병렬 빌드                ── sv-orchestrator / gf-build (모듈 분해→병렬 생성)
   │
   ▼
[5] 검증 루프 ──────────────┐
   │  lint (gf-lint)        │
   │  sim  (gf-sim)         │  실패 시: gf-errors 로 에러 3계층 번역
   │  formal (gf-formal)    │  → sv-debug / sv-refactor 로 자동 수정 → 재검증
   │  synth (gf-synth)      │
   └───────────────────────┘
   │
   ▼
"동작 검증 완료" 코드 전달
```

### 라우팅 규칙 요약

| 사용자가 원하는 것 | 라우팅 대상 |
|--------------------|-------------|
| 모듈/FSM/FIFO 생성 | `sv-codegen` (병렬 시 `sv-orchestrator`) |
| 테스트벤치 작성 | `sv-testbench` / `gf-cocotb` |
| 시뮬레이션 실패 디버그 | `sv-debug` |
| lint/스타일 수정 | `sv-refactor` |
| 어설션/커버리지 | `sv-verification` |
| formal 증명 | `sv-formal` |
| 합성/면적·타이밍 | `sv-synth` |
| 코드 이해/설명 | `sv-understanding` |
| 계획/아키텍처 | `sv-planner` |

내부적으로 `gf-router`(불명확한 요청 분류)와 `gf-expand`(옵션·트레이드오프 제시)가
보조하며, 에이전트 스폰 시 **세션 모델을 상속**해 일관성을 유지합니다.

### 에이전트 스폰(Agent Spawning) 상세

오케스트레이터는 RTL 작업을 직접 하지 않고 `Task` 툴로 전문 서브에이전트를
**실행(spawn)** 시킵니다. 각 에이전트는 독립 컨텍스트에서 돌고 결과를 반환합니다.

**① 기본 패턴** — `Task` 툴에 대상 에이전트와 자족적 프롬프트를 전달:

```
Use Task tool:
  subagent_type: "gateflow:sv-codegen"     # gateflow: 접두사 + 에이전트 이름
  prompt: |
    ## Component: [이름]
    ## Specification  [상세 요구사항]
    ## Interface      [포트/파라미터/프로토콜]
    ## Constraints    - lint-clean, 네이밍 규칙 준수
    ## Output         Write to: rtl/<file>.sv
```

서브에이전트는 부모 대화 맥락을 자동으로 갖지 못하므로 **스펙·인터페이스·제약·파일
경로를 프롬프트에 명시**해야 합니다.

> **"Task 툴로 스폰된다"는 무슨 뜻인가?**
> `Task`는 Claude Code(및 Agent SDK)가 제공하는 **서브에이전트 실행 도구**입니다.
> 오케스트레이터가 이 툴을 호출하면 지정한 종류(`subagent_type`)의 에이전트 인스턴스가
> **새로 만들어져(spawn)** 작업을 수행하고 결과만 돌려줍니다. "스폰"은 OS에서 부모
> 프로세스가 자식을 띄우는 것에 빗댄 표현입니다. 스폰된 에이전트의 특성:
>
> | 특성 | 의미 |
> |------|------|
> | **독립 컨텍스트** | 부모의 대화 히스토리를 물려받지 않음 → 프롬프트가 자족적이어야 하는 이유 |
> | **자체 도구 루프** | 스스로 Read/Write/Bash/검색을 여러 턴 반복 수행 |
> | **결과만 반환** | 내부 작업 과정은 부모에 노출되지 않고 **최종 요약 하나**만 반환 |
> | **모델 상속** | (GateFlow) 부모 세션과 동일한 모델로 실행 |
> | **병렬 가능** | 부모가 한 메시지에서 여러 Task를 호출하면 동시 실행 |
>
> 이점은 **컨텍스트 격리**(서브에이전트의 시행착오가 부모 컨텍스트를 오염시키지 않음),
> **병렬성**(독립 모듈 동시 생성), **역할 분리**(각자 전문 시스템 프롬프트·도구만 사용)입니다.

> **자체 도구 루프(own tool loop)란?**
> LLM 에이전트는 한 응답으로 끝내지 않고 **"추론 → 도구 호출 → 결과 관찰 → 다시 추론"**
> 을 완료될 때까지 반복합니다. 이 사이클이 도구 루프(agentic loop)입니다. 미리 짜인
> 순서가 아니라, 관찰한 결과에 따라 다음 행동을 **스스로 결정**합니다(lint 실패 → 수정 →
> 재-lint).
>
> ```
> ┌─► ① 추론    무엇을 해야 하나?
> │   ② 도구    Read/Write/Bash/Grep …
> │   ③ 관찰    파일 내용·에러·출력
> └── ④ 판단    끝? 아니면 ①로            (완료까지 반복)
> ```
>
> **"자체(own)"** 인 이유: 스폰된 자식은 부모와 분리된 **자기만의 루프**를 돌립니다.
> 부모는 `Task`를 한 번 호출하고 대기하지만, 그 사이 자식은 **여러 턴에 걸쳐** 도구를
> 스스로 반복 호출해 작업을 완수하고 **최종 결과 하나만** 부모에 반환합니다. 부모에게
> `Task` 호출은 "블랙박스 작업 하나"지만, 안에서 자식은 완전한 에이전트로 동작합니다.
>
> 예: `sv-codegen` — `Write rtl/fifo.sv` → `Bash: lint` → 경고 관찰 → `Edit` → 재-lint
> PASS → `STATUS: complete` 반환 (이 여러 턴이 자식 루프 안에서 일어남).
>
> **도구 루프 ≠ 검증 루프**(혼동 주의):
>
> | | 자체 도구 루프 | 검증 루프 |
> |---|---------------|-----------|
> | 주체 | 개별 에이전트(자식) 내부 | 오케스트레이터(부모) 수준 |
> | 반복 | reason→tool→observe 사이클 | lint→sim→formal→synth 단계 |
> | 성격 | 작동 **메커니즘** | 품질 보장 **정책** |

> **자족적 프롬프트(self-contained prompt)란?**
> `Task`로 스폰된 에이전트는 **완전히 새로운 독립 컨텍스트**에서 시작합니다. 사용자와
> 오케스트레이터가 나눈 대화, 명확화 질문의 답변, 앞서 정한 설계 결정 — **아무것도
> 자동 전달되지 않고**, 서브에이전트가 아는 것은 오직 `prompt`에 적힌 내용뿐입니다.
> 그래서 프롬프트가 **그 하나만으로 작업을 완수할 수 있을 만큼 완결**되어야 합니다.
> 빠진 정보가 있으면 되물을 수 없어 추측(→ 오설계)하거나 실패합니다.
>
> | 섹션 | 담는 정보 | 없으면 |
> |------|-----------|--------|
> | **Component** | 무엇을 만드는지(이름·정체) | 엉뚱한 모듈 생성 |
> | **Specification** | 동작·기능 요구(확정된 폭·깊이·리셋 등) | 스펙 추측 → 오설계 |
> | **Interface** | 포트·파라미터·프로토콜 | 상위 모듈과 배선 불일치 |
> | **Constraints** | lint-clean, 네이밍 규칙, 공용 패키지 타입 | 스타일 위반 → 재작업 |
> | **Output** | **정확한 파일 경로** | 산출물 미검출/오배치 |
>
> **명확화 질문을 스폰 전에 반드시 하는 이유가 이것**입니다 — 그 답변이 프롬프트의
> Specification·Interface를 채우는 재료가 됩니다. 또 병렬 스폰 시 각 프롬프트가
> 자족적이어야 에이전트들끼리 맥락을 몰라도 인터페이스가 맞물리고(공용 타입·포트
> 규약 명시), Output 경로가 명확해야 스폰 후 `ls`로 산출물을 검증해 집계로 이어집니다.

**② 세션 모델 상속** — 스폰된 에이전트는 부모 세션과 **동일한 모델**로 실행되어
오케스트레이터와 품질·일관성을 맞춥니다(`gf-lint`/`gf-sim` 같은 순수 툴 실행은 모델 불필요).

**③ 단일 메시지 · 다중 Task 병렬 스폰** — 의존성이 없는 모듈은 한 번에 병렬 생성:

```
단일 응답 안에서:
  Task 1: sv-codegen → ALU
  Task 2: sv-codegen → RegFile
  Task 3: sv-codegen → ImmGen   (동시 실행)
```

이것이 `sv-orchestrator`의 기본 동작으로, 설계를 의존성에 따라 단계(Phase)로 분해합니다:

```
Phase 1: 독립 리프 모듈   → 병렬 스폰
Phase 2: 의존 모듈        → 병렬 스폰 (Phase 1 이후)
Phase 4: 테스트벤치·검증   → 모듈별 병렬/순차
```

**④ 결과 집계** — 모든 에이전트가 반환할 때까지 대기 후, 각 에이전트의 구조화 블록을
파싱해 취합합니다:

```
---GATEFLOW-RETURN---
STATUS: complete
FILES_CREATED: rtl/alu.sv
```

| 분류 | 조건 | 조치 |
|------|------|------|
| **ALL_PASS** | 전부 `complete` | 다음 단계 진행 |
| **PARTIAL_FAIL** | 일부만 실패 | 성공분 유지, **실패분만 재스폰**(모듈당 최대 2회) |
| **ALL_FAIL** | 전부 실패 | 사용자에게 질문(스펙/환경 문제) |

- `GATEFLOW-RETURN` 블록이 없으면 → `STATUS: ERROR`로 처리
- 파일이 실제로 디스크에 있는지 `ls`로 검증 후 진행

**⑤ Phase Gate** — 각 단계는 통과 조건을 만족해야 다음으로 넘어가고, 실패한 부분만
재스폰합니다:

| 단계 | 통과 조건 | 실패 시 |
|------|-----------|---------|
| Phase 1 (생성) | 전 컴포넌트 `complete` + 파일 존재 | 실패분 재스폰 |
| Phase 2 (Lint) | `gf-lint` = PASS | 파일별 `sv-refactor` 스폰 후 재-lint |
| Phase 5 (Sim) | `gf-sim` = PASS | `sv-debug` → `sv-refactor` 스폰 후 재-sim |

> **핵심**: ① 위임 · ② 자족적 프롬프트 · ③ 세션 모델 상속 · ④ 단일 메시지 병렬 스폰 ·
> ⑤ 구조화 반환 블록 집계 · ⑥ 실패분만 재스폰 — 관문형(Phase Gate) 파이프라인.

---

## 5. 에이전트 (20개)

에이전트는 특정 전문 영역을 담당하는 서브에이전트입니다. `agents/*.md`의
frontmatter(`description`, `tools`, `color`)로 정의됩니다.

### 네이밍 규칙 — `sv-` vs `gf-`

접두사가 곧 **아키텍처 계층**을 나타냅니다.

- **`sv-`** = **일을 하는 작업자(worker) 에이전트** — SystemVerilog RTL 도메인 전문가.
  전부 `agents/`에 있고 `Task`로 스폰됩니다. 도메인이 다르면 접두사도 달라집니다:
  **`vhdl-`**(vhdl-codegen/testbench), **`pcb-`**(pcb-designer).
- **`gf-`** = **GateFlow 브랜드 네임스페이스** — 사용자가 부르는 진입점, 즉 **슬래시
  커맨드(21개 전부)와 스킬**에 붙습니다. 다른 플러그인과 이름 충돌을 피하려는
  네임스페이스이며, 플러그인 자체를 감사·수정하는 유지보수 에이전트
  (`gf-auditor`, `gf-pluginfixer`)도 여기에 해당합니다.

즉 `sv-`는 **"누가(역할·도메인)"**, `gf-`는 **"제품 표면(어떻게 불리나)"** 을 뜻합니다.
가장 중요한 점은 **같은 기능이 두 접두사로 짝**을 이루고, `gf-`(진입점)가 `sv-`(작업자)에게
위임한다는 것입니다:

| 사용자 진입점 (`gf-`) | 실제 작업자 (`sv-`) |
|----------------------|---------------------|
| `/gf-formal`, `gf-formal` 스킬 | `sv-formal` 에이전트 |
| `gf-plan` 스킬 | `sv-planner` 에이전트 |
| `gf-viz` 스킬 | `sv-viz` 에이전트 |
| `/gf-detect`, `gf-ip-detect` 스킬 | `sv-ip-scanner` 에이전트 |
| `/gf-fix` 커맨드 | `sv-refactor` 에이전트 |
| `gf-synth` 스킬 · `/gf-pinmap` | `sv-synth` · `sv-pinmap` 에이전트 |

```
사용자 ──► /gf-*  또는  gf-* 스킬     ← 진입점(오케스트레이션 표면)
                │  (명확화 → 계획 → 스폰)
                ▼
            sv-* 에이전트             ← 실제 RTL 작업자
```

> 비유하면 `gf-`는 **프런트데스크 + 작업 지시서**, `sv-`는 **현장 기술자**입니다.
> (예외: 루트 오케스트레이터 스킬 `gf`와 `tb-best-practices`는 이 접두사 패턴 밖.)

### SystemVerilog 코어

| 에이전트 | 역할 | 트리거 예시 |
|----------|------|-------------|
| `sv-codegen` | RTL 아키텍트 — 합성 가능한 모듈 생성 | "FIFO 만들어줘", "UART FSM 작성" |
| `sv-testbench` | 검증 엔지니어 — 테스트벤치/자가검증 | "ALU 테스트벤치 작성" |
| `sv-debug` | 디버그 전문 — X값/타이밍/시뮬 실패 진단 | "출력이 왜 X야", "시뮬 멈춤" |
| `sv-refactor` | 코드 품질 — 리팩터/lint 수정/최적화 | "lint 에러 수정", "코드 정리" |
| `sv-verification` | 검증 방법론 — SVA/커버리지/formal 제약 | "핸드셰이크 어설션 추가" |
| `sv-formal` | Formal 전문 — 자연어→SVA, SymbiYosys 증명 | "FIFO 오버플로 없음 증명" |
| `sv-synth` | 합성 최적화 — Yosys, 면적/타이밍 리포트 | "합성해줘", "LUT 줄여줘" |
| `sv-understanding` | RTL 분석 — 코드 설명/신호 흐름/FSM 해석 | "이 모듈 설명", "데이터패스 추적" |
| `sv-planner` | 계획 — 명확화 질문 후 아키텍처 계획 | "DMA 설계", "서브시스템 아키텍처" |
| `sv-developer` | 풀스택 — 다중 파일/대규모 기능 구현 | "메모리 서브시스템 구현" |
| `sv-orchestrator` | 병렬 빌드 엔진 — 설계 분해 후 병렬 생성 | "RISC-V CPU 빌드", "SoC 구성" |
| `sv-viz` | 터미널 시각화 — ASCII/유니코드 계층·FSM 다이어그램 | "코드베이스 시각화", "FSM 보기" |
| `sv-tutor` | 튜터 — 풀이 리뷰/힌트/개념 교육 | "SystemVerilog 가르쳐줘" |
| `sv-ip-scanner` | IP 스캐너 — 누락 모듈/CDC 위반 탐지·자동 채움 | "누락 IP 스캔", "CDC 위반 탐지" |
| `sv-pinmap` | 핀 배치 — 보드별 제약 파일 생성 | "Arty A7 PMOD JA에 SPI 매핑" |

### VHDL

| 에이전트 | 역할 |
|----------|------|
| `vhdl-codegen` | 합성 가능한 VHDL entity/architecture 생성 |
| `vhdl-testbench` | VHDL 테스트벤치/스티뮬러스 생성 |

### PCB / 플러그인 유지보수

| 에이전트 | 역할 |
|----------|------|
| `pcb-designer` | KiCad 회로도/PCB 초안 생성 (AI 검증 루프) |
| `gf-auditor` | 플러그인 품질 감사 — 갭/불일치/누락 리포트 |
| `gf-pluginfixer` | 감사 결과를 받아 자동으로 갭 수정 |

### 자세히 보기 — `sv-viz` (터미널 시각화)

`sv-viz`는 코드베이스 아키텍처를 **ASCII/유니코드 다이어그램**으로 그려 터미널 안에서
대화형으로 탐색하게 해주는 **읽기 전용** 에이전트입니다(도구: `Read`/`Glob`/`Grep`).

**전제 — 맵이 있어야 함.** 직접 RTL을 파싱하지 않고, `/gf-map`이 미리 만든
`.gateflow/map/` 데이터를 읽어 렌더링합니다. 맵이 없으면 "Run /gf-map first"라고 안내합니다.

```
/gf-map ──► .gateflow/map/ 생성 ──► gf-viz(진입점) ──► sv-viz(렌더)
            CODEBASE.md, hierarchy.md, fsm.md …
```

**4가지 뷰** — 각기 다른 맵 파일을 읽어 렌더:

| 뷰 | 내용 | 읽는 파일 |
|----|------|-----------|
| Dashboard | 요약(모듈·FSM·health) + 압축 계층 | `CODEBASE.md`·`hierarchy.md`·`fsm.md`·`clock-domains.md` |
| Hierarchy | 모듈 계층 트리 + 인스턴스 테이블 | `hierarchy.md`·`modules/*.md` |
| FSM Viewer | 상태 다이어그램(7+ 상태는 전이 테이블) | `fsm.md`·`modules/<m>.md` |
| Module Detail | 포트·파라미터·연결·health 카드 | `modules/<m>.md`·`signals.md` 등 |

**기호 체계** — `◆`최상위 `■`중간 `□`리프 모듈, `→←↔`포트 방향, `↻`FSM, `◉`리셋 상태,
`✓`통과 `⚠`경고. 박스 드로잉과 트리 커넥터로 계층 깊이를 표현합니다.

**대화형 탐색** — 정적 그림이 아니라 세션입니다. 모든 뷰가 하단 번호 메뉴(`[1]`계층
`[2]`FSM `[3]`상세, `H`홈, `↑`부모)와 자유 입력("show uart_tx", "trace <signal>",
"which modules use X?")으로 끝나 뷰 사이를 오갑니다.

> `/gf-map`(맵 생성) → `gf-viz`(진입 스킬) → `sv-viz`(렌더 에이전트)는 앞서 설명한
> `gf-`→`sv-` 위임 패턴의 대표 사례입니다.

### 자세히 보기 — `sv-tutor` (SystemVerilog 튜터)

`sv-tutor`는 학생 풀이를 채점·리뷰하고 **답을 직접 주지 않으면서** 힌트로 유도하며
개념을 가르치는 교육 에이전트입니다(도구: `Read`/`Bash`/`Grep`/`Glob`). 학습 모드
스킬 `gf-learn`에서 라우팅됩니다. 핵심 철학은 *"정답을 그대로 주지 않는다"* — 그래서
그냥 고쳐주는 `sv-refactor`나 만들어주는 `sv-codegen`과 결정적으로 다릅니다.

**3가지 모드** (프롬프트의 `mode`로 결정):

| 모드 | 동작 |
|------|------|
| `review` | 채점 + 피드백 (답은 안 줌) |
| `hint` | 점진적 힌트만 (모호 → 구체) |
| `explain` | 개념을 가르침 |

난이도(`beginner`/`advanced`)도 받아 설명 깊이를 조절합니다.

**Review 흐름** — ① `verilator --lint-only -Wall`로 **실제 lint 실행** → ② 연습문제
스펙 대조 → ③ **Correctness·Style을 각각 10점**으로 채점 + 힌트(답 아님) + Next Steps.
`needs_revision`이면 학생이 고친 뒤 `/gf-learn check`로 돌아오는 **반복 학습 루프**가
형성됩니다. 반환 블록에 `STATUS`(complete/needs_revision)와 `SCORE: X/10`을 담습니다.

**학습 계층 구분**:

| | 정체 | 역할 |
|---|------|------|
| `gf-learn` | 스킬(진입점, 직접 호출) | 학습 모드 — 연습문제 생성, 풀이 접수 |
| `sv-tutor` | 에이전트(작업자) | 풀이 리뷰·채점·힌트·교육 |
| `gf-learn-ctx` | 스킬(내부 전용) | 워크플로 중 마이크로 레슨 삽입 |

```
"SystemVerilog 가르쳐줘"
   ▼
gf-learn 스킬 ── 문제 생성 → 풀이 접수 ──► sv-tutor (lint 실행 → 채점 → 힌트)
   │        ◄──── STATUS/SCORE 반환 ────────┘
needs_revision → /gf-learn check 로 재리뷰 (반복)
```

### 자세히 보기 — `pcb-designer` (물리 하드웨어)

`pcb-designer`는 GateFlow에서 **유일하게 RTL을 벗어나 물리 하드웨어(PCB)** 를 다루는
에이전트입니다. KiCad **회로도(.kicad_sch)·PCB(.kicad_pcb)·BOM(.csv)** 을 AI 검증
초안으로 생성합니다. 진입점은 `gf-pcb` 스킬 / `/gf-pcb`.

다른 SV 에이전트와 도구가 다릅니다 — **`Write`**(읽기 전용이 아님)와 **`WebSearch`/
`WebFetch`**(실제 부품 번호·유통사 검색)를 가집니다.

**⚠ 안전 면책 필수** — 물리 하드웨어이므로 모든 출력 파일에 경고 헤더를 넣습니다:
*"AI 생성 설계. PCB 발주·실제 회로 연결 전 반드시 사람의 엔지니어링 검토 필요."*

**자기개선 검증 루프** — `Generate → DRC → ERC → AI Review → Fix → Re-verify → Deliver`.
`kicad-cli pcb drc` / `sch erc`로 규칙 검사하고, AI Review 체크리스트(전원 넷 연결,
5mm 내 디커플링 캡, floating 입력 없음, I/O 전압 일치, 크리스털 배치 등)를 돌립니다.

**신뢰도 점수 + 범위 한계** — 출력마다 High/Medium/Low로 사람 검토 강도를 안내하고,
잘하는 것(FPGA 브레이크아웃·센서·MCU·LED 드라이버)과 **부적합(고속 >1GHz·RF·전력전자
>1A·Flex·임피던스 제어)** 을 명시해 위험 영역을 스스로 거부합니다. DRC/ERC 오류는
`~/.gateflow/pcb_learnings.json`에 축적해 다음 생성 품질을 개선합니다.

| | 대부분의 `sv-*` | `pcb-designer` |
|---|----------------|-----------------|
| 도메인 | RTL(논리) | 물리 PCB/회로도 |
| 도구 | Read/Bash 위주 | Write + WebSearch/WebFetch |
| 검증 | lint/sim/formal | DRC/ERC/AI Review |
| 특이점 | — | 안전 면책·신뢰도 점수·범위 거부·learnings |

---

### 참고 — 에이전트가 쓰는 Claude Code 도구 (Glob/Grep/Read/Bash)

에이전트 frontmatter의 `tools` 목록은 **GateFlow 고유 기능이 아니라 Claude Code가
기본 제공하는 도구**입니다. 그중 `Glob`은 여러 GateFlow 에이전트가 "작업할 파일을 먼저
수집"하는 첫 단계로 씁니다.

**Glob** — 파일 **이름/경로**를 와일드카드 패턴으로 매칭해 경로 목록을 빠르게 얻는 도구.
파일 내용은 보지 않고 이름/위치만 매칭합니다.

| 패턴 | 의미 | 예 |
|------|------|-----|
| `*` | `/` 제외 임의 문자열 | `*.sv` |
| `**` | 디렉터리 가로지르는 재귀 | `rtl/**/*.sv` |
| `?` | 한 글자 | `tb_?.sv` |
| `{a,b}` | 택일 | `*.{sv,svh}` |

**도구 구분** — 역할이 다릅니다:

| 도구 | 무엇으로 찾나 | 결과 |
|------|--------------|------|
| `Glob` | 파일 **이름/경로** 패턴 | 파일 경로 목록 |
| `Grep` | 파일 **내용**(정규식) | 매칭된 줄/파일 |
| `Read` | 지정 파일 | 파일 내용 |
| `Bash` | 쉘 명령(lint/sim 등) | 명령 출력 |

Claude Code는 파일 찾기에 `find`/`ls`보다 `Glob`·`Grep` 전용 도구를 우선 쓰도록 안내합니다.
전형적 흐름은 **Glob(찾기) → Grep(좁히기) → Read(확인)**. 예: `sv-viz`는
`Glob`으로 `.gateflow/map/CODEBASE.md` **존재를 먼저 확인**(없으면 "Run /gf-map first").

---

## 6. 스킬 (27개)

스킬은 조건에 맞으면 **자동 활성화**되는 작업 단위입니다. 각 스킬은
`skills/<name>/SKILL.md`로 정의되며, 일부는 `/gf-*` 커맨드로 직접 호출 가능하고
일부는 오케스트레이터 내부 전용(`user-invocable: false`)입니다.

### 오케스트레이션 / 라우팅

| 스킬 | 역할 | 직접 호출 |
|------|------|:--------:|
| `gf` | **주 오케스트레이터** — 전문 에이전트로 라우팅, 검증 반복 | ✅ |
| `gf-router` | 요청 분류 후 적절한 전문가로 핸드오프 | ✅ |
| `gf-expand` | 명확화 질문 + 옵션/트레이드오프 제시 | ❌(내부) |
| `gf-build` | 병렬 빌드 오케스트레이터(모듈 분해→병렬) | — |
| `gf-project` | `.gateflow/project.yaml` 프로젝트 설정 관리 | ❌(내부) |

### 설계 / 생성

| 스킬 | 역할 |
|------|------|
| `gf-plan` | 종합 RTL 구현 계획 수립 |
| `gf-protocols` | 프로토콜 스캐폴드(AXI4-Lite/Full/Stream, SPI, UART, I2C, Wishbone) |
| `gf-architect` | 코드베이스 아키텍처 매핑·문서화 |
| `gf-ip` | IP 블록 라이브러리 관리(설치/목록/조회) |
| `gf-ip-detect` | 코드베이스 내 IP/누락 모듈/CDC 자동 탐지 |

### 검증 / 빌드

| 스킬 | 역할 |
|------|------|
| `gf-lint` | Verilator lint + 구조화된 결과 출력 |
| `gf-sim` | DUT/TB 자동 판별 → Verilator 컴파일·시뮬 |
| `gf-cocotb` | Python(Cocotb) 테스트벤치 생성 |
| `gf-formal` | 자연어→SVA, SymbiYosys 증명·해설 |
| `gf-synth` | Yosys 합성 + 면적/타이밍/자원 리포트 |
| `gf-pnr` | nextpnr Place & Route (iCE40/ECP5/Gowin) |
| `gf-pinmap` | 보드별 핀 제약(.xdc/.pcf/.lpf/.cst) 생성 |
| `gf-fusesoc` | FuseSoC `.core` 생성, Edalize 백엔드 구동 |
| `gf-pcb` | KiCad 회로도/PCB 생성(DRC/ERC/AI 리뷰 루프) |

### 출력 해석 / 학습 / UX

| 스킬 | 역할 |
|------|------|
| `gf-errors` | Verilator/Yosys/GHDL 에러를 3계층 설명으로 번역(내부 전용) |
| `gf-summary` | 빌드/lint/시뮬 출력을 읽기 쉬운 형태로 요약 |
| `gf-viz` | 코드베이스 맵을 ASCII/유니코드로 시각화 |
| `gf-tui` | 터미널 콘솔(워크스페이스/툴/맵/릴리스 상태 한 화면) |
| `gf-learn` | SystemVerilog 학습 모드(연습문제/풀이 리뷰) |
| `gf-learn-ctx` | 워크플로 중 마이크로 레슨 삽입(내부 전용) |
| `tb-best-practices` | 테스트벤치 아키텍처·검증 방법론 가이드 |
| `gf-release` | 플러그인 릴리스 준비(매니페스트/문서/카운트 검증) |

---

## 7. 슬래시 커맨드 (21개)

`/gf-*` 형태로 직접 호출하는 명령입니다. 대부분 대응하는 스킬을 실행합니다.

### 환경 / 프로젝트

| 커맨드 | 인자 | 설명 |
|--------|------|------|
| `/gf-doctor` | — | 툴체인 환경 점검(Verilator/Yosys/sby/z3/GHDL/nextpnr/cocotb/fusesoc 등) |
| `/gf-demo` | — | 원커맨드 데모: 카운터 생성 → lint → 시뮬 |
| `/gf-scan` | — | 프로젝트 인덱싱 |
| `/gf-map` | — | 코드베이스 맵 생성 |
| `/gf-tui` | `[--snapshot] [--json] [--plain]` | GateFlow 터미널 콘솔 열기 |

### 생성 / 설계

| 커맨드 | 인자 | 설명 |
|--------|------|------|
| `/gf-gen` | `<type> <name> [options]` | 스캐폴드 생성 |
| `/gf-ip` | `add\|list\|info <block>` | IP 블록 라이브러리 관리 |
| `/gf-detect` | `[--auto-fill] [--cdc-only] [path]` | 누락 IP/스텁/CDC 이슈 스캔 |

### 검증 / 빌드

| 커맨드 | 인자 | 설명 |
|--------|------|------|
| `/gf-lint` | `[files...]` | lint 실행 |
| `/gf-sim` | `<testbench> [dut-files...]` | 시뮬레이션 실행 |
| `/gf-cocotb` | `<module> [test-description]` | Cocotb Python 테스트벤치 생성 |
| `/gf-formal` | `[files...] [--property '설명']` | formal 검증 실행 |
| `/gf-fix` | `<file>` | lint 자동 수정 |
| `/gf-fusesoc` | `[--target sim\|synth]` | FuseSoC `.core` 생성 |

### 합성 / 구현 / 배포

| 커맨드 | 인자 | 설명 |
|--------|------|------|
| `/gf-pnr` | `[--target ice40\|ecp5\|gowin]` | Place & Route |
| `/gf-pinmap` | `<board> [peripheral] [connector]` | 핀 제약 파일 생성 |
| `/gf-boards` | `[board-name] [connector]` | 지원 보드/핀아웃 조회 |
| `/gf-flash` | `[bitstream-file]` | 비트스트림을 FPGA에 플래시 |
| `/gf-pcb` | `[description]` | KiCad 회로도/PCB 초안 생성 |

### 플러그인 유지보수

| 커맨드 | 인자 | 설명 |
|--------|------|------|
| `/gf-audit` | `[--fix] [--category ...]` | 플러그인 품질 감사(+자동 수정) |
| `/gf-release` | `[--version X.Y.Z] [--check-only]` | 릴리스 준비/검증 |

---

## 8. IP 블록 라이브러리 (8개)

`ip/<block>/` 아래에 **RTL + 테스트벤치 + formal 속성 + 문서 + 메타데이터**가
한 세트로 들어 있는 검증된 드롭인 블록입니다.

매번 새로 생성·검증하는 대신, 이미 **lint·시뮬레이션·formal 속성**까지 갖춰진 블록을
프로젝트에 복사해 넣습니다.

### 블록 해부 — 한 블록 = 6개 파일

각 블록은 "코드 + 테스트 + 수학적 증명 + 문서"를 자족적으로 담습니다.

```
ip/<block>/
├── block.yaml             # 메타데이터 (파라미터·포트·formal 증명 목록·의존성)
├── rtl/<block>.sv         # 합성 가능한 RTL 소스
├── tb/tb_<block>.sv       # 자가검증 테스트벤치
├── formal/<block>_props.sv# SVA 속성 (assert property)
├── formal/<block>.sby     # SymbiYosys 증명 설정
└── README.md              # 인스턴스화 예시 + 검증 명령
```

### 8개 블록 상세

| 블록 | 설명 | 핵심 파라미터 | Formal 속성 |
|------|------|---------------|-------------|
| `fifo_sync` | 동기 FIFO, full/empty 플래그 | `WIDTH=8`, `DEPTH=16` | 오버플로·언더플로 없음, 포인터 범위 |
| `fifo_async` | 비동기(2클럭) FIFO, **Gray 코드 포인터**로 CDC | `WIDTH=8`, `DEPTH=8` | full 시 쓰기 없음 |
| `cdc_2ff` | 단일 비트 2단 FF 동기화기 | `STAGES=2` | (props 포함) |
| `cdc_handshake` | 멀티비트 req/ack 핸드셰이크 CDC | `WIDTH=8` | 전송 중 back-pressure |
| `debouncer` | 버튼 디바운서 + 엣지 검출(rise/fall) | `CLK_FREQ`, `DEBOUNCE_MS=20` | (props 포함) |
| `spi_master` | SPI 마스터, **4가지 CPOL/CPHA 모드 전부** | `CLK_DIV=4`, `DATA_WIDTH=8` | busy일 때 CS_N low |
| `uart` | UART TX+RX, 설정 가능 보드레이트(8N1) | `CLK_FREQ`, `BAUD_RATE=115200` | idle 시 TX high, valid 후 ready 해제 |
| `axi4lite_slave` | AXI4-Lite 레지스터 슬레이브, 바이트 strobe | `ADDR_WIDTH=8`, `DATA_WIDTH=32`, `NUM_REGS=16` | write 완료 후 응답 |

### `block.yaml` — 기계가 읽는 계약

메타데이터가 단순 설명이 아니라 포트 폭을 파라미터로 표현하고 증명해야 할 불변식을
목록화한 계약입니다. `sv-ip-scanner`가 이를 읽어 포트 매칭·자동 삽입에 활용합니다.

```yaml
name: fifo_sync
version: 1.0.0
description: Synchronous FIFO with parameterized width and depth
parameters:
  WIDTH: { type: int, default: 8,  description: "Data width in bits" }
  DEPTH: { type: int, default: 16, description: "FIFO depth (power of 2)" }
ports:
  - { name: wr_data, dir: input,  width: WIDTH }   # 폭을 파라미터로 표현
  - { name: full,    dir: output, width: 1 }
formal_proofs:
  - p_no_overflow:  "FIFO never accepts writes when full"
  - p_no_underflow: "FIFO never allows reads when empty"
  - p_ptr_range:    "Pointer difference never exceeds DEPTH"
dependencies: []
```

각 formal 속성은 실제 SVA로 구현됩니다 — 예: 언더플로 방지

```systemverilog
p_no_underflow: assert property (@(posedge clk) disable iff (!rst_n)
    !(rd_en && empty));    // 비었을 때 읽기 요청이 있으면 위반
```

### `gf-ip` — 라이브러리 조작

| 동작 | 하는 일 |
|------|---------|
| `/gf-ip list` | 모든 블록의 이름·설명·검증 상태 표시 |
| `/gf-ip info <block>` | 파라미터·포트·formal 증명·의존성 상세 |
| `/gf-ip add <block>` | 블록을 현재 프로젝트에 설치 |

**`add` 흐름 (6단계)** — ① `block.yaml` 읽기 → ② `rtl/*.sv`를 프로젝트 `rtl/`로 복사
→ ③ `tb/*.sv` 복사 → ④ `formal/*` 복사 → ⑤ `.gateflow/project.yaml`의 `ip_blocks`에
추가 → ⑥ README 인스턴스화 예시 표시.

```systemverilog
fifo_sync #(.WIDTH(8), .DEPTH(32)) u_fifo (
    .clk(sys_clk), .rst_n(sys_rst_n),
    .wr_en(wr_valid && !fifo_full), .wr_data(wr_data),
    .rd_en(rd_consume), .rd_data(rd_out),
    .full(fifo_full), .empty(fifo_empty)
);
```

### 자동 탐지·자동 채움과의 연계

수동 `add`뿐 아니라, **`sv-ip-scanner` 에이전트 / `gf-ip-detect` 스킬 / `/gf-detect`** 가
코드베이스를 스캔해 *인스턴스화됐지만 정의 없는 모듈*, *스텁*, *CDC 위반*을 찾아
라이브러리 블록으로 **자동 채움(auto-fill)** 을 제안합니다. (예: CDC 위반 발견 시
`cdc_2ff`/`cdc_handshake` 삽입 유도.)

### 검증 상태 — 실측

스킬 문서는 8개 블록 전부 `lint + sim + formal`로 표기합니다. 이 저장소에 설치된
툴로 `fifo_sync`를 직접 검증한 결과:

- ✅ **Lint** — `verilator --lint-only -Wall` → PASS
- ✅ **Sim** — `tb_fifo_sync` 실행 → **8 passed, 0 failed**
- ⚠️ **Formal 주의** — 이 저장소에 apt로 설치한 **Yosys 0.33 / SymbiYosys 0.68** 조합에서는
  IP의 formal 증명이 그대로 통과하지 않습니다:
  1. `.sby`의 `[files]` 경로가 sby 0.68에서 basename으로 평탄화되어 스크립트의
     `read -formal rtl/…` 경로와 어긋남
  2. `_props.sv`의 concurrent SVA(`assert property (@(posedge clk) …)`)를 Yosys 0.33
     네이티브 프론트엔드가 거부(`unexpected '@'`) — 최신 Yosys 또는 Verific 프론트엔드 필요

  → formal 증명은 더 최신 Yosys/sby 조합을 전제로 작성돼 있습니다(플러그인 저장소 쪽
  버전 이슈이며 `gateflow-ex` 코드와는 무관). 또한 IP 테스트벤치도 예제 카운터와 같이
  클럭 생성에 blocking 할당을 써서 `-Wall`을 fatal로 두면 시뮬 빌드가 막히므로
  `-Wno-BLKSEQ`로 우회합니다.

---

## 9. 보드 데이터베이스 (4개)

`boards/<board>/`에 보드 메타데이터(`board.yaml`)와 핀 제약 파일이 들어 있습니다.
`sv-pinmap`/`gf-pinmap`이 이를 참조해 올바른 핀 배치를 생성합니다.

| 보드 | FPGA | 제약 포맷 | 합성/PNR 타깃 |
|------|------|-----------|---------------|
| Arty A7-35T | Xilinx xc7a35t | `.xdc` | synth_xilinx |
| Basys 3 | Xilinx xc7a35t | `.xdc` | synth_xilinx |
| iCEBreaker | Lattice iCE40UP5K | `.pcf` | synth_ice40 / nextpnr-ice40 |
| Tang Nano 9K | Gowin GW1NR-9 | `.cst` | synth_gowin |

**`board.yaml` 예시 (iCEBreaker)** — 클럭/LED/버튼/PMOD 핀맵 포함:

```yaml
name: 1BitSquared iCEBreaker
fpga: { family: ice40, device: iCE40UP5K-SG48I, package: SG48 }
synth_target: synth_ice40
pnr_target: nextpnr-ice40 --up5k --package sg48
programmer: openFPGALoader -b ice40_generic
clock: { pin: 35, frequency: 12MHz }
leds: [11, 37]
pmod:
  p1a: [4, 2, 47, 45, 3, 48, 46, 44]
```

새 보드는 `community/contributing-boards.md` 가이드에 따라 추가할 수 있습니다.

---

## 10. Hooks (자동화 훅)

`hooks/hooks.json`에 정의된 이벤트 훅으로, Claude Code 라이프사이클에 개입합니다.
스크립트는 **결정적(deterministic)** 으로 작성되어(LLM 호출 없음) 훅 실패로 인한
잡음을 방지합니다.

| 이벤트 | 스크립트 | 동작 |
|--------|----------|------|
| **SessionStart** | `check-dependencies.sh` | 세션 시작 시 툴 의존성 점검 + 웰컴 배너 표시(자동 설치는 안 함, 수동 안내만) |
| **SessionStart** | `session-tracker.py` | 세션 추적 |
| **UserPromptSubmit** | `userpromptsubmit-sv-nudge.py` | 프롬프트가 SV/V 관련이면 작은 넛지 메시지 표시(차단하지 않음) |
| **PreToolUse (Bash)** | `pretooluse-bash-guard.py` | SV/V 소스 파일을 삭제·덮어쓸 것 같은 Bash 명령에 확인 요청 |
| **PostToolUse (Write\|Edit)** | `posttooluse-sv-lint-nudge.py` | SV 파일 수정 후 lint 실행을 넛지 |
| **Stop** | `stop-hook.sh` | 세션 종료 시 정리 |

> ⚠️ 참고: SessionStart 훅의 의존성 체크는 **자동 설치를 하지 않습니다**. 누락된 툴은
> 안내만 하므로, 실제 설치는 별도로 해야 합니다(이 저장소에서는 이미 전체 툴체인을 설치함).

---

## 11. 외부 도구 통합 / 툴체인

GateFlow는 오픈소스 EDA 툴을 감싸 자연어로 구동합니다.

| 단계 | 툴 | 담당 스킬/커맨드 |
|------|-----|-----------------|
| Lint | Verilator, Verible | `gf-lint` / `/gf-lint`, `/gf-fix` |
| 시뮬레이션 | Verilator, Icarus, Cocotb | `gf-sim`, `gf-cocotb` / `/gf-sim` |
| Formal | SymbiYosys(sby) + z3/boolector | `gf-formal` / `/gf-formal` |
| 합성 | Yosys | `gf-synth` / `/gf-synth` |
| Place & Route | nextpnr (iCE40/ECP5/Gowin) | `gf-pnr` / `/gf-pnr` |
| 비트스트림 | icestorm(icepack), trellis | (PNR 후속) |
| 플래시 | openFPGALoader | `/gf-flash` |
| VHDL | GHDL | `vhdl-codegen`, `vhdl-testbench` |
| 빌드 관리 | FuseSoC + Edalize | `gf-fusesoc` / `/gf-fusesoc` |
| 파형 | GTKWave | (시뮬 산출물 `.vcd`) |
| PCB | KiCad | `gf-pcb` / `/gf-pcb` |

`integrations/` 폴더에는 OpenLane, F4PGA, OpenFPGA, OpenClaw 등과의 연동 문서가 있습니다.

---

## 12. 설정 방법

### 설치 (3가지)

```bash
# 1) 마켓플레이스 (권장)
claude plugin marketplace add codejunkie99/Gateflow-Plugin
claude plugin install gateflow

# 2) 클론 후 실행
git clone https://github.com/codejunkie99/Gateflow-Plugin.git
claude --plugin-dir ./Gateflow-Plugin/plugins/gateflow

# 3) settings.json 에 영구 등록 (gateflow-ex 방식)
```

### 저장소 단위 활성화 (`.claude/settings.json`)

`gateflow-ex`는 아래처럼 마켓플레이스를 등록하고 플러그인을 활성화합니다.
이 저장소를 열면 GateFlow가 자동 로드됩니다.

```json
{
  "extraKnownMarketplaces": {
    "gateflow": { "source": { "source": "github", "repo": "codejunkie99/Gateflow-Plugin" } }
  },
  "enabledPlugins": { "gateflow@gateflow": true }
}
```

### 프로젝트별 설정 (`.claude/gateflow.local.md`)

```yaml
---
verilator_flags: ["-Wall"]
top_module: counter
clock_freq: 100MHz
---
# Project Notes
- 프로젝트 고유 메모/제약을 여기에 기록
```

---

## 13. gateflow-ex 에서의 활용

`gateflow-ex`는 이 플러그인을 사용하는 최소 예제 프로젝트입니다.

| 파일 | 역할 |
|------|------|
| `.claude/settings.json` | GateFlow 플러그인 활성화 |
| `.claude/gateflow.local.md` | 프로젝트별 GateFlow 설정 |
| `rtl/counter.sv` | 예제 DUT(파라미터화 카운터) |
| `tb/tb_counter.sv` | 자가검증 테스트벤치(6 checks) |
| `Makefile` | `make lint` / `make sim` 단축 |

### 바로 해볼 수 있는 것

```
/gf-doctor                 # 툴체인 점검
/gf-lint                   # rtl/ 린트
/gf-sim tb/tb_counter.sv   # 시뮬레이션
"FIFO 만들고 테스트해줘"     # gf 오케스트레이터가 생성→검증까지
"UART 컨트롤러 설계 계획"    # sv-planner 로 아키텍처 계획
/gf-formal --property "카운터가 MAX를 넘지 않음"
```

로컬(`Makefile`)로도 검증 가능:

```bash
make lint    # verilator --lint-only -Wall
make sim     # 빌드 + 자가검증 TB 실행 → "6 passed, 0 failed"
make clean
```

---

> **요약**: GateFlow는 20 에이전트 · 27 스킬 · 21 커맨드 · 8 IP · 4 보드로 구성된
> "자연어 하드웨어 개발 플랫폼"입니다. 핵심은 `gf` 오케스트레이터가 요청을 전문
> 에이전트로 라우팅하고, lint→sim→formal→synth 검증 루프를 자동으로 돌려
> **검증된 RTL**을 만들어 준다는 점입니다.
