# ----------------------------------------------------------------------------------
# -- Company: University of Stuttgart (IIS)
# -- Engineer: Yichao Peng
# --
# -- Description:
# -- This python file include all the widgets used in the GUI for pulse_gen module

# -- log: last modification:
# -- -- 20230304 add average function
# -- -- 20230316 modify Ipad GUI
# -- -- 20230411 fix not idle bug
# ----------------------------------------------------------------------------------

import threading
import time
import plotly.graph_objects as go
import numpy as np
import ipywidgets as widgets
import src.all_of_the_parameters as all_of_the_parameters
import src.data_processing as data_processing
import src.fpga_tracing_func as fpga_tracing_func
import src.web_GUI_config_panel as web_GUI_config_panel
import json

from IPython.display import display

dma_recv = data_processing.dma_recv
GUI_plot = web_GUI_config_panel.GUI_plot()
conf_dict = all_of_the_parameters.conf_dict
mmio = data_processing.mmio
osci = fpga_tracing_func.osci

screen_width = all_of_the_parameters.screen_width  # original: 1920px
screen_height = all_of_the_parameters.screen_height

# -------------- 1. Register command address: type integer, object constant -----------------

# dictionary for pulse gen fpga controlling
pulse_gen_dict = all_of_the_parameters.pulse_gen_dict

# -------------- 2. GUI Elements and Display Function -----------------

# --- Textbox for user inputs: CPMG ---
# Experiment number
left_text = widgets.IntText(value=1, description="# Exp.:", layout=widgets.Layout(width=str(round(0.0573 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.026 * screen_width)) + "px"})
# Echo number
right_text = widgets.IntText(value=40, description="# Echo:", layout=widgets.Layout(width=str(round(0.0573 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.026 * screen_width)) + "px"})
# Echo time
left_text1 = widgets.IntText(value=2000, description="TE (us):", layout=widgets.Layout(width=str(round(0.0677 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.026 * screen_width)) + "px"})
# 90 deg TX pulse length
right_text1 = widgets.FloatText(value=20.0, description="P90 (us):", layout=widgets.Layout(width=str(round(0.0625 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.03125 * screen_width)) + "px"})
# Pulse delay # original 0.0625 / 0.03125
left_text2 = widgets.IntText(value=4, description="Pulse Delay (us):", layout=widgets.Layout(width=str(round(0.08854 * screen_width)) + "px", height="24px"), min=1, style={"description_width": str(round(0.0625 * screen_width)) + "px"})
# Acquisition length
right_text2 = widgets.IntText(value=200, description="Len_acqui (us):", layout=widgets.Layout(width=str(round(0.09375 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.0573 * screen_width)) + "px"})
# Excitation frequency
left_text3 = widgets.IntText(value=1530000, description="f_tx (Hz):", layout=widgets.Layout(width=str(round(0.078125 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.03125 * screen_width)) + "px"})
# Receiver frequency
right_text3 = widgets.IntText(value=1530000, description="f_rx (Hz):", layout=widgets.Layout(width=str(round(0.078125 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.03125 * screen_width)) + "px"})
# Phase offset value for CPMG
left_text5 = widgets.IntText(value=0, description="Off_phase (deg):", layout=widgets.Layout(width=str(round(0.09375 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.0625 * screen_width)) + "px"})
# 180 deg TX pulse length
right_text5 = widgets.FloatText(value=480.0, description="P180 (us):", layout=widgets.Layout(width=str(round(0.07292 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.041667 * screen_width)) + "px"})


# --- Textbox for user inputs: FID ---

# Experiment number
left_text6 = widgets.IntText(value=1, description="Exp.:", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.026 * screen_width)) + "px"})
# 90 deg TX pulse length
right_text6 = widgets.FloatText(value=20.0, description="P90 (us):", layout=widgets.Layout(width=str(round(0.0573 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.03125 * screen_width)) + "px"})
# Dead time
left_text7 = widgets.IntText(value=5, description="Dead Time :", layout=widgets.Layout(width=str(round(0.07292 * screen_width)) + "px", height="24px"), min=1, style={"description_width": str(round(0.046875 * screen_width)) + "px"})  # us
# Acquisition length
right_text7 = widgets.IntText(value=50000, description="Len_acqui :", layout=widgets.Layout(width=str(round(0.08333 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.046875 * screen_width)) + "px"})  # us
# TX reference frequency, change with temperature
left_text8 = widgets.IntText(value=3000000, description="f_tx (Hz):", layout=widgets.Layout(width=str(round(0.078125 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.03125 * screen_width)) + "px"})
# RX reference frequency
right_text8 = widgets.IntText(value=3000000, description="f_rx (Hz):", layout=widgets.Layout(width=str(round(0.078125 * screen_width)) + "px", height="24px"), style={"description_width": str(round(0.03125 * screen_width)) + "px"})
# sinterval between experiments
left_text9 = widgets.IntText(value=1, description="pause (s):", layout=widgets.Layout(width=str(round(0.07292 * screen_width)) + "px", height="24px"), min=0, max=10, allow_out_of_range=False, style={"description_width": str(round(0.041667 * screen_width)) + "px"})  # original 0.07292 / 0.041667

# --------------- Start Button ---------------

# To trigger the experiment
b_start_c = widgets.Button(  # cpmg
    description="Start", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px")
)
b_start_f = widgets.Button(  # fid
    description="Start", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px")
)
b_start_a = widgets.Button(  # arbitrary
    description="Start", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px")
)

# --------------- Stop Button ----------------

# To terminate the experiment
b_stop_c = widgets.Button(description="Stop", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px"))
b_stop_f = widgets.Button(description="Stop", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px"))
b_stop_a = widgets.Button(description="Stop", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px"))

# --------------- Configure Button ----------------

# To read parameter from textboxs and write into the IP core
b_config_c = widgets.Button(description="Configure", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px"))
b_config_f = widgets.Button(description="Configure", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px"))
b_config_a = widgets.Button(description="Configure", button_style="warning", layout=widgets.Layout(width=str(round(0.0521 * screen_width)) + "px", height="28px"))

# --------------- Average Button ----------------

# To perform time domain averaging according to experiment repitition number
# currently not in use, automatic average
# b_avg_c = widgets.Button(
#    description = 'Average',
#    button_style = 'warning',
#    layout = widgets.Layout(width='100px', height='28px')
# )
# b_avg_f = widgets.Button(
#    description = 'Average',
#    button_style = 'warning',
#    layout = widgets.Layout(width='100px', height='28px')
# )
# b_avg_a = widgets.Button(
#    description = 'Average',
#    button_style = 'warning',
#    layout = widgets.Layout(width='100px', height='28px')
# )

# --------------- Blank text area ----------------

# blank_block = widgets.Label(value='  ',layout=widgets.Layout(width='20px', height='24px'))

# --------------- Pull-down Menu to Select ----------------

sequence_choice_menu = widgets.Dropdown(
    options=["User Defined", "FID", "CPMG"],
    description="Choose Sequence Type:",
    layout=widgets.Layout(width=str(round(0.1448 * screen_width)) + "px", height="24px"),  #  'max-content' to fit max length of content
    style={"description_width": "143px"},
)
sequence_choice_menu_frame = widgets.HBox(
    children=(sequence_choice_menu,),  # a = 'sdf', returns a tuple, a = 'sdf' returns a string
    layout=widgets.Layout(
        height="38px",
        width=str(round(0.15625 * screen_width)) + "px",
        border="solid 4px yellow",
        # margin='5px 5px 0px 5px',
        padding="0px 0px 0px 0px",
    ),
    align_items="flex-start",
)

# --------------- Setting number of rx pulses according to select menu (cpmg-echo, fid-1) ----------------


def on_value_change_nr_rx(change):
    mmio.write(conf_dict["conf_token"], 1)
    if sequence_choice_menu.value == "CPMG":
        mmio.write(conf_dict["conf_nr_rx_pulse"], change["new"])
        osci.write(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"], change["new"])
    else:
        mmio.write(conf_dict["conf_nr_rx_pulse"], 1)
        osci.write(all_of_the_parameters.fpga_func_dict["C_SET_STREAM_NR_RX_PULSE"], 1)
    return


right_text.observe(on_value_change_nr_rx, names="value")

# --------------- Combination for Different Sequences ----------------

# CPMG combination
a0_c = widgets.HBox(
    children=(
        right_text3,
        left_text5,
        right_text5,
        left_text9,
    ),
    layout=widgets.Layout(height="40px", width=str(round(0.33854 * screen_width)) + "px", border="solid 4px yellow", margin="0px 5px 0px 0px", padding="0px 0px 0px 0px"),
)

a00_c = widgets.HBox(
    children=(
        sequence_choice_menu,
        left_text,
        right_text,
        left_text1,
        right_text1,
        left_text2,
        right_text2,
        left_text3,
    ),
    layout=widgets.Layout(
        height="40px",
        width=str(round(0.67604 * screen_width)) + "px",
        # width=str(round(0.69604*screen_width))+'px',
        border="solid 4px yellow",
        margin="0px 5px 0px 0px",
        padding="0px 0px 0px 0px",
    ),
)

a1_c = widgets.HBox(
    children=(b_config_c, b_start_c, b_stop_c),
    layout=widgets.Layout(height="40px", width=str(round(0.15625 * screen_width)) + "px", border="solid 4px yellow", margin="0px 5px 0px 0px", padding="0px 0px 0px 0px"),
)

a2_c = widgets.HBox(
    children=(a1_c, a0_c),
    layout=widgets.Layout(height="40px", width="auto"),
)

a3_c = widgets.VBox(
    children=(a00_c, a2_c),
)


# FID combination

a0_f = widgets.HBox(
    children=(left_text6, right_text6, left_text7, right_text7, left_text8, right_text8, left_text9),
    layout=widgets.Layout(
        height="40px",
        width=str(round(0.51667 * screen_width)) + "px",
        # width=str(round(0.52067*screen_width))+'px',
        border="solid 4px yellow",
        margin="0px 5px 0px 0px",
        padding="0px 0px 0px 0px",
    ),
)
a1_f = widgets.HBox(
    children=(b_config_f, b_start_f, b_stop_f),
    layout=widgets.Layout(
        height="40px",
        width=str(round(0.15625 * screen_width)) + "px",
        border="solid 4px yellow",
        # margin='0px 5px 0px 0px',
        margin="0px 0px 0px 0px",
        padding="0px 0px 0px 0px",
    ),
)
########################################################
## under construction and test
# conf_f = widgets.HBox(
#     children = (sequence_choice_menu_frame, web_GUI_config_panel.config_boxes),
#     layout = widgets.Layout(height='40px', width='auto'),
# )
conf_f = widgets.HBox(
    children=(sequence_choice_menu_frame, web_GUI_config_panel.pll_boxes),
    layout=widgets.Layout(height="40px", width="auto"),
)

spi_f = widgets.HBox(
    children=(web_GUI_config_panel.config_boxes,),
    layout=widgets.Layout(height="40px", width="auto"),
)
############################################


a2_f = widgets.HBox(
    children=(a1_f, a0_f),
    layout=widgets.Layout(height="40px", width="auto"),
)

w_A = widgets.HBox(
    children=(b_config_a, b_start_a, b_stop_a),
    layout=widgets.Layout(height="40px", width=str(round(0.15625 * screen_width)) + "px", border="solid 4px yellow", margin="0px 5px 0px 0px", padding="0px 0px 0px 0px"),
)

f = go.FigureWidget()
f.update_layout(
    autosize=True,
    width=round(0.676042 * screen_width),
    height=130,
    margin=dict(l=10, r=10, b=30, t=30, pad=4),
    xaxis={
        "showgrid": False,  # thin lines in the background
        "zeroline": False,  # thick line at x=0
        "visible": False,  # numbers below
    },
    yaxis={
        "showgrid": False,  # thin lines in the background
        "zeroline": False,  # thick line at x=0
        "visible": False,  # numbers below
    },
    showlegend=False,
)
f_frame = widgets.HBox(
    children=(f,),
    layout=widgets.Layout(height=str(round(0.1204 * screen_height)) + "px", width=str(round(0.676042 * screen_width)) + "px", border="solid 4px yellow", margin="5px 5px 5px 0px", padding="0px 0px 0px 0px"),
)

# create Vboxes


def make_box():
    global w_CPMG
    global w_FID
    global w_ARBITRARY

    w_CPMG = widgets.VBox(
        children=(a3_c, f_frame),
    )
    ###############################################
    #     w_FID = widgets.VBox(
    #         children = (conf_f,a2_f, spi_f ,f_frame),
    #         layout = widgets.Layout(
    #             height='215px',
    #             width=str(screen_width)+'px'
    #         ),
    #     )
    w_FID = widgets.VBox(
        children=(conf_f, a2_f, spi_f, f_frame),
        layout=widgets.Layout(height="265px", width=str(screen_width) + "px"),
    )
    ###############################################

    w_ARBITRARY = widgets.VBox(
        children=(sequence_choice_menu_frame, w_A, f_frame),
    )


# --------------- Display Functions ----------------


def choiceS(arg):
    output_class.clear_output()
    with output_class:
        if arg.new == "User Defined":
            display(w_ARBITRARY)
        elif arg.new == "CPMG":
            display(w_CPMG)
            # change button description
            web_GUI_config_panel.GUI_FFT_run_stop.description = "T2 Relaxation"
        elif arg.new == "FID":
            # change button description
            web_GUI_config_panel.GUI_FFT_run_stop.description = "FFT Run/Stop"
            display(w_FID)


sequence_choice_menu.observe(choiceS, names="value")
output_class = widgets.Output()

# -------------- 3. Pulse Generator Classes -----------------

#  This chapter uses class and instantiations to connect input text boxes and IP core on FPGA

sys_clk_freq = all_of_the_parameters.sys_clk_freq  # 100MHz
dds_clk_freq = all_of_the_parameters.dds_clk_freq  # 250MHz
phase_width = all_of_the_parameters.phase_width

# tag for warning for negtive section duration

tag_neg_duration = False  # if True then warning

# --- Class Definition for CPMG ---


class PulseGen_CPMG:
    def __init__(self, IP, No_scans, No_echos, t_echo, P_90, pulse_delay, P_RX, f_TX, f_RX, phase_offset, P_180):
        # order according to the text boxes
        self.IP = IP

        # cpmg parameters in unit us
        self.t = sys_clk_freq  # 1 unit correspond to (1/f) us => 1 us -- 250 unit with f = 250 MHz
        self.t_echo = t_echo * self.t  # echo time
        self.P_90 = int(P_90 * self.t)  # 90 deg pulse length
        self.P_180 = int(P_180 * self.t)  # 180 deg pulse length (need not be double P_90!)
        self.P_RX = P_RX * self.t  # acquisition time
        self.No_scans = No_scans  # number of experiments
        self.No_echos = No_echos  # number of echos
        self.f_TX = int(f_TX * (2**phase_width) / 1e6 / dds_clk_freq)  # excitation frequency Hz, phase_width = 32
        self.f_RX = int(f_RX * (2**phase_width) / 1e6 / dds_clk_freq)  # receiver frequency Hz, phase_width = 32
        self.pulse_delay = pulse_delay * self.t

        # adjust phase offset according to PLL ratio
        option = web_GUI_config_panel.GUI_chip_cfg_pll_mult.value
        if option == 0:
            pll_divider = 64
        elif option == 1:
            pll_divider = 32
        elif option == 2:
            pll_divider = 16
        elif option == 3:
            pll_divider = 8
        elif option == 4:
            pll_divider = 4
        elif option == 5:
            pll_divider = 2
        elif option == 6:
            pll_divider = 1
        elif option == 8:
            pll_divider = 0.5
        else:
            pll_divider = 1
        self.phase_offset = phase_offset * 11930465 / pll_divider

        # parameters below don't change, system structure
        self.start_pointer = 4
        self.end_pointer = 11
        self.section_nr = 13
        self.phase_width = phase_width  # DDS phase width default = 32 bits, see Vivado environment DDS Compiler Configuration

        # store length sequence for plotting use, with initial value
        self.t_total = 0  # calculate whole experiment duration after configuration
        self.cpmg_len = [25000, 25000, 4500, 142250, 1000, 9000, 1000, 43500, 1000, 200000, 1000, 43500, 25000]
        self.cpmg_p0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    def Exp_Config(self):
        # for experiment parameter configuration

        self.IP.write(pulse_gen_dict["C_SET_NR_SECTIONS"], int(self.section_nr))  # 0-12 for CPMG
        self.IP.write(pulse_gen_dict["C_SET_START_REPEAT_POINTER"], int(self.start_pointer))
        self.IP.write(pulse_gen_dict["C_SET_END_REPEAT_POINTER"], int(self.end_pointer))
        self.IP.write(pulse_gen_dict["C_SET_CYCLE_REPETITION_NUMBER"], int(self.No_echos))
        # self.IP.write(pulse_gen_dict['C_SET_EXPERIMENT_REPETITION_NUMBER'],int(self.No_scans))
        self.IP.write(pulse_gen_dict["C_SET_EXPERIMENT_REPETITION_NUMBER"], 1)  # let repitition in PL != 1

    def Sec_Config_Basic(self, sec, s_type, delay, mux, p0, f0, p1, f1, rstn):
        # for each section's configuration
        # choose section to configure
        self.IP.write(pulse_gen_dict["C_SEL_SECTION"], sec)
        # define section type
        self.IP.write(pulse_gen_dict["C_SET_SECTION_TYPE"], s_type)
        # define delay duration
        self.IP.write(pulse_gen_dict["C_SET_DELAY"], delay)
        # define multiplexer type
        self.IP.write(pulse_gen_dict["C_SET_MUX"], mux)
        # DDS channel 0 phase
        self.IP.write(pulse_gen_dict["C_SET_PHASE_CH0"], p0)
        # DDS channel 0 frequency
        self.IP.write(pulse_gen_dict["C_SET_FREQUENCY_CH0"], f0)
        # DDS channel 1 phase
        self.IP.write(pulse_gen_dict["C_SET_PHASE_CH1"], p1)
        # DDS channel 1 frequency
        self.IP.write(pulse_gen_dict["C_SET_FREQUENCY_CH1"], f1)
        # resetn for each section
        self.IP.write(pulse_gen_dict["C_SET_RESETN_DDS"], rstn)

    def Sec_Config_CPMG(self, _):
        # add a non-use parameter b to avoid strange problem: type error, takes 1 arguments 2 given
        # update self.parameters from text boxes then write into IP core pulse_gen
        global left_text, right_text, left_text1, right_text1, left_text2, right_text2, left_text3, right_text3, left_text4, right_text4
        global tag_neg_duration

        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 0)

        self.t_echo = left_text1.value * self.t  # echo time
        self.P_90 = int(right_text1.value * self.t)  # 90 deg pulse length
        self.P_180 = int(right_text5.value * self.t)  # 180 deg pulse length (need not be double P_90!)
        self.P_RX = right_text2.value * self.t  # acquisition time
        # self.No_scans = left_text.value           # number of experiments
        self.No_scans = 1  # number of experiments
        self.No_echos = right_text.value  # number of echos
        self.f_TX = int(left_text3.value * 2 * (2**phase_width) / 1e6 / dds_clk_freq)  # excitation frequency, phase_width = 32
        self.f_RX = int(right_text3.value * 2 * (2**phase_width) / 1e6 / dds_clk_freq)  # receiver frequency, phase_width = 32
        self.pulse_delay = left_text2.value * self.t

        # adjust phase offset according to PLL ratio
        option = web_GUI_config_panel.GUI_chip_cfg_pll_mult.value
        if option == 0:
            pll_divider = 64
        elif option == 1:
            pll_divider = 32
        elif option == 2:
            pll_divider = 16
        elif option == 3:
            pll_divider = 8
        elif option == 4:
            pll_divider = 4
        elif option == 5:
            pll_divider = 2
        elif option == 6:
            pll_divider = 1
        elif option == 8:
            pll_divider = 0.5
        else:
            pll_divider = 1
        self.phase_offset = left_text5.value * 11930465 / pll_divider

        # write parameter from Python Object to IP core in FPGA
        f_tx = self.f_TX
        f_rx = self.f_RX
        p = self.phase_offset * 8
        t0 = (self.t_echo - self.P_90 - self.P_180) / 2 - self.pulse_delay
        t1 = (self.t_echo - self.P_RX - self.P_180) / 2 - self.pulse_delay * 2

        if (t0 < 0) or (t1 < 0):  # negative section duration
            tag_neg_duration = True
            f.layout.title = "Warning: CPMG section duration negative! Please adjust parameters again."
        else:
            tag_neg_duration = False

        l_type = [2, 2, 0, 2, 2, 0, 2, 2, 2, 1, 2, 2, 2]
        l_delay = [100 * self.t, 100 * self.t, self.P_90, t0, self.pulse_delay, self.P_180, self.pulse_delay, t1, self.pulse_delay, self.P_RX, self.pulse_delay, t1, 100 * self.t]
        l_mux = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0]
        l_p0 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        l_f1 = [f_tx, f_tx, f_tx, f_tx, f_tx, f_tx, f_tx, f_tx, f_tx, f_tx, f_tx, f_tx, f_tx]
        l_p1 = [0, 0, 0, 0, p, p, p, 0, 0, 0, 0, 0, 0]
        l_f0 = [f_tx, f_tx, f_tx, f_rx, f_rx, f_rx, f_rx, f_rx, f_rx, f_rx, f_rx, f_rx, f_rx]
        # l_rstn  =  [0,0,1,0,0,1,0,0,0,1,0,0,0]
        l_rstn = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        # l_rstn  =  [0,0,0,0,0,0,0,0,0,0,0,0,0] # 0 will clear DDS output

        vals = {
            "f_tx": f_tx,
            "f_tx_gui": left_text3.value,
            "f_rx_gui": right_text3.value,
            "pulse_delay": self.pulse_delay,
            "P_180_gui": right_text5.value,
            "P_180": self.P_180,
            "P_90_gui": right_text1.value,
            "P_90": self.P_90,
            "f_rx": f_rx,
            "t0": t0,
            "t1": t1,
            "pll_divider": pll_divider,
            "self.phase_offset": self.phase_offset,
            "p": p,
            "phase": left_text5.value,
        }

        json.dump(vals, open("config.json", "w"))

        # First: configure IP core: experiment number and cycle number
        self.Exp_Config()
        # Second: configure IP core: echo number
        # already int type, no need to perform the following lines!
        for i in range(0, len(l_delay)):
            l_delay[i] = int(l_delay[i])
            l_p0[i] = int(l_p0[i])
            l_f0[i] = int(l_f0[i])
            l_p1[i] = int(l_p1[i])
            l_f1[i] = int(l_f1[i])
            l_rstn[i] = int(l_rstn[i])
        # calculate total experiment duration
        t_total = sum(l_delay[0 : self.start_pointer]) + self.No_echos * sum(l_delay[self.start_pointer : self.end_pointer + 1]) + sum(l_delay[self.end_pointer + 1 : self.section_nr])
        t_total = self.No_scans * t_total / (self.t * 1000)

        for i in range(0, self.section_nr):
            self.Sec_Config_Basic(i, l_type[i], l_delay[i], l_mux[i], l_p0[i], l_f0[i], l_p1[i], l_f1[i], l_rstn[i])

        self.t_total = t_total  # pass calculated value to instantiation's attribute
        self.cpmg_phase = l_p0
        self.cpmg_len = l_delay

    def Exp_Start(self, _):
        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 0)  # first set enable signal 0 then 1.
        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 1)
        # thread = threading.Thread(target=self.Exp_Trigger_Thread)  # create a new thread for showing without disturbing experiment
        # thread.start()
        # thread.join()

    def Exp_Trigger_Thread(self):
        t_total_s = self.t_total / 1000
        time.sleep(t_total_s)
        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 0)

    def Exp_Stop(self, _):  # to terminate the experiment before it's finished
        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 0)


# --- Class Definition for FID ---


class PulseGen_FID:
    def __init__(self, IP, No_scans, P_90, t_dead, P_RX, f_TX, f_RX):
        self.IP = IP
        # fid parameters in unit us
        self.t = sys_clk_freq  # 1 us -- sys_clk_fre MHz, user should not change!
        self.No_scans = No_scans  # experiment number
        self.No_echos = 1  # echo number, for FID is 1, not change
        self.P_90 = int(P_90 * self.t)  # 90 deg excitation pulse length
        self.dead_time = t_dead * self.t  # dead time between excitation and receiver pulse
        self.P_RX = P_RX * self.t  # acquisition time
        self.f_TX = int(f_TX * (2**phase_width) / 1e6 / dds_clk_freq)  # TX reference frequency
        self.f_RX = int(f_RX * (2**phase_width) / 1e6 / dds_clk_freq)  # RX reference frequency

        # FID section setting, below don't change
        self.phase_width = phase_width  # DDS phase width 32, change in IP core, user should not change!
        self.start_pointer = 1
        self.end_pointer = 4
        self.section_nr = 6
        # to store whole experiment duration after configuration
        self.t_total = 0  # calculate whole experiment duration after configuration
        self.fid_len = [10, 25000, 10, 5000, 5000, 2500000, 25000]
        self.fid_p0 = [0, 0, 0, 0, 0, 0, 0]

    def Exp_Config(self):
        # for experiment parameter configuration
        self.IP.write(pulse_gen_dict["C_SET_NR_SECTIONS"], int(self.section_nr))  # 0-12 for CPMG
        self.IP.write(pulse_gen_dict["C_SET_START_REPEAT_POINTER"], int(self.start_pointer))
        self.IP.write(pulse_gen_dict["C_SET_END_REPEAT_POINTER"], int(self.end_pointer))
        self.IP.write(pulse_gen_dict["C_SET_CYCLE_REPETITION_NUMBER"], int(self.No_echos))
        self.IP.write(pulse_gen_dict["C_SET_EXPERIMENT_REPETITION_NUMBER"], int(self.No_scans))

    def Sec_Config_Basic(self, sec, s_type, delay, mux, p0, f0, p1, f1, rstn):
        # for each section's configuration
        # choose section to configure
        self.IP.write(pulse_gen_dict["C_SEL_SECTION"], sec)
        # define section type
        self.IP.write(pulse_gen_dict["C_SET_SECTION_TYPE"], s_type)
        # define delay duration
        self.IP.write(pulse_gen_dict["C_SET_DELAY"], delay)
        # define multiplexer type
        self.IP.write(pulse_gen_dict["C_SET_MUX"], mux)
        # DDS channel 0 phase
        self.IP.write(pulse_gen_dict["C_SET_PHASE_CH0"], p0)
        # DDS channel 0 frequency
        self.IP.write(pulse_gen_dict["C_SET_FREQUENCY_CH0"], f0)
        # DDS channel 1 phase
        self.IP.write(pulse_gen_dict["C_SET_PHASE_CH1"], p1)
        # DDS channel 1 frequency
        self.IP.write(pulse_gen_dict["C_SET_FREQUENCY_CH1"], f1)
        # resetn for each section
        self.IP.write(pulse_gen_dict["C_SET_RESETN_DDS"], rstn)

    def Sec_Config_FID(self, _):
        # print('test pulse gen sec_config_fid')

        # add a non-use parameter b to avoid strange problem: type error, takes 1 arguments 2 given
        # update self.parameters from sliders
        global left_text6, right_text6, left_text7, right_text7, left_text8, right_text8
        # self.No_scans = left_text6.value        # number of experiments

        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 0)

        self.No_scans = 1  # number of experiments != 1
        self.P_90 = int(right_text6.value * self.t)  # 90 deg pulse length
        self.dead_time = left_text7.value * self.t  # dead time
        self.P_RX = right_text7.value * self.t  # acquisition time
        self.f_TX = int(left_text8.value * 2 * (2**phase_width) / 1e6 / dds_clk_freq)  # excitation frequency
        self.f_RX = int(right_text8.value * 2 * (2**phase_width) / 1e6 / dds_clk_freq)  # receiver frequency

        # write parameter from Python Object to IP core in FPGA
        f_tx = self.f_TX  # TX frequency
        f_rx = self.f_RX  # RX frequency
        p = 0  # 0 offset for FID
        l_type = [2, 2, 0, 2, 1, 2]
        l_delay = [2 * self.t, 2500 * self.t, self.P_90, self.dead_time, self.P_RX, 100 * self.t]
        # l_delay =  [100*self.t, self.P_90, self.dead_time, 2*self.t, self.P_RX, 100*self.t, 100*self.t]
        l_mux = [0, 0, 0, 0, 0, 0]
        # l_mux   =  [1,1,1,1,0,1,1]
        l_p0 = [0, 0, 0, 0, 0, 0]
        l_f1 = [f_tx, f_tx, f_tx, f_tx, f_rx, f_tx]
        l_p1 = [0, 0, 0, 0, 0, 0, 0]
        l_f0 = [f_rx, f_rx, f_rx, f_rx, f_rx, f_rx]
        l_rstn = [1, 1, 1, 1, 1, 1]
        # l_rstn  =  [1,1,1,1,1,1,1]

        # first configure IP core: experiment number and cycle number
        self.Exp_Config()

        # second configure IP core: echo number
        for i in range(0, len(l_delay)):
            l_delay[i] = int(l_delay[i])
            l_p0[i] = int(l_p0[i])
            l_f0[i] = int(l_f0[i])
            l_p1[i] = int(l_p1[i])
            l_f1[i] = int(l_f1[i])
            l_rstn[i] = int(l_rstn[i])

        self.fid_len = l_delay

        t_total = sum(l_delay[0 : self.start_pointer]) + self.No_echos * sum(l_delay[self.start_pointer : self.end_pointer + 1]) + sum(l_delay[self.end_pointer + 1 : self.section_nr])
        t_total = self.No_scans * t_total / (self.t * 1000)

        for i in range(0, self.section_nr):
            self.Sec_Config_Basic(i, l_type[i], l_delay[i], l_mux[i], l_p0[i], l_f0[i], l_p1[i], l_f1[i], l_rstn[i])

        self.t_total = t_total

    def Exp_Start(self, _):
        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 0)  # first set enable signal 0 then 1.
        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 1)

        thread = threading.Thread(target=self.Exp_Trigger_Thread)  # create a new thread for showing without disturbing experiment
        thread.start()
        thread.join()

    def Exp_Trigger_Thread(self):
        t_total_s = self.t_total / 1000
        time.sleep(t_total_s)
        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 0)

    def Exp_Stop(self, b):  # to terminate the experiment before it's finished
        self.IP.write(pulse_gen_dict["C_SEQUENCE_GENERATOR_EN"], 0)


# -------------- 4. Pulse Generator Class Instantiation function and Connect to GUI functions -----------------


def Object_Create(IP):  # creation instantiation and plotly object
    annotation_scale = 1298 / 1680

    global pg  # use global variable

    pg = PulseGen_CPMG(IP, left_text.value, right_text.value, left_text1.value, right_text1.value, left_text2.value, right_text2.value, left_text3.value, right_text3.value, left_text5.value, right_text5.value)
    global pg_1
    pg_1 = PulseGen_FID(IP, left_text6.value, right_text6.value, left_text7.value, right_text7.value, left_text8.value, right_text8.value)
    global y2
    cpmg_len = [250, 250, 45, 1423, 10, 90, 10, 435, 10, 2000, 10, 435, 10]
    cpmg_len = [int(x * annotation_scale) for x in cpmg_len]

    cpmg_len = np.array(cpmg_len).tolist()
    y = np.ones(sum(cpmg_len)) + 0.5
    y2 = np.ones(sum(cpmg_len)) + 0.5
    y1 = np.zeros(sum(cpmg_len))
    y[sum(cpmg_len[0:2]) : sum(cpmg_len[0:3]) + 1] = 2
    y[sum(cpmg_len[0:5]) : sum(cpmg_len[0:6]) + 1] = 2
    y1[sum(cpmg_len[0:9]) : sum(cpmg_len[0:10]) + 1] = 0.5
    y2[sum(cpmg_len[0:2]) : sum(cpmg_len[0:3]) + 1] = 2

    f.add_scatter(y=y)  # trace 2
    f.add_scatter(y=y1)  # trace 3

    f.layout.title = r"Pulse Sequence: %d echos %d times" % (0, 0)

    # add annotations (option to include arrow or text or both)

    f.add_annotation(  # 0
        x=int(1950 * annotation_scale),  # arrows' head
        y=0.7,  # arrows' head
        ax=int(4550 * annotation_scale),  # arrows' tail
        ay=0.7,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="",  # if you want only the arrow
        showarrow=True,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 1
        x=int(4550 * annotation_scale),  # arrows' head
        y=0.7,  # arrows' head
        ax=int(1950 * annotation_scale),  # arrows' tail
        ay=0.7,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="",  # if you want only the arrow
        showarrow=True,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 2
        x=int(50 * annotation_scale),  # arrows' head
        y=1.7,  # arrows' head
        ax=int(50 * annotation_scale),  # arrows' tail
        ay=1.7,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="TX",  # if you want only the arrow
        showarrow=False,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 3
        x=int(50 * annotation_scale),  # arrows' head
        y=0.2,  # arrows' head
        ax=int(50 * annotation_scale),  # arrows' tail
        ay=0.2,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="RX",  # if you want only the arrow
        showarrow=False,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 4
        x=int(3200 * annotation_scale),  # arrows' head
        y=0.9,  # arrows' head
        ax=int(3200 * annotation_scale),  # arrows' tail
        ay=0.9,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="Echo duration:%d " % left_text1.value,  # if you want only the arrow
        showarrow=False,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 5
        x=int(3500 * annotation_scale),  # arrows' head
        y=0.3,  # arrows' head
        ax=int(3500 * annotation_scale),  # arrows' tail
        ay=0.3,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="RX duration:%d " % right_text1.value,  # if you want only the arrow
        showarrow=False,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 6
        x=int(2550 * annotation_scale),  # arrows' head
        y=0.1,  # arrows' head
        ax=int(4500 * annotation_scale),  # arrows' tail
        ay=0.1,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="",  # if you want only the arrow
        showarrow=True,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 7
        x=int(4500 * annotation_scale),  # arrows' head
        y=0.1,  # arrows' head
        ax=int(2550 * annotation_scale),  # arrows' tail
        ay=0.1,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="",  # if you want only the arrow
        showarrow=True,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 8
        x=int(1950 * annotation_scale),  # arrows' head
        y=1.6,  # arrows' head
        ax=int(1450 * annotation_scale),  # arrows' tail
        ay=1.6,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="",  # if you want only the arrow
        showarrow=True,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 9
        x=int(2080 * annotation_scale),  # arrows' head
        y=1.6,  # arrows' head
        ax=int(3080 * annotation_scale),  # arrows' tail
        ay=1.6,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="",  # if you want only the arrow
        showarrow=True,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 10
        x=int(3000 * annotation_scale),  # arrows' head
        y=1.8,  # arrows' head
        ax=int(3000 * annotation_scale),  # arrows' tail
        ay=1.8,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="180 deg TX duration:%d " % right_text5.value,  # if you want only the arrow
        showarrow=False,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 11
        x=int(500 * annotation_scale),  # arrows' head
        y=1.1,  # arrows' head
        ax=0,  # arrows' tail
        ay=1.1,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="",  # if you want only the arrow
        showarrow=True,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 12
        x=int(545 * annotation_scale),  # arrows' head
        y=1.1,  # arrows' head
        ax=1545 * annotation_scale,  # arrows' tail
        ay=1.1,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="",  # if you want only the arrow
        showarrow=True,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    f.add_annotation(  # 13
        x=int(1500 * annotation_scale),  # arrows' head
        y=1.3,  # arrows' head
        ax=int(1500 * annotation_scale),  # arrows' tail
        ay=1.3,  # arrows' tail
        xref="x",
        yref="y",
        axref="x",
        ayref="y",
        text="90 deg TX duration:%d " % right_text1.value,  # if you want only the arrow
        showarrow=False,
        arrowhead=3,
        arrowsize=1,
        arrowwidth=1,
        arrowcolor="black",
    )
    return pg, pg_1, f


# ------------- Connect function with GUI and IP core ------------


def config_plot_c(self):  # must pass function (name) to Button on_click without calling it
    # config + plot
    mmio.write(conf_dict["conf_nr_rx_pulse"], right_text.value)  # update echo number
    mmio.write(conf_dict["conf_nr_sample"], web_GUI_config_panel.GUI_set_nr_samples.value)  # update mmio
    mmio.write(conf_dict["conf_scale"], web_GUI_config_panel.GUI_Scale.value)  # update clock division ratio
    data_processing.func_update_config_tracing()
    web_GUI_config_panel.GUI_TBtn_run_stop.value = 0
    global pg
    pg.Sec_Config_CPMG(0)
    cpmg_plot_modify(left_text.value, pg.No_echos)


def config_plot_f(self):  # must pass function (name) to Button on_click without calling it
    # for Freddy's chip

    # config + plot

    # print('test config plot_f')

    mmio.write(conf_dict["conf_nr_rx_pulse"], 1)  # update echo number
    mmio.write(conf_dict["conf_nr_sample"], web_GUI_config_panel.GUI_set_nr_samples.value)  # update mmio
    mmio.write(conf_dict["conf_scale"], web_GUI_config_panel.GUI_Scale.value)  # update clock division ratio
    data_processing.func_update_config_tracing()  # update tracing IP from mmio data
    web_GUI_config_panel.GUI_TBtn_run_stop.value = 0
    global pg_1
    pg_1.Sec_Config_FID(0)
    fid_plot_modify(left_text6.value, pg_1.No_echos)  # upate dynamic plotting of pulse_gen GUI
    # fpga_tracing_func.osci.write(fpga_func_dict['C_SET_STREAM_NR_RX_PULSE'],1)

    # bind frequency in CPMG to FID
    left_text3.value = left_text8.value
    right_text3.value = right_text8.value


def config_plot_a(self):  # must pass function (name) to Button on_click without calling it
    # config + plot
    mmio.write(conf_dict["conf_nr_rx_pulse"], 1)  # update echo number
    mmio.write(conf_dict["conf_nr_sample"], web_GUI_config_panel.GUI_set_nr_samples.value)  # update mmio
    mmio.write(conf_dict["conf_scale"], web_GUI_config_panel.GUI_Scale.value)  # update clock division ratio
    data_processing.func_update_config_tracing()
    web_GUI_config_panel.GUI_TBtn_run_stop.value = 0
    global pg_2
    pg_2.Sec_Config_ARBITRARY(0)
    arbitrary_plot_modify(pg_2.No_scans, pg_2.No_echos)


# -------------- 5. GUI Plot Functions Using matplotlib.pyplot-----------------


def cpmg_plot_modify(exp_num, echo_num):
    global f
    f.layout.title = r"CPMG Pulse Sequence: %d echo(s) %d time(s)" % (echo_num, exp_num)
    f["layout"]["annotations"][4]["text"] = "Echo duration:%d " % left_text1.value
    f["layout"]["annotations"][5]["text"] = "RX duration:%d " % right_text2.value
    f["layout"]["annotations"][10]["text"] = "180 deg TX duration:%d " % right_text5.value
    f["layout"]["annotations"][13]["text"] = "90 deg TX duration:%d " % right_text1.value


def fid_plot_modify(exp_num, echo_num):
    # print('test pulse_gen fid_plot_mod')

    global f
    global y2
    f.layout.title = r"FID Pulse Sequence: %d echo(s) %d time(s)" % (echo_num, exp_num)
    f["layout"]["annotations"][4]["text"] = ""
    f["layout"]["annotations"][5]["text"] = "RX duration:%d " % right_text7.value
    f["layout"]["annotations"][10]["text"] = ""
    f["layout"]["annotations"][13]["text"] = "90 deg TX duration:%d " % right_text6.value
    f["layout"]["annotations"][8]["showarrow"] = False
    f["layout"]["annotations"][9]["showarrow"] = False
    f["layout"]["annotations"][0]["showarrow"] = False
    f["layout"]["annotations"][1]["showarrow"] = False
    f.data[0]["y"] = y2
