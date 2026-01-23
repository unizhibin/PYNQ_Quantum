# ----------------------------------------------------------------------------------
# -- Company: University of Stuttgart (IIS)
# -- Engineer: Yichao Peng
# -- 
# -- Description: 
# -- This python file include all the widgets used in the GUI
# ----------------------------------------------------------------------------------

import ipywidgets as widgets
import plotly.graph_objects as go
import src.data_processing as data_processing
import src.all_of_the_parameters as all_of_the_parameters
import src.fpga_tracing_func as fpga_tracing_func
import time

Dep_Mem = all_of_the_parameters.Dep_Mem
sample_value_half = all_of_the_parameters.sample_value_half
sample_size = all_of_the_parameters.sample_size
adc_volt = all_of_the_parameters.adc_volt
point_number_on_screen = all_of_the_parameters.point_number_on_screen

screen_width = all_of_the_parameters.screen_width # original: 1920px
screen_height = all_of_the_parameters.screen_height
flag_bitstream = all_of_the_parameters.flag_bitstream

"""
from here the GUI for NMR_CHIP_CFG
"""

def GUI_chip_cfg_ref_current():
    
    GUI_chip_cfg_ref_current = widgets.Dropdown(      
        options=[
            ('-15%', 0), 
            ('-10%', 1),
            ('-5%', 2),
            ('+0%', 3),
            ('+5%', 4),
            ('+10%', 5),
            ('+15%', 6),
            ('+20%', 7)
        ],
        value=3,
        description='Reference Current:',
        disabled=False,
        style = {'description_width': str(round(0.0625*screen_width))+'px'},
        layout={
            'width': str(round(0.14*screen_width))+'px', # original 0.1448
            'height':'30px',
        }, 
    )
    return GUI_chip_cfg_ref_current

def GUI_chip_cfg_vga_gain():
    
    GUI_chip_cfg_vga_gain = widgets.Dropdown(      
        options=[
            ('0dB', 0), 
            ('3dB', 1),
            ('6dB', 2),
            ('9dB', 3),
            ('10dB', 4),
            ('11dB', 5),
            ('13dB', 6),
            ('15dB', 7),
            ('20dB', 8), 
            ('23dB', 9),
            ('25dB', 10),
            ('28dB', 11),
            ('29dB', 12),
            ('30dB', 13),
            ('32dB', 14),
            ('34dB', 15)
        ],
        value=10,
        description='VGA Gain:',
        disabled=False,
        style = {'description_width': str(round(0.0625*screen_width))+'px'},
        layout={
            'width': str(round(0.14*screen_width))+'px',
            'height':'30px',
        }, 
    )
    return GUI_chip_cfg_vga_gain

def GUI_chip_cfg_pll_mult():
    
    GUI_chip_cfg_pll_mult = widgets.Dropdown(
        options=[
            ('64x', 0), 
            ('32x', 1),
            ('16x', 2),
            ('8x', 3),
            ('4x', 4),
            ('2x', 5),
            ('1x', 6),
            ('set to Bridge', 8)
        ],
        value=3,
        description='PLL Multiplier:',
        disabled=False,
        style = {'description_width': str(round(0.0625*screen_width))+'px'},
        layout={
            'width': str(round(0.14*screen_width))+'px',
            'height':'30px', # original 42px
        }, 
    )
    return GUI_chip_cfg_pll_mult

def GUI_chip_cfg_ref_current_box(a):
    
    GUI_chip_cfg_ref_current_box = widgets.VBox(
        [
            a,
        ],
        layout = widgets.Layout(
            height='42px',
            width=str(round(0.15625*screen_width))+'px',
            border='solid 4px red',
            margin='0px 5px 0px 5px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_chip_cfg_ref_current_box

def GUI_progress_bar_box(a):
    
    GUI_progress_bar_box = widgets.VBox(
        [
            a,
        ],
        layout = widgets.Layout(
            height='42px',
            width=str(round(0.2109375*screen_width))+'px',
            border='solid 4px red',
            margin='0px 5px 0px 5px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_progress_bar_box

def GUI_chip_cfg_vga_gain_box(a):
    
    GUI_chip_cfg_vga_gain_box = widgets.VBox(
        [
            a,
        ],
        layout = widgets.Layout(
            height='42px',
            width=str(round(0.15625*screen_width))+'px',
            border='solid 4px red',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_chip_cfg_vga_gain_box

def GUI_chip_cfg_pll_mult_box(a):
    
    GUI_chip_cfg_pll_mult_box = widgets.VBox(
        [
            a,
        ],
        layout = widgets.Layout(
            height='42px',
            width=str(round(0.15625*screen_width))+'px',
            border='solid 4px red',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_chip_cfg_pll_mult_box

def GUI_chip_cfg_box_hf(a, b, c, d):
    
    GUI_chip_cfg_box_hf = widgets.HBox(
        [
            a,
            b,
            c,
            d,
        ],
        layout = widgets.Layout(height='42px', width=str(round(0.678125*screen_width))+'px'), # 970px original
        align_items='flex-start',
    )
    return GUI_chip_cfg_box_hf

def GUI_chip_cfg_mixer_high_voltage_box(a):
    
    GUI_chip_cfg_mixer_high_voltage_box = widgets.VBox(
        [
            a,
        ],
        layout = widgets.Layout(
            height='42px',
            width=str(round(0.08*screen_width))+'px', # original 0.15625
            border='solid 4px red',
            margin='0px 5px 0px 5px', # control inner and outer boarder margin
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_chip_cfg_mixer_high_voltage_box

def GUI_chip_cfg_if_amp_high_voltage_box(a):
    
    GUI_chip_cfg_if_amp_high_voltage_box = widgets.VBox(
        [
            a,
        ],
        layout = widgets.Layout(
            height='42px',
            width=str(round(0.08*screen_width))+'px', # original 0.15625
            border='solid 4px red',
            margin='0px 5px 0px 5px', # control inner and outer boarder margin
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_chip_cfg_if_amp_high_voltage_box

def GUI_chip_cfg_pll_high_voltage_box(a):
    
    GUI_chip_cfg_pll_high_voltage_box = widgets.VBox(
        [
            a,
        ],
        layout = widgets.Layout(
            height='42px',
            width=str(round(0.08*screen_width))+'px', # original 0.15625
            border='solid 4px red',
            margin='0px 5px 0px 5px', # control inner and outer boarder margin
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_chip_cfg_pll_high_voltage_box

def GUI_chip_cfg_box_hv(a, b, c, d):
    
    GUI_chip_cfg_box_hv = widgets.HBox(
        [
            a,
            b,
            c,
            d,
        ],
        layout = widgets.Layout(height='42px', width=str(round(0.9*0.678125*screen_width))+'px'), # 970px original
        align_items='flex-start',
    )
    return GUI_chip_cfg_box_hv

"""
from here the GUI for TRACING PART
"""

"""
logo of iis on the title box
"""

def GUI_logo():
    
    file_GUI_logo = open("src/icons/logo_iis.png", "rb")
    image = file_GUI_logo.read()
    GUI_logo = widgets.Image(
        value=image,
        format='png',
        width=320,
        height=80,
    )
    return GUI_logo

def GUI_logo_iis():
    
    file_GUI_logo_iis = open("src/icons/logo_iis_blue.png", "rb")
    image = file_GUI_logo_iis.read()
    GUI_logo_iis = widgets.Image(
        value=image,
        format='png',
        width = 160, #width=200,
        height=64, #height=80,
    )
    return GUI_logo_iis

def ris_edge():
    
    file_ris_edge = open("src/icons/ris_edge.png", "rb")
    image = file_ris_edge.read()
    ris_edge = widgets.Image(
        value=image,
        format='png',
        width=round(0.16667*screen_width),
        height=8,
    )
    return ris_edge

def fal_edge():
    
    file_fal_edge = open("src/icons/fal_edge.png", "rb")
    image = file_fal_edge.read()
    fal_edge = widgets.Image(
        value=image,
        format='png',
        width=round(0.013*screen_width),
        height=8,
    )
    return fal_edge

"""
settings on the function bar
"""

def GUI_title():
    
    GUI_title = widgets.Label(
        value="-----------------Tracing for NMR Signal-----------------",
        layout = widgets.Layout(height='25px', width=str(round(0.16667*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_title

def GUI_RX_Synchronization():
    
    GUI_RX_Synchronization = widgets.Label(
        value="RX Synchronization:",
        layout = widgets.Layout(height='25px', width=str(round(0.07292*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_RX_Synchronization

def GUI_Exp_loop():
    
    GUI_Exp_loop = widgets.ToggleButton(
        value=False,
        description='Loop Off',
        disabled=False,
        button_style='',
        tooltip='set patameters before activate',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'), # min118px, 128px original
    )
    return GUI_Exp_loop

def GUI_TBtn_arm():
    
    GUI_TBtn_arm = widgets.ToggleButton(
        value=False,
        description='Unsynchronized',
        disabled=False,
        button_style='',
        tooltip='set patameters before activate',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'), # min118px, 128px original
    )
    return GUI_TBtn_arm

def GUI_TBtn_run_stop():
    
    GUI_TBtn_run_stop = widgets.ToggleButton(
        value=False,
        description='Run/Stop',
        disabled=False,
        button_style='',
        tooltip='Freeze Screen',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'),
    )
    return GUI_TBtn_run_stop

def GUI_onoff(a, b):
    
    GUI_onoff = widgets.VBox(
        [
            GUI_RX_Synchronization(),
            a,
            b,
        ],
        layout = widgets.Layout(
            height='118px',
            width=str(round(0.08594*screen_width))+'px', # 150px
            border='solid 4px lightgreen',
            margin='0px 5px 0px 5px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_onoff

"""
part 1 ana trigger cbox (deserted)
"""

def GUI_ana_label():
    
    GUI_ana_label = widgets.Label(
        value="Analog Trigger:",
        layout = widgets.Layout(height='25px', width=str(round(0.04792*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_ana_label

#set analog rising edge
def GUI_checkbox_ana_ris():
    
    GUI_checkbox_ana_ris = widgets.Checkbox(
        value=False,
        layout = widgets.Layout(height='22px', width=str(round(0.04896*screen_width))+'px'),
        description='Rising Edge',
        disabled=False,
        indent=False
    )
    return GUI_checkbox_ana_ris

def GUI_checkbox_ana_fal():
    
    GUI_checkbox_ana_fal = widgets.Checkbox(
        value=False,
        layout = widgets.Layout(height='22px', width=str(round(0.04896*screen_width))+'px'),
        description='Falling Edge',
        disabled=False,
        indent=False
    )
    return GUI_checkbox_ana_fal

def GUI_hbox_ana_ris(a,b):
    
    GUI_hbox_ana_ris = widgets.HBox(
        [
            a,
            b
        ],
        layout = widgets.Layout(height='30px', width=str(round(0.075521*screen_width))+'px'), # min. 30 x 123 128px original
        align_items='flex-start'
    )
    return GUI_hbox_ana_ris

def GUI_hbox_ana_fal(a,b):
    
    GUI_hbox_ana_fal = widgets.HBox(
        [
            a,
            b
        ],
        layout = widgets.Layout(height='30px', width=str(round(0.075521*screen_width))+'px'), #min 30 x 123 128px original
        align_items='flex-start'
    )
    return GUI_hbox_ana_fal

def GUI_ana_cbox(a, b, c):

    GUI_ana_cbox = widgets.VBox(
        [
            a,
            b,
            c,
        ],
        layout = widgets.Layout(
            height='90px', 
            width=str(round(0.078125*screen_width))+'px'
        ),
        align_items='flex-start',
    )
    return GUI_ana_cbox

"""
part 2 ana trigger ch tl (deserted)
"""

def GUI_ana_label_blank():
    
    GUI_ana_label_blank = widgets.Label(
        value=" ",
        layout = widgets.Layout(height='25px', width=str(round(0.00521*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_ana_label_blank

#set the trigger channel
def GUI_Dropdown_analog_ch():
    
    GUI_Dropdown_analog_ch = widgets.Dropdown(      
        options=[('0', 0), ('1', 1), ('2', 2), ('3', 3)],
        value=0,
        description='ch: ',
        disabled=False,
        style = {'description_width': str(round(0.019271*screen_width))+'px'},
        layout={'width': str(round(0.06667*screen_width))+'px'}, 
    )
    return GUI_Dropdown_analog_ch

#set the analog trigger level
def GUI_Analog_Level():
    
    GUI_Analog_Level = widgets.FloatText(
        value=0.0,
        description='TL(V):',
        disabled=False,
        style = {'description_width': str(round(0.019271*screen_width))+'px'},
        layout={'width': str(round(0.06667*screen_width))+'px'}, 
    )
    return GUI_Analog_Level

def GUI_ana_ch_tl(a, b, c):
    
    GUI_ana_ch_tl = widgets.VBox(
        [
            a,
            b, 
            c, 
        ],
        layout = widgets.Layout(
            height='90px', 
            width=str(round(0.078125*screen_width))+'px'
        ),
        align_items='flex-start',
    )
    return GUI_ana_ch_tl

def GUI_ana_all(a,b):

    GUI_ana_all = widgets.HBox(
        [
            a,
            b, 
        ],
        layout = widgets.Layout(
            height='110px', 
            width=str(round(0.16667*screen_width))+'px', # 300px original
            border='solid 4px lightgreen',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_ana_all

"""
part 3 dig cbox (deserted)
"""

def GUI_dig_label():
    
    GUI_dig_label = widgets.Label(
        value="Digital Trigger:",
        layout = widgets.Layout(height='25px', width=str(round(0.0521*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_dig_label

def GUI_checkbox_dig_ris():
    
    GUI_checkbox_dig_ris = widgets.Checkbox(
        value=False,
        layout = widgets.Layout(height='22px', width=str(round(0.049*screen_width))+'px'),
        description='Rising Edge',
        disabled=False,
        indent=False
    )
    return GUI_checkbox_dig_ris

def GUI_checkbox_dig_fal():
    
    GUI_checkbox_dig_fal = widgets.Checkbox(
        value=False,
        layout = widgets.Layout(height='22px', width=str(round(0.049*screen_width))+'px'),
        description='Falling Edge',
        disabled=False,
        indent=False
    )
    return GUI_checkbox_dig_fal

def GUI_hbox_dig_ris(a, b):
    
    GUI_hbox_dig_ris = widgets.HBox(
        [
            a,
            b
        ],
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_hbox_dig_ris

def GUI_hbox_dig_fal(a, b):
    
    GUI_hbox_dig_fal = widgets.HBox(
        [
            a,
            b
        ],
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_hbox_dig_fal

def GUI_dig_cbox(a, b, c):
    
    GUI_dig_cbox = widgets.VBox(
        [
            a,
            b,
            c,
        ],
        layout = widgets.Layout(
            height='110px', 
            width=str(round(0.078125*screen_width))+'px',
            border='solid 4px lightgreen',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_dig_cbox

"""
part 4 zoom
"""

def GUI_zoom_title():
    
    GUI_zoom_title = widgets.Label(
        value="Visualization:",
        layout = widgets.Layout(height='25px', width=str(round(0.0521*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_zoom_title

def GUI_Scale():
    
    GUI_Scale = widgets.IntSlider(
        value = 5, #value=10,
        min=1,
        max=100,
        step=1,
        description='Sampling Rate (MHz):',
        disabled=False,
        continuous_update=False,
        orientation='horizontal',
        readout=True,
        readout_format='d',
        layout = widgets.Layout(height='30px', width=str(round(0.15104*screen_width))+'px'),
        style = {'description_width': '130px'},
    )
    return GUI_Scale

def GUI_set_nr_samples():

    GUI_set_nr_samples = widgets.IntSlider(
        value = 2**16, #value=2**10,
        min=256,
        max=2**20,
        step=1,
        description='Number of Samples:',
        disabled=False,
        continuous_update=False,
        orientation='horizontal',
        readout=True,
        readout_format='d',
        layout = widgets.Layout(height='30px', width=str(round(0.15104*screen_width))+'px'),
        style = {'description_width': '130px'},
    )
    
    return GUI_set_nr_samples

def GUI_zoom1(a, b):
    
    GUI_zoom1 = widgets.VBox(
        [
            GUI_zoom_title(),
            a,
            b,
        ],
        layout = widgets.Layout(
            height='118px',
            width=str(round(0.16667*screen_width))+'px', # 300px original
            border='solid 4px lightgreen',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_zoom1

"""
part 5 bandpass
"""
def GUI_bandpass_label():
    
    GUI_bandpass_label = widgets.Label(
        value="Bandpass Filter:",
        layout = widgets.Layout(height='27px', width=str(round(0.07292*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_bandpass_label

# set the lower limit
def GUI_bandpass_lowFrequency():
    
    GUI_bandpass_lowFrequency = widgets.FloatText(
        value=1,
        min=1,
        max=1000,
        disabled=False,
        layout = widgets.Layout(height='25px', width=str(round(0.088542*screen_width))+'px'),
        description = 'f_low (kHz)',
        style = {'description_width': str(round(0.04167*screen_width))+'px'},
    )
    return GUI_bandpass_lowFrequency

# set the higher limit
def GUI_bandpass_highFrequency():
    
    GUI_bandpass_highFrequency = widgets.FloatText(
        value=100,
        min=1,
        max=1000,
        disabled=False,
        layout = widgets.Layout(height='25px', width=str(round(0.088542*screen_width))+'px'),
        description = 'f_high (kHz)',
        style = {'description_width': str(round(0.04167*screen_width))+'px'},
    )
    return GUI_bandpass_highFrequency

# set bandpass order
def GUI_bandpass_order():
    
    GUI_bandpass_order = widgets.FloatText(
        value=0.0,
        disabled=False,
        layout = widgets.Layout(height='25px', width=str(round(0.088542*screen_width))+'px'),
        description = 'Order',
        style = {'description_width': str(round(0.04167*screen_width))+'px'},
    )
    return GUI_bandpass_order

# checkbox for choosing type of filter
def GUI_checkbox_Butterworth():
    
    GUI_checkbox_Butterworth = widgets.Checkbox(
        value=False,
        layout = widgets.Layout(height='15px', width=str(round(0.057292*screen_width))+'px'),
        description='Butterworth',
        disabled=False,
        indent=False
    )
    return GUI_checkbox_Butterworth

def GUI_checkbox_Cheby1():
    
    GUI_checkbox_Cheby1 = widgets.Checkbox(
        value=False,
        layout = widgets.Layout(height='15px', width=str(round(0.057292*screen_width))+'px'),
        description='Chebyshev I',
        disabled=False,
        indent=False
    )
    return GUI_checkbox_Cheby1

def GUI_checkbox_Cheby2():
    
    GUI_checkbox_Cheby2 = widgets.Checkbox(
        value=False,
        layout = widgets.Layout(height='15px', width=str(round(0.057292*screen_width))+'px'),
        description='Chebyshev II',
        disabled=False,
        indent=False
    )
    return GUI_checkbox_Cheby2

# VBoxes
def GUI_vbox_setting(a, b): # order default 3
    
    GUI_vbox_setting = widgets.VBox(
        [
            a,
            b,
            # c,
        ],
        layout = widgets.Layout(height='80px', width=str(round(0.09375*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_vbox_setting

def GUI_vbox_filterType(a, b, c):
    
    GUI_vbox_filterType = widgets.VBox(
        [
            a,
            b,
            c,
        ],
        layout = widgets.Layout(height='80px', width=str(round(0.0625*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_vbox_filterType

# configure part combination for bandpass filter
def GUI_bandpass_configure(a, b):
    
    GUI_bandpass_configure = widgets.HBox(
        [
            a,
            b,
        ],
        layout = widgets.Layout(
            height='100px', # 80px
            width=str(round(0.16*screen_width))+'px', # original 0.1771
            # border='solid 4px lightgreen',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_bandpass_configure

# bandpass filter
def GUI_bandpass(b):
    
    GUI_bandpass = widgets.VBox(
        [
            GUI_bandpass_label,
            b,
        ],
        layout = widgets.Layout(
            height='118px', # 118px 
            width=str(round(0.1823*screen_width))+'px', # original 0.1823
            border='solid 4px lightgreen',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_bandpass

"""
part 6 Enhancement (deserted)
"""

def GUI_Dropdown_Enh_ch():
    
    GUI_Dropdown_Enh_ch = widgets.Dropdown(      
        options=[('0', 0), ('1', 1), ('2', 2), ('3', 3)],
        value=0,
        description='ch: ',
        disabled=False,
        style = {'description_width': str(round(0.01927*screen_width))+'px'},
        layout={'width': '128px'}, 
    )
    return GUI_Dropdown_Enh_ch

def GUI_blankline():
    
    GUI_blankline = widgets.Label(
        value="  ",
        layout = widgets.Layout(height='25px', width=str(round(0.01042*screen_width))+'px'),
        align_items='top'
    )
    return GUI_blankline

def GUI_Enh_title():
    
    GUI_Enh_title = widgets.Label(
        value="Enhancement:",
        layout = widgets.Layout(height='25px', width=str(round(0.046875*screen_width))+'px'), #min 90px
        align_items='top'
    )
    return GUI_Enh_title

def GUI_Enh_tau():
    
    GUI_Enh_tau = widgets.FloatText(
        value=1,
        description=r'$\tau$:',
        disabled=False,
        style = {'description_width': str(round(0.019271*screen_width))+'px'},
        layout={'width': '128px'},
    )
    return GUI_Enh_tau

def GUI_Enh_DC():
    
    GUI_Enh_DC = widgets.ToggleButton(
        value=False,
        description='Remove DC',
        disabled=False,
        button_style='',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'), #min 100px
    )
    return GUI_Enh_DC

def GUI_Enh_sensitivity():
    
    GUI_Enh_sensitivity = widgets.ToggleButton(
        value=False,
        description='Sensitivity',
        disabled=False,
        button_style='',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'),
    )
    return GUI_Enh_sensitivity

def GUI_Enh_Resolution():
    
    GUI_Enh_Resolution = widgets.ToggleButton(
        value=False,
        description='Resolution',
        disabled=False,
        button_style='',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'),
    )
    return GUI_Enh_Resolution

def GUI_blankline_Enh():
    
    GUI_blankline_Enh = widgets.Label(
        value="  ",
        layout = widgets.Layout(height='20px', width=str(round(0.01042*screen_width))+'px'),
        align_items='top'
    )
    return GUI_blankline_Enh

def GUI_Enh_2x2(a, b, c):
    
    GUI_Enh_2x2 = widgets.TwoByTwoLayout(
        top_left=a,
        bottom_left=b,
        top_right=c,
        merge=False
    )
    return GUI_Enh_2x2

def GUI_Enh1(a, b, c):
    
    GUI_Enh1 = widgets.VBox(
        [
            a,
            b, 
            c,
        ],
        layout = widgets.Layout(height='90px', width=str(round(0.084375*screen_width))+'px'),
        align_items='top',
    )
    return GUI_Enh1

def GUI_Enh2(a, b, c):
    
    GUI_Enh2 = widgets.VBox(
        [
            a,
            b,
            c,
        ],
        layout = widgets.Layout(height='92px', width=str(round(0.078125*screen_width))+'px'),
        align_items='top',
    )
    return GUI_Enh2

def GUI_Enh(a, b):
    
    GUI_Enh = widgets.HBox(
        [
            a,
            b,
        ],
        layout = widgets.Layout(
            height='110px', 
            width=str(round(0.15625*screen_width))+'px',
            border='solid 4px lightgreen',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_Enh

"""
save file
"""

def GUI_save_label():
    
    GUI_save_label = widgets.Label(
        value="Save Data:",
        layout = widgets.Layout(height='25px', width=str(round(0.03646*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_save_label

def GUI_save_name():
    
    GUI_save_name = widgets.Text(
        description="File Name:",
        layout = widgets.Layout(height='30px', width=str(round(0.13021*screen_width))+'px'), # 276px original
        style = {'description_width': str(round(0.03646*screen_width))+'px'},
    )
    return GUI_save_name

def GUI_save_format():
    
    GUI_save_format = widgets.Dropdown(      
        options=[('.csv', 0), ('.txt', 1)],
        value=0,
        description='Save as:',
        disabled=False,
        style = {'description_width': str(round(0.03646*screen_width))+'px'},
        layout={
            'width': str(round(0.09375*screen_width))+'px',
            'height':'30px',
        }, 
    )
    return GUI_save_format

def GUI_save_button():
    
    GUI_save_button = widgets.Button(
    description='Save',
    layout = widgets.Layout(height='30px', width=str(round(0.0391*screen_width))+'px'), # 94px original
    )
    return GUI_save_button
   
def GUI_save_HBox(a, b):

    GUI_save_HBox = widgets.HBox(
        [
            a,
            b,
        ],
        layout = widgets.Layout(height='34px', width=str(round(0.14583*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_save_HBox
    
def GUI_save(a, b, c):
    
    GUI_save = widgets.VBox(
        [
            a,
            b, 
            c,
        ],
        layout = widgets.Layout(
            height='118px', 
            width=str(round(0.15729*screen_width))+'px', # 300px original
            border='solid 4px lightgreen',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_save

"""
NMR high voltage mixer
"""
def GUI_chip_cfg_mixer_high_voltage():
    
    GUI_chip_cfg_mixer_high_voltage = widgets.ToggleButton(
        value=False,
        # description='Mixer off',
        description='Mixer',
        disabled=False,
        button_style='',
        tooltip='mixer',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'), # min118px, 128px original
    )
    return GUI_chip_cfg_mixer_high_voltage


"""
NMR high pll enable
"""
def GUI_chip_cfg_pll_high_voltage():
    
    GUI_chip_cfg_pll_high_voltage = widgets.ToggleButton(
        value=False,
        description='PLL',
        disabled=False,
        button_style='',
        tooltip='phase locked loop',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.06667*screen_width))+'px'), # min118px, 128px original
    )
    return GUI_chip_cfg_pll_high_voltage


"""
FFT
"""

def GUI_FFT_label():
    
    GUI_FFT_label = widgets.Label(
        value="FFT: ",
        layout = widgets.Layout(height='25px', width=str(round(0.03646*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_FFT_label

def GUI_FFT_run_stop():
    
    GUI_FFT_run_stop = widgets.ToggleButton(
        value=False,
        description='FFT Run/Stop',
        disabled=False,
        button_style='',
        tooltip='FFT Run/Stop',
        icon='',
        layout = widgets.Layout(height='30px', width=str(round(0.0625*screen_width))+'px'), # 128px
    )
    return GUI_FFT_run_stop

def GUI_FFT_ch():
    
    GUI_FFT_ch = widgets.Dropdown(      
        options=[('0', 0), ('1', 1)],
        value=0,
        description='Channel: ',
        style = {'description_width': str(round(0.03125*screen_width))+'px'},
        layout={'width': str(round(0.0625*screen_width))+'px'}, 
    )
    return GUI_FFT_ch

def GUI_FFT(a, b, c):
    
    GUI_FFT = widgets.VBox(
        [
            a,
            b,
            c,
        ],
        layout = widgets.Layout(
            height='118px', 
            width=str(round(0.078125*screen_width))+'px',
            border='solid 4px lightgreen',
            margin='0px 5px 0px 0px',
            padding='0px 5px 0px 5px'
        ),
        align_items='flex-start',
    )
    return GUI_FFT

def GUI_head(a, b):
    
    GUI_head = widgets.HBox(
        [
            a,
            b,
        ],
        layout = widgets.Layout(height='80px', width=str(round(0.41667*screen_width))+'px'), 
        #layout = widgets.Layout(height='80px', width=str(round(0.2*screen_width))+'px'),
        align_items='flex-start',
    )
    return GUI_head

def GUI_pulse_gen(a):
    
    GUI_pulse_gen = widgets.HBox(
        [
            a,
        ],
        layout = widgets.Layout(height='100px', width=str(round(0.973958*screen_width))+'px'),
        align_items='flex-start',
    )
    return GUI_pulse_gen

def GUI_head_blank():
    
    GUI_ana_label_blank = widgets.Label(
        value=" ",
        layout = widgets.Layout(height='22px', width=str(round(0.021354*screen_width))+'px'),
        align_items='flex-start'
    )
    return GUI_ana_label_blank

def GUI_tracing(
    module1,
    module2,
    module3,
    module4,
    module5,
    # module6,
    # module7,
):
    
    GUI_tracing = widgets.HBox(
        [
#             GUI_head_blank(),
            module1,
            module2,
            module3,
            module4,
            module5,
            # module6,
            # module7,
        ],
        layout = widgets.Layout(height='125px', width=str(round(0.6796875*screen_width))+'px'),
        align_items='flex-start',
    )
    return GUI_tracing

def GUI_total(a, b, c, d):
    
    GUI_total = widgets.VBox(
        [
            a,
            b,
            c,
            d,
        ],
        layout = widgets.Layout(height='auto', width=str(round(0.97396*screen_width))+'px'),
        align_items='flex-start',
    )
    return GUI_total

# --------------- Progress Bar ----------------

#  show averaging progress
prog = widgets.IntProgress()
prog.value = 0
prog.style.bar_color = 'green'
prog.description = 'Avg. Progress'
prog.style = {'description_width':'initial'}
prog.orientation = 'horizontal'
prog.layout = widgets.Layout(width = str(round(0.1875*screen_width))+'px', height = '40px') # general method to adjust width of widgets
GUI_progress_bar_box = GUI_progress_bar_box(prog)


# NMR_CHIP_CFG
GUI_chip_cfg_ref_current = GUI_chip_cfg_ref_current()
GUI_chip_cfg_ref_current_box = GUI_chip_cfg_ref_current_box(GUI_chip_cfg_ref_current)
GUI_chip_cfg_vga_gain = GUI_chip_cfg_vga_gain()
GUI_chip_cfg_vga_gain_box = GUI_chip_cfg_vga_gain_box(GUI_chip_cfg_vga_gain)
GUI_chip_cfg_pll_mult = GUI_chip_cfg_pll_mult()
GUI_chip_cfg_pll_mult_box = GUI_chip_cfg_pll_mult_box(GUI_chip_cfg_pll_mult)
GUI_chip_cfg_mixer_high_voltage = GUI_chip_cfg_mixer_high_voltage()
GUI_chip_cfg_mixer_high_voltage_box = GUI_chip_cfg_mixer_high_voltage_box(GUI_chip_cfg_mixer_high_voltage)
GUI_chip_cfg_pll_high_voltage = GUI_chip_cfg_pll_high_voltage()
GUI_chip_cfg_pll_high_voltage_box = GUI_chip_cfg_pll_high_voltage_box(GUI_chip_cfg_pll_high_voltage)
GUI_chip_cfg_if_amp_high_voltage_box = GUI_chip_cfg_if_amp_high_voltage_box(fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage)
GUI_chip_cfg_box_hf = GUI_chip_cfg_box_hf(GUI_chip_cfg_ref_current_box, GUI_chip_cfg_vga_gain_box, GUI_chip_cfg_pll_mult_box, GUI_progress_bar_box) # add progress bar
GUI_chip_cfg_box_hv = GUI_chip_cfg_box_hv(GUI_chip_cfg_mixer_high_voltage_box, GUI_chip_cfg_pll_high_voltage_box, GUI_chip_cfg_if_amp_high_voltage_box, GUI_progress_bar_box)
GUI_chip_cfg_box = GUI_chip_cfg_box_hf if flag_bitstream == 1 else GUI_chip_cfg_box_hv

# Tracing
#icons
GUI_logo = GUI_logo()
GUI_logo_iis = GUI_logo_iis()
ris_edge = ris_edge()
fal_edge = fal_edge()
GUI_blankline = GUI_blankline()

# onoff button
GUI_TBtn_arm = GUI_TBtn_arm()
GUI_TBtn_run_stop = GUI_TBtn_run_stop()
GUI_Exp_loop = GUI_Exp_loop()
GUI_onoff = GUI_onoff(GUI_TBtn_arm, GUI_Exp_loop)

# ana trigger cbox
GUI_ana_label_blank = GUI_ana_label_blank()
GUI_checkbox_ana_ris = GUI_checkbox_ana_ris()
GUI_checkbox_ana_fal = GUI_checkbox_ana_fal()
GUI_hbox_ana_ris = GUI_hbox_ana_ris(ris_edge, GUI_checkbox_ana_ris)
GUI_hbox_ana_fal = GUI_hbox_ana_fal(fal_edge, GUI_checkbox_ana_fal)
GUI_ana_cbox = GUI_ana_cbox(GUI_ana_label_blank, GUI_hbox_ana_ris, GUI_hbox_ana_fal)

# ana trigger ch tl
GUI_ana_label = GUI_ana_label()
GUI_Dropdown_analog_ch = GUI_Dropdown_analog_ch()
GUI_Analog_Level = GUI_Analog_Level()
GUI_ana_ch_tl = GUI_ana_ch_tl(GUI_ana_label, GUI_Dropdown_analog_ch, GUI_Analog_Level)
GUI_ana_all = GUI_ana_all(GUI_ana_ch_tl, GUI_ana_cbox)

# dig trigger cbox
GUI_dig_label = GUI_dig_label()
GUI_checkbox_dig_ris = GUI_checkbox_dig_ris()
GUI_checkbox_dig_fal = GUI_checkbox_dig_fal()
GUI_hbox_dig_ris = GUI_hbox_dig_ris(ris_edge, GUI_checkbox_dig_ris)
GUI_hbox_dig_fal = GUI_hbox_dig_fal(fal_edge, GUI_checkbox_dig_fal)
GUI_dig_cbox = GUI_dig_cbox(GUI_dig_label, GUI_hbox_dig_ris, GUI_hbox_dig_fal)

# zoom1
GUI_Scale = GUI_Scale()
GUI_set_nr_samples = GUI_set_nr_samples()
GUI_zoom1 = GUI_zoom1(GUI_Scale, GUI_set_nr_samples)

# Enh1
GUI_Enh_title = GUI_Enh_title()
GUI_Dropdown_Enh_ch = GUI_Dropdown_Enh_ch()
GUI_Enh_tau = GUI_Enh_tau()
GUI_Enh1 = GUI_Enh1(GUI_Enh_title, GUI_Dropdown_Enh_ch, GUI_Enh_tau)
GUI_blankline_Enh = GUI_blankline_Enh()

# Enh2
GUI_Enh_sensitivity = GUI_Enh_sensitivity()
GUI_Enh_Resolution = GUI_Enh_Resolution()
GUI_Enh_DC = GUI_Enh_DC()
GUI_Enh_2x2 = GUI_Enh_2x2(GUI_Enh_sensitivity, GUI_Enh_Resolution, GUI_Enh_DC)
GUI_Enh2 = GUI_Enh2(GUI_blankline_Enh, GUI_Enh_sensitivity, GUI_Enh_Resolution)

# Enh
GUI_Enh = GUI_Enh(GUI_Enh1, GUI_Enh2)

# Save
GUI_save_label = GUI_save_label()
GUI_save_name = GUI_save_name()
GUI_save_format = GUI_save_format()
GUI_save_button = GUI_save_button()
GUI_save_HBox = GUI_save_HBox(GUI_save_format, GUI_save_button)
GUI_save = GUI_save(GUI_save_label, GUI_save_name, GUI_save_HBox)

# bandpass
GUI_bandpass_label = GUI_bandpass_label()
GUI_bandpass_lowFrequency = GUI_bandpass_lowFrequency()
GUI_bandpass_highFrequency = GUI_bandpass_highFrequency()
GUI_bandpass_order = GUI_bandpass_order()
GUI_checkbox_Butterworth = GUI_checkbox_Butterworth()
GUI_checkbox_Cheby1 = GUI_checkbox_Cheby1()
GUI_checkbox_Cheby2 = GUI_checkbox_Cheby2()
GUI_vbox_setting = GUI_vbox_setting(GUI_bandpass_lowFrequency, GUI_bandpass_highFrequency)
GUI_vbox_filterType = GUI_vbox_filterType(GUI_checkbox_Butterworth, GUI_checkbox_Cheby1, GUI_checkbox_Cheby2)
GUI_bandpass_configure = GUI_bandpass_configure(GUI_vbox_setting, GUI_vbox_filterType)
GUI_bandpass = GUI_bandpass(GUI_bandpass_configure)

# FFT
GUI_FFT_label = GUI_FFT_label()
GUI_FFT_run_stop = GUI_FFT_run_stop()
GUI_FFT_ch = GUI_FFT_ch()
GUI_FFT = GUI_FFT(GUI_FFT_label, GUI_FFT_run_stop, GUI_FFT_ch)

def GUI_prop_init():

    GUI_TBtn_run_stop.button_style = 'danger'
    GUI_TBtn_arm.button_style = 'danger'
    GUI_TBtn_arm.disabled = False
    GUI_Enh_sensitivity.button_style = 'danger'
    GUI_Enh_Resolution.button_style = 'danger'
    GUI_Enh_DC.button_style = 'danger'
    GUI_save_button.disabled = False
    GUI_FFT_run_stop.button_style = 'danger'
    GUI_Exp_loop.botton_style = 'danger'
    GUI_Exp_loop.disabled = False
    GUI_chip_cfg_mixer_high_voltage.button_style = 'danger'
    GUI_chip_cfg_mixer_high_voltage.disabled = False
    GUI_chip_cfg_pll_high_voltage.button_style = 'danger'
    GUI_chip_cfg_pll_high_voltage.disabled = False
    fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.button_style = 'danger'
    fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.disabled = False    

    return

def GUI_plot():

    GUI_plot = go.FigureWidget(layout={'hovermode' : 'closest',
                            'height'    : round(0.3241*screen_height),
                            'width'     : round(0.4125*screen_width),
                            'margin'    :
                            {
                                't':0, 'b':20, 'l':0, 'r':0
                            },
                            'showlegend' : True,
                            'xaxis_title': 'Time(s)',
                            'yaxis_title': 'Voltage(mV)',
                            })

    Analog0_stream = [0]
    Analog1_stream = [0]

    GUI_plot.layout.yaxis.range = [-2500, 2500]
    GUI_plot.layout.xaxis.range = [0, 1]

    GUI_plot.add_trace(go.Scattergl(
        y = Analog0_stream,
        name = 'Channel 0',
        showlegend = True,)
                    )

    GUI_plot.add_trace(go.Scattergl(
        y = Analog1_stream,
        name = 'Channel 1',
        showlegend = True,)
                    )

    GUI_plot.update_layout(legend=dict(
        yanchor="top",
        y=0.99,
        xanchor="left",
        x=0.01
    ))

    return GUI_plot

def GUI_plot_FFT():

    GUI_plot_FFT = go.FigureWidget(layout={'hovermode' : 'closest',
                            'height'    : round(0.3241*screen_height),
                            'width'     : round(0.259375*screen_width),
                            'margin'    : 
                            {
                                't':0, 'b':20, 'l':0, 'r':0
                            },
                            'showlegend' : False,
                            'xaxis_title': 'Frequency',
                            'yaxis_title': 'Amplitude',
                            })

    GUI_plot_FFT.layout.yaxis.range = [0, 1]
    GUI_plot_FFT.layout.xaxis.range = [0, 10**6]
    normalization_half_y = [0]

    GUI_plot_FFT.add_trace(go.Scattergl(
        y = normalization_half_y,
        name = 'FFT',
        showlegend = True,
        visible = False,
    )
                    )
    GUI_plot_FFT.add_trace(go.Scattergl(
        y = normalization_half_y,
        name = 'T2',
        showlegend = True,
        visible = False,
    )
                    )
    GUI_plot_FFT.add_trace(go.Scattergl(
        y = normalization_half_y,
        name = 'T2_fit',
        showlegend = True,
        visible = False,
    )
                    )
    GUI_plot_FFT.add_annotation(
        x=5,  # x coordinate of annotation
        y=0.3,  # y coordinate of annotation
        text="T2 = %d" % 2,  # text content of annotation
        showarrow=False,  # hide arrow
        font=dict(size=16, color="red"),  # set text size and color
)
    GUI_plot_FFT.update_annotations(visible = False)
    return GUI_plot_FFT

def GUI_plot_3D():

    GUI_plot_3D = go.FigureWidget(data=go.Scatter3d(
    x=[0], y=[0], z=[0],
    marker=dict(
        size=4,
    #         color=z,
    #         colorscale='Viridis',
        ),
        line=dict(
            color='lightgreen',
            width=2
        )
    ))

    GUI_plot_3D.update_layout(
        width=1830,
        height=500,
        autosize=False,
        scene=dict(
            camera=dict(
                up=dict(
                    x=0,
                    y=0,
                    z=1
                ),
                eye=dict(
                    x=-0.2,
                    y=1,
                    z=0.2,
                )
            ),
            aspectmode = 'manual'
        ),
    )

    return GUI_plot_3D

"""
Functions for config Change
"""
#conf_dict['conf_token'] is an indicater for update the conf_paras.
#when this == 1, update all other Paras.
mmio = data_processing.mmio
conf_dict = all_of_the_parameters.conf_dict

# observe function for nmr_chip_cfg 
def on_value_change_GUI_chip_cfg_ref_current(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_nmr_chip_cfg_ref_curr'], change['new'])
        #config nmr chip
    ref_curr = mmio.read(conf_dict['conf_nmr_chip_cfg_ref_curr'])
    vga_gain = mmio.read(conf_dict['conf_nmr_chip_cfg_vga_gain'])
    pll_mult = mmio.read(conf_dict['conf_nmr_chip_cfg_pll_mult'])
    fpga_tracing_func.fpga_func_chip_cfg(ref_curr * 256 + vga_gain * 16 + pll_mult)

    return

def on_value_change_GUI_chip_cfg_vga_gain(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_nmr_chip_cfg_vga_gain'], change['new'])
        #config nmr chip
    ref_curr = mmio.read(conf_dict['conf_nmr_chip_cfg_ref_curr'])
    vga_gain = mmio.read(conf_dict['conf_nmr_chip_cfg_vga_gain'])
    pll_mult = mmio.read(conf_dict['conf_nmr_chip_cfg_pll_mult'])
    fpga_tracing_func.fpga_func_chip_cfg(ref_curr * 256 + vga_gain * 16 + pll_mult)

    return

def on_value_change_GUI_chip_cfg_pll_mult(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_nmr_chip_cfg_pll_mult'], change['new'])
        #config nmr chip
    ref_curr = mmio.read(conf_dict['conf_nmr_chip_cfg_ref_curr'])
    vga_gain = mmio.read(conf_dict['conf_nmr_chip_cfg_vga_gain'])
    pll_mult = mmio.read(conf_dict['conf_nmr_chip_cfg_pll_mult'])
    fpga_tracing_func.fpga_func_chip_cfg(ref_curr * 256 + vga_gain * 16 + pll_mult)

    return

# Send these command if Mixer button clicked


# -------------- 2. GUI Elements and Display Function -----------------

screen_width = all_of_the_parameters.screen_width

# Prescaler pll
spi_text_0 = widgets.IntText(value=3, description='pre_pll:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.024*screen_width))+'px'})
# PLL divider
spi_text_1 = widgets.IntText(value=7, description='pll_div:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.024*screen_width))+'px'})
# Pre tx 
spi_text_2 = widgets.IntText(value=2, description='pre_tx:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), min=1, style = {'description_width': str(round(0.024*screen_width))+'px'})
# TX shortening counter
spi_text_3 = widgets.IntText(value=4, description='tx_cnt:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.024*screen_width))+'px'})
# Deadtime hs_p
spi_text_4 = widgets.IntText(value=0, description='dt_hsp:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.024*screen_width))+'px'})
# Deadtime ls_p
spi_text_5 = widgets.IntText(value=0, description='dt_lsp:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.024*screen_width))+'px'})
# Deadtime hs_n
spi_text_6 = widgets.IntText(value=0, description='dt_hsn:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.024*screen_width))+'px'})
# Deadtime ls_n
spi_text_7 = widgets.IntText(value=0, description='dt_lsn:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.024*screen_width))+'px'})
# Deadtime comp_p
spi_text_8 = widgets.IntText(value=0, description='dt_com_p:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.030*screen_width))+'px'})
# Deadtime comp_n
spi_text_9 = widgets.IntText(value=0, description='dt_com_n:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.030*screen_width))+'px'})
# Delay p
spi_text_10 = widgets.IntText(value=0, description='delay_p:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.0274*screen_width))+'px'})
# Delay n
spi_text_11 = widgets.IntText(value=0, description='delay_n:', layout=widgets.Layout(width=str(round(0.055*screen_width))+'px', height='24px'), style = {'description_width': str(round(0.0274*screen_width))+'px'})

## 0.0573, 0.024/0.0274
## 0.045, 0.024/0.0274, too short textBox

# Combination
###########################################################
# config_boxes = widgets.HBox(
#     children = (spi_text_0,spi_text_1,spi_text_2,spi_text_3,spi_text_4,spi_text_5,spi_text_6,spi_text_7,spi_text_8,spi_text_9,spi_text_10,spi_text_11),
#     layout = widgets.Layout(
#         height='40px',
#         width=str(round(0.51667*screen_width))+'px',
#         border='solid 4px yellow',
#         margin='0px 5px 0px 0px',
#         padding='0px 0px 0px 0px'
#     ),
# )

pll_boxes = widgets.HBox(
    children = (spi_text_0,spi_text_1),
    layout = widgets.Layout(
        height='40px',
        width=str(round(0.156*screen_width))+'px',
        border='solid 4px yellow',
        margin='0px 5px 0px 0px',
        padding='0px 0px 0px 0px'
    ),
)



config_boxes = widgets.HBox(
    children = (spi_text_2,spi_text_3,spi_text_4,spi_text_5,spi_text_6,spi_text_7,spi_text_8,spi_text_9,spi_text_10,spi_text_11),
    layout = widgets.Layout(
        height='40px',
        width=str(round(0.6735*screen_width))+'px',
        border='solid 4px yellow',
        margin='0px 5px 0px 0px',
        padding='0px 0px 0px 0px'
    ),
)

#################################################################









def spi_init_cmd():
     
    # bit 53 pll_or_spi_out is don't care bit, bit 54 also
    
    # update mixer on/off
    if (GUI_chip_cfg_mixer_high_voltage.value == True):
        mixer_flag = 0
    else:
        mixer_flag = 1

    # update pll on/off
    if (GUI_chip_cfg_pll_high_voltage.value == True):
        pll_flag = 0
    else:
        pll_flag = 1    
    
    
    # update if amplifier on/off
    if (fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.value == True):
        gain_flag = 0
    elif (fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.value == False):
        gain_flag = 1
    else:
        print('Value error!')
    # # update pll parameter
    # if (spi_text_5.value == 0):
    #     pll_flag = 0
    # else:
    #     pll_flag = 1    
    
    # first
    fpga_tracing_func.clear_register() 
    fpga_tracing_func.spi_write_pll_en(pll_flag)
    fpga_tracing_func.spi_write_gain(gain_flag)
    fpga_tracing_func.spi_write_skip_mixer(mixer_flag)   
    fpga_tracing_func.spi_write_prescaler_pll(spi_text_0.value)    
    fpga_tracing_func.spi_write_N_divider_pll(spi_text_1.value)
    fpga_tracing_func.spi_write_prescaler_tx_logic(spi_text_2.value)
    fpga_tracing_func.spi_write_tx_shortening_counter(spi_text_3.value)    
    fpga_tracing_func.spi_write_deadtime_hs_p(spi_text_4.value)
    fpga_tracing_func.spi_write_deadtime_ls_p(spi_text_5.value)
    fpga_tracing_func.spi_write_deadtime_hs_n(spi_text_6.value)
    fpga_tracing_func.spi_write_deadtime_ls_n(spi_text_7.value)
    fpga_tracing_func.spi_write_deadtime_comp_p(spi_text_8.value)
    fpga_tracing_func.spi_write_deadtime_comp_n(spi_text_9.value)
    fpga_tracing_func.spi_write_delay_p(spi_text_10.value)
    fpga_tracing_func.spi_write_delay_n(spi_text_11.value)
    fpga_tracing_func.spi_write_amplifier_reset(1)
    fpga_tracing_func.spi_write_start(1)
    time.sleep(1)

    # second
    fpga_tracing_func.clear_register() 
    fpga_tracing_func.spi_write_pll_en(pll_flag)
    fpga_tracing_func.spi_write_gain(gain_flag)
    fpga_tracing_func.spi_write_skip_mixer(mixer_flag)   
    fpga_tracing_func.spi_write_prescaler_pll(spi_text_0.value)    
    fpga_tracing_func.spi_write_N_divider_pll(spi_text_1.value)
    fpga_tracing_func.spi_write_prescaler_tx_logic(spi_text_2.value)
    fpga_tracing_func.spi_write_tx_shortening_counter(spi_text_3.value)    
    fpga_tracing_func.spi_write_deadtime_hs_p(spi_text_4.value)
    fpga_tracing_func.spi_write_deadtime_ls_p(spi_text_5.value)
    fpga_tracing_func.spi_write_deadtime_hs_n(spi_text_6.value)
    fpga_tracing_func.spi_write_deadtime_ls_n(spi_text_7.value)
    fpga_tracing_func.spi_write_deadtime_comp_p(spi_text_8.value)
    fpga_tracing_func.spi_write_deadtime_comp_n(spi_text_9.value)
    fpga_tracing_func.spi_write_delay_p(spi_text_10.value)
    fpga_tracing_func.spi_write_delay_n(spi_text_11.value)
    fpga_tracing_func.spi_write_amplifier_reset(0)
    fpga_tracing_func.spi_write_start(1)
    time.sleep(1)

    # third
    fpga_tracing_func.clear_register() 
    fpga_tracing_func.spi_write_pll_en(pll_flag)
    fpga_tracing_func.spi_write_gain(gain_flag)
    fpga_tracing_func.spi_write_skip_mixer(mixer_flag)   
    fpga_tracing_func.spi_write_prescaler_pll(spi_text_0.value)    
    fpga_tracing_func.spi_write_N_divider_pll(spi_text_1.value)
    fpga_tracing_func.spi_write_prescaler_tx_logic(spi_text_2.value)
    fpga_tracing_func.spi_write_tx_shortening_counter(spi_text_3.value)    
    fpga_tracing_func.spi_write_deadtime_hs_p(spi_text_4.value)
    fpga_tracing_func.spi_write_deadtime_ls_p(spi_text_5.value)
    fpga_tracing_func.spi_write_deadtime_hs_n(spi_text_6.value)
    fpga_tracing_func.spi_write_deadtime_ls_n(spi_text_7.value)
    fpga_tracing_func.spi_write_deadtime_comp_p(spi_text_8.value)
    fpga_tracing_func.spi_write_deadtime_comp_n(spi_text_9.value)
    fpga_tracing_func.spi_write_delay_p(spi_text_10.value)
    fpga_tracing_func.spi_write_delay_n(spi_text_11.value)
    fpga_tracing_func.spi_write_amplifier_reset(0)
    fpga_tracing_func.spi_write_start(1)
    time.sleep(1)

def on_value_change_mixer(change): # when mixer clicked, update SPI data

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_nmr_cfg_mixer_high_voltage'], 1)
        GUI_chip_cfg_mixer_high_voltage.button_style = 'success'
        # GUI_chip_cfg_mixer_high_voltage.description='Mixer on'
        GUI_chip_cfg_mixer_high_voltage.description='Mixer'
        fpga_tracing_func.clear_register()
        spi_init_cmd()
    elif change['new'] == False:
        mmio.write(conf_dict['conf_nmr_cfg_mixer_high_voltage'], 0)
        GUI_chip_cfg_mixer_high_voltage.button_style = 'danger'
        GUI_chip_cfg_mixer_high_voltage.description='Mixer'
        spi_init_cmd()
    else:
        pass
    return

def on_value_change_pll(change): # when mixer clicked, update SPI data

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_nmr_cfg_pll_high_voltage'], 1)
        GUI_chip_cfg_pll_high_voltage.button_style = 'danger' # 'success'
        GUI_chip_cfg_pll_high_voltage.description='PLL'
        fpga_tracing_func.clear_register()
        spi_init_cmd()
    elif change['new'] == False:
        mmio.write(conf_dict['conf_nmr_cfg_pll_high_voltage'], 0)
        GUI_chip_cfg_pll_high_voltage.button_style = 'success' # 'danger'
        GUI_chip_cfg_pll_high_voltage.description='PLL'
        spi_init_cmd()
    else:
        pass
    return

def on_value_change_if_amp(change): # when if_amp button clicked, update SPI if_amp data

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_nmr_cfg_if_amp_high_voltage'], 1)
        fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.button_style = 'success'
        fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.description='IF Amplifier'
        spi_init_cmd()
    elif change['new'] == False:
        mmio.write(conf_dict['conf_nmr_cfg_if_amp_high_voltage'], 0)
        fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.button_style = 'danger'
        fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.description='IF Amplifier'
        spi_init_cmd()
    else:
        pass
    return



# observe function for tracing 
def on_value_change_GUI_run_stop(change):

    trigger  = GUI_TBtn_arm.value # 0 = RX synchronized, 1 = not RX synchronized
    mmio.write(conf_dict['conf_token'], 1)
    if trigger == 0: # not trigger
        if change['new'] == True: # 0 = disable, 1 = enable
            mmio.write(conf_dict['conf_onoff'], 1)
            GUI_TBtn_run_stop.button_style = 'success'
            GUI_TBtn_run_stop.description='Run/Stop'
        elif change['new'] == False: 
            mmio.write(conf_dict['conf_onoff'], 0)
            GUI_TBtn_run_stop.button_style = 'danger'
            GUI_TBtn_run_stop.description='Run/Stop'    
    if trigger == 1: #trigger
        if change['new'] == True: # 0 = disable, 1 = enable
            mmio.write(conf_dict['conf_onoff'], 1)
            GUI_TBtn_run_stop.button_style = 'warning'
            GUI_TBtn_run_stop.description='Single'
        elif change['new'] == False: 
            mmio.write(conf_dict['conf_onoff'], 0)
            GUI_TBtn_run_stop.button_style = 'warning'
            GUI_TBtn_run_stop.description='Single' 

    return

def on_value_change_Trigger_Activate(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True: # 0 = 'arm', 1 = 'singleshot'
        mmio.write(conf_dict['conf_trigger'], 0) # triggered
        mmio.write(conf_dict['conf_dig_ris'], 1)
        GUI_TBtn_arm.button_style = 'success'
        GUI_TBtn_arm.description='RX Synchronized'
#         GUI_TBtn_run_stop.value = False
#         GUI_TBtn_run_stop.description='Single'
#         GUI_TBtn_run_stop.button_style = 'warning'
    elif change['new'] == False:
        mmio.write(conf_dict['conf_trigger'], 1) # not triggered
        mmio.write(conf_dict['conf_dig_ris'], 0)
        GUI_TBtn_arm.button_style = 'danger'
        GUI_TBtn_arm.description='Unsynchronized'
#         GUI_TBtn_run_stop.description='Run/Stop'
#         GUI_TBtn_run_stop.button_style = 'danger'
#         GUI_TBtn_run_stop.value = False

    return

def on_value_change_ana_ris(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_ana_ris'], 1)
        GUI_TBtn_arm.disabled = False
        GUI_checkbox_dig_ris.value = False
        GUI_checkbox_dig_fal.value = False
    elif change['new'] == False:
        mmio.write(conf_dict['conf_ana_ris'], 0)
        if (
            GUI_checkbox_ana_ris.value == False and
            GUI_checkbox_ana_fal.value == False and
            GUI_checkbox_dig_ris.value == False and
            GUI_checkbox_dig_fal.value == False
        ):
            GUI_TBtn_arm.disabled = True
            GUI_TBtn_arm.value = False

    return

def on_value_change_ana_fal(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_ana_fal'], 1)
        GUI_TBtn_arm.disabled = False
        GUI_checkbox_dig_ris.value = False
        GUI_checkbox_dig_fal.value = False
    elif change['new'] == False:
        mmio.write(conf_dict['conf_ana_fal'], 0)
        if (
            GUI_checkbox_ana_ris.value == False and
            GUI_checkbox_ana_fal.value == False and
            GUI_checkbox_dig_ris.value == False and
            GUI_checkbox_dig_fal.value == False
        ):
            GUI_TBtn_arm.disabled = True
            GUI_TBtn_arm.value = False

    return

def on_value_change_ana_ch(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_ana_ch'], change['new'])

    return

def on_value_change_ana_TL(change):

    mmio.write(conf_dict['conf_token'], 1)
    trigger_level = int(change['new']) * sample_size
    mmio.write(conf_dict['conf_ana_tl'], trigger_level)

    return

def on_value_change_dig_ris(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_dig_ris'], 1)
        GUI_TBtn_arm.disabled = False
        GUI_checkbox_ana_ris.value = False
        GUI_checkbox_ana_fal.value = False
    elif change['new'] == False:
        mmio.write(conf_dict['conf_dig_ris'], 0)
        if (
            GUI_checkbox_ana_ris.value == False and
            GUI_checkbox_ana_fal.value == False and
            GUI_checkbox_dig_ris.value == False and
            GUI_checkbox_dig_fal.value == False
        ):
            GUI_TBtn_arm.disabled = False
            GUI_TBtn_arm.value = False

    return

def on_value_change_dig_fal(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_dig_fal'], 1)
        GUI_TBtn_arm.disabled = False
        GUI_checkbox_ana_ris.value = False
        GUI_checkbox_ana_fal.value = False
    elif change['new'] == False:
        mmio.write(conf_dict['conf_dig_fal'], 0)
        if (
            GUI_checkbox_ana_ris.value == False and
            GUI_checkbox_ana_fal.value == False and
            GUI_checkbox_dig_ris.value == False and
            GUI_checkbox_dig_fal.value == False
        ):
            GUI_TBtn_arm.disabled = True
            GUI_TBtn_arm.value = False

    return

def on_value_change_Scale(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_scale'], change['new'])

    return

def on_value_change_samples(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_nr_sample'], change['new'])

    return

def on_value_change_nr_rx(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_nr_rx_pulse'], change['new'])

    return

def on_value_change_Position(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_position'], change['new'])

    return
    
def on_value_change_fft_ch(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_fft_ch'], change['new'])

    return

def on_value_change_fft_onoff(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_fft_onoff'], 1)
        GUI_FFT_run_stop.button_style = 'success'
    else: 
        mmio.write(conf_dict['conf_fft_onoff'], 0)
        GUI_FFT_run_stop.button_style = 'danger'

    return

def on_value_change_enh_ch(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_enh_ch'], change['new'])

    return

def on_value_change_enh_sen(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        GUI_Enh_sensitivity.button_style = 'success'
        mmio.write(conf_dict['conf_enh_sen'], 1)
    elif change['new'] == False:
        GUI_Enh_sensitivity.button_style = 'danger'
        mmio.write(conf_dict['conf_enh_sen'], 0)

    return

def on_value_change_enh_res(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        GUI_Enh_Resolution.button_style = 'success'
        mmio.write(conf_dict['conf_enh_res'], 1)
    elif change['new'] == False:
        GUI_Enh_Resolution.button_style = 'danger'
        mmio.write(conf_dict['conf_enh_res'], 0)

    return

def on_value_change_enh_tau(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_enh_tau'], change['new'])

    return

def on_value_change_enh_dc(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        GUI_Enh_DC.button_style = 'success'
        mmio.write(conf_dict['conf_enh_dc'], 1)
    elif change['new'] == False:
        GUI_Enh_DC.button_style = 'danger'
        mmio.write(conf_dict['conf_enh_dc'], 0)

    return

def on_value_change_bp_low_value(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_enh_bp_low_value'], change['new'])

    return

def on_value_change_bp_high_value(change):

    mmio.write(conf_dict['conf_token'], 1)
    mmio.write(conf_dict['conf_enh_bp_high_value'], change['new'])

    return

def on_value_change_bp_low_cb(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_enh_bp_low_cb'], 1)
    elif change['new'] == False:
        mmio.write(conf_dict['conf_enh_bp_low_cb'], 0)

    return

def on_value_change_bp_high_cb(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True:
        mmio.write(conf_dict['conf_enh_bp_high_cb'], 1)
    elif change['new'] == False:
        mmio.write(conf_dict['conf_enh_bp_high_cb'], 0)

    return

def on_save_btn_click(self):    

    mmio.write(conf_dict['conf_save_file'], 1)

    return

# observe function for bandpass filter type, mutual exclusive

# Define a function to handle the selected state change event of the check box
def on_checkbox_bandpass_change(change, filter_type):
    
    mmio.write(conf_dict['conf_token'], 1)
    
    # If checkbox 1 is checked, uncheck checkbox 2 and checkbox 3
    if change['owner'] == GUI_checkbox_Butterworth and change['new']:
        GUI_checkbox_Cheby1.value = False
        GUI_checkbox_Cheby2.value = False
    # If checkbox 2 is checked, uncheck checkbox 1 and checkbox 3
    elif change['owner'] == GUI_checkbox_Cheby1 and change['new']:
        GUI_checkbox_Butterworth.value = False
        GUI_checkbox_Cheby2.value = False
    # If checkbox 3 is checked, uncheck checkbox 1 and checkbox 2
    elif change['owner'] == GUI_checkbox_Cheby2 and change['new']:
        GUI_checkbox_Butterworth.value = False
        GUI_checkbox_Cheby1.value = False
    mmio.write(conf_dict['conf_bandpass_filter'], filter_type)
    if not GUI_checkbox_Butterworth.value and not GUI_checkbox_Cheby1.value and not GUI_checkbox_Cheby2.value:
        mmio.write(conf_dict['conf_bandpass_filter'], 0)

# control experiment loop function        
def on_value_change_Exp_loop(change):

    mmio.write(conf_dict['conf_token'], 1)
    if change['new'] == True: # 0 = loop, 1 = stop
        mmio.write(conf_dict['conf_loop_stop'], 0)
        GUI_Exp_loop.button_style = 'success'
        GUI_Exp_loop.description='Loop On'
    elif change['new'] == False:
        mmio.write(conf_dict['conf_loop_stop'], 1)
        GUI_Exp_loop.button_style = 'danger'
        GUI_Exp_loop.description='Loop Off'

    return


# update chip config for Heiko's SPI

def on_value_change_spi_config(change):

    spi_init_cmd()
        
    return



# observing spi_chip_config GUI element

spi_text_0.observe(on_value_change_spi_config, names='value')
spi_text_1.observe(on_value_change_spi_config, names='value')
spi_text_2.observe(on_value_change_spi_config, names='value')
spi_text_3.observe(on_value_change_spi_config, names='value')
spi_text_4.observe(on_value_change_spi_config, names='value')
spi_text_5.observe(on_value_change_spi_config, names='value')
spi_text_6.observe(on_value_change_spi_config, names='value')
spi_text_7.observe(on_value_change_spi_config, names='value')
spi_text_8.observe(on_value_change_spi_config, names='value')
spi_text_9.observe(on_value_change_spi_config, names='value')
spi_text_10.observe(on_value_change_spi_config, names='value')
spi_text_11.observe(on_value_change_spi_config, names='value')

# observing nmr_chip_cfg GUI element
GUI_chip_cfg_ref_current.observe(on_value_change_GUI_chip_cfg_ref_current, names='value')
GUI_chip_cfg_vga_gain.observe(on_value_change_GUI_chip_cfg_vga_gain, names='value')
GUI_chip_cfg_pll_mult.observe(on_value_change_GUI_chip_cfg_pll_mult, names='value')
GUI_chip_cfg_mixer_high_voltage.observe(on_value_change_mixer, names='value')
GUI_chip_cfg_pll_high_voltage.observe(on_value_change_pll, names='value')
fpga_tracing_func.GUI_chip_cfg_if_amp_high_voltage.observe(on_value_change_if_amp, names='value')


# observing tracing GUI element
GUI_TBtn_arm.observe(on_value_change_Trigger_Activate, names='value')
GUI_Exp_loop.observe(on_value_change_Exp_loop, names='value')
GUI_Dropdown_Enh_ch.observe(on_value_change_enh_ch, names='value')
GUI_Enh_tau.observe(on_value_change_enh_tau, names='value')
GUI_Enh_DC.observe(on_value_change_enh_dc, names='value')
GUI_Enh_sensitivity.observe(on_value_change_enh_sen, names='value')
GUI_Enh_Resolution.observe(on_value_change_enh_res, names='value')

# observing Bandpass Filter GUI element
GUI_checkbox_Butterworth.observe(lambda change: on_checkbox_bandpass_change(change, 2), names='value')
GUI_checkbox_Cheby1.observe(lambda change: on_checkbox_bandpass_change(change, 3), names='value')
GUI_checkbox_Cheby2.observe(lambda change: on_checkbox_bandpass_change(change, 4), names='value')

GUI_Scale.observe(on_value_change_Scale, names='value')
GUI_set_nr_samples.observe(on_value_change_samples, names='value')


GUI_FFT_ch.observe(on_value_change_fft_ch, names='value')
GUI_FFT_run_stop.observe(on_value_change_fft_onoff, names='value')

GUI_save_button.on_click(on_save_btn_click)