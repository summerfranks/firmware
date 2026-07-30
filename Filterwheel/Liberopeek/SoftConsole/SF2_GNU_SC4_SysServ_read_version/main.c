/*******************************************************************************
 * (c) Copyright 2012-2016 Microsemi SoC Products Group.  All rights reserved.
 *
 * Retrieve device and design information using System Services.
 *
 * Please refer to file README.TXT for further details about this example.
 *
 * SVN $Revision: 8684 $
 * SVN $Date: 2016-11-27 16:11:19 +0530 (Sun, 27 Nov 2016) $
 */
#include <stdio.h>
#include "drivers/mss_sys_services/mss_sys_services.h"
#include "drivers/mss_uart/mss_uart.h"

/*==============================================================================
  Messages displayed over the UART.
 */
const uint8_t g_greeting_msg[] =
"\r\n\r\n\
**********************************************************************\r\n\
********* SmartFusion2 System Services Read Version Example **********\r\n\
**********************************************************************\r\n\
This example project displays information about the device/design\r\n\
retrieved using the SmartFusion2 System Services.\r\n\
It uses the following System Services driver functions:\r\n\
    - MSS_SYS_get_serial_number()\r\n\
    - MSS_SYS_get_user_code()\r\n\
    - MSS_SYS_get_design_version()\r\n\
    - MSS_SYS_get_device_certificate()\r\n\
    - MSS_SYS_check_digest()\r\n\
----------------------------------------------------------------------\r\n";

const uint8_t g_separator[] =
"\r\n----------------------------------------------------------------------\r\n";

/*==============================================================================
  Private functions.
 */
static void display_greeting(void);
static void display_hex_values
(
    const uint8_t * in_buffer,
    uint32_t byte_length
);

/*==============================================================================
  UART selection.
  Replace the line below with this one if you want to use UART1 instead of
  UART0:
  mss_uart_instance_t * const gp_my_uart = &g_mss_uart1;
 */
mss_uart_instance_t * const gp_my_uart = &g_mss_uart0;

/*==============================================================================
  Main function.
 */
int main()
{
    uint8_t serial_number[16];
    uint8_t user_code[4];
    uint8_t design_version[2];
    uint8_t device_certificate[768];
    uint8_t status;
    int8_t tx_complete;
    
    MSS_SYS_init(MSS_SYS_NO_EVENT_HANDLER);
    
    MSS_UART_init(gp_my_uart,
                  MSS_UART_115200_BAUD,
                  MSS_UART_DATA_8_BITS | MSS_UART_NO_PARITY | MSS_UART_ONE_STOP_BIT);
        
    /* Display greeting message. */
    display_greeting();
    
    /*--------------------------------------------------------------------------
     * Device Serial Number (DSN).
     */
    status = MSS_SYS_get_serial_number(serial_number);
    
    if(MSS_SYS_SUCCESS == status)
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"Device serial number: ");
        display_hex_values(serial_number, sizeof(serial_number));
    }
    else
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"Service read device serial number failed.\r\n");
        
        if(MSS_SYS_MEM_ACCESS_ERROR == status)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"Error - MSS memory access error.");
        }
    }
    MSS_UART_polled_tx_string(gp_my_uart, g_separator);
    
    /*--------------------------------------------------------------------------
     * User code.
     */
    status = MSS_SYS_get_user_code(user_code);
    if(MSS_SYS_SUCCESS == status)
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"User code: ");
        display_hex_values(user_code, sizeof(user_code));
    }
    else
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"Service read user code failed.\r\n");
        
        if(MSS_SYS_MEM_ACCESS_ERROR == status)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"Error - MSS memory access error.");
        }
    }
    MSS_UART_polled_tx_string(gp_my_uart, g_separator);

    /*--------------------------------------------------------------------------
     * Design version.
     */
    status = MSS_SYS_get_design_version(design_version);
    if(MSS_SYS_SUCCESS == status)
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"Design version: ");
        display_hex_values(design_version, sizeof(design_version));
    }
    else
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"Service get design version failed.\r\n");
        
        if(MSS_SYS_MEM_ACCESS_ERROR == status)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"Error - MSS memory access error.");
        }
    }
    MSS_UART_polled_tx_string(gp_my_uart, g_separator);
    
    /*--------------------------------------------------------------------------
     * Device certificate.
     */
    status = MSS_SYS_get_device_certificate(device_certificate);
    if(MSS_SYS_SUCCESS == status)
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"Device certificate: ");
        display_hex_values(device_certificate, sizeof(device_certificate));
    }
    else
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"Service get device certificate failed.\r\n");
        
        if(MSS_SYS_MEM_ACCESS_ERROR == status)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"Error - MSS memory access error.");
        }
    }
    MSS_UART_polled_tx_string(gp_my_uart, g_separator);
    do {
        tx_complete = MSS_UART_tx_complete(gp_my_uart);
    } while(0 == tx_complete);
    
    /*--------------------------------------------------------------------------
     * Check digest.
     */
    status = MSS_SYS_check_digest(MSS_SYS_DIGEST_CHECK_FABRIC);
    if(MSS_SYS_SUCCESS == status)
    {
        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"Digest check success.");
    }
    else
    {
        uint8_t fabric_digest_check_failure;
        uint8_t envm0_digest_check_failure;
        uint8_t envm1_digest_check_failure;
        uint8_t sys_digest_check_failure;
        uint8_t envmfp_digest_check_failure;
        uint8_t envmup_digest_check_failure;
        uint8_t svcdisabled_digest_check_failure;
        
        fabric_digest_check_failure = status & MSS_SYS_DIGEST_CHECK_FABRIC;
        envm0_digest_check_failure = status & MSS_SYS_DIGEST_CHECK_ENVM0;
        envm1_digest_check_failure = status & MSS_SYS_DIGEST_CHECK_ENVM1;
        sys_digest_check_failure = status & MSS_SYS_DIGEST_CHECK_SYS;
        envmfp_digest_check_failure = status & MSS_SYS_DIGEST_CHECK_ENVMFP;
        envmup_digest_check_failure = status & MSS_SYS_DIGEST_CHECK_ENVMUP;
        svcdisabled_digest_check_failure = status & MSS_SYS_DIGEST_CHECK_SVCDISABLED;

        MSS_UART_polled_tx_string(gp_my_uart,
                                  (const uint8_t*)"\r\nDigest check failure:");
        if(fabric_digest_check_failure)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"\r\nFabric digest check failed.");
        }
        if(envm0_digest_check_failure)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"\r\neNVM0 digest check failed.");
        }
        if(envm1_digest_check_failure)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"\r\neNVM1 digest check failed.");
        }
        if(sys_digest_check_failure)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"\r\n System Controller ROM digest check failed.");
        }
        if(envmfp_digest_check_failure)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"\r\n Private eNVM factory digest check failed.");
        }
        if(envmup_digest_check_failure)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"\r\n Private eNVM user digest check failed.");
        }
        if(svcdisabled_digest_check_failure)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"\r\n Digest check service disabled by the user lock.");
        }
        if(status == MSS_SYS_CLK_DIVISOR_ERROR)
        {
            MSS_UART_polled_tx_string(gp_my_uart,
                                      (const uint8_t*)"\r\n Clock divisor error.");
        }
    }
    MSS_UART_polled_tx_string(gp_my_uart, g_separator);
    
    for(;;)
    {
        ;
    }
}

/*==============================================================================
  Display greeting message when application is started.
 */
static void display_greeting(void)
{
    MSS_UART_polled_tx_string(gp_my_uart, g_greeting_msg);
}

/*==============================================================================
  Display content of buffer passed as parameter as hex values
 */
static void display_hex_values
(
    const uint8_t * in_buffer,
    uint32_t byte_length
)
{
    uint8_t display_buffer[128];
    uint32_t inc;
    
    if(byte_length > 16u)
    {
        MSS_UART_polled_tx_string( gp_my_uart,(const uint8_t*)"\r\n" );
    }
    
    for(inc = 0; inc < byte_length; ++inc)
    {
        if((inc > 1u) &&(0u == (inc % 16u)))
        {
            MSS_UART_polled_tx_string( gp_my_uart,(const uint8_t*)"\r\n" );
        }
        snprintf((char *)display_buffer, sizeof(display_buffer), "%02x ", in_buffer[inc]);
        MSS_UART_polled_tx_string(gp_my_uart, display_buffer);
    }
}
