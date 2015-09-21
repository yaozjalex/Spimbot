# syscall constants
PRINT_STRING  = 4

# spimbot constants
VELOCITY      = 0xffff0010
ANGLE         = 0xffff0014
ANGLE_CONTROL = 0xffff0018
BOT_X         = 0xffff0020
BOT_Y         = 0xffff0024
PRINT_INT     = 0xffff0080
OTHER_BOT_X   = 0xffff00a0
OTHER_BOT_Y   = 0xffff00a4

BONK_MASK     = 0x1000
BONK_ACK      = 0xffff0060

SCAN_X        = 0xffff0050
SCAN_Y        = 0xffff0054
SCAN_RADIUS   = 0xffff0058
SCAN_ADDRESS  = 0xffff005c
SCAN_MASK     = 0x2000
SCAN_ACK      = 0xffff0064

TIMER         = 0xffff001c
TIMER_MASK    = 0x8000
TIMER_ACK     = 0xffff006c

.data
index:        .word 0
addresses:  .space 16384
token_x:    .space 1024
token_y:    .space 1024
timer_done: .word 0
decode_done:.word 0
scan_done:    .word 0
scan_counter: .word 0
write_index: .word 0
decode_counter: .word 0
three:    .float    3.0
five:    .float    5.0
PI:    .float    3.141592
F180:    .float  180.0

.text
main:
    # go wild
    # the world is your oyster
    sw    $0, VELOCITY

    li    $t0, TIMER_MASK
    or    $t0, $t0, SCAN_MASK
    or    $t0, $t0, BONK_MASK
    or    $t0, $t0, 1
    mtc0    $t0, $12        # enable_timer_interrupts()
    
scan1:
    li      $t0, 150        
    sw      $t0, SCAN_X        # center x
    li        $t0, 150
    sw      $t0, SCAN_Y        # center y
    li      $t0, 60        # set radius to 213 (212.132)
    sw        $t0, SCAN_RADIUS
    la      $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS

first_scan:
    lw        $t0, scan_done
    bne        $t0, 1, first_scan
    jal        decode
    jal        drive
    j        start_scan
    
check_flags:
    lw        $t0, timer_done
    beq        $t0, 1, start_drive
    lw        $t0, scan_done
    beq        $t0, 1, start_scan
    j        check_flags
    
start_scan:
    jal        initiate_scan
    
looper:
    lw        $t9, scan_done
    lw        $t0, timer_done
    beq        $t0, 1, start_drive2
looper2:
    bne        $t9, 1, looper

    jal       decode
    j        check_flags
    
start_drive:
    sw        $0, timer_done
    jal        drive
    j        check_flags

start_drive2:
    jal        drive
    j         looper2
    
.kdata                # interrupt handler data (separated just for readability)
chunkIH:    .space 16    # space for two registers
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:
.set noat
    move    $k1, $at        # Save $at                               
.set at
    la    $k0, chunkIH
    sw    $a0, 0($k0)        # Restore saved registers
    sw    $a1, 4($k0)        # 
    sw    $v0, 8($k0)
    # by storing them to a global variable     

    mfc0    $k0, $13        # Get Cause register                       
    srl        $a0, $k0, 2                
    and        $a0, $a0, 0xf        # ExcCode field                            
    bne        $a0, 0, non_intrpt         


interrupt_dispatch:            # Interrupt:                             
    mfc0    $k0, $13        # Get Cause register, again                 
    beq        $k0, 0, done        # handled all outstanding interrupts   
      
    and     $a0, $k0, SCAN_MASK    # is there a scan interrupt?
    bne     $a0, 0, scan_interrupt

    and        $a0, $k0, TIMER_MASK    # is there a timer interrupt?
    bne        $a0, 0, timer_interrupt
    
    # add dispatch for other interrupt types here.
    and        $a0, $k0, BONK_MASK
    bne        $a0, 0, bonk_interrupt    # if $t0 != $t1 then target

    li        $v0, PRINT_STRING    # Unhandled interrupt types
    la        $a0, unhandled_str
    syscall 
    j        done

timer_interrupt:
    sw    $zero, TIMER_ACK    # acknowledge_timer_interrupt()
    
    li    $a0, 1
    sw    $a0, timer_done
    
    j    interrupt_dispatch

scan_interrupt:
    sw      $a1, SCAN_ACK        # acknowledge scan interrupt
    li        $a0, 1
    sw        $a0, scan_done
    lw        $a0, scan_counter
    add        $a0, $a0, 1
    sw        $a0, scan_counter
    j       interrupt_dispatch    # see if other interrupts are waiting

bonk_interrupt:
    sw    $a1, BONK_ACK        # 
    sw    $0, VELOCITY        # 
    j    interrupt_dispatch    # jump to interrupt_dispatch
    
non_intrpt:                # was some non-interrupt
    li    $v0, PRINT_STRING
    la    $a0, non_intrpt_str
    syscall                # print out an error message
    # fall through to done

done:
    la    $k0, chunkIH
    lw    $a0, 0($k0)        # Restore saved registers
    lw    $a1, 4($k0)        # # 
    lw    $v0, 8($k0)
    mfc0    $k0, $14                 # Exception Program Counter (PC)
.set noat
    move    $at, $k1        # Restore $at
.set at 
    eret


.text
initiate_scan:
    lw    $a0, scan_counter
    beq $a0, 1, scan2
    beq    $a0, 2, scan3
    beq    $a0, 3, scan4
    beq    $a0, 4, scan5
    beq    $a0, 5, scan6
    beq    $a0, 6, scan7
    beq    $a0, 7, scan8
    beq    $a0, 8, scan9
    jr    $ra
    
scan2:
    li      $t0, 50    
    sw      $t0, SCAN_X        # center x
    li        $t0, 150
    sw      $t0, SCAN_Y        # center 
    la  $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS
    j        scan_end
    
scan3:
    li      $t0, 50        
    sw      $t0, SCAN_X        # center x
    li        $t0, 50
    sw      $t0, SCAN_Y        # center y
    la  $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS
    j        scan_end
scan4:
    li      $t0, 150        
    sw      $t0, SCAN_X        # center x
    li        $t0, 50
    sw      $t0, SCAN_Y        # center y
    la  $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS
    j        scan_end
    
scan5:
    li      $t0, 250        
    sw      $t0, SCAN_X        # center x
    li        $t0, 50
    sw      $t0, SCAN_Y        # center y
    la  $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS
    j        scan_end
    
scan6:
    li      $t0, 250        
    sw      $t0, SCAN_X        # center x
    li        $t0, 150
    sw      $t0, SCAN_Y        # center y
    la  $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS
    j        scan_end
    
scan7:
    li      $t0, 250        
    sw      $t0, SCAN_X        # center x
    li        $t0, 250
    sw      $t0, SCAN_Y        # center y
    la  $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS
    j        scan_end
    
scan8:
    li      $t0, 150        
    sw      $t0, SCAN_X        # center x
    li        $t0, 250
    sw      $t0, SCAN_Y        # center y
    la  $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS
    j        scan_end
    
scan9:
    li      $t0, 50        
    sw      $t0, SCAN_X        # center x
    li        $t0, 250
    sw      $t0, SCAN_Y        # center y
    la  $t1, addresses        # loads address
    sw      $t1, SCAN_ADDRESS
    j        scan_end

scan_end:
    sw        $0, scan_done
    jr        $ra
    
    
drive:    
    lw    $a0, BOT_X        # current_x = get_current_x()
    lw    $v0, index
    mul    $v0, $v0, 4
    lw    $v0, token_x($v0)    # target_x = token_x[index]
    sub    $a0, $v0, $a0        # diff = target_x - current_x


    lw    $a1, BOT_Y        # current_y = get_current_y()
    lw    $v0, index
    mul    $v0, $v0, 4
    lw    $v0, token_y($v0)    # target_y = token_y[index]
    sub    $a1, $v0, $a1        # diff = target_y - current_y
    
    beq    $v0, 0, stall

# taylor
sb_arctan:
    li    $v0, 0        # angle = 0;

    abs    $t0, $a0    # get absolute values
    abs    $t1, $a1
    ble    $t1, $t0, no_TURN_90      

    ## if (abs(y) > abs(x)) { rotate 90 degrees }
    move    $t0, $a1    # int temp = y;
    neg    $a1, $a0    # y = -x;      
    move    $a0, $t0    # x = temp;    
    li    $v0, 90        # angle = 90;  

no_TURN_90:
    bgez    $a0, pos_x     # skip if (x >= 0)

    ## if (x < 0) 
    add    $v0, $v0, 180    # angle += 180;

pos_x:
    mtc1    $a0, $f0
    mtc1    $a1, $f1
    cvt.s.w $f0, $f0    # convert from ints to floats
    cvt.s.w $f1, $f1
    
    div.s    $f0, $f1, $f0    # float v = (float) y / (float) x;

    mul.s    $f1, $f0, $f0    # v^^2
    mul.s    $f2, $f1, $f0    # v^^3
    l.s    $f3, three    # load 5.0
    div.s     $f3, $f2, $f3    # v^^3/3
    sub.s    $f6, $f0, $f3    # v - v^^3/3

    mul.s    $f4, $f1, $f2    # v^^5
    l.s    $f5, five    # load 3.0
    div.s     $f5, $f4, $f5    # v^^5/5
    add.s    $f6, $f6, $f5    # value = v - v^^3/3 + v^^5/5

    l.s    $f8, PI        # load PI
    div.s    $f6, $f6, $f8    # value / PI
    l.s    $f7, F180    # load 180.0
    mul.s    $f6, $f6, $f7    # 180.0 * value / PI

    cvt.w.s $f6, $f6    # convert "delta" back to integer
    mfc1    $t0, $f6
    add    $v0, $v0, $t0    # angle += delta

euclidean_dist:
    mul    $a0, $a0, $a0    # x^2
    mul    $a1, $a1, $a1    # y^2
    add    $a2, $a0, $a1    # x^2 + y^2
    mtc1    $a2, $f0
    cvt.s.w    $f0, $f0    # float(x^2 + y^2)
    sqrt.s    $f0, $f0    # sqrt(x^2 + y^2)
    cvt.w.s    $f0, $f0    # int(sqrt(...))
    mfc1    $a2, $f0

    bge    $a2, 2, drive_end    # skip if !(abs_diff_x < 2)
    lw    $t2, index        # index
    add    $t2, $t2, 1        # index + 1
    sw    $t2, index        # index = index + 1
    j    drive            # continue
    
stall:
    lw    $t0, decode_counter
    beq    $t0, 1, stall1
    beq $t0, 2, stall2
    beq    $t0, 3, stall3
    beq    $t0, 4, stall4
    beq    $t0, 5, stall5
    beq    $t0, 6, stall6
    beq    $t0, 7, stall7
    beq    $t0, 8, stall8
    beq    $t0, 9, stall9
    jr    $ra

stall1:
    li    $a0, 180
    j    stall_end
stall2:
    li    $a0, 90
    j    stall_end
stall3:
    li    $a0, 0
    j    stall_end
stall4:
    li    $a0, 0
    j    stall_end
stall5:
    li    $a0, 270
    j    stall_end
stall6:
    li    $a0, 270
    j    stall_end
stall7:
    li    $a0, 180
    j    stall_end
stall8:
    li    $a0, 180
    j    stall_end
stall9:
    li    $a0, 90
stall_end:
    sw    $a0, ANGLE
    li    $a0, 1
    sw    $a0, ANGLE_CONTROL    # set_absolute_angle(new_angle)
    li    $a0, 10
    sw    $a0, VELOCITY
    lw    $a0, TIMER        # get_time()
    add    $a0, $a0, 50        # get_time() + 400
    sw    $a0, TIMER        # set_timer(get_time() + 400)
    jr    $ra
    
drive_end:
    move $a0, $v0
    sw    $a0, ANGLE
    li    $a0, 1
    sw    $a0, ANGLE_CONTROL    # set_absolute_angle(new_angle)

    li    $t0, 10
    sw    $t0, VELOCITY        # set_velocity to 10 at the beginning

    lw    $a0, TIMER        # get_time()
    mul    $a2, $a2, 450
    add    $a0, $a0, $a2        # get_time() + 400
    sw    $a0, TIMER        # set_timer(get_time() + 400)
    sw    $0, timer_done

    jr    $ra

decode:
    lw    $v0, decode_counter
    blt    $v0, 9, decode_start
    jr    $ra
    
decode_start:
    sub    $sp, $sp, 8    # $sp = $sp - 16
    sw    $ra, 0($sp)
    sw    $a0, 4($sp)

    lw    $s0, write_index
    la    $t7, token_x        # &token_x
    la    $t8, token_y        # &token_y
    la    $t6, addresses
    
decode_loop:
    move    $a0, $t6
    jal    sort_list
    move    $a0, $t6
    jal    compact    
            
    srl       $t1, $v0, 16            # x_coord = result >> 16
    bgt    $t1, 300, end_decode
    
    and       $t2, $v0, 0xffff        # y_coord = result & 0xffff
#    bgt    $t2, 300, end_decode    
    
    mul    $t5, $s0, 4

    add    $t3, $t7, $t5
    sw    $t1, 0($t3)
    add    $s0, $s0, 1
    add    $t4, $t8, $t5
    sw    $t2, 0($t4)
    
    add    $t6, $t6, 8
    add    $t9, $t9, 1
    j    decode_loop

end_decode:
    sw    $s0, write_index
    li  $a0, 1
    sw    $a0, decode_done
    lw    $a0, decode_counter
    add    $a0, $a0, 1
    sw    $a0, decode_counter
    lw    $ra, 0($sp)
    lw    $a0, 4($sp)
    add    $sp, $sp, 8
    jr    $ra
    
##sort list
sort_list:
    lw    $t0, 0($a0)        # mylist->head
    lw    $t1, 4($a0)        # mylist->tail
    bne    $t0, $t1, sl_main    # skip if !(mylist->head == mylist->tail)
    jr    $ra

sl_main:
    sub    $sp, $sp, 12
    sw    $ra, 0($sp)
    sw    $s0, 4($sp)
    sw    $s1, 8($sp)

    move    $s0, $a0        # mylist
    lw    $s1, 0($s0)        # smallest = mylist->head
    lw    $t0, 8($s1)        # trav = smallest->next

sl_loop:
    beq    $t0, 0, sl_recurse    # exit loop if !(trav != NULL)
    lw    $t1, 0($t0)        # trav->data
    lw    $t2, 0($s1)        # smallest->data
    bge    $t1, $t2, sl_next    # skip if !(trav->data < smallest->data)
    move    $s1, $t0        # smallest = trav

sl_next:
    lw    $t0, 8($t0)        # trav = trav->next
    j    sl_loop

sl_recurse:
    move    $a0, $s1        # smallest
    move    $a1, $s0        # mylist
    jal    remove_element

    move    $a0, $s0        # mylist
    jal    sort_list

    move    $a0, $s1        # smallest
    li    $a1, 0
    move    $a2, $s0        # mylist
    jal    insert_element_after

    lw    $ra, 0($sp)
    lw    $s0, 4($sp)
    lw    $s1, 8($sp)
    add    $sp, $sp, 12
    jr    $ra


##compact
compact:
    li     $v0, 0                # ret_val = 0
    li     $t1, 1                # mask = 1
    sll    $t1, $t1, 31             # mask = 1 << 31
    lw     $t2, 0($a0)        # trav = list->head

loop:
    beqz   $t2, end_loop        # !(trav != NULL)

    lw     $t3, 12($t2)            # trav->value
    beqz   $t3, else        # !(trav->value != 0)

    or     $v0, $v0, $t1        # ret_val |= mask
    j      end_if

else:    
    not    $t4, $t1                 # ~mask
    and    $v0, $v0, $t4        # ret_val &= ~mask

end_if:
    srl    $t1, $t1, 1                # mask = mask >> 1
    lw     $t2, 8($t2)          # trav = trav->next
    j      loop            # jump loop

end_loop:
    jr    $ra


##insert element
insert_element_after:
    bne    $a1, 0, iae_else    # skip if !(prev == NULL)
    lw    $t0, 0($a2)        # mylist->head
    sw    $t0, 8($a0)        # node->next = mylist->head
    sw    $zero, 4($a0)        # node->prev = NULL
    beq    $t0, 0, iae_head    # skip if !(mylist->head != NULL)
    sw    $a0, 4($t0)        # mylist->head->prev = node

iae_head:
    sw    $a0, 0($a2)        # mylist->head = node
    lw    $t0, 4($a2)        # mylist->tail
    bne    $t0, 0, iae_done    # skip if !(mylist->tail == NULL)
    sw    $a0, 4($a2)        # mylist->tail = node
    j    iae_done

iae_else:
    lw    $t0, 8($a1)        # prev->next
    bne    $t0, 0, iae_else2    # skip if !(prev->next == NULL)
    sw    $zero, 8($a0)        # node->next = NULL
    sw    $a0, 4($a2)        # mylist->tail = node
    j    iae_next

iae_else2:
    sw    $t0, 8($a0)        # node->next = prev->next
    sw    $a0, 4($t0)        # node->next->prev = node

iae_next:
    sw    $a0, 8($a1)        # prev->next = node
    sw    $a1, 4($a0)        # node->prev = prev

iae_done:
    jr    $ra
    
    
##remove element
remove_element:
    lw    $t0, 0($a1)        # mylist->head
    lw    $t1, 4($a1)        # mylist->tail
    bne    $t0, $t1, re_prev    # skip if !(mylist->head == mylist->tail)
    sw    $zero, 0($a1)        # mylist->head = NULL
    sw    $zero, 4($a1)        # mylist->tail = NULL
    j    re_done

re_prev:
    lw    $t0, 4($a0)        # node->prev
    bne    $t0, 0, re_next        # skip if !(node->prev == NULL)
    lw    $t0, 8($a0)        # node->next
    sw    $t0, 0($a1)        # mylist->head = node->next
    sw    $zero, 4($t0)        # node->next->prev = NULL
    j    re_done

re_next:
    lw    $t0, 8($a0)        # node->next
    bne    $t0, 0, re_else        # skip if !(node->next == NULL)
    lw    $t0, 4($a0)        # node->prev
    sw    $t0, 4($a1)        # mylist->tail = node->prev
    sw    $zero, 8($t0)        # node->prev->next = NULL
    j    re_done

re_else:
    lw    $t0, 8($a0)        # node->next
    lw    $t1, 4($a0)        # node->prev
    sw    $t0, 8($t1)        # node->prev->next = node->next
    sw    $t1, 4($t0)        # node->next->prev = node->prev

re_done:
    sw    $zero, 8($a0)        # node->next = NULL
    sw    $zero, 4($a0)        # node->prev = NULL
    jr    $ra