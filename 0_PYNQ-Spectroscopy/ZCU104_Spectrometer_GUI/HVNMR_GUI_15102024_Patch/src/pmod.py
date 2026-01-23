import src.fpga_tracing_func as fpga_tracing_func

ol = fpga_tracing_func.ol
da4 = ol.fpga_pmod_da4_a1_0

def da4_reset():
    global da4
    # reset
    da4.write(4, 0b0111)
    # fire command
    da4.write(16, 0b0001)
    da4.write(0,0b0001)
    # after reset also need to initialize again

def da4_init():
    global da4
    # internal command for using internal ref voltage
    da4.write(4,0b1000)
    # LSB to 1 for ref interal
    da4.write(16, 0b0001)
    # fire transition: 
    da4.write(0,0b0001)

def da4_setall( value):
    global da4
    # write and update channel n
    da4.write(4,0b0011)
    # addressing

    da4.write(8, 0b1111)# all channel
    # write 12-bit value: 
    da4.write(12, value)

    # write last Byte of Not cares
    da4.write(16, 0)
    # fire 
    da4.write(0, 1)
    
def da4_set(chn,value):
    global da4
    ## Write C , X
    # write and update channel n
    da4.write(4,0b0011)
    # addressing
    da4.write(8, chn)
    ## write value
    da4.write(12,value)
    # write last Byte of Not cares
    da4.write(16, 0)
    # fire 
    da4.write(0, 1)

da4_init()