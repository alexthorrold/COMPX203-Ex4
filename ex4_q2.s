.global main
.text

main:
    # Enable IRQ2
    movsg $2, $cctrl
    andi $2, $2, 0x000F
    ori $2, $2, 0x42
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
    addi $2, $0, 0x3
    sw $2, 0x72000($0)

loop:
    lw $1, counter($0)
    remi $1, $1, 100   # Gets only the last two digits of counter

    # Sends the tens of seconds value to the lower left SSD
    divi $2, $1, 10
    sw $2, 0x73008($0)

    # Sends the seconds value to the lower right SSD
    remi $2, $1, 10
    sw $2, 0x73009($0)

    j loop

handler:
    # Branches to label handle_irq2 if the interrupt is caused by IRQ2
    movsg $13, $estat
    andi $13, $13, 0xFFB0
    beqz $13, handle_irq2

    # If the interrupt was not caused by IRQ2, go to the default interrupt handler
    lw $13, old_vector($0)
    jr $13

handle_irq2:
    # Increases the value in counter by 1
    lw $13, counter($0)
    addi $13, $13, 1
    sw $13, counter($0)

    sw $0, 0x72003($0)
    rfe

.data
counter:
    .word 0

old_vector:
    .word 0