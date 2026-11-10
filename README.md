# APB FIFO UVM Verification

A personal verification-improvement project based on the upstream open-source APB FIFO UVM repository.

- **Upstream project:** https://github.com/osaidnur/APB-FIFO-Verification-using-UVM
- **Personal repository:** https://github.com/hahayyf666-netizen/APB-FIFO-Verification-using-UVM
- **Final RTL/UVM commit:** [aef813f](https://github.com/hahayyf666-netizen/APB-FIFO-Verification-using-UVM/commit/aef813f4cb9baa696f0ddbf1e322289c6005d42c)
- **Methodology:** SystemVerilog / UVM 1.2
- **Simulator used for final regression:** Synopsys VCS O-2018.09-SP2
- **Coverage tool:** Synopsys URG O-2018.09-SP2

> This repository is a personal fork containing study, debugging, verification and documentation work on top of the upstream project. The upstream implementation and the work performed in this fork should be distinguished.

## 1. DUT Overview

The Design Under Test is an APB3-accessible synchronous FIFO.

| Parameter | Value |
|---|---:|
| Data width | 8 bits |
| FIFO depth | 16 entries |
| Clock | 100 MHz (10 ns period) |
| Reset | Active-low asynchronous reset (PRESETn) |
| APB wait states | Zero-wait (PREADY tied high) |

### Register map

| Address | Register | Access | Description |
|---|---|---|---|
| 0x00 | CTRL | R/W | Enable, software clear, Drop-on-Full |
| 0x04 | THRESH | R/W | Almost-full and almost-empty thresholds |
| 0x08 | STATUS | R | FIFO count and status flags |
| 0x0C | DATA | R/W | Write pushes a byte; read pops a byte |

CTRL:
- Bit 0 — EN: FIFO enable.
- Bit 1 — CLR: software clear request; self-clearing.
- Bit 2 — DOF: Drop On Full control.

THRESH:
- Bits [7:0] — almost-full threshold.
- Bits [15:8] — almost-empty threshold.

STATUS:
- Bit 0 — EMPTY.
- Bit 1 — FULL.
- Bit 2 — ALMOST_FULL.
- Bit 3 — ALMOST_EMPTY.
- Bit 4 — OVERFLOW.
- Bit 5 — UNDERFLOW.
- Bits [13:6] — COUNT.

The FIFO count must represent values from 0 through 16, so the internal count requires 5 bits.

In this implementation, the almost-full flag is asserted when count > almost_full_th; the almost-empty flag is asserted when count <= almost_empty_th.

PSLVERR is asserted for a DATA-register write during the APB ACCESS phase when the FIFO is enabled, full, and DOF is set.

## 2. UVM Verification Architecture

The environment uses the following transaction flow:

1. A Sequence creates APB sequence items.
2. The Sequencer arbitrates sequence items.
3. The Driver converts sequence items into APB SETUP and ACCESS signaling.
4. The DUT performs the requested register or FIFO operation.
5. The Monitor observes completed APB transfers and publishes transaction objects through an Analysis Port.
6. The Scoreboard uses a Reference Model to calculate expected behavior and compares expected values with observed DUT responses.
7. The Subscriber samples functional coverage independently of the Scoreboard.

Main components include:
- APB interface, sequence item, sequencer, driver and monitor.
- APB agent and UVM environment.
- FIFO Reference Model and Scoreboard.
- Functional Coverage Subscriber.
- Directed, random and stress tests.

## 3. Verification Scenarios

Nine UVM tests were run in the final regression:

| Test | Main objective |
|---|---|
| reset_test | Reset behavior and recovery |
| basic_operation_test | FIFO push/pop and data integrity |
| fifo_clear_test | Software clear behavior |
| fifo_enable_test | Enable/disable behavior |
| overflow_test | Full FIFO write, overflow flag and PSLVERR behavior |
| underflow_test | Empty FIFO read and underflow flag behavior |
| threshold_test | Almost-full/almost-empty threshold boundaries |
| random_test | Constrained-random APB transactions |
| stress_test | Combined directed sequences and stress traffic |

## 4. Debugging and Verification Improvements

The work recorded in this personal development history includes investigation and fixes or improvements involving:

- Active-low reset polarity and reset behavior.
- FIFO full indication and count handling.
- Sticky overflow/underflow flag clearing behavior.
- APB PSLVERR assertion conditions for writes to a full FIFO.
- Scoreboard handling of unsuccessful FIFO pop operations.
- Command-line UVM test selection through +UVM_TESTNAME.
- Threshold sequence boundary checks.
- Randomization failure handling and response consumption.
- Direction-specific DATA coverage sampling (WDATA on writes and RDATA on reads).

The exact changes are recorded in the Git history, including commit aef813f.

## 5. Final Regression Results

The final source version was compiled and all nine tests were rerun with seed 12345.

| Test | Total transactions | Passed checks | Failed checks |
|---|---:|---:|---:|
| reset_test | 12 | 10 | 0 |
| basic_operation_test | 136 | 126 | 0 |
| fifo_clear_test | 48 | 42 | 0 |
| fifo_enable_test | 20 | 16 | 0 |
| overflow_test | 75 | 66 | 0 |
| underflow_test | 52 | 39 | 0 |
| threshold_test | 118 | 110 | 0 |
| random_test | 113 | 83 | 0 |
| stress_test | 502 | 419 | 0 |
| **Total** | **1076** | **911** | **0** |

Final regression summary:
- 9/9 tests passed.
- 1076 observed transactions.
- 911 Scoreboard checks passed.
- 0 failed checks.
- UVM_WARNING: 0.
- UVM_ERROR: 0.
- UVM_FATAL: 0.

The transaction count and Scoreboard check count are different metrics: not every observed transaction results in a data/register comparison.

## 6. Coverage Results

The final URG report was generated by merging the coverage databases from the nine tests with the design coverage database.

### DUT code coverage — apb_sync_fifo

| Metric | Coverage |
|---|---:|
| Line | 98.33% |
| Branch | 95.83% |
| Condition | 72.73% |
| Toggle | 80.67% |
| FSM | No reportable data |

**Functional Group Coverage: 97.62%.**

The URG Dashboard Overall Score (61.46%) includes UVM/testbench modules. It is not the DUT-only coverage score. The DUT figures above are taken specifically from the apb_sync_fifo module report.

Coverage is not claimed to be 100%; uncovered RTL conditions and toggles should be interpreted in the context of the design and legal stimulus.

## 7. Environment and Reproduction

Final regression environment:
- CentOS Linux 7.
- Synopsys VCS O-2018.09-SP2.
- UVM 1.2.
- Synopsys URG O-2018.09-SP2.
- SystemVerilog and GNU Make.

A compatible VCS installation, UVM 1.2 support and a valid license are required.

Run commands from the repository root.

Compile: **make -C sim compile**

Run one test (default is basic_operation_test):
- **make -C sim run TEST_NAME=reset_test**
- **make -C sim run TEST_NAME=overflow_test**
- **make -C sim run TEST_NAME=random_test**
- **make -C sim run TEST_NAME=stress_test**

Run one test with VCS/URG coverage:
- **make -C sim coverage TEST_NAME=stress_test**

The Makefile coverage target builds and runs the selected test with line, condition, FSM, toggle and branch metrics, then generates an URG report under sim/coverage_report/.

**Note:** The final nine-test merged report described above was produced using separate per-test coverage databases and URG merge. Running the single-test Makefile coverage target does not reproduce that merged nine-test report by itself.

## 8. Learning Outcomes

This project provided practical work with:
- APB transaction phases and register access.
- FIFO RTL behavior and boundary conditions.
- UVM component roles and transaction flow.
- Reference Model and Scoreboard checking.
- Constrained-random stimulus and seed-based reproducibility.
- Functional Coverage planning and sampling.
- VCS regression execution and URG analysis.
- RTL/testbench debug using logs and source inspection.

## 9. Repository and Attribution

The upstream project is maintained at https://github.com/osaidnur/APB-FIFO-Verification-using-UVM.

This personal repository preserves the upstream project structure and adds the local verification/debugging work documented in the commit history. For attribution, original upstream contributions should be credited to the upstream author; only work actually performed in this personal fork should be presented as personal modifications.
