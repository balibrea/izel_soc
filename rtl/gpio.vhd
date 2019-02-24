--------------------------------------------------------------------------------------
-- GPIO																				--
--																					--
-- Copyright 2018 - 2019 Yosel de Jesus Balibrea Lastre								--
--																					--
-- This program is free software: you can redistribute it and/or modify it under    --
-- the terms of the GNU General Public License as published by the Free Software    --
-- Foundation, either version 3 of the License, or (at your option) any later       --
-- version.                                                                         --
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY  --
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A  --
-- PARTICULAR PURPOSE.  See the GNU General Public License for more details.        --
--                                                                                  --
-- You should have received a copy of the GNU General Public License along with		--
-- this program.  If not, see <http://www.gnu.org/licenses/>.						--
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity gpio is
	generic(
	GPIO_LEN : integer := 3
	);
	port(
	clk : in std_logic;
	rst : in std_logic;
	
	rd : in std_logic;
	wr : in std_logic;
	
	data_i : in std_logic_vector(GPIO_LEN downto 0);
	data_o : out std_logic_vector(GPIO_LEN downto 0);
		
	GPIO_IN : in std_logic_vector(GPIO_LEN downto 0);
	GPIO_OUT : out std_logic_vector(GPIO_LEN downto 0)
	);
end entity;


architecture rtl of gpio is
signal data_o_r : std_logic_vector(GPIO_LEN downto 0);
signal GPIO_OUT_r : std_logic_vector(GPIO_LEN downto 0);

begin

	process(clk) is
	begin
		if rst = '0' then
			data_o_r <= (others => '0');
			GPIO_OUT_r <= (others => '0');
		elsif rising_edge(clk) then
			if wr = '1' then
				GPIO_OUT_r <= data_i;				
			elsif rd = '1' then
				data_o_r <= GPIO_IN;
			end if;
		end if;
	end process;
	
	GPIO_OUT <= GPIO_OUT_r;
	data_o <= data_o_r;
end rtl;
