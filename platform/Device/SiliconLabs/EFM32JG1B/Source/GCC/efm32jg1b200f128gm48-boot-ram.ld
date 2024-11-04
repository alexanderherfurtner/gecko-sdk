/* Linker script for Silicon Labs EFM32JG1B devices                      */
/*                                                                     */
/* This file is subject to the license terms as defined in ARM's       */
/* CMSIS END USER LICENSE AGREEMENT.pdf, governing the use of          */
/* Example Code.                                                       */
/*                                                                     */
/* Copyright 2017 Silicon Laboratories, Inc. http://www.silabs.com     */
/*                                                                     */
/* Version 5.1.3 */
/*                                                                     */

/* Default memory layout for code and data */
/*
MEMORY
{
  FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 256K
  RAM0_C (rx) : ORIGIN = 0x10000000, LENGTH = 31K
  RAMH_C (rx) : ORIGIN = 0x1003fc00, LENGTH = 1K
  RAM (rw)    : ORIGIN = 0x20000000, LENGTH = 32K
}
*/

/* Default ramcode memory layout for code and data */
/*
 * Default vector table and startup code are placed at the beginning of the
 * FLASH using the default section .text. Further sections like .*.table will
 * be placed afterwards in the FLASH, being part of the startup code.
 *
 * Rest of the program code is placed in .text.ram which will end up in FLASH,
 * but will be executed from RAM_C memory region.
 *
 * Data sections are placed in RAM region.
 */
MEMORY
{
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 32K
  RAM_C (rx) : ORIGIN = 0x10000000, LENGTH = 30K
  RAM   (rw) : ORIGIN = 0x20007800, LENGTH = 2K
}

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 *
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __copy_table_start__
 *   __copy_table_end__
 *   __zero_table_start__
 *   __zero_table_end__
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 *   __Vectors_End
 *   __Vectors_Size
 */
ENTRY(Reset_Handler)

SECTIONS
{
  .text :
  {
    KEEP(*(.vectors))
    __Vectors_End = .;
    __Vectors_Size = __Vectors_End - __Vectors;
    __end__ = .;

    *startup_efm32jg1b.o (.text* .rodata*)
    *system_efm32jg1b.o (.text.SystemInit)
  } > FLASH

  /* Info table for RAM regions,
   * define __STARTUP_CLEAR_RAM_MULTIPLE in startup code */
  .info.table :
  {
    . = ALIGN(4);
    __info_table_ram_start__ = .;
    LONG (ORIGIN(RAM))
    LONG (LENGTH(RAM))
    LONG (ORIGIN(RAM_C))
    LONG (LENGTH(RAM_C))
    __info_table_ram_end__ = .;
  } > FLASH

  /* To copy multiple ROM to RAM sections,
   * define __STARTUP_COPY_MULTIPLE in startup code */
  .copy.table :
  {
    . = ALIGN(4);
    __copy_table_start__ = .;
    LONG (__etext)
    LONG (__ramtext_arm_start__)
    LONG (__ramtext_arm_end__ - __ramtext_arm_start__)
    LONG (__etext_ram_arm)
    LONG (__ramtext_start__)
    LONG (__ramtext_end__ - __ramtext_start__)
    LONG (__etext_ram)
    LONG (__data_start__)
    LONG (__data_end__ - __data_start__)
    __copy_table_end__ = .;
  } > FLASH

  /* To clear multiple BSS sections,
   * define __STARTUP_CLEAR_BSS_MULTIPLE in startup code */
  .zero.table :
  {
    . = ALIGN(4);
    __zero_table_start__ = .;
    LONG (__bss_start__)
    LONG (__bss_end__ - __bss_start__)
    __zero_table_end__ = .;
  } > FLASH

  __etext = .;
  .ARM.text.ram :
  {
    /* ARM text ram start */
    . = ALIGN(4);
    __ramtext_arm_start__ = .;

    __exidx_start = .;
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    __exidx_end = .;
    
    *(.ARM.extab* .gnu.linkonce.armextab.*)

    /* ARM text ram end */
    . = ALIGN(4);
    __ramtext_arm_end__ = .;
  } > RAM_C AT> FLASH

  __etext_ram_arm = __etext + SIZEOF(.ARM.text.ram);
  .text.ram :
  {
    /* text ram start */
    . = ALIGN(4);
    __ramtext_start__ = .;
    *(.text*)
    *(.ram)

    /* .crt */
    *crt?.o (.text*)
    *crtbegin.o (.text*)

    KEEP(*(.init))
    KEEP(*(.fini))

    /* .ctors */
    *crtbegin.o(.ctors)
    *crtbegin?.o(.ctors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
    *(SORT(.ctors.*))
    *(.ctors)

    /* .dtors */
    *crtbegin.o(.dtors)
    *crtbegin?.o(.dtors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
    *(SORT(.dtors.*))
    *(.dtors)

    *(.rodata*)
    KEEP(*(.eh_frame))

    /* text ram end */
    . = ALIGN(4);
    __ramtext_end__ = .;
  } > RAM_C AT> FLASH

  __etext_ram = __etext_ram_arm + SIZEOF(.text.ram);
  .data :
  {
    . = ALIGN(4);
    /* All data start */
    __data_start__ = .;
    *(vtable)
    *(.data*)

    . = ALIGN(4);
    /* preinit data */
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP(*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);

    . = ALIGN(4);
    /* init data */
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    PROVIDE_HIDDEN (__init_array_end = .);

    . = ALIGN(4);
    /* finit data */
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP(*(SORT(.fini_array.*)))
    KEEP(*(.fini_array))
    PROVIDE_HIDDEN (__fini_array_end = .);

    KEEP(*(.jcr*))
    . = ALIGN(4);
    /* All data end */
    __data_end__ = .;
  } > RAM AT> FLASH

  .bss :
  {
    . = ALIGN(4);
    __bss_start__ = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end__ = .;
  } > RAM

  .heap (COPY):
  {
    __HeapBase = .;
    __end__ = .;
    end = __end__;
    _end = __end__;
    KEEP(*(.heap*))
    __HeapLimit = .;
  } > RAM

  /* .stack_dummy section doesn't contains any symbols. It is only
   * used for linker to calculate size of stack sections, and assign
   * values to stack symbols later */
  .stack_dummy (COPY):
  {
    KEEP(*(.stack*))
  } > RAM

  /* Set stack top to end of RAM, and stack limit move down by
   * size of stack_dummy section */
  __StackTop = ORIGIN(RAM) + LENGTH(RAM);
  __StackLimit = __StackTop - SIZEOF(.stack_dummy);
  PROVIDE(__stack = __StackTop);

  /* Check if data + heap + stack exceeds RAM limit */
  ASSERT(__StackLimit >= __HeapLimit, "region RAM overflowed with stack")

  /* Check if RAM_C usage exceeds size */
  ASSERT( LENGTH(RAM_C) >= (SIZEOF(.text.ram) + SIZEOF(.ARM.text.ram)), "RAM_C memory overflowed !")

  /* Check if FLASH usage exceeds size */
  ASSERT( LENGTH(FLASH) >= (SIZEOF(.text) + SIZEOF(.text.ram) + SIZEOF(.ARM.text.ram) + SIZEOF(.data)), "FLASH memory overflowed !")
}
