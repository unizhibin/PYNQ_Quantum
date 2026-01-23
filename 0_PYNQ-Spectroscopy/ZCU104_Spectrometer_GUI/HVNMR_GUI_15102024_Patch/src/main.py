# ----------------------------------------------------------------------------------
# -- Company: University of Stuttgart (IIS)
# -- Engineer: Yichao Peng
# --
# -- Description:
# -- This Python file contains code for main functions of pNMR GUI.
# ----------------------------------------------------------------------------------


"""
import libraries and scripts
"""

import numpy as np
import time
import src.fpga_tracing_func as fpga_tracing_func
import src.web_GUI_config_panel as web_GUI_config_panel
import src.web_GUI_pulse_gen as web_GUI_pulse_gen
import src.data_processing as data_processing
import src.all_of_the_parameters as all_of_the_parameters
import ipywidgets as widgets
import threading
import math
import matplotlib.pyplot as plt
import warnings
from scipy.fftpack import fft, ifft
from scipy.optimize import OptimizeWarning
from scipy.optimize import curve_fit
from pynq import MMIO
import pandas as pd
import os


"""
GUI Size
"""
screen_width = all_of_the_parameters.screen_width
screen_height = all_of_the_parameters.screen_height


"""
Warning dealing
"""
np.seterr(invalid="ignore")


"""
Parameter Setting
"""
point_number_on_screen = all_of_the_parameters.point_number_on_screen
plot_interval = all_of_the_parameters.plot_interval
Nr_Ana_Ch = all_of_the_parameters.Nr_Ana_Ch
Nr_Dig_Ch = all_of_the_parameters.Nr_Dig_Ch
Nr_Ana_Mem = all_of_the_parameters.Nr_Ana_Mem
Nr_Dig_Mem = all_of_the_parameters.Nr_Dig_Mem
Dep_Mem = all_of_the_parameters.Dep_Mem
sampling_time = all_of_the_parameters.sampling_time
conf_dict = all_of_the_parameters.conf_dict
sys_clk_freq = all_of_the_parameters.sys_clk_freq
adc_sampling_bit = all_of_the_parameters.adc_sampling_bit


"""
FPGA initialization
"""
dma_recv = data_processing.dma_recv  # DMA receiver channel
dma_controller_base_address = data_processing.dma.mmio.base_addr
dma_reset_reg = MMIO(dma_controller_base_address + 0x4, 4)
dma_reset_reg.write_mm(0, 1)  # reset DMA

# initialize tracing and chip configure settings
fpga_tracing_func.fpga_tracing_init(web_GUI_config_panel.GUI_set_nr_samples.value)

# delete buffer in case it's already allocated once before to avoid repeated declaration
try:
    del output_buffer_0, output_buffer_1
    # print('Delete old buffer.')
except NameError:
    # print('No old buffer allocated.')
    pass
output_buffer_0 = data_processing.output_buffer_0  # allocate buffers
output_buffer_1 = data_processing.output_buffer_1
mmio = data_processing.mmio
data_processing.mmio_init()  # initialize the config_buffer


"""
Experiment Start Functions
"""
# function status tags
fpga_tracing_func.enable(1)  # enable tracing part
config_fail = 0  # for CPMG sequence, show whether section duration configuration meaningful, 0 successful


# 1. CPMG experiment
def Exp_Start_pg(i, buffer_size):  # single experiment
    global output_buffer_0, output_buffer_1  # to modify global buffer objects

    output_buffer_0.fill(0)  # clear buffer before each experiment

    np.seterr(invalid="ignore")
    mmio.write(conf_dict["conf_nr_sample"], fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]))
    try:
        dma_recv.start()
        dma_recv.transfer(output_buffer_0[0:buffer_size])  # dma transfer in unit byte
    except RuntimeError:
        print("DMA not idle")
        pass
    fpga_tracing_func.terminate_stream_transfer()
    fpga_tracing_func.start_stream_transfer()  # starting stream
    web_GUI_pulse_gen.pg.Exp_Start(1)  # start pulse generator
    try:
        dma_recv.wait()
    except (TimeoutError, RuntimeError) as e:
        pass
    dma_recv.stop()

    output_buffer_1[0:buffer_size] = (i * output_buffer_1[0:buffer_size] + output_buffer_0[0:buffer_size]) / (i + 1)  # calculate average based on result from last step

    points_total = int(buffer_size / 4)  # int32

    # divide data into 2 channels
    Analog0_stream = output_buffer_1[0:points_total:Nr_Ana_Ch]
    Analog1_stream = output_buffer_1[1:points_total:Nr_Ana_Ch]

    filter_type = mmio.read(conf_dict["conf_bandpass_filter"])
    if filter_type != 0:
        try:
            f_low = web_GUI_config_panel.GUI_bandpass_lowFrequency.value * 1000
            f_high = web_GUI_config_panel.GUI_bandpass_highFrequency.value * 1000
            Analog0_stream = data_processing.bandpass_filter(Analog0_stream, f_low, f_high, type=filter_type)
            Analog1_stream = data_processing.bandpass_filter(Analog1_stream, f_low, f_high, type=filter_type)

            # print('filtered!')
        except np.linalg.LinAlgError:
            print("Singular matrix filtered!")
            pass

    # calculate x-axis for time domain signal
    clock_scale = int(100 / web_GUI_config_panel.GUI_Scale.value)
    data_length = len(Analog0_stream)  # length of data stream for n packages(echos)
    # receiver_time_total = data_length / (sys_clk_freq * (10 ** 6) / clock_scale) # total time length for n echos
    receiver_time_total = web_GUI_pulse_gen.pg.t_total / 1000  # in s
    time_stream = np.linspace(0, receiver_time_total, data_length)  # linspace instead of arange

    ch0_plot, ch1_plot, time_stream_sampled = data_processing.func_data_processing_for_plot(time_stream, Analog0_stream, Analog1_stream, buffer_size / (4 * Nr_Ana_Ch))

    func_plot_data(receiver_time_total, time_stream_sampled, ch0_plot, ch1_plot)  # update plots
    if web_GUI_config_panel.GUI_FFT_run_stop.value == True:
        func_T2_fitting(Analog0_stream, Analog1_stream)
    else:
        GUI_plot_FFT.update_traces(visible=False, selector=dict(name="T2"))
        GUI_plot_FFT.update_traces(visible=False, selector=dict(name="T2_fit"))
        GUI_plot_FFT.update_traces(visible=False, selector=dict(name="FFT"))

    return


def Exp_Avg_pg(total_exp_nr=None):  # several experiments and time domain averaging
    if total_exp_nr is None:
        total_exp_nr = web_GUI_pulse_gen.left_text.value
    global output_buffer_0, output_buffer_1, buffer_size

    mmio.write(conf_dict["conf_exp_stop"], 0)  # reset stop flag

    output_buffer_0[:] = 0  # set initial value, no need any more
    output_buffer_1[:] = 0

    config_c(1)

    exp_interval = web_GUI_pulse_gen.left_text9.value
    buffer_size = all_of_the_parameters.Nr_Bytes_per_Ch * all_of_the_parameters.Nr_Ana_Ch * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]) * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"])

    for i in range(total_exp_nr):
        if mmio.read(conf_dict["conf_exp_stop"]) == 0:
            web_GUI_config_panel.prog.value = int((i + 1) / total_exp_nr * 100)
            Exp_Start_pg(i, buffer_size)  # update output buffer 0
            time.sleep(exp_interval)
        else:
            web_GUI_config_panel.prog.value = 100
            break

    return


def thread_of_Exp_Avg_pg(_):  # start a thread for CPMG experiments
    if config_fail == 0:  # first check if configure flag True (0 True)
        thread_Avg_pg = threading.Thread(target=Exp_Avg_pg, name="thread_cpmg")
        print("Create FID thread named: ", thread_Avg_pg.name)
        if check_existing_thread(thread_Avg_pg.name) == False:
            print("No current thread")
            thread_Avg_pg.start()
            # thread_Avg_pg.join()
    else:  # CPMG sequence time requirement(1. receiving time enough, 2. buffer size not exceeded, 3. section duration non-negative)
        pass


# 2. FID experiment
def Exp_Start_pg1(i, buffer_size):  # connect to FID
    # print('debug fid pg1 exp start')

    np.seterr(invalid="ignore")

    global output_buffer_0, output_buffer_1

    output_buffer_0.fill(0)  # clear buffer 0 content before each FID experiment

    mmio.write(conf_dict["conf_nr_sample"], fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]))

    # transfer data from osci through DMA into buffer allocated

    dma_reset_reg.write_mm(0, 1)  # reset DMA

    dma_recv.start()

    dma_recv.transfer(output_buffer_0[0:buffer_size])

    fpga_tracing_func.terminate_stream_transfer()

    fpga_tracing_func.start_stream_transfer()

    web_GUI_pulse_gen.pg_1.Exp_Start(1)

    try:
        dma_recv.wait()
    except (TimeoutError, RuntimeError) as e:
        print("Time out error.")
        pass

    dma_recv.stop()

    fpga_tracing_func.terminate_stream_transfer()

    # get averaged signal

    output_buffer_1[0:buffer_size] = (i * output_buffer_1[0:buffer_size] + output_buffer_0[0:buffer_size]) / (i + 1)  # calculate average based on result from last step

    # divide data into 2 channels
    clock_scale = int(100 / web_GUI_config_panel.GUI_Scale.value)  # GUI_scale is the sampling rate
    points_total = int(buffer_size / 4)  # int32

    Analog0_stream = output_buffer_1[0:points_total:Nr_Ana_Ch]
    Analog1_stream = output_buffer_1[1:points_total:Nr_Ana_Ch]

    filter_type = mmio.read(conf_dict["conf_bandpass_filter"])
    if filter_type != 0:
        try:
            f_low = web_GUI_config_panel.GUI_bandpass_lowFrequency.value * 1000
            f_high = web_GUI_config_panel.GUI_bandpass_highFrequency.value * 1000
            Analog0_stream = data_processing.bandpass_filter(Analog0_stream, f_low, f_high, type=filter_type)
            Analog1_stream = data_processing.bandpass_filter(Analog1_stream, f_low, f_high, type=filter_type)

            # print('filtered!')
        except np.linalg.LinAlgError:
            print("Singular matrix filtered!")
            pass

    data_length = len(Analog0_stream)  # length of data stream for n packages(echos)
    receiver_time_total = data_length / (sys_clk_freq * (10**6) / clock_scale)  # total time length for one channel, one echo for FID

    time_stream = np.linspace(0, receiver_time_total, data_length)  # linspace instead of arange before data sampling and compressing for plot

    ch0_plot, ch1_plot, time_stream_sampled = data_processing.func_data_processing_for_plot(time_stream, Analog0_stream, Analog1_stream, buffer_size / (4 * Nr_Ana_Ch))

    # calculate x-axis for time domain signal

    func_plot_data(receiver_time_total, time_stream_sampled, ch0_plot, ch1_plot)  # update plots
    if web_GUI_config_panel.GUI_FFT_run_stop.value == True:
        func_fft_processing(Analog0_stream, Analog1_stream)
    else:
        GUI_plot_FFT.update_traces(visible=False, selector=dict(name="T2"))
        GUI_plot_FFT.update_traces(visible=False, selector=dict(name="T2_fit"))
        GUI_plot_FFT.update_traces(visible=False, selector=dict(name="FFT"))

    return


def Exp_Avg_pg1(total_exp_nr=None):
    if total_exp_nr is None:
        total_exp_nr = web_GUI_pulse_gen.left_text6.value
    # print('avg exp begins')
    # print('total_exp_nr=', total_exp_nr)

    global output_buffer_0, output_buffer_1, buffer_size

    mmio.write(conf_dict["conf_exp_stop"], 0)  # reset stop flag

    output_buffer_0[:] = 0
    output_buffer_1[:] = 0

    web_GUI_pulse_gen.config_plot_f(1)

    # print('debug 1')

    exp_interval = web_GUI_pulse_gen.left_text9.value
    buffer_size = all_of_the_parameters.Nr_Bytes_per_Ch * all_of_the_parameters.Nr_Ana_Ch * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]) * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"])

    # print('debug 2')

    for i in range(total_exp_nr):
        # print('debug 3')
        if mmio.read(conf_dict["conf_exp_stop"]) == 0:
            # print('fid continue')
            web_GUI_config_panel.prog.value = int((i + 1) / total_exp_nr * 100)
            Exp_Start_pg1(i, buffer_size)  # update output buffer 0
            time.sleep(exp_interval)
        else:
            web_GUI_config_panel.prog.value = 100
            print("force out")
            break

    return


def thread_of_Exp_Avg_pg1(_):  # FID
    thread_Avg_pg1 = threading.Thread(target=Exp_Avg_pg1, name="thread_fid")
    print("Create FID thread named: ", thread_Avg_pg1.name)
    if check_existing_thread(thread_Avg_pg1.name) == False:
        print("No current thread")
        thread_Avg_pg1.start()
    # thread_Avg_pg1.join() # block the current thread until it's finished


# check active thread of same name, for example start a single experiment when the former one still running
def check_existing_thread(thread_name):
    # traverse all threads
    index = 0
    for thread in threading.enumerate():
        # print(type(thread.name))
        index += 1
        # print("Current thread's name is:", thread.name)
        # print('\n')
        if thread.name == thread_name:
            if thread.is_alive():
                print("Current thread still in process!")
                # thread.join() # block the thread until it's done
                return True
            else:
                thread.stop()
                print("Current thread finished!")
    return False


"""
CPMG Experiment parameter configuration
"""


def config_c(_):
    # rx pulse duration should be longer than the time to transfer the points in a package
    # section duration should not be zero or negative
    # points * echo_nr * 16 should not exceed the length of output_buffer
    global config_fail

    config_fail = 0  # if fail, this flag equal to 1

    web_GUI_pulse_gen.config_plot_c(1)

    clock_scale = int(100 / web_GUI_config_panel.GUI_Scale.value)
    fre_sys = sys_clk_freq * (10**6)
    points_nr = fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"])

    pulse_delay = web_GUI_pulse_gen.left_text2.value * (10**-6)
    P_180 = web_GUI_pulse_gen.right_text5.value * (10**-6)
    t_echo = web_GUI_pulse_gen.left_text1.value * (10**-6)
    P_90 = web_GUI_pulse_gen.right_text1.value * (10**-6)
    P_RX = web_GUI_pulse_gen.right_text2.value * (10**-6)
    t0 = (t_echo - P_90 - P_180) / 2 - pulse_delay
    t1 = (t_echo - P_RX - P_180) / 2 - pulse_delay * 2

    t_package = pulse_delay + P_180 + pulse_delay + t1 + pulse_delay + P_RX + pulse_delay + t1

    rest_time = points_nr / (fre_sys / clock_scale) - t_package

    if (rest_time < 0) and (web_GUI_pulse_gen.tag_neg_duration == False) and (fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]) * 16 * pg.No_echos < len(output_buffer_1)):
        pass
    else:
        f_main.layout.title = r"CPMG configuration failed(neg duration or dma not idle)! Please reconfigure."
        config_fail = 1


"""
Stop experiment
"""


def nmr_stop(_):  # terminate the experiment
    print("stop button clicked.")
    mmio.write(conf_dict["conf_exp_stop"], 1)


"""
Connect widget buttons with functions
"""


def Connect_c():  # connect
    web_GUI_pulse_gen.make_box()
    web_GUI_pulse_gen.b_config_c.on_click(config_c)  # intText to Object, then to IP core
    web_GUI_pulse_gen.b_start_c.on_click(thread_of_Exp_Avg_pg)
    web_GUI_pulse_gen.b_stop_c.on_click(nmr_stop)
    web_GUI_pulse_gen.b_config_f.on_click(web_GUI_pulse_gen.config_plot_f)  # intText to Object, then to IP core
    web_GUI_pulse_gen.b_start_f.on_click(thread_of_Exp_Avg_pg1)
    web_GUI_pulse_gen.b_stop_f.on_click(nmr_stop)


"""
Create and merge GUI widgets
"""
# GUI_header
GUI_head = web_GUI_config_panel.GUI_head(web_GUI_config_panel.GUI_logo, web_GUI_config_panel.GUI_logo_iis)

# GUI for NMR_CHIP_CFG
GUI_chip_cfg_box = web_GUI_config_panel.GUI_chip_cfg_box

# Pulse_Gen
Pulse_Gen_Total = widgets.VBox(
    #    children = (web_GUI_pulse_gen.sequence_choice_menu_frame,web_GUI_pulse_gen.output_class),
    children=(web_GUI_pulse_gen.output_class,),
    layout=widgets.Layout(
        height="265px",
        width=str(screen_width) + "px",
    ),
)

GUI_pulse_gen = Pulse_Gen_Total
pg, pg1, f_main = web_GUI_pulse_gen.Object_Create(fpga_tracing_func.pulse_gen)  # create instantiation of class
Connect_c()  # function to connect button with the plot function
web_GUI_pulse_gen.sequence_choice_menu.value = "FID"

# GUI_tracing
GUI_tracing = web_GUI_config_panel.GUI_tracing(web_GUI_config_panel.GUI_onoff, web_GUI_config_panel.GUI_bandpass, web_GUI_config_panel.GUI_zoom1, web_GUI_config_panel.GUI_FFT, web_GUI_config_panel.GUI_save)

GUI_config_total = web_GUI_config_panel.GUI_total(GUI_head, GUI_chip_cfg_box, GUI_pulse_gen, GUI_tracing)
web_GUI_config_panel.GUI_prop_init()

"""
Plot Graphic
"""

GUI_plot = web_GUI_config_panel.GUI_plot()
GUI_plot_FFT = web_GUI_config_panel.GUI_plot_FFT()
GUI_plot_total = widgets.HBox(
    [
        GUI_plot,
        GUI_plot_FFT,
    ],
    layout=widgets.Layout(height=str(round(0.3426 * screen_height)) + "px", width=str(round(0.676 * screen_width)) + "px", border="solid 4px cyan", margin="0px 5px 0px 5px", padding="0px 0px 0px 0px"),
    align_items="center",
)


"""
display GUI
"""

GUI_total = widgets.VBox(
    [GUI_config_total, GUI_plot_total],
    layout=widgets.Layout(height="100%", width="100%"),
)

display(GUI_total)


"""
system function loop
"""


def func_system_cycle():  # give all the 2 ** 15 samples out
    warnings.filterwarnings("ignore", message="Setting frequency to the closest possible value")  # ignore frequency warning

    # parameter loading
    trigger = web_GUI_config_panel.GUI_TBtn_arm.value

    if dma_recv.idle == True:
        buffer_size = all_of_the_parameters.Nr_Bytes_per_Ch * all_of_the_parameters.Nr_Ana_Ch * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]) * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"])
        mmio.write(conf_dict["conf_nr_sample"], fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]))
        Analog0_stream, Analog1_stream, Analog2_stream, Analog3_stream = data_processing.func_update_data(fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"]), buffer_size)
        thread_fft = threading.Thread(target=func_fft_processing, args=(Analog0_stream, Analog1_stream))
        thread_fft.start()

        if trigger == 1:  # 0 = not triggered, 1 = triggered
            web_GUI_config_panel.GUI_TBtn_run_stop.value = False
            web_GUI_config_panel.GUI_TBtn_run_stop.description = "Single"
            web_GUI_config_panel.GUI_TBtn_run_stop.button_style = "warning"
        else:
            web_GUI_config_panel.GUI_TBtn_run_stop.description = "Run/Stop"

        ch0_plot, ch1_plot = data_processing.func_data_processing_for_plot(Analog0_stream, Analog1_stream, all_of_the_parameters.plot_interval)
        try:
            func_plot_data(x_axis_range, time_stream, ch0_plot, ch1_plot)
        except Exception as e:
            pass
        thread_fft.join()
    else:
        pass
    time.sleep(0.05)

    return Analog0_stream, Analog1_stream


def thread_of_plot_data():
    global output_buffer_0, output_buffer_1

    while True:
        warnings.filterwarnings("ignore", message="Setting frequency to the closest possible value")  # ignore frequency warning

        # print('test thread plot data')

        trigger = web_GUI_config_panel.GUI_TBtn_arm.value
        if mmio.read(conf_dict["conf_onoff"]) == 1:
            if mmio.read(conf_dict["conf_token"]) == 0:
                Analog0_stream, Analog1_stream = func_system_cycle()
            else:
                data_processing.func_update_config_tracing()
                Analog0_stream, Analog1_stream = func_system_cycle()
            web_GUI_config_panel.GUI_save_button.disabled = False
            if trigger == 1:  # 0 = not triggered, 1 = triggered
                web_GUI_config_panel.GUI_TBtn_run_stop.value = False
        else:
            # time.sleep(0.1)
            pass
        if mmio.read(conf_dict["conf_save_file"]) == 1:
            buffer_size = all_of_the_parameters.Nr_Ana_Ch * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]) * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"])
            try:
                data_processing.func_save_file(output_buffer_1[0:buffer_size:Nr_Ana_Ch], output_buffer_1[1:buffer_size:Nr_Ana_Ch])
            except (UnboundLocalError, NameError):
                print("Error when saving file.")
                pass
        mmio.write(conf_dict["conf_save_file"], 0)
    return


buffer_size = all_of_the_parameters.Nr_Ana_Ch * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]) * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"])
Thread_plot = threading.Thread(target=thread_of_plot_data)
Thread_plot.start()


"""
plot functions
"""


def find_maxAmp(data0, data1):  # function for acquiring maximum peak-to-peak amplitude within one echo, I-Q channels
    # remove DC
    mean = np.mean(data0)
    data0 = np.subtract(data0, mean.astype(np.int32))
    mean = np.mean(data1)
    data1 = np.subtract(data1, mean.astype(np.int32))

    # calculate A for each element
    A = np.sqrt(np.square(data0) + np.square(data1))

    # return max A in an echo
    maxAmp = max(A[10:])
    maxIndex = np.argmax(A)
    return maxAmp, maxIndex


def func(t, T2):  # T2 relaxation fitting paradigm
    return np.exp(-t / T2)


def func_T2_fitting(Analog0_stream, Analog1_stream):  # for CPMG T2 relaxation
    # neglect optimizaWarning from scipy
    warnings.simplefilter("ignore", OptimizeWarning)

    GUI_plot_FFT.update_annotations(visible=True)  # show annotation
    points_per_pkg = fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"])
    nr_rx = fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"])

    # preprocessing
    fft_ch = mmio.read(conf_dict["conf_fft_ch"])
    fft_onoff = mmio.read(conf_dict["conf_fft_onoff"])
    data0 = Analog0_stream  # channel 2 and channel 3 from ADC
    data1 = Analog1_stream

    # processing
    if nr_rx < 3:  # difficult for plot
        return

    if fft_onoff == 1:  # T2 relaxometry on
        max_vec = []  # to store maximum amplitude in each echo
        max_time = []  # to store index of maximum amplitude in each echo
        for i in range(0, nr_rx):
            in_data0 = data0[0 + i * points_per_pkg : (i + 1) * points_per_pkg - 1]
            in_data1 = data1[0 + i * points_per_pkg : (i + 1) * points_per_pkg - 1]
            max_echo_amp, max_echo_index = find_maxAmp(in_data0, in_data1)
            max_vec.append(max_echo_amp)
            index_time = (i + (max_echo_index / points_per_pkg)) * pg.t_echo / 10**8  # echo time as interval between echos plus relative time
            max_time.append(index_time)

        xdata = max_time
        ydata = max_vec / max(max_vec)  # y-axis normalization
        # neglect optimizaWarning from scipy
        warnings.simplefilter("ignore", OptimizeWarning)
        try:  # try fitting
            popt, pcov = curve_fit(func, xdata, ydata)
        except ValueError:
            # if NaN or Inf, pass
            print("Value Error!")
            return
        else:  # if try successful and no error happened
            # print(popt)
            pass

        GUI_plot_FFT.update_xaxes(title_text="Time(s)")
        GUI_plot_FFT.update_xaxes(range=[0, max(xdata)])
        GUI_plot_FFT.update_yaxes(range=[-0.1, 1.1])
        GUI_plot_FFT.update_traces(visible=False, selector=dict(name="FFT"))
        y_fit = func(np.array(xdata), *popt)
        y_fit = np.array(y_fit)
        GUI_plot_FFT.update_traces(x=xdata, y=y_fit, visible=True, selector=({"name": "T2_fit"}))
        GUI_plot_FFT.update_traces(x=xdata, y=ydata, visible=True, selector=({"name": "T2"}))

        x_annotation = max(xdata) * 2 / 3
        new_annotation = dict(text="T2 = %.4f" % popt[0], x=x_annotation, y=0.95)
        GUI_plot_FFT.update_layout(annotations=[dict(xref="x", yref="y", showarrow=False, **new_annotation)])

    return


def func_fft_processing(Analog0_stream, Analog1_stream):  # for FID
    # preprocessing
    fft_ch = mmio.read(conf_dict["conf_fft_ch"])
    fft_onoff = mmio.read(conf_dict["conf_fft_onoff"])
    data = [0]

    if fft_ch == 0 and fft_onoff == 1:  # onoff为FFT_RUNSTOP按钮，ch为选择菜单
        data = Analog0_stream

    elif fft_ch == 1 and fft_onoff == 1:
        data = Analog1_stream

    # preprocessing: get rid of DC component
    mean = np.mean(data)
    data = np.subtract(data, mean.astype(np.int32))

    # fast fourier transformation
    fft_y = fft(data)

    abs_y = np.abs(fft_y)  # choose the abs from complex number, Bilateral spectrum
    max_amplitude = max(abs_y)
    normalization_y = abs_y / max_amplitude  # Normalization process (bilateral spectrum)
    normalization_half_y = normalization_y[range(int(len(data) / 2))]  # Due to symmetry, only half of the interval (one-sided spectrum) is taken

    func_plot_FFT(normalization_half_y)

    return


def func_plot_FFT(input_data):
    GUI_plot_FFT.layout.yaxis.range = [0, 1]
    GUI_plot_FFT.update_xaxes(title_text="Frequency(Hz)")
    try:
        GUI_plot_FFT.update_traces(visible=False, selector=dict(name="T2"))
    except (TypeError, ValueError, KeyError) as e:
        pass
    GUI_plot_FFT.update_traces(visible=False, selector=dict(name="T2_fit"))
    GUI_plot_FFT.update_annotations(visible=False)

    clock_scale = int(100 / web_GUI_config_panel.GUI_Scale.value)
    data_length = fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"])
    fs = sys_clk_freq * (10**6) / clock_scale  # sampling rate after CIC
    receiver_time_total = data_length / fs

    N = len(input_data) * 2  # length of input data
    try:
        f_fft = np.arange(0, N) * (fs / N)  # x-axis of Fourier Spectrum
    except ZeroDivisionError:
        print("An ZeroDivision Error occurred.")
        return
    except:
        print("An other error occurred.")
        return
    GUI_plot_FFT.update_traces(x=f_fft, y=input_data, visible=True, selector=({"name": "FFT"}))
    # GUI_plot_FFT.update_xaxes(range=[0, f_fft[-1]])

    # calculate linewidth and show annotation on frequency spectrum
    if web_GUI_config_panel.GUI_Exp_loop.value == True:
        nmr_linewidth = data_processing.calculate_nmr_linewidth(f_fft, input_data)
        x_annotation = 1e5
        new_annotation = dict(text="linewidth = %d Hz" % nmr_linewidth, x=x_annotation, y=0.95)
        GUI_plot_FFT.update_layout(annotations=[dict(xref="x", yref="y", showarrow=False, **new_annotation)])
        GUI_plot_FFT.update_annotations(visible=True)
    else:
        GUI_plot_FFT.update_annotations(visible=False)

    return


def func_plot_data(x_axis_range, time_stream, ch0, ch1):
    GUI_plot.update_layout(xaxis_range=[0, x_axis_range])  # update x-axis range first

    code_adc = 5.11 / (2**adc_sampling_bit) * 1000  # digital value to mV

    ch0_volts = ch0 * code_adc
    ch1_volts = ch1 * code_adc

    GUI_plot.update_traces(x=time_stream, y=ch0_volts, selector=({"name": "Channel 0"}))
    GUI_plot.update_traces(x=time_stream, y=ch1_volts, selector=({"name": "Channel 1"}))

    return


"""
Automatic experiment and data collection
"""


def auto_collect_data():
    num_exp = int(input("Number of experiments: "))  # modify experiment number here
    material_name = input("Material name: ")  # modify material name here
    time_between_exp = int(input("Time between experiments: "))  # time interval between two consecutive experiments
    c_for_convert_a = all_of_the_parameters.c_for_convert_a  # ADC plot converting code

    for i in range(num_exp):
        thread_of_Exp_Avg_pg1(0)  # thread_of_Exp_Avg_pg1(_) # experiment parameters should be adjusted in GUI
        time.sleep(time_between_exp)  # wait for signal generation
        buffer_size = all_of_the_parameters.Nr_Ana_Ch * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_NR_SAMPLES_CMD"]) * fpga_tracing_func.osci.read(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"])
        file_name = material_name + str(i)
        data_processing.func_save_file_for_automatic_collection(output_buffer_1[0:buffer_size:Nr_Ana_Ch], output_buffer_1[1:buffer_size:Nr_Ana_Ch], file_name)


"""
Automatic experiment loop (FID or CPMG)
"""


def fid_loop():
    while not mmio.read(conf_dict["conf_loop_stop"]):  # loop on
        Exp_Avg_pg1(1)
        # time.sleep(0.1)


def cpmg_loop():
    while not mmio.read(conf_dict["conf_loop_stop"]):  # loop on
        Exp_Avg_pg(1)  # once each time
        # time.sleep(0.1)


def exp_loop(change):
    if not mmio.read(conf_dict["conf_loop_stop"]):  # flag = 0, loop running
        if web_GUI_pulse_gen.sequence_choice_menu.value == "FID":  # detect whether CPMG or FID to loop
            thread_fid_loop = threading.Thread(target=fid_loop)  # create new thread for FID loop
            thread_fid_loop.start()
        elif web_GUI_pulse_gen.sequence_choice_menu.value == "CPMG":
            thread_cpmg_loop = threading.Thread(target=cpmg_loop)  # create new thread for CPMG loop
            thread_cpmg_loop.start()


web_GUI_config_panel.GUI_Exp_loop.observe(exp_loop, "value")  # connect click button action to experiment loop
