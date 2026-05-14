#include "xparameters.h"
#include "xil_printf.h"
#include "xgpio.h"
#include "xuartlite.h"
#include "sleep.h"

#define GPIO_BASEADDR XPAR_XGPIO_0_BASEADDR
#define UART_BASEADDR XPAR_XUARTLITE_0_BASEADDR

#include "xuartlite_l.h"
#include "xuartlite.h"
#include "xintc.h"

static XUartLite UartLite;

int uartlite_init(void) {
    int status;
    status = XUartLite_Initialize(&UartLite, XPAR_XUARTLITE_0_BASEADDR);
    if (status != XST_SUCCESS)
        return status;
    XUartLite_DisableInterrupt(&UartLite);
    XUartLite_ResetFifos(&UartLite);
    return XST_SUCCESS;
}
int main()
{
    XGpio Gpio;
    //XUartLite UartLite;
    //XUartLite_Config *UartConfig;
    int Status;
    u32 value = 0;

    uartlite_init();
    // /* Initialize UART - SDT approach using base address */
    // UartConfig = XUartLite_LookupConfig(UART_BASEADDR);
    // if (UartConfig == NULL) {
    //     return XST_FAILURE;
    // }

    // Status = XUartLite_CfgInitialize(&UartLite, UartConfig, UART_BASEADDR);
    // if (Status != XST_SUCCESS) {
    //     return XST_FAILURE;
    // }

    int res = XUartLite_SelfTest(&UartLite);


    xil_printf("\r\nMicroBlaze UART+GPIO standalone test\r\n");

    Status = XGpio_Initialize(&Gpio, GPIO_BASEADDR);
    if (Status != XST_SUCCESS) {
        xil_printf("GPIO init failed\r\n");
        return XST_FAILURE;
    }

    /* Channel 1 as outputs (all bits output). */
    XGpio_SetDataDirection(&Gpio, 1, 0x00000000);

    while (1) {
        unsigned char c;
        XGpio_DiscreteWrite(&Gpio, 1, value);
        xil_printf("GPIO write: 0x%08x\r\n", value);
        value++;
        usleep(500000);
    }

    return 0;
}