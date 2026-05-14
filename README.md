# MicroBlaze Standalone Setup (Vivado 2024.1 + Vitis 2024.1)

This guide walks through creating a MicroBlaze-based design that can run standalone C code and includes:

- AXI UART Lite (serial console)
- AXI GPIO (digital I/O)

Target tools:

- Vivado 2024.1
- Vitis 2024.1

---

## 1) Create the Vivado hardware platform

1. Open **Vivado 2024.1**.
2. Click **Create Project**.
3. Name the project (for example: `mb_uart_gpio`) and choose a location.
4. Select **RTL Project** and check **Do not specify sources at this time**.
5. Select your FPGA board/part.
6. Finish the wizard.

### Create block design

1. In **Flow Navigator** → **IP Integrator** → **Create Block Design**.
2. Name it (for example: `design_1`).
3. Click **Add IP** and add:

   - `MicroBlaze`
   - `AXI UART Lite`
   - `AXI GPIO`
   - `Processor System Reset`
   - `Clocking Wizard` (if your board clock is not already suitable)

4. Click **Run Block Automation** for MicroBlaze.

   - Accept defaults to automatically add local memory, AXI interconnect, etc.

### Connect UART and GPIO

**Important:** AXI peripherals connect through an **AXI Interconnect**, not directly to MicroBlaze memory buses.

When you run **Block Automation** on MicroBlaze, it automatically creates:

- `axi_mem_intercon`: AXI interconnect for peripheral access
- This connects the MicroBlaze `M_AXI_DP` (Data-side AXI Master) port to slave peripherals

**Connection steps:**

1. **Connect AXI UART Lite:**
   - Drag connection from `axi_mem_intercon/M00_AXI` (or next available M*_AXI) to `axi_uartlite_0/S_AXI`
   - If `axi_mem_intercon` doesn't exist, create one:
     - Add → AXI Interconnect
     - Connect `axi_uartlite_0/S_AXI` to a slave port (e.g., S00_AXI)
     - Connect MicroBlaze `M_AXI_DP` to `axi_mem_intercon/S00_AXI` (slave side of interconnect)

2. **Connect AXI GPIO:**
   - Similarly connect `axi_gpio_0/S_AXI` to an available master port of `axi_mem_intercon` (e.g., M01_AXI)
   - Alternatively, connect directly if the interconnect has multiple slave ports

3. **Clock and reset connections:**
   - `axi_uartlite_0/s_axi_aclk` → `clk_wiz_0/clk_out1` (or system clock)
   - `axi_uartlite_0/s_axi_aresetn` → `proc_sys_reset_0/peripheral_aresetn`
   - Repeat for `axi_gpio_0`

4. **External pins for UART:**
   - Right-click `axi_uartlite_0/tx` → **Make External** → names it `tx`
   - Right-click `axi_uartlite_0/rx` → **Make External** → names it `rx`

5. **External pins for GPIO:**
   - Right-click `axi_gpio_0/gpio` (or `gpio_rtl_0` depending on direction) → **Make External** → names it (e.g., `gpio_pins`)
   - Configure GPIO width/direction in IP properties before making external

**Key Bus Hierarchy Reference:**

```text
MicroBlaze Core
├── ILMB (Instruction Local Memory Bus) → Program memory
├── DLMB (Data Local Memory Bus) → Data memory (lmb_bram)
└── M_AXI_DP (Data-side AXI Master) → AXI Interconnect (for peripherals)
    └── axi_mem_intercon
        ├── M00_AXI → axi_uartlite_0
        ├── M01_AXI → axi_gpio_0
        └── S00_AXI ← MicroBlaze M_AXI_DP
```

- **DLMB**: Only for local block RAM (memory)
- **M_AXI_DP**: Used for AXI peripheral communication (UART, GPIO, etc.)

### Address assignment and validation

1. Open **Address Editor**.
2. Ensure `axi_uartlite_0` and `axi_gpio_0` have assigned base addresses.
3. Click **Validate Design** (Tools → Validate Design).
4. Save the block design.

### Generate output products and bitstream

1. Right-click block design → **Generate Output Products**.
2. Right-click block design → **Create HDL Wrapper** (let Vivado manage wrapper).
3. In Flow Navigator:

   - **Run Synthesis**
   - **Run Implementation**
   - **Generate Bitstream**

### Export hardware for Vitis

1. After bitstream generation, go to **File → Export → Export Hardware**.
2. Ensure **Include bitstream** is checked.
3. Export as `.xsa` (for example: `mb_uart_gpio.xsa`).

---

## 2) Create a standalone application in Vitis 2024.1

1. Open **Vitis 2024.1**.
2. Create/select a workspace.
3. **File → New → Platform Project**.
4. Name it (for example: `mb_platform`) and choose the exported `.xsa`.
5. Finish platform creation.
6. **File → New → Application Project**.
7. Select the created platform.
8. Choose the MicroBlaze domain and set OS to **standalone**.
9. Pick a template:

   - `Empty Application` (recommended), or
   - `Hello World`.

---

## 3) Example standalone C code (UART + GPIO)

Use this in `main.c` for a simple test:

```c
#include "xparameters.h"
#include "xil_printf.h"
#include "xgpio.h"
#include "sleep.h"

#define GPIO_DEVICE_ID XPAR_AXI_GPIO_0_DEVICE_ID

int main()
{
    XGpio Gpio;
    int Status;
    u32 value = 0;

    xil_printf("\r\nMicroBlaze UART+GPIO standalone test\r\n");

    Status = XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
    if (Status != XST_SUCCESS) {
        xil_printf("GPIO init failed\r\n");
        return XST_FAILURE;
    }

    /* Channel 1 as outputs (all bits output). */
    XGpio_SetDataDirection(&Gpio, 1, 0x00000000);

    while (1) {
        XGpio_DiscreteWrite(&Gpio, 1, value);
        xil_printf("GPIO write: 0x%08lx\r\n", value);
        value++;
        usleep(500000);
    }

    return 0;
}
```

> Note: Macro names (`XPAR_AXI_GPIO_0_DEVICE_ID`, etc.) come from generated `xparameters.h`. If your IP instance names differ, update accordingly.

---

## 4) Build, program, and run

1. Connect board via JTAG and UART.
2. In Vitis, build the application project.
3. Open **Serial Terminal** in Vitis (set the board COM port and baud, typically 9600 for AXI UART Lite default unless changed).
4. Run the application:

   - **Run As → Launch on Hardware (Single Application Debug)**, or
   - standard run configuration on hardware.
5. Confirm UART prints appear in terminal and GPIO toggles/changes as expected.

---

## 5) Common issues

- **No UART output**
  - Check external pin constraints for UART TX/RX.
  - Confirm baud rate matches terminal settings.
  - Confirm correct board COM port.

- **GPIO not changing**
  - Verify GPIO direction is set to output.
  - Check pin constraints (XDC) map GPIO bits correctly.

- **Build errors on device IDs/macros**
  - Re-check IP instance names in Vivado.
  - Regenerate/export hardware `.xsa` and refresh Vitis platform.

---

## 6) Recommended project hygiene

- Keep Vivado project and Vitis workspace in separate folders.
- Re-export `.xsa` after major hardware changes.
- Version-control source code and constraints files.
- Document clock frequency, UART baud rate, and GPIO pin mapping in your repo.
