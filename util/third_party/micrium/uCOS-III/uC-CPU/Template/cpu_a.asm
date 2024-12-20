;********************************************************************************************************
;                                                uC/CPU
;                                    CPU CONFIGURATION & PORT LAYER
;
;                          (c) Copyright 2004-2016; Micrium, Inc.; Weston, FL
;
;               All rights reserved.  Protected by international copyright laws.
;
;               uC/CPU is provided in source form to registered licensees ONLY.  It is 
;               illegal to distribute this source code to any third party unless you receive 
;               written permission by an authorized Micrium representative.  Knowledge of 
;               the source code may NOT be used to develop a similar product.
;
;               Please help us continue to provide the Embedded community with the finest 
;               software available.  Your honesty is greatly appreciated.
;
;               You can find our product's user manual, API reference, release notes and
;               more information at https://doc.micrium.com.
;               You can contact us at www.micrium.com.
;********************************************************************************************************

;********************************************************************************************************
;
;                                            CPU PORT FILE
;
;                                              TEMPLATE
;
;                                         $$$$ Insert CPU Name
;                                      $$$$ Insert Compiler Name
;
; Filename      : cpu_a.asm            $$$$ Insert CPU assembly port file name
; Version       : V1.31.00          $$$$ Insert CPU assembly port file version number
; Programmer(s) : ITJ                  $$$$ Insert CPU assembly port file programmer(s) initials
;********************************************************************************************************
; Note(s)       : (1) To provide the required CPU port functionality, insert the appropriate CPU- &/or
;                     compiler-specific code to perform the stated actions wherever '$$$$' comments are
;                     found.
;
;                     #### This note MAY be entirely removed for specific CPU port files.
;********************************************************************************************************


;********************************************************************************************************
;                                           PUBLIC FUNCTIONS
;********************************************************************************************************

                                ; $$$$ Extern required CPU port functions :
    PUBLIC  CPU_IntDis
    PUBLIC  CPU_IntEn

    PUBLIC  CPU_SR_Push
    PUBLIC  CPU_SR_Pop

    PUBLIC  CPU_SR_Save
    PUBLIC  CPU_SR_Restore


    PUBLIC  CPU_CntLeadZeros
    PUBLIC  CPU_CntTrailZeros
    PUBLIC  CPU_RevBits


;********************************************************************************************************
;                                                EQUATES
;********************************************************************************************************

                                ; $$$$ Define possible required CPU equates :


;********************************************************************************************************
;                                      CODE GENERATION DIRECTIVES
;********************************************************************************************************

                                ; $$$$ Insert possible required CPU-compiler code generation directives :


;********************************************************************************************************
;                                      DISABLE/ENABLE INTERRUPTS
;
; Description : Disable/Enable interrupts.
;
;               (1) (a) For CPU_CRITICAL_METHOD_INT_DIS_EN, interrupts are enabled/disabled WITHOUT saving
;                       or restoring the state of the interrupt status.
;
;
; Prototypes  : void  CPU_IntDis(void);
;               void  CPU_IntEn (void);
;********************************************************************************************************

CPU_IntDis
                                ; $$$$ Insert code to disable CPU interrupts


CPU_IntEn
                                ; $$$$ Insert code to enable  CPU interrupts


;********************************************************************************************************
;                                    PUSH/POP CPU STATUS REGISTER
;
; Description : Push/Pop the state of CPU interrupts onto the local stack, if possible.
;
;               (1) (b) For CPU_CRITICAL_METHOD_STATUS_STK, the state of the interrupt status flag is
;                       stored in onto the local stack & interrupts are then disabled.  The previous
;                       interrupt status state is restored from the local stack into the CPU's status
;                       register.
;
;
; Prototypes  : void  CPU_SR_Push(void);
;               void  CPU_SR_Pop (void);
;********************************************************************************************************

CPU_SR_Push
                                ; $$$$ Insert code to push CPU status onto local stack & disable interrupts


CPU_SR_Pop
                                ; $$$$ Insert code to pop  CPU status from local stack


;********************************************************************************************************
;                                  SAVE/RESTORE CPU STATUS REGISTER
;
; Description : Save/Restore the state of CPU interrupts, if possible.
;
;               (1) (c) For CPU_CRITICAL_METHOD_STATUS_LOCAL, the state of the interrupt status flag is
;                       stored in the local variable 'cpu_sr' & interrupts are then disabled ('cpu_sr' is
;                       allocated in all functions that need to disable interrupts).  The previous interrupt
;                       status state is restored by copying 'cpu_sr' into the CPU's status register.
;
;
; Prototypes  : CPU_SR  CPU_SR_Save   (void);
;               void    CPU_SR_Restore(CPU_SR  cpu_sr);
;
; Note(s)     : (1) These functions are used in general like this :
;
;                       void  Task (void  *p_arg)
;                       {
;                           CPU_SR_ALLOC();                     /* Allocate storage for CPU status register */
;                               :
;                               :
;                           CPU_CRITICAL_ENTER();               /* cpu_sr = CPU_SR_Save();                  */
;                               :
;                               :
;                           CPU_CRITICAL_EXIT();                /* CPU_SR_Restore(cpu_sr);                  */
;                               :
;                       }
;********************************************************************************************************

CPU_SR_Save
                                ; $$$$ Insert code to save    CPU status register(s) & disable interrupts


CPU_SR_Restore
                                ; $$$$ Insert code to restore CPU status register(s)


;********************************************************************************************************
;                                         CPU_CntLeadZeros()
;                                        COUNT LEADING ZEROS
;
; Description : Counts the number of contiguous, most-significant, leading zero bits before the 
;                   first binary one bit in a data value.
;
; Prototype   : CPU_DATA  CPU_CntLeadZeros(CPU_DATA  val);
;
; Argument(s) : val         Data value to count leading zero bits.
;
; Return(s)   : Number of contiguous, most-significant, leading zero bits in 'val'.
;
; Caller(s)   : Application.
;
;               This function is an INTERNAL CPU module function but MAY be called by application 
;               function(s).
;
; Note(s)     : (1) (a) Supports up to the following data value sizes, depending on the configured 
;                       size of 'CPU_DATA' (see 'cpu.h  CPU WORD CONFIGURATION  Note #1') :
;
;                       (1)  8-bits
;                       (2) 16-bits
;                       (3) 32-bits
;                       (4) 64-bits
;
;                   (b) (1) For  8-bit values :
;
;                                  b07  b06  b05  b04  b03  b02  b01  b00    # Leading Zeros
;                                  ---  ---  ---  ---  ---  ---  ---  ---    ---------------
;                                   1    x    x    x    x    x    x    x            0
;                                   0    1    x    x    x    x    x    x            1
;                                   0    0    1    x    x    x    x    x            2
;                                   0    0    0    1    x    x    x    x            3
;                                   0    0    0    0    1    x    x    x            4
;                                   0    0    0    0    0    1    x    x            5
;                                   0    0    0    0    0    0    1    x            6
;                                   0    0    0    0    0    0    0    1            7
;                                   0    0    0    0    0    0    0    0            8
;
;
;                       (2) For 16-bit values :
;
;                             b15  b14  b13  ...  b04  b03  b02  b01  b00    # Leading Zeros
;                             ---  ---  ---       ---  ---  ---  ---  ---    ---------------
;                              1    x    x         x    x    x    x    x            0
;                              0    1    x         x    x    x    x    x            1
;                              0    0    1         x    x    x    x    x            2
;                              :    :    :         :    :    :    :    :            :
;                              :    :    :         :    :    :    :    :            :
;                              0    0    0         1    x    x    x    x           11
;                              0    0    0         0    1    x    x    x           12
;                              0    0    0         0    0    1    x    x           13
;                              0    0    0         0    0    0    1    x           14
;                              0    0    0         0    0    0    0    1           15
;                              0    0    0         0    0    0    0    0           16
;
;
;                       (3) For 32-bit values :
;
;                             b31  b30  b29  ...  b04  b03  b02  b01  b00    # Leading Zeros
;                             ---  ---  ---       ---  ---  ---  ---  ---    ---------------
;                              1    x    x         x    x    x    x    x            0
;                              0    1    x         x    x    x    x    x            1
;                              0    0    1         x    x    x    x    x            2
;                              :    :    :         :    :    :    :    :            :
;                              :    :    :         :    :    :    :    :            :
;                              0    0    0         1    x    x    x    x           27
;                              0    0    0         0    1    x    x    x           28
;                              0    0    0         0    0    1    x    x           29
;                              0    0    0         0    0    0    1    x           30
;                              0    0    0         0    0    0    0    1           31
;                              0    0    0         0    0    0    0    0           32
;
;
;                       (4) For 64-bit values :
;
;                             b63  b62  b61  ...  b04  b03  b02  b01  b00    # Leading Zeros
;                             ---  ---  ---       ---  ---  ---  ---  ---    ---------------
;                              1    x    x         x    x    x    x    x            0
;                              0    1    x         x    x    x    x    x            1
;                              0    0    1         x    x    x    x    x            2
;                              :    :    :         :    :    :    :    :            :
;                              :    :    :         :    :    :    :    :            :
;                              0    0    0         1    x    x    x    x           59
;                              0    0    0         0    1    x    x    x           60
;                              0    0    0         0    0    1    x    x           61
;                              0    0    0         0    0    0    1    x           62
;                              0    0    0         0    0    0    0    1           63
;                              0    0    0         0    0    0    0    0           64
;
;               (2) MUST be defined in 'cpu_a.asm' (or 'cpu_c.c') if CPU_CFG_LEAD_ZEROS_ASM_PRESENT 
;                   is #define'd in 'cpu_cfg.h' or 'cpu.h'.
;********************************************************************************************************

CPU_CntLeadZeros

                                ; $$$$ Insert code to count the number of contiguous, most-significant, ...
                                ; ... leading zero bits in 'val' (see Note #1b)


;********************************************************************************************************
;                                         CPU_CntTrailZeros()
;                                        COUNT TRAILING ZEROS
;
; Description : Counts the number of contiguous, least-significant, trailing zero bits before the 
;                   first binary one bit in a data value.
;
; Prototype   : CPU_DATA  CPU_CntTrailZeros(CPU_DATA  val);
;
; Argument(s) : val         Data value to count trailing zero bits.
;
; Return(s)   : Number of contiguous, least-significant, trailing zero bits in 'val'.
;
; Caller(s)   : Application.
;
;               This function is an INTERNAL CPU module function but MAY be called by application 
;               function(s).
;
; Note(s)     : (1) (a) Supports up to the following data value sizes, depending on the configured 
;                       size of 'CPU_DATA' (see 'cpu.h  CPU WORD CONFIGURATION  Note #1') :
;
;                       (1)  8-bits
;                       (2) 16-bits
;                       (3) 32-bits
;                       (4) 64-bits
;
;                   (b) (1) For  8-bit values :
;
;                                  b07  b06  b05  b04  b03  b02  b01  b00    # Trailing Zeros
;                                  ---  ---  ---  ---  ---  ---  ---  ---    ----------------
;                                   x    x    x    x    x    x    x    1            0
;                                   x    x    x    x    x    x    1    0            1
;                                   x    x    x    x    x    1    0    0            2
;                                   x    x    x    x    1    0    0    0            3
;                                   x    x    x    1    0    0    0    0            4
;                                   x    x    1    0    0    0    0    0            5
;                                   x    1    0    0    0    0    0    0            6
;                                   1    0    0    0    0    0    0    0            7
;                                   0    0    0    0    0    0    0    0            8
;
;
;                       (2) For 16-bit values :
;
;                             b15  b14  b13  b12  b11  ...  b02  b01  b00    # Trailing Zeros
;                             ---  ---  ---  ---  ---       ---  ---  ---    ----------------
;                              x    x    x    x    x         x    x    1            0
;                              x    x    x    x    x         x    1    0            1
;                              x    x    x    x    x         1    0    0            2
;                              :    :    :    :    :         :    :    :            :
;                              :    :    :    :    :         :    :    :            :
;                              x    x    x    x    1         0    0    0           11
;                              x    x    x    1    0         0    0    0           12
;                              x    x    1    0    0         0    0    0           13
;                              x    1    0    0    0         0    0    0           14
;                              1    0    0    0    0         0    0    0           15
;                              0    0    0    0    0         0    0    0           16
;
;
;                       (3) For 32-bit values :
;
;                             b31  b30  b29  b28  b27  ...  b02  b01  b00    # Trailing Zeros
;                             ---  ---  ---  ---  ---       ---  ---  ---    ----------------
;                              x    x    x    x    x         x    x    1            0
;                              x    x    x    x    x         x    1    0            1
;                              x    x    x    x    x         1    0    0            2
;                              :    :    :    :    :         :    :    :            :
;                              :    :    :    :    :         :    :    :            :
;                              x    x    x    x    1         0    0    0           27
;                              x    x    x    1    0         0    0    0           28
;                              x    x    1    0    0         0    0    0           29
;                              x    1    0    0    0         0    0    0           30
;                              1    0    0    0    0         0    0    0           31
;                              0    0    0    0    0         0    0    0           32
;
;
;                       (4) For 64-bit values :
;
;                             b63  b62  b61  b60  b59  ...  b02  b01  b00    # Trailing Zeros
;                             ---  ---  ---  ---  ---       ---  ---  ---    ----------------
;                              x    x    x    x    x         x    x    1            0
;                              x    x    x    x    x         x    1    0            1
;                              x    x    x    x    x         1    0    0            2
;                              :    :    :    :    :         :    :    :            :
;                              :    :    :    :    :         :    :    :            :
;                              x    x    x    x    1         0    0    0           59
;                              x    x    x    1    0         0    0    0           60
;                              x    x    1    0    0         0    0    0           61
;                              x    1    0    0    0         0    0    0           62
;                              1    0    0    0    0         0    0    0           63
;                              0    0    0    0    0         0    0    0           64
;
;               (2) MUST be defined in 'cpu_a.asm' (or 'cpu_c.c') if CPU_CFG_TRAIL_ZEROS_ASM_PRESENT 
;                   is #define'd in 'cpu_cfg.h' or 'cpu.h'.
;********************************************************************************************************

CPU_CntTrailZeros

                                ; $$$$ Insert code to count the number of contiguous, least-significant, ...
                                ; ... trailing zero bits in 'val' (see Note #1b)


;********************************************************************************************************
;                                            CPU_RevBits()
;                                            REVERSE BITS
;
; Description : Reverses the bits in a data value.
;
; Prototypes  : CPU_DATA  CPU_RevBits(CPU_DATA  val);
;
; Argument(s) : val         Data value to reverse bits.
;
; Return(s)   : Value with all bits in 'val' reversed (see Note #1).
;
; Caller(s)   : Application.
;
;               This function is an INTERNAL CPU module function but MAY be called by application function(s).
;
; Note(s)     : (1) The final, reversed data value for 'val' is such that :
;
;                       'val's final bit  0       =  'val's original bit  N
;                       'val's final bit  1       =  'val's original bit (N - 1)
;                       'val's final bit  2       =  'val's original bit (N - 2)
;
;                               ...                           ...
;
;                       'val's final bit (N - 2)  =  'val's original bit  2
;                       'val's final bit (N - 1)  =  'val's original bit  1
;                       'val's final bit  N       =  'val's original bit  0
;********************************************************************************************************

CPU_RevBits

                                ; $$$$ Insert code to reverse the bits in 'val' (see Note #1)


;********************************************************************************************************
;                                     CPU ASSEMBLY PORT FILE END
;********************************************************************************************************

                                ; $$$$ Insert assembly end-of-file directive, if any

