Change CPMG visualization time into total time instead of only acquisition time (RX).
Change location: main.py line 132.

In progress.

2024/02/06: modify web_GUI_pulse_gen.py L641 change mux.

2024/02/07: modify main L135 2 changed into 4. Should be 4 (bytes), don't know why changed and CPMG not identical to FID.

2024/02/08: modify main L706 func_plot_data. Plot voltage calibration.

2024/02/13: modify frequency and p90 according to pynq zu in pulse_gen.

2024/02/21: change TX into phase coherent. RX only frequency shift.

2024/02/23:  1. add CPMG filter.
         2. web_GUI_config L243. Change logo.
         3. add IF Amp button in tracing and corresponding function. L449.
         4. change two spi config function into 1. Old version: Effectiveness needs to be checked.
         
---------------------------------------------------------------------
def spi_mixer_off():
    
    # update if amp on/off
    if (GUI_chip_cfg_if_amp_high_voltage.value == True):
        gain_flag = 0
    elif (GUI_chip_cfg_if_amp_high_voltage.value == False):
        gain_flag = 1
    else:
        print('Value error!')

    # update pll parameter
    if (spi_text_5.value == 0):
        pll_flag = 0
    else:
        pll_flag = 1
    
    # first
    clear_register()
    # reverse spi bit order
    spi_write_amplifier_reset(1)
    spi_write_delay_n(spi_text_0.value)
    spi_write_delay_p(spi_text_0.value)
    spi_write_deadtime_comp_n(spi_text_1.value)
    spi_write_deadtime_comp_p(spi_text_1.value)
    spi_write_deadtime_ls_n(spi_text_2.value)
    spi_write_deadtime_hs_n(spi_text_2.value)
    spi_write_deadtime_ls_p(spi_text_2.value)
    spi_write_deadtime_hs_p(spi_text_2.value)
    spi_write_tx_shortening_counter(spi_text_3.value)
    spi_write_prescaler_tx_logic(spi_text_4.value)
    spi_write_N_divider_pll(spi_text_5.value)
    spi_write_skip_mixer(1)
    spi_write_gain(gain_flag)
    spi_write_pll_en(pll_flag)
    spi_write_start(1)
    time.sleep(1)
  
    # second
    clear_register()
    spi_write_amplifier_reset(0)
    spi_write_delay_n(spi_text_0.value)
    spi_write_delay_p(spi_text_0.value)
    spi_write_deadtime_comp_n(spi_text_1.value)
    spi_write_deadtime_comp_p(spi_text_1.value)
    spi_write_deadtime_ls_n(spi_text_2.value)
    spi_write_deadtime_hs_n(spi_text_2.value)
    spi_write_deadtime_ls_p(spi_text_2.value)
    spi_write_deadtime_hs_p(spi_text_2.value)
    spi_write_tx_shortening_counter(spi_text_3.value)
    spi_write_prescaler_tx_logic(spi_text_4.value)
    spi_write_N_divider_pll(spi_text_5.value)
    spi_write_skip_mixer(1)
    spi_write_gain(gain_flag)
    spi_write_pll_en(pll_flag)
    spi_write_start(1)
    time.sleep(1)

    # third
    clear_register() 
    spi_write_amplifier_reset(0)
    spi_write_delay_n(spi_text_0.value)
    spi_write_delay_p(spi_text_0.value)
    spi_write_deadtime_comp_n(spi_text_1.value)
    spi_write_deadtime_comp_p(spi_text_1.value)
    spi_write_deadtime_ls_n(spi_text_2.value)
    spi_write_deadtime_hs_n(spi_text_2.value)
    spi_write_deadtime_ls_p(spi_text_2.value)
    spi_write_deadtime_hs_p(spi_text_2.value)
    spi_write_tx_shortening_counter(spi_text_3.value)
    spi_write_prescaler_tx_logic(spi_text_4.value)
    spi_write_N_divider_pll(spi_text_5.value)
    spi_write_skip_mixer(1)
    spi_write_gain(gain_flag)
    spi_write_pll_en(pll_flag)
    spi_write_start(1)
    time.sleep(1)            
---------------------------------------------------------------------            
            