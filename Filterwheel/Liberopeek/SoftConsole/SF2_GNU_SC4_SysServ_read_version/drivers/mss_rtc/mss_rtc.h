/*******************************************************************************
 * (c) Copyright 2008-2010 Actel Corporation.  All rights reserved.
 * 
 *  SmartFusion2 MSS RTC bare metal software driver public API.
 *
 * SVN $Revision: 4707 $
 * SVN $Date: 2012-10-03 14:00:44 +0100 (Wed, 03 Oct 2012) $
 */

/*=========================================================================*//**
  @mainpage SmartFusion2 MSS RTC Bare Metal Driver.

  Following are key features supported by the RTC driver:
  - Initialization of RTC.
  - Read/Write calendar and binary counter to/from RTC.
  - Set alarm conditions
  - Control of RTC clock
  - Handling of Wakeup interrupt signal

  @section intro_sec Introduction
  The SmartFusion2 microcontroller subsystem (MSS) includes a real time counter (RTC)
  which allows timing delays using a low power 32 kHz oscillator or internal
  clock of 1Mhz.This software driver provides a set of functions for controlling
  the SmartFusion2 MSS RTC as part of a bare metal system where no operating system is
  available.
  This driver can be adapted for use as part of an operating system but the
  implementation of the adaptation layer between this driver and the operating
  system's driver model is outside the scope of this driver.

  @section hw_dependencies Hardware Flow Dependencies
  The configuration of all features of the SmartFusion2 MSS RTC is covered by this driver.
  There are no dependencies on the hardware flow when configuring the SmartFusion2 MSS RTC.
  The base address and register addresses and interrupt number assignment for the
  MSS RTC block are defined as constants in the SmartFusion2 CMSIS-PAL. You must ensure
  that the SmartFusion2 CMSIS-PAL is either included in the software tool chain used to
  build your project or is included in your project.

  @section theory_op Theory of Operation

  The MSS RTC driver functions are grouped into the following categories:
    - Initialization
    - Setting and reading the RTC counter current value
    - Setting the RTC match and mask values
    - RTC counter increment detection
    - Control of RTC
    - Interrupt Control

  The SmartFusion2 MSS RTC driver is initialized through a call to the MSS_RTC_init() function.
  The MSS_RTC_init() function must be called before any other RTC driver functions
  can be called. This function takes prescalar value as an input parameter.
  The MSS clock controller can supply three clock sources to the RTC
  1. Crystal Oscillator 32.767 KHz
  2. 1MHz Oscillator
  3. 50MHz Oscillator.  (25 MHz in a 1.0v part).
  The prescaler should be programmed to derive a 1Hz signal, therefore for 32.767KHz clock
  the prescaler should be programmed to 32767-1 = 32766. The prescaler is 26 bits allowing
  up to a 67 MHz Clock source to be used to derive the 1Hz time base.
  
  The SmartFusion2 MSS RTC supports two mode of operation. First is Calendar mode, which stores
  RTC values in terms of seconds, minutes, hours, days, months, years, weekdays and weeks.
  Other mode is binary mode, whose counter values can scale up to 2^43. The RTC driver
  supports both mode of operation with independent set of functions.

  Note :1. Weekday, 1: Sunday, 2: Monday ….  7:Saturday
  Note:	Reset date is Saturday 1 January 2000.
  Note:	The leap year calculations assume the year value 0-255 map to 2000 to 2255.

  The RTC current value can be set or read using the following functions:
    - MSS_RTC_set_calendar_count() - It sets new calendar values to RTC counter.
    - MSS_RTC_set_binary_count() - It sets new binary values to RTC counter.
    - MSS_RTC_get_calendar_count() - It returns calendar count.
    - MSS_RTC_get_binary_count() - It returns binary counter value.

  The compare and match features of the RTC hardware are used to generate single
  shot or periodic alarms. A wakeup interrupt is generated when an alarm triggers.
  The RTC alarm can be set using the following functions:
    - MSS_RTC_set_calendar_count_alarm()
    - MSS_RTC_set_binary_count_alarm()

  The RTC counter increment detection is done using the following function:
    - MSS_RTC_get_update_flag
    - MSS_RTC_clear_update_flag
    
  The different control functionalities of RTC are:
    - MSS_RTC_start()
    - MSS_RTC_stop()
    - MSS_RTC_reset_counter()

  The RTC Wakeup interrupt is controlled using the following functions:
    - MSS_RTC_enable_irq()- This enables wakeup interrupt. It also configures RTC whether to reset its
      counter values when a wakeup event occurs.
    - MSS_RTC_disable_irq() - It disables wakeup interrupt.
    - MSS_RTC_clear_irq() - It clears wakeup interrupt.

  The function prototypes for the RTC interrupt handler is as follows:
     void RTC_Wakeup_IRQHandler ( void )

  Entry for this interrupt handler is provided in the SmartFusion2 CMSIS-PAL vector table.
  To add a RTC wakeup interrupt handler, you must implement a
  RTC_Wakeup_IRQHandler() function as part of your application code.

 *//*=========================================================================*/
#ifndef MSS_RTC_H_
#define MSS_RTC_H_

#ifdef __cplusplus
extern "C" {
#endif 

#include "../../CMSIS/m2sxxx.h"

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_BINARY_MODE constant is used to specify the clock_mode parameter
  to the MSS_RTC_init() function. RTC will run in binary mode if this constant
  is used.
  In binary mode, the calendar counter consecutively counts from 0 all the way
  to 2^43.
 */
#define MSS_RTC_BINARY_MODE               0u

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_CALENDAR_MODE constant is used to specify the clock_mode parameter
  to the MSS_RTC_init() function. RTC will run in calendar mode if this constant
  is used.
  In calendar mode, the calendar counter counts seconds, minutes, hours, days
  month, years, weekdays and week.
 */
#define MSS_RTC_CALENDAR_MODE             1u

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_CALENDAR_DONT_CARE define is used to indicate that a field of 
  the mss_rtc_calendar_t data structure passed as parameter to
  MSS_RTC_set_calendar_count_alarm() must not be used in deciding when the requested
  alarm will be triggered. 
 */
#define MSS_RTC_CALENDAR_DONT_CARE      0xFFu

/*-------------------------------------------------------------------------*//**
  Days of the week.
 */
#define MSS_RTC_SUNDAY      1u
#define MSS_RTC_MONDAY      2u
#define MSS_RTC_TUESDAY     3u
#define MSS_RTC_WEDNESDAY   4u
#define MSS_RTC_THRUSDAY    5u
#define MSS_RTC_FRIDAY      6u
#define MSS_RTC_SATURDAY    7u

/*-------------------------------------------------------------------------*//**
  The mss_rtc_alarm_type_t enumeration is used as parameter to functions
  MSS_RTC_set_calendar_count_alarm() and MSS_RTC_set_binary_count_alarm() to specify if the
  requested alarm should occur only one time or periodically.
 */
typedef enum {
    MSS_RTC_SINGLE_SHOT_ALARM,
    MSS_RTC_PERIODIC_ALARM
} mss_rtc_alarm_type_t;

/*-------------------------------------------------------------------------*//**
  This structure is used to identify the various data types representing
  a calendar data. This will be used by RTC for only calendar mode of
  operation.
 */
typedef struct mss_rtc_calendar
{
     uint8_t second  ;
     uint8_t minute  ;
     uint8_t hour    ;
     uint8_t day     ;
     uint8_t month   ;
     uint8_t year    ;
     uint8_t weekday ;
     uint8_t week    ;
}mss_rtc_calendar_t ;

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_init() function initializes the RTC driver to a known state.
  It sets the RTS's operating mode, binary counter or calendar counter.  
  This function clears any pended RTC wake up interrupt.
  It disables RTC wake up interrupt.
  The MSS clock controller can supply three clock sources to the RTC
  1. Crystal Oscillator 32.767 KHz
  2. 1MHz Oscillator
  3. 50MHz Oscillator.  (25 MHz in a 1.0v part).
  The prescaler should be programmed to derive a 1Hz signal, therefore for
  32.767KHz clock the prescaler should be programmed to 32767-1(N-1) = 32766.
  The prescaler is 26 bits allowing up to a 67 MHz Clock source to be used to
  derive the 1Hz time base.

  @param mode
  
  @param prescaler
    The prescaler parameter contains the prescaler value which will be
    depending on the clock source used in the system.
    For 32.767KHz clock the prescaler should be programmed to 32767-1(N-1) = 32766.
    The prescaler is 26 bits allowing up to a 67 MHz Clock source to be used to
    derive the 1Hz time base.

  @return
    none
    
  The example code below shows how the RTC can be initialized only after a power-on
  reset.
  @code
    #define PO_RESET_DETECT_MASK    0x00000001u
    
    void init_application(void)
    {
        uint32_t power_on_reset;
        power_on_reset = SYSREG->RESET_SOURCE_CR & PO_RESET_DETECT_MASK;
        if(power_on_reset)
        {
            MSS_RTC_init(MSS_RTC_CALENDAR_MODE, 32767);
            SYSREG->RESET_SOURCE_CR = PO_RESET_DETECT_MASK;
        }
    }
  @endcode
 */
void
MSS_RTC_init
(
    uint8_t mode,
    uint32_t prescaler
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_set_calendar_count() function sets the current value of
  the RTC calendar counter. The usual way of setting RTC calendar count is
  to load values to date time registers before issuing an upload command.

  @param new_rtc_value
    The new_rtc_value parameter contains the calendar RTC counter of type
    mss_rtc_calendar_t that will be used as the new RTC counter value.

  @return
    none.
 */

void
MSS_RTC_set_calendar_count
(
	const mss_rtc_calendar_t *new_rtc_value
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_set_binary_count() function sets the current value of the RTC
  binary counter. The usual way of setting RTC binary count is to load
  values to counter registers before issuing an upload command.

  @param new_rtc_value
    The new_rtc_value parameter contains the binary counter of type uint64_t
    that will be used as the new RTC counter value. The binary counter is 43
    bit wide, so the maximum allowed binary value is 2^43.

  @return
    none.
 */

void
MSS_RTC_set_binary_count
(
	uint64_t new_rtc_value
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_get_calendar_count() function reads the current value of
  the RTC calendar counter.

  @param p_rtc_calendar
    The p_rtc_calendar parameter is a pointer to a mss_rtc_calendar_t structure
    where the value of the calendar will be written by the
    MSS_RTC_get_calendar_count() function.

  @return
    none.
 */
void
MSS_RTC_get_calendar_count
(
    mss_rtc_calendar_t *p_rtc_calendar
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_get_binary_count() function returns the current value of
  the RTC binary counter. The RTC count data is downloaded to data register
  by issuing download command.

  @param
    none

  @return
    This function returns the current binary RTC counter value of type uint64_t.
 */
uint64_t
MSS_RTC_get_binary_count
(
    void
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_start() function starts the RTC incrementing.

  @param
    none

  @return
    none
 */
void
MSS_RTC_start
(
    void
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_stop(() function stops the RTC from incrementing.

  @param
    none

  @return
    none
 */
void
MSS_RTC_stop
(
    void
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_reset_counter() resets the calendar counters, which includes
  seconds, minutes, hours, days, months, years.

  @param
    none

  @return
    none
 */
void
MSS_RTC_reset_counter
(
    void
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_enable_irq() function enables the RTC wakeup interrupt
  (RTC_Wakeup_IRQn) in the Cortex-M3 interrupt controller.
  The RTC_Wakeup_IRQHandler() function will be called when an RTC wakeup interrupt
  occurs.

  Note: A RTC_Wakeup_IRQHandler() default implementation is defined, with weak
        linkage, in the G4main CMSIS-PAL. You must provide your own
        implementation of the RTC_Wakeup_IRQHandler() function, that will override
        the default implementation, to suit your application.
 */
void MSS_RTC_enable_irq(void);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_disable_irq() function disables the RTC wakeup interrupt
  (RTC_Wakeup_IRQn) in the Cortex-M3 interrupt controller.

   @param
     none

   @return
     none
 */
void
MSS_RTC_disable_irq
(
    void
);

/*-------------------------------------------------------------------------*//**
 The MSS_RTC_clear_irq() function clears pending RTC wakeup interrupt. This
  function also clears the interrupt in the Cortex-M3 interrupt controller.
  Note: You must call the MSS_RTC_clear_irq() function as part of your
        implementation of the RTC_Wakeup_IRQHandler() RTC wakeup interrupt service
        routine (ISR) in order to prevent the same interrupt event retriggering
        a call to the ISR.
  @param
    none

  @return
    none
  
  Example:
  The example code below demoinstrates how the MSS_RTC_clear_irq() function is
  intended to be used as part of the RTC wakeup interrupt servicer routine used
  by an application to handle RTC alarms.
  @code
    #if defined(__GNUC__)
    __attribute__((__interrupt__)) void RTC_Wakeup_IRQHandler( void )
    #else
    void RTC_Wakeup_IRQHandler( void )
    #endif
    {
        process_alarm();
        MSS_RTC_clear_irq();
    }
  @endcode
*/
void
MSS_RTC_clear_irq
(
    void
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_set_calendar_count_alarm() function sets the RTC to generate an alarm
  when the time and date passed as parameter is reached by the RTC counter. The
  RTC counter keeps counting when the alarm is reached allowing to read the date
  time from the RTC regardless of alarms being set and having occured.
  The alarm is in the form of a wakeup interrupt generated to the Cortex-M3.
  The alarm can be a single shot alarm which will result in one single wakeup
  interrupt being generated the first time date/time parameter is reached. A
  single shot alarm is achieved by specifying a value for every fields of the
  alarm_value parameter.
  The alarm can also be set to be a periodic alarm which will occur everytime
  the date/time parameter condition is reached. The periodic alarm can be set to
  occur every minute, hour, day, month, year, week, day of the week or any valid
  combination of the above. This is achieved by setting some of the 
  mss_rtc_calendar_t structure fields, passed as parameter, to
  MSS_RTC_CALENDAR_DONT_CARE. For example, setting the weekday field
  MSS_RTC_MONDAY and all other fields to MSS_RTC_CALENDAR_DONT_CARE will result
  in alarm occuring every Monday. You can refine the time at which the alarm will
  occur by specifying a value for the hour and minute fields.
  
  Please note that this function can only be used when the RTC has been
  initialized to operate in calendar mode.
  
  @param alarm_value
    The alarm_value parameter is a pointer to a data structure of type
    mss_rtc_calendar_t containing the date and time alarm condition at which the
    alarm is requested to occur.
    Some of the fields within that structure can be set to MSS_RTC_CALENDAR_DONT_CARE
    to indicate that they are not to be considered in deciding when the alarm will
    occur. This can be particularly usefull when setting periodic alarms.
  
  @return
    none
     
  Examples:
  
  The example code below demonstrates how to configure the RTC to generate a
  single calendar alarm at a specific date and time. The alarm will only occur
  once and the RTC will keep incrementing regardless of the alarm taking place.
  
  @code
    const mss_rtc_calendar_t initial_calendar_count =
    {
        15u,     second
        30u,     minute
        6u,      hour
        6u,      day
        9u,      month
        12u,     year
        5u,      weekday
        37u      week
    };
    
    mss_rtc_calendar_t alarm_calendar_count =
    {
        17u,     second
        30u,     minute
        6u,      hour
        6u,      day
        9u,      month
        12u,     year
        5u,      weekday
        37u      week
    };
    
    MSS_RTC_init(MSS_RTC_CALENDAR_MODE, RTC_PRESCALER);
    MSS_RTC_clear_irq();
    MSS_RTC_set_calendar_count(&initial_calendar_count);
    MSS_RTC_enable_irq();
    MSS_RTC_start();
    
    MSS_RTC_set_calendar_count_alarm(&alarm_calendar_count);
  @endcode
  
  The example below demonstrates how to configure the RTC to generate a periodic
  calendar alarm. The RTC is configured to generate an alarm every Tuesday at
  16:45:00. The alarm will keep reoccuring every week unless the RTC alarm
  interrupt is disabled using a call to MSS_RTC_disable_irq().
  
  @code
    mss_rtc_calendar_t initial_calendar_count =
    {
        58u,                            <--second
        59u,                            <--minute
        23u,                            <--hour
        10u,                            <--day
        9u,                             <--month
        12u,                            <--year
        MSS_RTC_MONDAY,                 <--weekday
        37u                             <--week
    };
    
    mss_rtc_calendar_t alarm_calendar_count =
    {
        MSS_RTC_CALENDAR_DONT_CARE,     <--second
        45u,                            <--minute
        16u,                            <--hour
        MSS_RTC_CALENDAR_DONT_CARE,     <--day
        MSS_RTC_CALENDAR_DONT_CARE,     <--month
        MSS_RTC_CALENDAR_DONT_CARE,     <--year
        MSS_RTC_TUESDAY,                <--weekday
        MSS_RTC_CALENDAR_DONT_CARE      <--week
    };
    
    MSS_RTC_init(MSS_RTC_CALENDAR_MODE, RTC_PRESCALER);
    MSS_RTC_set_calendar_count(&initial_calendar_count);
    MSS_RTC_enable_irq();
    MSS_RTC_start();
    
    MSS_RTC_set_calendar_count_alarm(&alarm_calendar_count);
  @endcode
  
  The example below demonstrates the code that you need to include in your
  application to handle alarms. It is the interrupt service routine for the RTC
  wakeup Cortex-M3 interrupt. You need to add your application code in this
  function in place of the process_alarm() function but you must retain the call
  to MSS_RTC_clear_irq() to ensure that the same alarm does not retrigger the
  interrupt.
  @code
    #if defined(__GNUC__)
    __attribute__((__interrupt__)) void RTC_Wakeup_IRQHandler( void )
    #else
    void RTC_Wakeup_IRQHandler( void )
    #endif
    {
        process_alarm();
        MSS_RTC_clear_irq();
    }
  @endcode
 */
void MSS_RTC_set_calendar_count_alarm
(
    const mss_rtc_calendar_t * alarm_value
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_set_binary_count_alarm() function sets the RTC to generate an
  alarm when the counter value passed as parameter is reached by the RTC counter.
  The alarm is in the form of a wakeup interrupt generated to the Cortex-M3.
  The alarm can be a single shot alarm which will result in one single wakeup
  interrupt being generated the first time the alarm value passed as parameter
  is reached. The RTC counter will keep incrementing after a single shot alarm
  occurs.
  The alarm can also be set to be a periodic alarm which will occur everytime
  the RTC counter reaches the alarm value passed as parameter. The RTC counter
  will automatically reset to zero and start incrementing when a periodic alarm
  occurs.
  
  @param alarm_value
    The alarm_value parameter is a 64-bit unsigned value specifying the RTC
    counter value that must be reached for the requested alarm to occur.
  
  @param alarm_type
    The alarm_type parameter specifies whether the requested alarm is a single
    shot or periodic alarm. It can only take one of two values:
     - MSS_RTC_SINGLE_SHOT_ALARM,
     - MSS_RTC_PERIODIC_ALARM
  
  @return
    none.
 */
void MSS_RTC_set_binary_count_alarm
(
    uint64_t alarm_value,
    mss_rtc_alarm_type_t alarm_type
);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_get_update_flag() function indicates if the RTC counter
  incremented since the last call to MSS_RTC_clear_update_flag(). It returns
  zero if no RTC counter increment occured. It returns a non-zero value if the
  RTC counter incremented. This function can be used whether the RTC is
  configured to operate in calendar or counter mode.
  
  @return
   Returns zero if no RTC increment occured since last call to
   MSS_RTC_clear_update_flag().
   Returns non-zero if the RTC incremented since the last call to
   MSS_RTC_clear_update_flag().
   
  Example
  The example function below will display the RTC time if it changed since the
  last call to this function.
  @code
  void display_time_if_required(void)
  {
      mss_rtc_calendar_t calendar_count;
      uint32_t rtc_count_updated;
      rtc_count_updated = MSS_RTC_get_update_flag();
      if(rtc_count_updated)
      {
          MSS_RTC_get_calendar_count(&calendar_count);
          MSS_RTC_clear_update_flag();
          display_time(&calendar_count);
      }
  }
  @endcode
 */
uint32_t MSS_RTC_get_update_flag(void);

/*-------------------------------------------------------------------------*//**
  The MSS_RTC_clear_update_flag() clears the hardware flag set when the RTC
  counter increments. It is used alongside function MSS_RTC_get_update_flag()
  to detect RTC counter increments.
  
  @return
    none.
    
  Example
  The example below will wait for the RTC timer to increment by one second.
  @code
  void wait_start_of_second(void)
  {
      uint32_t rtc_count_updated;
      MSS_RTC_clear_update_flag();
      do {
          rtc_count_updated = MSS_RTC_get_update_flag();
      } while(!rtc_count_updated)
  }
  @endcode
 */
void MSS_RTC_clear_update_flag(void);

#ifdef __cplusplus
}
#endif

#endif /* MSS_RTC_H_ */
