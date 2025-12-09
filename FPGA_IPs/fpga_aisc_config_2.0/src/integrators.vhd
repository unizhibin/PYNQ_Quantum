----------------------------------------------------------------------------------
-- Title: Entity integrators
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: CIC Filter
--
-- Target Devices: 
-- Tool Versions: 
-- Description: N order integrator (stages) by re-using only one block. (Save space)
--
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/8/22 12:54
--  Version 2.0 -rm variable, Zhibin Zhao, 2024/03/23 18:50
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY integrators IS
	GENERIC (
		Nbit : integer	:= 32;			-- Integrator input data width
		Ibit : integer  := 64;			-- Internal result data width
		Mbit : integer	:= 18;			-- Integrator output data width
		bus_width : integer := 32;		-- Data bus width
		buffer_depth : integer := 16	-- Store result from all stages, should be larger than N_max (highest order of CIC)
	);
	PORT (
		M      				: IN std_logic_vector(bus_width - 1 DOWNTO 0);-- of integrator blocks (order of CIC filter)
		clk					: IN std_logic;
		rstn				: IN std_logic;
		i_integrators_ready : IN std_logic; 
		iv_integrators 		: IN std_logic_vector(Nbit - 1 DOWNTO 0);
		ov_integrators 		: OUT std_logic_vector(Mbit - 1 DOWNTO 0)-- Output valid only when all N stages are processed
	);
END integrators;

ARCHITECTURE Behavioral OF integrators IS

	TYPE result_buffer_type IS ARRAY(buffer_depth - 1 DOWNTO 0) OF std_logic_vector(bus_width - 1 DOWNTO 0);
	SIGNAL result_buffer : result_buffer_type;					-- Initialization of internal result buffer
	SIGNAL d1_iv_integrator : std_logic_vector(Nbit - 1 DOWNTO 0):= (others=>'0');
		
		
BEGIN

	-- Equation of each integrator stage: y(n+1) = y(n) + x(n), n - time index
	
	counter_proc : PROCESS(clk)
	BEGIN 
		IF rising_edge(clk) THEN
			IF rstn = '0' THEN
				d1_iv_integrator <= (others =>'0');
			ELSE				
				d1_iv_integrator <= iv_integrators;
			END IF;
		END IF;
	END PROCESS;

	integration_proc : PROCESS(clk)

	BEGIN
		IF rising_edge(clk) THEN
			IF rstn = '0' THEN
				ov_integrators 				<= (OTHERS => '0');
				result_buffer 				<= (OTHERS => (OTHERS=>'0'));									-- Update order of CIC			
			ELSE
				ov_integrators				<= 	std_logic_vector(to_signed(to_integer(signed(result_buffer(to_integer(unsigned(M))))),ov_integrators'length));
				IF i_integrators_ready = '1' THEN
					result_buffer(0) 		<= std_logic_vector(shift_right((signed(result_buffer(0)) + resize(signed(iv_integrators),bus_width)),1));
					for I in 0 to (buffer_depth - 2) Loop  
						result_buffer(I+1) 	<= std_logic_vector(shift_right(signed((result_buffer(I + 1) + result_buffer(I))),1));
					end loop;
				ELSE
					result_buffer <= result_buffer;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
END Behavioral;