----------------------------------------------------------------------------------
-- Title: Entity cic_filter
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng 
-- 
-- Project Name: CIC Filter 
--
-- Target Devices: 
-- Tool Versions: 
-- Description: low pass filter, integrator + decimation + comb
--
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2024/11/11 21:13
--  Version 0.2 Modify file, Yichao Peng, 2024/11/13 00:10
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.numeric_std.ALL;

ENTITY CIC_Filter_v2 IS
    GENERIC (
        N : integer := 3;          -- Number of integrator and comb stages
        R : integer := 5;          -- Decimation factor
        DATA_WIDTH : integer := 16 -- Data bit width
    );
    PORT (
        clk 	: IN STD_LOGIC;
        rstn 	: IN STD_LOGIC;
        iv_cic 	: IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
        ov_cic 	: OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
    );
END CIC_Filter_v2;

ARCHITECTURE Behavioral OF CIC_Filter_v2 IS

    -- Define integrator register
    TYPE integrator_array IS ARRAY (0 TO N-1) OF STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL integrator : integrator_array := (OTHERS => (OTHERS => '0'));

    -- Define comb filter register
    TYPE comb_array IS ARRAY (0 TO N-1) OF STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    SIGNAL comb : comb_array := (OTHERS => (OTHERS => '0'));
    -- SIGNAL comb_delay : comb_array := (OTHERS => (OTHERS => '0')); -- Used to store previous comb values

    -- Decimation counter
    SIGNAL sample_counter : integer RANGE 0 TO R-1 := 0;
    -- SIGNAL temp_output : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

BEGIN

    PROCESS(clk, rstn)
		-- VARIABLE sample_counter : integer RANGE 0 TO R-1 := 0;
		-- VARIABLE sample_counter : integer := 0;
    BEGIN
        IF rstn = '0' THEN
            -- reset all registers
            integrator <= (OTHERS => (OTHERS => '0'));
            comb <= (OTHERS => (OTHERS => '0'));
            -- comb_delay <= (OTHERS => (OTHERS => '0'));
            sample_counter <= 0;
            -- temp_output <= (OTHERS => '0');
            ov_cic <= (OTHERS => '0');

        ELSIF rising_edge(clk) THEN
		
            -- Integrator stage
            integrator(0) <= integrator(0) + std_logic_vector(to_signed(to_integer(signed(iv_cic))*2-1, DATA_WIDTH));
            FOR j IN 1 TO N-1 LOOP
                integrator(j) <= std_logic_vector(signed(integrator(j)) + signed(integrator(j-1)));
            END LOOP;
			
            -- Decimation stage
            IF (sample_counter+1) mod R = 0 THEN
				-- Comb stage
				comb(0) <= integrator(N-1);
				FOR j IN 1 TO N-1 LOOP
					comb(j) <= std_logic_vector(signed(comb(j)) + signed(comb(j-1)));
				END LOOP;
			ELSE
				FOR j IN 1 TO N-1 LOOP
					comb(j) <= comb(j);
				END LOOP;
			END IF;

            -- Assign final comb filter output TO the output SIGNAL
            ov_cic <= comb(N-1);
			
			sample_counter <= sample_counter + 1;
			
        END IF;
    END PROCESS;

END Behavioral;
