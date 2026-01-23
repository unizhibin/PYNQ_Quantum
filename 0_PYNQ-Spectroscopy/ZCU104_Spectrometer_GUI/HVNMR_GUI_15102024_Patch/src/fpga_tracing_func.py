# ----------------------------------------------------------------------------------
# -- Company: University of Stuttgart (IIS)
# -- Engineer: Yichao Peng
# -- 
# -- Description: 
# -- This Python file is for communication with FPGA board (Pynq ZCU104)
# ----------------------------------------------------------------------------------

import ipywidgets as widgets
import src.all_of_the_parameters as all_of_the_parameters
from pynq import Overlay
import warnings
import time

chip_cfg_data_default = all_of_the_parameters.chip_cfg_data_default
Dep_Mem = all_of_the_parameters.Dep_Mem
sample_size = all_of_the_parameters.sample_size

warnings.filterwarnings("ignore", message="Setting frequency to the closest possible value") # ignore frequency inaccuracy problem
if all_of_the_parameters.flag_bitstream == 0:
    ol = Overlay(all_of_the_parameters.path_to_bitstream_hv)
else:
    ol = Overlay(all_of_the_parameters.path_to_bitstream_hf)

pulse_gen = ol.fpga_pulse_generator_0    # DACs Pulse Generator unit
osci = ol.fpga_tracing_0    # ADCs tracing unit
adc0 = ol.fpga_ADC_AD7960_0  # ADC drivers
adc1 = ol.fpga_ADC_AD7960_1
chip_cfg = ol.fpga_nmr_chip_config_0 # chip config control unit definition

# dictionary for tracing fpga controlling
fpga_func_dict = all_of_the_parameters.fpga_func_dict

"""
Controlling Functions for nmr chip config
"""
# Freddy's high frequency overlay
def fpga_func_chip_cfg(input):
    chip_cfg.write(0 * 4, input)  # config data to chip config 
    chip_cfg.write(1 * 4, 1)  # chip config start
    return 

# Heiko's high voltage overlay

# SPI-configuration Command Addresses
# Constants
register_width = 32

# Register 0 and 2 are for SPI data
# Register 1 is for start the transmission
# Register 3 is for read out of done signal

Address_register_SPI_data = tuple(x * 4 for x in (0, 2))
Address_register_start = 1 * 4
Address_register_done = 3 * 4

# Sub-adress of SPI configuration under Register 0 and 2, 51 bits in total

sub_addr_array = [
    0,   # Sub_Address_SPI_pll_en
    1,   # Sub_Address_SPI_gain
    2,   # Sub_Address_SPI_skip_mixer
    3,   # Sub_Address_SPI_prescaler_pll
    5,   # Sub_Address_SPI_N_divider_pll
    10,  # Sub_Address_SPI_prescaler_tx_logic
    12,  # Sub_Address_SPI_tx_shortening_counter
    20,  # Sub_Address_SPI_deadtime_hs_p
    24,  # Sub_Address_SPI_deadtime_ls_p
    28,  # Sub_Address_SPI_deadtime_hs_n
    32,  # Sub_Address_SPI_deadtime_ls_n
    36,  # Sub_Address_SPI_deadtime_comp_p
    40,  # Sub_Address_SPI_deadtime_comp_n
    44,  # Sub_Address_SPI_delay_p
    48,  # Sub_Address_SPI_delay_n
    52,  # Sub_Address_SPI_amplifier_reset
    53,  # Sub_Address_SPI_pll_or_spi_output
    54   # Sub_Address_SPI_ls
]

# 18 SPI configuration commands in total for heiko's chip

Sub_Address_SPI_pll_en = 0
Sub_Address_SPI_gain = 1
Sub_Address_SPI_skip_mixer = 2
Sub_Address_SPI_prescaler_pll = 3
Sub_Address_SPI_N_divider_pll = 4
Sub_Address_SPI_prescaler_tx_logic = 5
Sub_Address_SPI_tx_shortening_counter = 6
Sub_Address_SPI_deadtime_hs_p = 7
Sub_Address_SPI_deadtime_ls_p = 8
Sub_Address_SPI_deadtime_hs_n = 9
Sub_Address_SPI_deadtime_ls_n = 10
Sub_Address_SPI_deadtime_comp_p = 11
Sub_Address_SPI_deadtime_comp_n = 12
Sub_Address_SPI_delay_p = 13
Sub_Address_SPI_delay_n = 14
Sub_Address_SPI_amplifier_reset = 15
Sub_Address_SPI_pll_or_spi_output = 16
Sub_Address_SPI_ls = 17

# Basic functions

# Read whole register value
def read_register(address):
    return chip_cfg.read(address)

# Write whole register value
def write_register(address, val):
    return chip_cfg.write(address, val)

# Clear all registers
def clear_register():
    chip_cfg.write(Address_register_SPI_data[0], 0)
    chip_cfg.write(Address_register_SPI_data[1], 0)
    chip_cfg.write(Address_register_start, 0)
    chip_cfg.write(Address_register_done, 0)

# Read SPI data register sub-function value
def read_spi_sub_address(sub_address):
    cur = chip_cfg.read(Address_register_SPI_data[1]) + 2**32 * chip_cfg.read(Address_register_SPI_data[0])
    if (sub_address == 17):
        len = 1
    else:
        len = sub_addr_array[sub_address + 1] - sub_addr_array[sub_address]
    result = (cur >> (9 + sub_addr_array[sub_address])) % (2**len)
    return result
    
# Read SPI data register specific bit value
def read_bit(address, bit):
    pass
    
# Write SPI data register sub-function value
def write_spi_sub_address(sub_address, set_val):
    address = Address_register_SPI_data[0] if sub_addr_array[sub_address] > 22 else Address_register_SPI_data[1]  # firstly find out whether the subaddress in register 0 or 2
    cur_0 = read_register(Address_register_SPI_data[0])
    cur_2 = read_register(Address_register_SPI_data[1])
    if (sub_address == Sub_Address_SPI_deadtime_hs_p): # special, need change both register 0 and 2
        # print("Command in both register 0 and register 2.")
        # print(4)
        if (set_val >= 8):
            masked = cur_0 & (2 ** register_width - 1 - 1)
            result_0 = masked | 1
            set_val = set_val - 8
            # print(set_val)
        else:
            masked = cur_0 & (2 ** register_width - 1 - 1)
            result_0 = masked
        chip_cfg.write(Address_register_SPI_data[0], result_0)
        max_val = 7
        set_val = set_val if (set_val<=max_val) else max_val
        # print(set_val)
        masked = cur_2 & (2 ** register_width - 1 - (max_val << 29))
        result_2 = masked | (set_val << 29)
        chip_cfg.write(Address_register_SPI_data[1], result_2)
    else:
        if (sub_address == 17):
            len = 1
        else:
            len = sub_addr_array[sub_address + 1] - sub_addr_array[sub_address]
        # print(len)
        max_val = 2 ** len - 1
        if (set_val > max_val):
            set_val = max_val
        if (address == Address_register_SPI_data[1]):
            masked = cur_2 & (2 ** register_width - 1 - (max_val << (sub_addr_array[sub_address] + 9)))
            result_2 = masked | (set_val << (sub_addr_array[sub_address] + 9))
            chip_cfg.write(Address_register_SPI_data[1], result_2)
        else:
            masked = cur_0 & (2 ** register_width - 1 - (max_val << (sub_addr_array[sub_address] - 23)))
            result_0 = masked | (set_val << (sub_addr_array[sub_address] - 23))
            chip_cfg.write(Address_register_SPI_data[0], result_0)
    return

# Register 1
def spi_write_start(val): # rising edge trigger
    chip_cfg.write(Address_register_start, val)

# Register 3
def spi_read_finish(): # spi finish signal
    chip_cfg.read(Address_register_done)

# Register 0 and 2
# Bit 0: internal PLL
def spi_read_pll_en():
    return read_spi_sub_address(Sub_Address_SPI_pll_en)
def spi_write_pll_en(val):
    return write_spi_sub_address(Sub_Address_SPI_pll_en, val)

# Bit 1: gain
def spi_read_gain():
    return read_spi_sub_address(Sub_Address_SPI_gain)
def spi_write_gain(val):
    return write_spi_sub_address(Sub_Address_SPI_gain, val)

# Bit 2: skip_mixer
def spi_read_skip_mixer():
    return read_spi_sub_address(Sub_Address_SPI_skip_mixer)
def spi_write_skip_mixer(val):
    return write_spi_sub_address(Sub_Address_SPI_skip_mixer, val)

# Bit 3-4: prescaler_pll
def spi_read_prescaler_pll():
    return read_spi_sub_address(Sub_Address_SPI_prescaler_pll)
def spi_write_prescaler_pll(val):
    return write_spi_sub_address(Sub_Address_SPI_prescaler_pll, val)

# Bit 5-9: N_divider_pll
def spi_read_N_divider_pll():
    return read_spi_sub_address(Sub_Address_SPI_N_divider_pll)
def spi_write_N_divider_pll(val):
    return write_spi_sub_address(Sub_Address_SPI_N_divider_pll, val)

# Bit 10-11: prescaler_tx_logic
def spi_read_prescaler_tx_logic():
    return read_spi_sub_address(Sub_Address_SPI_prescaler_tx_logic)
def spi_write_prescaler_tx_logic(val):
    return write_spi_sub_address(Sub_Address_SPI_prescaler_tx_logic, val)

# Bit 12-19: tx_shortening_counter
def spi_read_tx_shortening_counter():
    return read_spi_sub_address(Sub_Address_SPI_tx_shortening_counter)
def spi_write_tx_shortening_counter(val):
    return write_spi_sub_address(Sub_Address_SPI_tx_shortening_counter, val)

# Bit 20-23: deadtime_hs_p
def spi_read_deadtime_hs_p():
    return read_spi_sub_address(Sub_Address_SPI_deadtime_hs_p)
def spi_write_deadtime_hs_p(val):
    return write_spi_sub_address(Sub_Address_SPI_deadtime_hs_p, val)

# Bit 24-27: deadtime_ls_p
def spi_read_deadtime_ls_p():
    return read_spi_sub_address(Sub_Address_SPI_deadtime_ls_p)
def spi_write_deadtime_ls_p(val):
    return write_spi_sub_address(Sub_Address_SPI_deadtime_ls_p, val)

# Bit 28-31: deadtime_hs_n
def spi_read_deadtime_hs_n():
    return read_spi_sub_address(Sub_Address_SPI_deadtime_hs_n)
def spi_write_deadtime_hs_n(val):
    return write_spi_sub_address(Sub_Address_SPI_deadtime_hs_n, val)

# Bit 32-35: deadtime_ls_n
def spi_read_deadtime_ls_n():
    return read_spi_sub_address(Sub_Address_SPI_deadtime_ls_n)
def spi_write_deadtime_ls_n(val):
    return write_spi_sub_address(Sub_Address_SPI_deadtime_ls_n, val)

# Bit 36-39: deadtime_comp_p
def spi_read_deadtime_comp_p():
    return read_spi_sub_address(Sub_Address_SPI_deadtime_comp_p)
def spi_write_deadtime_comp_p(val):
    return write_spi_sub_address(Sub_Address_SPI_deadtime_comp_p, val)

# Bit 40-43: deadtime_comp_n
def spi_read_deadtime_comp_n():
    return read_spi_sub_address(Sub_Address_SPI_deadtime_comp_n)
def spi_write_deadtime_comp_n(val):
    return write_spi_sub_address(Sub_Address_SPI_deadtime_comp_n, val)

# Bit 44-47: delay_p
def spi_read_delay_p():
    return read_spi_sub_address(Sub_Address_SPI_delay_p)
def spi_write_delay_p(val):
    return write_spi_sub_address(Sub_Address_SPI_delay_p, val)

# Bit 48-51: delay_n
def spi_read_delay_n():
    return read_spi_sub_address(Sub_Address_SPI_delay_n)
def spi_write_delay_n(val):
    return write_spi_sub_address(Sub_Address_SPI_delay_n, val)

# Bit 52: amplifier_reset
def spi_read_amplifier_reset():
    return read_spi_sub_address(Sub_Address_SPI_amplifier_reset)
def spi_write_amplifier_reset(val):
    return write_spi_sub_address(Sub_Address_SPI_amplifier_reset, val)

# Bit 53: pll_or_spi_output
def spi_read_pll_or_spi_output():
    return read_spi_sub_address(Sub_Address_SPI_pll_or_spi_output)
def spi_write_pll_or_spi_output(val):
    return write_spi_sub_address(Sub_Address_SPI_pll_or_spi_output, val)

# Bit 54: ls
def spi_read_ls():
    return read_spi_sub_address(Sub_Address_SPI_ls)
def spi_write_ls(val):
    return write_spi_sub_address(Sub_Address_SPI_ls, val)

def int32_to_string(number):
    binary_str = format(number, '032b')
    return binary_str

def reverse_digits(decimal):
    decimal_str = str(decimal)
    reversed_str = decimal_str[::-1]
    return reversed_str

def binary_to_decimal(binary_str):
    decimal_number = 0
    binary_str = binary_str[::-1]
    for i in range(len(binary_str)):
        if binary_str[i] == '1':
            decimal_number += 2 ** i
    return decimal_number

def reverse_register_heiko():
    reg_0 = read_register(0*4)
    reg_2 = read_register(2*4)
    reg_2_truncated = int(reg_2 / 2 ** 9)
    reg = reg_0 * 2 ** 23 + reg_2_truncated
    reg_inversed = binary_to_decimal(reverse_digits(format(reg, '055b')))
    write_register(0*4, int(reg_inversed / 2 ** 23))
    write_register(2*4, int(reg_inversed % 2 ** 23) * 2 ** 9)


"""
Button for IF amplifier
"""
def GUI_chip_cfg_if_amp_high_voltage():
    
    GUI_chip_cfg_if_amp_high_voltage = widgets.ToggleButton(
        value=False,
        description='IF Amplifier',
        disabled=False,
        button_style='',
        tooltip='IF Amplifier',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*all_of_the_parameters.screen_width))+'px'), # min118px, 128px original
    )
    return GUI_chip_cfg_if_amp_high_voltage

GUI_chip_cfg_if_amp_high_voltage = GUI_chip_cfg_if_amp_high_voltage()    

"""
Controlling Functions for tracing part
"""

def enable(input):
    osci.write(fpga_func_dict['C_ENABLE_CMD'],input)
    return

def disable():
    osci.write(fpga_func_dict['C_ENABLE_CMD'],0)
    return

def digtal_trigger_ris_edge(input):#0/1
    osci.write(fpga_func_dict['C_BIN_CH_RE_TRIG_EN_CMD'],input)
    return

def digtal_trigger_fal_edge(input):#0/1
    osci.write(fpga_func_dict['C_BIN_CH_FE_TRIG_EN_CMD'],input)
    return

def set_nr_samples(data):
    osci.write(fpga_func_dict['C_SET_NR_SAMPLES_CMD'],data)
    return
    
def clock_step_size(data):
    osci.write(fpga_func_dict['C_CLOCK_STEP_SIZE_CMD'],data)
    return
    
def trigger_delay(data):
    osci.write(fpga_func_dict['C_SET_TRIGGER_DELAY_CMD'],data)
    return
    
def set_stream_number_rx_pulse(data):
    osci.write(fpga_func_dict['C_SET_STREAM_NR_RX_PULSE'],data)
    return
    
def start_stream_transfer():
    osci.write(fpga_func_dict['C_START_STREAM'],1)
    return

def terminate_stream_transfer():
    osci.write(fpga_func_dict['C_START_STREAM'],0)
    return
    
def type_stream(data):
    osci.write(fpga_func_dict['C_TYPE_STREAM'],data)
    return

def dma_init():
    dma    = ol.axi_dma_0
    dma_send = ol.axi_dma_0.sendchannel
    dma_recv = ol.axi_dma_0.recvchannel
    return dma, dma_send, dma_recv

def fpga_tracing_init(samples):
    
    # ADC configure
    mode = 9
    # 0 = rising , 1 = falling
    adc0.write(0x0,mode)
    adc1.write(0x0,mode)
    
    # chip_cfg.write(0 * 4, chip_cfg_data_default)  # config data to chip config
    # chip_cfg.write(1 * 4, 1)  # chip config start

    set_nr_samples(samples) # 2**15
    set_stream_number_rx_pulse(1)
    trigger_delay(-2**(Dep_Mem-1)+1)

    clock_step_size(10)
    digtal_trigger_ris_edge(0)
    digtal_trigger_fal_edge(0)
    return