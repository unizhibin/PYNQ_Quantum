import os

"""
general parameters
"""

# screen width and height
screen_width = 1920  # in pixel 1920
screen_height = 1080  # in pixel 1080

# choose bitstream, generated in Vivado
# path_to_bitstream_hv = "./src/HVNMR.bit"
path_to_bitstream_hv = "./src/MRI_Rev3.bit"
path_to_bitstream_hf = "./src/NMR_high_frequency.bit"

flag_bitstream = 0

if os.path.exists(path_to_bitstream_hf) and os.path.exists(path_to_bitstream_hv):
    raise NameError("Please put only one bitstream file in the folder.")
elif os.path.exists(path_to_bitstream_hv):  # heiko's chip
    flag_bitstream = 0
elif os.path.exists(path_to_bitstream_hf):  # freddy's chip
    flag_bitstream = 1
else:
    raise NameError("Please check bitstream name. It should have the name NMR_high_voltage or NMR_high_frequency.")

sys_clk_freq = 100  # MHz
dds_clk_freq = 250  # MHz
phase_width = 32  # see Vivado IP core configuration

"""
parameters for chip_config
"""
# for phase testing. This is a binary code contains 3 parameters for nmr chip config
# include 1. PLL(3 bits), 2. VGA gain(4 bits) 3. reference current(4 bits)
chip_cfg_data_default = 931  # config data to chip config unit (11bits)0b011|1010|0011

"""
AXI4 Lite slave address offset for pulse generator IP core
"""
pulse_gen_dict = {
    "C_SEQUENCE_GENERATOR_EN": 0 * 4,  # start the pulse sequence
    "C_SET_NR_SECTIONS": 1 * 4,  # set the number of section
    "C_SEL_SECTION": 2 * 4,  # write section select
    "C_SET_SECTION_TYPE": 3 * 4,  # set section type
    "C_SET_DELAY": 4 * 4,  # set section duration
    "C_SET_MUX": 5 * 4,  # set section muxplexer
    "C_SET_START_REPEAT_POINTER": 6 * 4,  # set repetition start section pointer
    "C_SET_END_REPEAT_POINTER": 7 * 4,  # set repetition end section pointer
    "C_SET_CYCLE_REPETITION_NUMBER": 8 * 4,  # set cycle repetition number
    "C_SET_EXPERIMENT_REPETITION_NUMBER": 9 * 4,  # set experiment repetition number
    "C_SET_PHASE_CH0": 10 * 4,  # channel 0 set phase
    "C_SET_FREQUENCY_CH0": 11 * 4,  # channel 0 set frequency
    "C_SET_PHASE_CH1": 12 * 4,  # channel 1 set phase
    "C_SET_FREQUENCY_CH1": 13 * 4,  # channel 1 set frequency
    "C_SET_RESETN_DDS": 14 * 4,  # DDS reset
    "C_GET_BUSY": 15 * 4,  # channel busy signal
    "C_GET_DATA_READY": 16 * 4,  # channel data ready signal
    "C_GET_NR_DDS_CH": 17 * 4,  # set number of DDS channel
    "C_GET_MEM_DEPTH": 18 * 4,  # set memory depth
    "C_GET_NR_ACTIVITY": 19 * 4,  # set number of activity
}


"""
parameters for tracing
"""

# these para are face to fpga config including information of channels and ram
Nr_Bytes_per_Ch = 4
Nr_Ana_Ch = 2
Nr_Dig_Ch = 16
Nr_Ana_Mem = 2
Nr_Dig_Mem = 1
Dep_Mem = 22  # 17 before
point_number_on_screen = 2**15  # 32768
sampling_time = 1000 / sys_clk_freq  # 4 ns for one sample. From the main frequency.
adc_sampling_bit = 18  # set ADC resolution
adc_volt = 500  # Voltage on one side from x axis in mV

sample_value_half = 2 ** (adc_sampling_bit - 1)
sample_size = 2**Dep_Mem
plot_interval = int(sample_size / point_number_on_screen)
c_for_convert_a = 2**adc_sampling_bit / adc_volt
# c_for_convert_b = adc_volt / 2

# address offset dictionary for FPGA tracing part
fpga_func_dict = {
    "C_ENABLE_CMD": 0 * 4,  # enable *
    "C_SINGLE_SHOT_CMD": 1 * 4,  # run the single shot
    "C_SELECT_ANALOG_TRIGGER_CHANNEL_CMD": 2 * 4,  # select the analog trigger chanel
    "C_SET_ANALOG_TRIGGER_RISING_EDGE_CMD": 3 * 4,  # set the analog trigger edge rising edge or falling edge enable
    "C_SET_ANALOG_TRIGGER_FALLING_EDGE_CMD": 4 * 4,  # set the analog trigger edge rising edge or falling edge enable
    "C_BIN_CH_RE_TRIG_EN_CMD": 5 * 4,  # set the digital chanle trigger rising edge enable *
    "C_BIN_CH_FE_TRIG_EN_CMD": 6 * 4,  # set the digital chanel trigger falling edge enable *
    "C_ARM_CMD": 7 * 4,  # arm
    "C_SET_NR_SAMPLES_CMD": 8 * 4,  # set the number of sumples, max 2^ memory depth *
    "C_CLOCK_STEP_SIZE_CMD": 9 * 4,  # set clock size Program Logic clock over the step of size *
    "C_SET_TRIGGER_DELAY_CMD": 10 * 4,  # trigger delay function using for the trigger center for ploting
    "C_SELECT_READ_MEMORY_CMD": 11 * 4,  # select the read memory from channel
    "C_SET_CURRENT_READ_ADDRESS_CMD": 12 * 4,  # set the current read address for block ram
    "C_READ_DATA": 13 * 4,  # read data
    "C_GET_NR_ANALOG_CHANNELS_CMD": 14 * 4,  # get the number of the analog channels
    "C_GET_NR_DIGITAL_CHANNELS_CMD": 15 * 4,  # get the number of digital channels
    "C_GET_NR_ANALOG_MEMORIES_CMD": 16 * 4,  # get the number of analog memories
    "C_GET_NR_DIGITAL_MEMORIES_CMD": 17 * 4,  # get the number of digital meories
    "C_GET_MEMORY_DEPTH_CMD": 18 * 4,  # get the memory depth of analog channel*
    "C_READ_BUSY_SIGNAL_CMD": 19 * 4,  # read the busy of block
    "C_READ_READY_SIGNAL_CMD": 20 * 4,  # read the ready signal
    "C_TOGGLE_LED_CMD": 21 * 4,  # toggle the led
    "C_SET_ANALOG_TRIGGER_THRESHOLD_CMD": 22 * 4,  # set the analog trigger threshold voltage
    "C_CTRL_MUX_SELECT_ANALOG_MEMORY_CMD": 23 * 4,  # control mux select analog memory
    "C_CTRL_MUX_SELECT_ANALOG_CH_CMD": 24 * 4,  # control mux select analog channel
    "C_SET_STREAM_NR_RX_PULSE": 25 * 4,  # set the number of rx pulse *
    "C_START_STREAM": 26 * 4,  # start stream transfer *
    "C_TYPE_STREAM": 27 * 4,  # type of stream arm 0 single shot 1 *
    "C_REST_SAMPLES": 28 * 4,  # rest of samples that not transferred
    "C_READ_STREAM_BUSY": 29 * 4,  # if there exist rest samples, then busy
}

# dictionary for fpga mmio controlling up to 40 * 4
conf_dict = {
    "conf_onoff": 0 * 4,
    "conf_trigger": 1 * 4,
    "conf_ana_ris": 2 * 4,
    "conf_ana_fal": 3 * 4,
    "conf_ana_ch": 4 * 4,
    "conf_ana_tl": 5 * 4,
    "conf_dig_ris": 6 * 4,
    "conf_dig_fal": 7 * 4,
    "conf_scale": 8 * 4,
    "conf_position": 9 * 4,
    "conf_fft_ch": 10 * 4,
    "conf_fft_onoff": 11 * 4,
    "conf_enh_sen": 12 * 4,
    "conf_enh_res": 13 * 4,
    "conf_enh_tau": 14 * 4,
    "conf_enh_dc": 15 * 4,
    "conf_enh_bp_low_value": 16 * 4,
    "conf_enh_bp_high_value": 17 * 4,
    "conf_enh_bp_low_cb": 18 * 4,
    "conf_enh_bp_high_cb": 19 * 4,
    "conf_enh_ch": 20 * 4,
    "conf_token": 21 * 4,
    "conf_save_file": 22 * 4,
    "conf_nmr_chip_cfg_ref_curr": 23 * 4,
    "conf_nmr_chip_cfg_vga_gain": 24 * 4,
    "conf_nmr_chip_cfg_pll_mult": 25 * 4,
    "C_START_STREAM": 26 * 4,  # start stream transfer
    "C_TYPE_STREAM": 27 * 4,  # type of stream arm 0 single shot 1
    "conf_nr_rx_pulse": 28 * 4,  # set number of rx pulse, fid:1, cpmg:echo text input
    "conf_nr_sample": 29 * 4,  # set number of sample each bag
    "conf_exp_stop": 30 * 4,  # terminate experiment, 0-average, 1-stop
    "conf_bandpass_filter": 31 * 4,  # whether to apply bandpass filter
    "conf_bandpass_filter_f_low": 32 * 4,  # lower band of bandpass filter
    "conf_bandpass_filter_f_high": 33 * 4,  # higher band of bandpass filter
    "conf_bandpass_filter_order": 34 * 4,  # order of bandpass filter
    "conf_loop_stop": 35 * 4,  # FID or CPMG loop token, 0-loop, 1-stop
    "conf_nmr_cfg_mixer_high_voltage": 36 * 4,  # mixer of high voltage chip
    "conf_nmr_cfg_if_amp_high_voltage": 37 * 4,  # IF amplifier of high voltage chip
    "conf_nmr_cfg_pll_high_voltage": 37 * 4,  # IF amplifier of high voltage chip
}
