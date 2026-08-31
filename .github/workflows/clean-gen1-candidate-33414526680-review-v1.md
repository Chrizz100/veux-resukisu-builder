# CLEAN-GEN1 Candidate Review v1
Snapshot run: 33414526680
Status: REVIEWED CANDIDATE — NOT PROMOTED
Kernel build: NO
Target: VEUX only / Linux 5.4.274

## Baseline
- P0 tree: `9a1395f5e72d12d0fdb107dc7531c8e2c731693c`
- ReSukiSU PRE: `419e270b50ad61725185dec74f438b8cb59c6889`
- ReSukiSU candidate: `0b5efe9e0102c43ca5c41174d500f5a7080cd0c7`
- ReSukiSU excluded feature commit remains: `b2ac2fc8703ce9f5226e2a38a59f8b72f8a3005c`
- Candidate remains `UNAPPROVED_CANDIDATE`.

## ReSukiSU delta classification

| Commit | Scope | CLEAN 5.4 decision | Reason |
|---|---|---|---|
| `d5298be49b7ead86f726b1563d6abc1b5efa240a` | ksud | TRACK SEPARATELY | Fixes `su` identity argument handling; userspace/runtime, not kernel source integration. |
| `83614d892d5fdbdb982ace46f6a2f837ef0c3595` | manager | SKIP KERNEL | Translations only. |
| `82c7f72d6486db3edc5deaa321e4acf96febd38e` | build/kernel build support | SKIP FOR 5.4 RUNTIME | Android 17/6.18 DDK/build support; 5.4 runtime semantics unchanged. |
| `a543d21c5f1c247a56f841a01167b6a1356a5248` | kernel/core/init.c | OPTIONAL / LATE-LOAD ONLY | Forces first late-load `track_throne` search synchronous; relevant to module/insmod late-load race, not required for built-in GEN1 semantics. |
| `736d9fe8a66c18908e67cfaa4abf82c4326308aa` | ksud | TRACK SEPARATELY | Slot parsing optimization. |
| `3e80ad77258e6736cac158bd6ab8f9e3f0dac942` | ksud | TRACK SEPARATELY | OTA post-processing behavior. |
| `b4e5faef6bf463a59ad9e74cfb88444497208cca` | ksud | TRACK SEPARATELY | ZIP reuse/module-ID validation. |
| `4a4b30f08391b203f8e29c7e8098ea1d13a7039f` | ksud deps | SKIP KERNEL | Dependency update. |
| `bef79c339794924a4f376d195b460325d9f058be` | CI | SKIP | CI dependency only. |
| `738b01a8152127acc8e1d2863c9dcfe001f51039` | ksuinit deps | SKIP KERNEL | Dependency update. |
| `aa7c82a7f5b5f8693118854383d88d522bdcd0f1` | manager/docs/license | SKIP KERNEL | License/about changes. |
| `0b5efe9e0102c43ca5c41174d500f5a7080cd0c7` | license | SKIP KERNEL | License file rename. |

### ReSukiSU conclusion
For the built-in VEUX/Linux-5.4.274 CLEAN kernel, no new mandatory runtime-kernel delta after `419e270b` was found. `a543d21c` remains an optional late-load-only compatibility change. Current ksud changes are tracked separately for manager/runtime compatibility and must not be confused with kernel source requirements.

## SUSFS 2.3 delta classification — gki-android12-5.10

| Commit | CLEAN 5.4 decision | Reason |
|---|---|---|
| `86bb893e9a103b97d17045306f35eb239a623f2a` | MUST ADAPT | OPEN_REDIRECT maps/SRCU lifetime: fixes memory leak and possible deadlock; caller must hold SRCU while using redirected pathname. |
| `c5723cc09c19786fcb701d25a8097e2edbee412a` | MUST REVIEW + ADAPT | OPEN_REDIRECT hook refactor moves redirect handling into namei/open path internals. Relevant to our already-confirmed fake-filename retry/lifetime defect. Do not cherry-pick blindly. |
| `ee7dc7a03b7c836952cce55c5f3834de62a465d1` | DO NOT WHOLESALE SYNC | Official KernelSU sync; CLEAN uses ReSukiSU and must compare only required interface semantics. |
| `3c14ad549f826b1f53878ec8c12253efebeed75a` | CONDITIONAL | Compiler fix associated with OPEN_REDIRECT refactor; carry only if the adapted 5.4 implementation requires the same fix. |
| `1b493defc6d26684a3bec612da47e03c9d8cfe20` | DO NOT WHOLESALE SYNC | Official KernelSU sync. |
| `f3087ec1be3bd9ea8d0486af64167a4bc6580b6f` | MUST PRESERVE SEMANTICS | `TIF_PROC_NO_SU`; already part of our required 5.4 process-state model. |
| `da34bba1f7803c0f3165661c64bf0d19545dfc07` | MUST ADAPT | Correct `stat/faccessat` bridge: `getname_flags()` → real `struct filename *` → handler → `filename_lookup()`. This directly addresses the confirmed CROSS-TU pointer-contract defect. Exact 5.4 ownership/retry behavior must be audited before implementation. |
| `a029a5189aa63b47f20c901557933d3b8b3a5db1` | DO NOT WHOLESALE SYNC | Official KernelSU sync. |
| `e5c00dc9ffd6f04ad6025f09d67e7db760b6d55b` | MUST ADAPT | zygote_next SUS_MOUNT handling in `__lookup_mnt`; relevant to the WebView/zygote_next path. |
| `44d9fed948b6d21c25ace142081418690f568dd3` | MUST PRESERVE SEMANTICS | Marks `TIF_PROC_UMOUNTED` for zygote_next children configured for umount. |
| `a587763bf4c5fa358793f368abff9186c1111b5c` | DO NOT WHOLESALE SYNC | Official KernelSU sync. |
| `27ee8466fc5f151f987ea8e0ad38ba16f180bacf` | MUST PRESERVE SEMANTICS | Avoid disabling static key from atomic input-hook context. Our ReSukiSU selected line already carries the corresponding semantic fix; verify no duplicate implementation. |
| `46e4c5a1a28ad97e0537496b5585bf7a5f2355e4` | DO NOT WHOLESALE SYNC | Official KernelSU sync. |
| `fb16b41a65180979f05eac837681c4dd0addffd1` | METADATA AFTER PORT | SUSFS version bump to 2.3.0; use only once the selected 2.3 semantics are actually present. |
| `ec785f47d49f7b3871ca9356f450411020af7017` | DO NOT WHOLESALE SYNC | Official KernelSU sync. |

## Mandatory CLEAN implementation gates before compile

1. No raw `const char __user *` may be passed as `struct filename **`.
2. `stat/faccessat` ownership must be proven for this exact 5.4 tree:
   - `getname_flags()` failure / `ERR_PTR`
   - `filename_lookup()` ownership/consumption
   - retry behavior
   - whether/when `putname()` is required
   - handler replacement of `fname`
3. OPEN_REDIRECT:
   - no use of fake filename after `putname()`
   - no retry path retaining freed filename/nameidata state
   - `ERR_PTR` checked, not NULL-only
   - SRCU protected pointers never escape their read-side critical section
   - writer uses `synchronize_srcu()` for the same domain
4. `TIF_PROC_NO_SU`, `TIF_PROC_UMOUNTED`, and zygote_next flag bits must remain collision-free on ARM64.
5. No official KernelSU sync commit is imported wholesale.
6. ReSukiSU `b2ac2fc8` module-load-filter remains excluded.
7. No candidate is promoted to LAST GOOD before source-only contract/lifetime audits pass.

## Planned CLEAN staging

- P1: replace legacy vendor KernelSU with the selected ReSukiSU kernel line; SUSFS disabled; no module-load-filter.
- P2: shared authoritative hook/API header and compile-time cross-TU type contracts.
- P3: SUSFS core + process-state + SRCU/RCU infrastructure, including selected 2.3 fixes.
- P4: safe 5.4 `stat/faccessat` filename bridge and exact ownership audit.
- P5: OPEN_REDIRECT 2.3 adaptation + remaining SUSFS features, one lifetime class at a time.
- P6: deterministic compile only after all source gates pass.
- P7-A: controlled A/B with one frozen Manager+embedded-ksud combination.
- P7-B: current Manager/ksud compatibility test.

## Promotion decision

`PROMOTE_CANDIDATE=NO`

The existing Last-Good lock remains unchanged.
