.global main
.text

main:
    # Enable IRQ2 and IRQ3
    movsg $2, $cctrl
    andi $2, $2, 0x000F
    ori $2, $2, 0xC2
    movgs $cctrl, $2

    # Save the default interrupt handler's address to memory
    movsg $2, $evec
    sw $2, old_vector($0)
    la $2, handler
    movgs $evec, $2

    # Enable the timer to generate an interrupt 100 times a second
    sw $0, 0x72003($0)
    addi $2, $0, 2400
    sw $2, 0x72001($0)
    addi $2, $0, 0x2
    sw $2, 0x72000($0)

    # Enable interrupts on the parallel control register
    addi $2, $0, 0x3
    sw $2, 0x73004($0)

loop:
    # Terminates the program if terminate_flag has been set to 1
    lw $1, terminate_flag($0)
    bnez $1, terminate

    lw $1, counter($0)
    remi $1, $1, 100   # Gets only the last two digits of counter

    # Sends the tens of seconds value to the lower left SSD
    divi $2, $1, 10
    sw $2, 0x73008($0)

    # Sends the seconds value to the lower right SSD
    remi $2, $1, 10
    sw $2, 0x73009($0)

    j loop

terminate:
    # Sets the terminate flag back to 0 and jumps to return address
    sw $0, terminate_flag($0)
    jr $ra

handler:
    # Branches to label handle_irq2 if the interrupt is caused by IRQ2
    movsg $13, $estat
    andi $13, $13, 0xFFB0
    beqz $13, handle_irq2

    # Branches to label handle_irq3 if the interrupt is caused by IRQ3
    movsg $13, $estat
    andi $13, $13, 0xFF70
    beqz $13, handle_irq3

    # If the interrupt was caused by neither, go to the default interrupt handler
    lw $13, old_vector($0)
    jr $13

handle_irq2:
    # Increases the value in counter by 1
    lw $13, counter($0)
    addi $13, $13, 1
    sw $13, counter($0)

    sw $0, 0x72003($0)
    rfe

handle_irq3:
    # Branches to label of the push button that was pressed
    lw $13, 0x73001($0)
    andi $13, $13, 0x1
    bnez $13, push_button_0
    lw $13, 0x73001($0)
    andi $13, $13, 0x2
    bnez $13, push_button_1
    lw $13, 0x73001($0)
    andi $13, $13, 0x4
    bnez $13, push_button_2

    # Returns if interrupt was caused by release not press
    j return

push_button_0:
    # Branches to label reset_counter if the timer is off
    lw $13, 0x72000($0)
    andi $13, $13, 0x1
    beqz $13, reset_counter

    # Returns without doing anything if timer is on
    j return

reset_counter:
    # Sets the value at counter to 0 and returns
    sw $0, counter($0)
    j return

push_button_1:
    # Turns the timer on if it is off and vice versa
    lw $13, 0x72000($0)
    xori $13, $13, 0x1
    sw $13, 0x72000($0)
    j return

push_button_2:
    # Sets terminate_flag to 1 and returns
    addi $13, $0, 1
    sw $13, terminate_flag($0)
    j return

return:
    sw $0, 0x73005($0)
    rfe

.data
counter:
    .word 0

old_vector:
    .word 0

terminate_flag:
    .word 0