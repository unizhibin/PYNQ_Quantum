# ----------------------------------------------------------------------------------
# -- Company: University of Stuttgart (IIS)
# -- Engineer: Yichao Peng
# --
# -- Description:
# -- This python file includes the functions for data processing module
# ----------------------------------------------------------------------------------

from pynq import allocate  # allocate memory that will be used by IP in the programmable logic
from pynq import MMIO
import src.all_of_the_parameters as all_of_the_parameters
import src.fpga_tracing_func as fpga_tracing_func
import src.web_GUI_config_panel as web_GUI_config_panel
import numpy as np
import pandas as pd
import os
import math
from scipy.signal import butter, filtfilt, cheby1, cheby2, lfilter, ellip
from scipy import signal

# clock frequency
sys_clk_freq = all_of_the_parameters.sys_clk_freq

# from hier are all parameters
Nr_Bytes_per_Ch = all_of_the_parameters.Nr_Bytes_per_Ch
Nr_Ana_Ch = all_of_the_parameters.Nr_Ana_Ch
Nr_Dig_Ch = all_of_the_parameters.Nr_Dig_Ch
Nr_Ana_Mem = all_of_the_parameters.Nr_Ana_Mem
Nr_Dig_Mem = all_of_the_parameters.Nr_Dig_Mem
Dep_Mem = all_of_the_parameters.Dep_Mem
sample_size = all_of_the_parameters.sample_size
plot_interval = all_of_the_parameters.plot_interval
sampling_time = all_of_the_parameters.sampling_time
adc_sampling_bit = all_of_the_parameters.adc_sampling_bit
adc_volt = all_of_the_parameters.adc_volt
c_for_convert_a = all_of_the_parameters.c_for_convert_a
# c_for_convert_b = all_of_the_parameters.c_for_convert_b
conf_dict = all_of_the_parameters.conf_dict
point_number_on_screen = all_of_the_parameters.point_number_on_screen
adc_sampling_bit = all_of_the_parameters.adc_sampling_bit

dma, dma_send, dma_recv = fpga_tracing_func.dma_init()

output_buffer_0 = allocate(shape=(sample_size * Nr_Ana_Ch * Nr_Bytes_per_Ch,), dtype=np.int32)  # define a DRAM block for memory, return buffer object
output_buffer_1 = allocate(shape=(sample_size * Nr_Ana_Ch * Nr_Bytes_per_Ch,), dtype=np.int32)  # define a DRAM block for sum, return buffer object
config_buffer = allocate(shape=(40,), dtype=np.int32)  # buffer special for configure panel
IP_Base_Addr = config_buffer.physical_address  # get physical address of already allocated memory section
mmio = MMIO(IP_Base_Addr, 40 * 4)  # MMIO provides a simple but powerful way to access and control peripherals (compared with DMA)


def mmio_init():
    mmio.write(conf_dict["conf_onoff"], 0)  # start/stop
    mmio.write(conf_dict["conf_trigger"], 1)  # trigger function
    mmio.write(conf_dict["conf_ana_ris"], 0)  # ana ris
    mmio.write(conf_dict["conf_ana_fal"], 0)  # ana fal
    mmio.write(conf_dict["conf_ana_ch"], 0)  # ana ch

    mmio.write(conf_dict["conf_ana_tl"], 0)  # ana TL
    mmio.write(conf_dict["conf_dig_ris"], 0)  # dig ris
    mmio.write(conf_dict["conf_dig_fal"], 0)  # dig fal
    mmio.write(conf_dict["conf_enh_sen"], 0)  # Enh_sensitivity
    mmio.write(conf_dict["conf_enh_res"], 0)  # Enh_Resolution

    mmio.write(conf_dict["conf_scale"], 10)  # clock step size (Scale)
    mmio.write(conf_dict["conf_position"], -(2 ** (Dep_Mem - 1)))  # Position
    mmio.write(conf_dict["conf_fft_ch"], 0)  # FFT_ch (e.g. 0,1,2,3)
    mmio.write(conf_dict["conf_fft_onoff"], 0)  # FFT_onoff
    mmio.write(conf_dict["conf_enh_tau"], 0)  # enh_tau

    mmio.write(conf_dict["conf_enh_dc"], 0)  # enh_dc
    mmio.write(conf_dict["conf_enh_bp_low_value"], 0)  # enh_bp_low_value
    mmio.write(conf_dict["conf_enh_bp_high_value"], 0)  # enh_bp_high_value
    mmio.write(conf_dict["conf_enh_bp_low_cb"], 0)  # enh_bp_low_cb
    mmio.write(conf_dict["conf_token"], 0)  # Token for config again

    mmio.write(conf_dict["conf_enh_bp_high_cb"], 0)  # enh_high_cb
    mmio.write(conf_dict["conf_enh_ch"], 0)  # enh_ch
    mmio.write(conf_dict["conf_nmr_chip_cfg_ref_curr"], 3)  # 011
    mmio.write(conf_dict["conf_nmr_chip_cfg_vga_gain"], 10)  # 1010
    mmio.write(conf_dict["conf_nmr_chip_cfg_pll_mult"], 3)  # 0011

    mmio.write(conf_dict["conf_nr_rx_pulse"], 1)  # initial rx number
    mmio.write(conf_dict["conf_nr_sample"], 2**16)  # initial sample per rx pulse package
    mmio.write(conf_dict["conf_exp_stop"], 1)  # set experiment stop flag - active low
    mmio.write(conf_dict["conf_loop_stop"], 1)  # set experiment stop flag - active low

    # mmio.write(conf_dict['conf_nmr_cfg_mixer_high_voltage'], 0) # set mixer on Heiko chip
    # mmio.write(conf_dict['conf_nmr_cfg_if_amp_high_voltage'], 1) # set IF amplifier on Heiko chip

    return


def func_update_config_tracing():  # communicate conf_para with fpga
    # print('test data processing func update config tracing')
    # config tracing
    fpga_tracing_func.enable(0)
    fpga_tracing_func.set_nr_samples(mmio.read(conf_dict["conf_nr_sample"]))  # number of samples for single rx
    fpga_tracing_func.trigger_delay(mmio.read(conf_dict["conf_position"]))  # position
    fpga_tracing_func.clock_step_size(int(sys_clk_freq / mmio.read(conf_dict["conf_scale"])))  # use fs to calculate(100MHz/scale=fs)
    fpga_tracing_func.digtal_trigger_ris_edge(mmio.read(conf_dict["conf_dig_ris"]))  # dig ris
    fpga_tracing_func.digtal_trigger_fal_edge(mmio.read(conf_dict["conf_dig_fal"]))  # dig fal
    fpga_tracing_func.type_stream(mmio.read(conf_dict["conf_trigger"]))  # 0 = arm, 1 = single shot
    fpga_tracing_func.set_stream_number_rx_pulse(mmio.read(conf_dict["conf_nr_rx_pulse"]))  # set Nr of Packages
    fpga_tracing_func.enable(1)
    fpga_tracing_func.enable(mmio.read(conf_dict["conf_onoff"]))  # disable
    mmio.write(conf_dict["conf_token"], 0)

    return


def func_update_config_special_for_pulse_gen():  # communicate conf_para with fpga
    # config tracing
    fpga_tracing_func.enable(0)
    fpga_tracing_func.set_nr_samples(sample_size)
    fpga_tracing_func.trigger_delay(mmio.read(conf_dict["conf_position"]))  # Position
    fpga_tracing_func.trigger_ris_edge(0)  # ana ris
    fpga_tracing_func.trigger_fal_edge(0)  # ana fal
    fpga_tracing_func.clock_step_size(int(sys_clk_freq / mmio.read(conf_dict["conf_scale"])))  # use fs to calculate(100MHz/scale=fs)
    fpga_tracing_func.digtal_trigger_ris_edge(1)  # dig ris
    fpga_tracing_func.digtal_trigger_fal_edge(0)  # dig fal
    fpga_tracing_func.type_stream(0)  # 0 = arm, 1 = single shot
    fpga_tracing_func.set_stream_number_rx_pulse(1)  # set Nr of Packages
    fpga_tracing_func.enable(1)
    mmio.write(conf_dict["conf_token"], 1)

    return


def func_update_data(number_rx_pulse, buffer_size):  # read data from dma into output_buffer_0 and split them into 4 channels outputs
    global output_buffer_0

    dma_recv.transfer(output_buffer_0[0:buffer_size])  # read back from the receive DMA to the output buffer.
    # the wait() method ensures the DMA transactions have completed.
    fpga_tracing_func.type_stream(mmio.read(conf_dict["conf_trigger"]))  # 0 = arm, 1 = single shot
    fpga_tracing_func.set_stream_number_rx_pulse(number_rx_pulse)  # set Nr of Packages, 1 for FID
    fpga_tracing_func.start_stream_transfer()

    _ch0 = output_buffer_0[0:buffer_size:Nr_Ana_Ch]
    _ch1 = output_buffer_0[1:buffer_size:Nr_Ana_Ch]

    return _ch0, _ch1


def func_timeline_update(time_list):
    time_multiplier = mmio.read(conf_dict["conf_scale"]) * sampling_time * plot_interval
    time_list_output = list(time_list * time_multiplier)

    return time_list_output


def func_dc_remove(data):
    mean = int(np.mean(data))
    data = np.clip(data, max(-sample_size, (-sample_size + mean)), min((sample_size - 1), (sample_size - 1 + mean))).tolist()
    data = np.subtract(data, mean)

    return data


def func_save_file(ch0, ch1):
    print("Begin generating file and writing data.")
    time_line_length = max(len(ch0), len(ch1))
    time_stream_root = np.arange(0, time_line_length)
    time_stream = list(time_stream_root * mmio.read(conf_dict["conf_scale"]) * sampling_time)
    _ch0 = list(np.array(ch0) / c_for_convert_a)  # + c_for_convert_b)
    _ch1 = list(np.array(ch1) / c_for_convert_a)  # + c_for_convert_b)

    data = {"time(ns)": time_stream, "channel0(mV)": _ch0, "channel1(mV)": _ch1}

    output_data = pd.DataFrame(data)
    path = "output"
    if not os.path.exists(path):
        os.mkdir(path)
    if web_GUI_config_panel.GUI_save_name.value == "":
        web_GUI_config_panel.GUI_save_name.value = "Untitled"
    if web_GUI_config_panel.GUI_save_format.value == 0:
        name = "output/" + web_GUI_config_panel.GUI_save_name.value + ".csv"
        try:
            output_data.to_csv(name)
        except FileNotFoundError:
            pass
    elif web_GUI_config_panel.GUI_save_format.value == 1:
        name = "output/" + web_GUI_config_panel.GUI_save_name.value + ".txt"
        try:
            output_data.to_csv(name)
        except FileNotFoundError:
            print("File not existed!")
            # pass
    print("File successfully saved.")
    return


def func_save_file_for_automatic_collection(ch0, ch1, name):
    print("Begin generating file and writing data.")
    time_line_length = max(len(ch0), len(ch1))
    time_stream_root = np.arange(0, time_line_length)
    time_stream = list(time_stream_root * mmio.read(conf_dict["conf_scale"]) * sampling_time)
    _ch0 = list(np.array(ch0) / c_for_convert_a)  # + c_for_convert_b)
    _ch1 = list(np.array(ch1) / c_for_convert_a)  # + c_for_convert_b)

    data = {"time(ns)": time_stream, "channel0(mV)": _ch0, "channel1(mV)": _ch1}

    output_data = pd.DataFrame(data)
    path = "output"
    if not os.path.exists(path):
        os.mkdir(path)
    name = "output/" + name + ".csv"
    try:
        output_data.to_csv(name)
    except FileNotFoundError:
        pass
    print("File successfully saved.")
    return


def func_data_processing_for_plot(time_stream, ch0, ch1, sample_per_channel):
    # compress data into fewer samples to plot on screen：65536 points

    x = np.linspace(0, sample_per_channel - 1, point_number_on_screen)  # linspace will include the later number
    x = x.tolist()

    for i in range(len(x)):
        x[i] = int(x[i])

    Analog0_output = ch0[x]  # sample analog stream according to vector x
    Analog1_output = ch1[x]

    time_stream_sampled = time_stream[x]  # sample time stream according to vector x

    return Analog0_output, Analog1_output, time_stream_sampled


def bandpass_filter(data, f_low, f_high, order=3, type=2):  # apply bandpass filter to time-domain signal
    # shared parameters
    L = len(data)
    clock_scale = int(100 / web_GUI_config_panel.GUI_Scale.value)  # frequency divider
    fs = 100 * (10**6) / clock_scale  # sampling rate
    fpass = [f_low, f_high]  # in Hz
    nyq = 0.5 * fs
    # order = order # 阶数会影响ripple，即通阻带之间的波纹现象，也会影响计算时间

    # 1. Butterworth filter
    if type == 2:
        Wn = [fpass[0] / nyq, fpass[1] / nyq]
        b, a = butter(order, Wn, btype="bandpass")
        data_butter_filtered = filtfilt(b, a, data)
        return data_butter_filtered

    # 2. Chebyshev filter type I
    if type == 3:
        ripple_db = 0.5  # 波纹参数
        b, a = cheby1(order, ripple_db, [25000, 75000], btype="bandpass", fs=fs)
        data_cheby1_filtered = lfilter(b, a, data)
        return data_cheby1_filtered

    # 3. Chebyshev filter type II
    if type == 4:
        passband_attenuation_db = 40  # 通带衰减要求
        b, a = cheby2(order, passband_attenuation_db, [25000, 75000], btype="bandpass", fs=fs)
        data_cheby2_filtered = lfilter(b, a, data)
        return data_cheby2_filtered

    # 4. Elliptic filter
    if type == 5:
        rp = 1  # 通带最大纹波衰减（单位：dB）
        rs = 40  # 阻带最小衰减（单位：dB）
        Wn = [fpass[0] / nyq, fpass[1] / nyq]
        b, a = signal.ellip(order, rp, rs, Wn, btype="band", analog=False, output="ba")  # 返回滤波器的分子系数（b）和分母系数（a）
        data_elliptic_filtered = lfilter()
    return data_elliptic_filtered


def calculate_nmr_linewidth(frequency, amplitude):  # find linewidth on frequency spectrum, y normalized
    # find peak and index
    peak_max = np.max(amplitude)
    peak_index = np.argmax(amplitude)

    # calculate linewidth using half peak width method
    half_max = peak_max / 2.0
    left_index = np.where(amplitude[:peak_index] <= half_max)[0][-1]
    right_index = np.where(amplitude[peak_index:] <= half_max)[0][0] + peak_index
    linewidth = frequency[right_index] - frequency[left_index]

    return linewidth
