----------------------------------------------------------------------------------
-- Company: university of stuttgart
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 16.03.2023 13:41:01
-- Design Name: PID magnet controller
-- Module Name: fpga_pid_controller - Behavioral
-- Project Name: NMR - Spectrometer
-- Target Devices: PYNQ Z2
-- Tool Versions: 2020.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
USE ieee.math_real.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity fpga_pid_controller is
    generic 
    (
        C_S_AXI_DATA_WIDTH	: integer	:= 32
    );
    Port 
    ( 
        clk 		: in std_logic;
        -- rest low enable
        rst_n 		: in std_logic;
        -- PID controller
        iv_Kp                   : in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
        iv_Ki                   : in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
        iv_Kd                   : in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
        iv_time                 : in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
        iv_time_safety	        : in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
        iv_voltage_safety 	    : in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0); 
        iv_target_value 	    : in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
        iv_actual_value 	    : in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
        ov_export_value         : out std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0);
		i_pid_en				: in std_logic;
		o_done					: out std_logic
    );
end fpga_pid_controller;

architecture Behavioral of fpga_pid_controller is
    
    -- -- reference voltage high
    -- constant
        -- C_V_REF_H
        -- : real := 4987.0;
        
    -- -- reference voltage low     
    -- constant
        -- C_V_REF_L
        -- : real := 2.5;
        
    -- -- calculate the real voltage with unit in mv to the digital code
    -- constant
        -- C0
        -- :integer := integer(ceil(real(2**17)/(C_V_REF_H - C_V_REF_L))); 
    -- constant
        -- C1
        -- :integer := integer(ceil((real(2**18)*C_V_REF_L)/(C_V_REF_H - C_V_REF_L))); 

  
    signal
        Kp,
        Ki,
        Kd,
        Kp_reg,
        Ki_reg,
        Kd_reg,        
        time_i,
        time_safety,
        voltage_safety,
        -- d1_voltage_safety,
        -- d2_voltage_safety,
        voltage_safety_reg,
        target_value,
        actual_value,
        result,
        abs_result
        : integer := 0;
    
    signal

        pid_kp,
        pid_ki,
        pid_kd,
        pid_error,
        pid_integral,
        pid_derivative,
        pid_actual_value,
        pid_target_value,
        pid_out_value
        : integer := 0;
        
    signal
        d_pid_error,
        d_pid_Kd,
        d_pid_Ki
        : integer := 0;
        
    signal
        c_time_safety,
        cnt_time_safety,
        cnt_time_delay        
        : integer := 0;
        
    type t_state is
    (
        s_idle,
        s_read_actual_parameter,
        s_calculate,
        s_safety_execute,
        s_delay    
    );
    
    signal
    state : t_state := s_idle;
    
begin

    process(clk)
    begin
        if rising_edge (clk) then 
        
            if (rst_n = '0') then
            
                Kp              <= 0;
                Ki              <= 0;
                Kd              <= 0;
                time_i          <= 0;
                time_safety     <= 0;
                voltage_safety  <= 0;
				-- d1_voltage_safety <= 0;
				-- d2_voltage_safety <= 0;
                target_value    <= 0;
                actual_value    <= 0;
                
                Kp_reg          <= 0;
                Ki_reg          <= 0;
                Kd_reg          <= 0;
                voltage_safety_reg <= 0;
                
                pid_kp          <= 0;
                pid_ki          <= 0;
                pid_kd          <= 0;
                pid_error       <= 0;
                pid_integral    <= 0;
                pid_derivative  <= 0;
                
                d_pid_error     <= 0;
                d_pid_Kd        <= 0;
                d_pid_Ki        <= 0;
                
                result          <= 0;
                abs_result      <= 0;

--              interface to DAC                
                pid_out_value   <= 0;
                
                c_time_safety   <= 0;
                cnt_time_safety <= 0;

                cnt_time_delay  <= 0;
                
                state           <= s_idle;
            else
                Kp              <= to_integer(signed(iv_Kp));
                Ki              <= to_integer(signed(iv_Ki));
                Kd              <= to_integer(signed(iv_Kd));
                time_i          <= to_integer(signed(iv_time));
				
                time_safety     <= to_integer(signed(iv_time_safety));
                voltage_safety  <= to_integer(signed(iv_voltage_safety));
				-- d1_voltage_safety <= voltage_safety * C0;
				-- d2_voltage_safety <= d1_voltage_safety - C1;
				
                actual_value    <= to_integer(signed(iv_actual_value));				
                target_value    <= to_integer(signed(iv_target_value));

				o_done 			<= '0';
				
                case (state) is
                
                    when s_idle =>
                    
                        Kp_reg              <= 0;
                        Ki_reg              <= 0;
                        Kd_reg              <= 0;
                        voltage_safety_reg  <= 0;      
                            
                        pid_kp          <= 0;
                        pid_ki          <= 0;
                        pid_kd          <= 0;
                        pid_error       <= 0;
                        pid_integral    <= 0;
                        pid_derivative  <= 0;
                        
                        d_pid_error     <= 0;
                        d_pid_Kd        <= 0;
                        d_pid_Ki        <= 0;
                        
                        result          <= 0;
                        abs_result      <= 0;
                        
                        pid_out_value   <= 0;
                        
                        c_time_safety   <= 0; 
                        cnt_time_safety <= 0;
                        
                        cnt_time_delay  <= 0;
					    if i_pid_en = '1' then 	
							state           <= s_read_actual_parameter;
                        else
							state           <= s_idle;
						end if;
						
                    when s_read_actual_parameter =>
					
						if i_pid_en = '1' then                    
							pid_actual_value 	<= actual_value;
							pid_target_value 	<= target_value;

							Kp_reg              <= Kp;
							Ki_reg              <= Ki;
							Kd_reg              <= Kd;
							voltage_safety_reg  <= voltage_safety;
							
							c_time_safety       <= time_safety;
							cnt_time_safety     <= time_safety;
							
							cnt_time_delay      <= time_i;
							state               <= s_calculate;
						else 
							state <= s_idle;
						end if;	
						
                    when s_calculate =>
					
						if i_pid_en = '1' then                        
							d_pid_error     <= pid_error;
							d_pid_Kd        <= pid_derivative;
							d_pid_Ki        <= pid_integral;
							
							pid_error       <= pid_target_value - pid_actual_value;
							pid_integral    <= pid_error + d_pid_ki;
							pid_derivative  <= pid_error - d_pid_error;
							
							pid_kp          <= Kp_reg * pid_error;
							pid_ki          <= Ki_reg * pid_integral;
							pid_kd          <= Kd_reg * pid_derivative;
				  
							result          <= pid_kp + pid_ki + pid_kd;
							abs_result      <= abs(pid_kp + pid_ki + pid_kd);
							
							state           <= s_safety_execute;
						else 
							state <= s_idle;
						end if;	
						
                    when s_safety_execute => 
                                              
                        if (cnt_time_safety > 0) then 
                            cnt_time_safety <= cnt_time_safety - 1;
                            state           <= s_safety_execute;
                        else
                            if (abs_result > voltage_safety) then
                            
                                if (result > 0) then 
                                    result          <= result - voltage_safety_reg;
                                    pid_out_value   <= pid_out_value + voltage_safety_reg;
                                else
                                    result          <= result + voltage_safety_reg;
                                    pid_out_value   <= pid_out_value - voltage_safety_reg;                        
                                end if;
                                cnt_time_safety     <= c_time_safety;
                                abs_result          <= abs_result - voltage_safety_reg;
                                state               <= s_safety_execute;
        
                            else
                                result          <= result;
                                pid_out_value   <= pid_out_value + result;
                                state           <= s_delay;    
                            end if;   
                        end if;
                    
                    when s_delay =>
					
						if i_pid_en = '1' then
						
							if (cnt_time_delay > 0) then 
								cnt_time_delay <= cnt_time_delay - 1;
								state <= s_delay;
							else
									state <= s_read_actual_parameter;
								o_done 			<= '1';
							end if;
							
						else 
							state <= s_idle;
						end if;
						
                end case;
            end if;
        end if;    
    end process;
    
    ov_export_value <= std_logic_vector(to_signed(pid_out_value,ov_export_value'length));
    
end Behavioral;
