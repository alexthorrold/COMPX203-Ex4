.global main
.text

main:
    # Enable IRQ1 and IRQ3
    movsg $2, $cctrl
    andi $2, $2, 0x000F
    ori $2, $2, 0xA2
    movgs $cctrl, $2

    # Save the default interrupt handler's address to memory
    movsg $2, $evec
    sw $2, old_vector($0)
    la $2, handler
    movgs $evec, $2

    # Enable interrupts on the parallel control register
    addi $2, $0, 0x3
    sw $2, 0x73004($0)

loop:
    lw $1, counter($0)
    remi $1, $1, 100   # Gets only the last two digits of counter

    # Sends the tens value to the lower left SSD
    divi $2, $1, 10
    sw $2, 0x73008($0)

    # Sends the value of the last digit to the lower right SSD
    remi $2, $1, 10
    sw $2, 0x73009($0)

    j loop

handler:
    # Branches to label handle_irq2 if the interrupt is caused by IRQ1
    movsg $13, $estat
    andi $13, $13, 0xFFD0
    beqz $13, handle_irq1

    # Branches to label handle_irq3 if the interrupt is caused by IRQ3
    movsg $13, $estat
    andi $13, $13, 0xFF70
    beqz $13, handle_irq3

    # If the interrupt was caused by neither, go to the default interrupt handler
    lw $13, old_vector($0)
    jr $13

handle_irq1:
    # Increases the value in counter by 1
    lw $13, counter($0)
    addi $13, $13, 1
    sw $13, counter($0)

    sw $0, 0x7F000($0)
    rfe

handle_irq3:
    # Returns if interrupt was caused by release not press
    lw $13, 0x73001($0)
    beqz $13, return

    # Increases the value in counter by 1
    lw $13, counter($0)
    addi $13, $13, 1
    sw $13, counter($0)

return:
    sw $0, 0x73005($0)
    rfe

.data
counter:
    .word 0

old_vector:
    .word 0