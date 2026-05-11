# Parameterized ALU Design and Verification

## Overview
This project implements a parameterized Arithmetic Logic Unit (ALU) using Verilog HDL.

The ALU supports arithmetic and logical operations with configurable data width and command width. The design includes overflow detection, carry generation, comparison flags, rotate operations, signed arithmetic, and multi-cycle operations.

## Features

### Arithmetic Mode Operations
- Addition
- Subtraction
- Addition with carry
- Subtraction with borrow
- Increment / Decrement
- Comparator operations
- Signed arithmetic
- Overflow detection
- Multi-cycle multiplication operations

### Logical Mode Operations
- AND / NAND
- OR / NOR
- XOR / XNOR
- Bitwise NOT
- Shift operations
- Rotate left / rotate right

## Parameters
- DATA_WIDTH = 8
- CMD_WIDTH = 4

## Inputs
| Signal | Description |
|--------|-------------|
| CLK | Clock signal |
| RST | Reset signal |
| MODE | Arithmetic / Logical mode select |
| CE | Chip enable |
| INP_VALID | Input validity indicator |
| CMD | Operation select command |
| OPA | Operand A |
| OPB | Operand B |
| CIN | Carry input |

## Outputs
| Signal | Description |
|--------|-------------|
| RES | Operation result |
| OFLOW | Overflow flag |
| COUT | Carry out |
| G | Greater-than flag |
| L | Less-than flag |
| E | Equality flag |
| ERR | Error flag |

## Folder Structure
```text
├── README.md
├── docs
│   ├── test_plan.md
│   └── verification_report.md
└── src
    ├── design
    │   └── alu.v
    └── test_bench
        └── alu_tb.v