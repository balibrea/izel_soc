library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;


entity usb_jtag_uart is
	port(
	clk : in std_logic;
	rst : in std_logic;
	
	data_i : in std_logic_vector(7 downto 0);
	data_o : out std_logic_vector(7 downto 0);
	
	rx_dat_av : out std_logic;
	tx_ready : out std_logic;
	
	readEn : in std_logic;
	writeEn : in std_logic
	);
end usb_jtag_uart;


architecture rtl of usb_jtag_uart is

signal enabled : std_logic;
signal write_reg : std_logic;
signal read_reg : std_logic;
signal data_i_reg : std_logic_vector(7 downto 0);
signal data_o_reg : std_logic_vector(7 downto 0);
signal txmt : std_logic;
signal txfl : std_logic;
signal rxmt : std_logic;
signal rxfl : std_logic;

type state_op is (IDLE_S, WAIT_S, READ_S, SETTLE_S, WRITE_S);

signal state : state_op;

signal ff1 : std_logic;
signal ff2 : std_logic;
signal tx_en : std_logic;

component jtag_uart
	port(
	clk_i : in std_logic;
	nreset_i : in std_logic;
	nwr_i : in std_logic;
	data_i : in std_logic_vector(7 downto 0);
	rd_i : in std_logic;
	data_o : out std_logic_vector(7 downto 0);
	txmt : out std_logic;
	txfl : out std_logic;
	rxmt : out std_logic;
	rxfl : out std_logic
	);
end component;

begin

usb_uart : jtag_uart
	port map(
	clk_i => clk,
	nreset_i => enabled,
	nwr_i => write_reg,
	data_i => data_i_reg,
	rd_i => read_reg,
	data_o => data_o_reg,
	txmt => txmt,
	txfl => txfl,
	rxmt => rxmt,
	rxfl => rxfl
	);

tx_ready <= txfl;
enabled <= rst;
rx_dat_av <= rxmt;
tx_en <= ff1 and not ff2;
	
process(clk) is
begin
	if rst = '0' then
		write_reg <= '1';
		read_reg <= '0';
		data_o <= (others => '0');
		ff1 <= '0';
		ff2 <= '0';
		--enabled <= '0'
	elsif rising_edge(clk) then
		ff1 <= writeEn;
		ff2 <= ff1;
		if readEn = '1' then
			state <= WAIT_S;
		elsif tx_en = '1' then
			state <= SETTLE_S;
		else
			state <= IDLE_S;
		end if;
		
		case(state) is
			when IDLE_S =>
				write_reg <= '1'; -- No write
				read_reg <= '0'; -- No read;
				
			when WAIT_S =>
				if rxmt = '0' then -- Data available, read
					read_reg <= '1';
					state <= READ_S;
				else					-- No Data available, so wait
					write_reg <= '1';
					read_reg <= '0';
					state <= IDLE_S;--WAIT_S;
				end if;
			
			when READ_S =>
				read_reg <= '0'; -- We don't need read any more
				data_o <= data_o_reg;
				state <= IDLE_S;
			
			when SETTLE_S =>
				write_reg <= '0'; -- We are going to write
				data_i_reg <= data_i;
				state <= WRITE_S;
			
			when WRITE_S =>
				--if txmt = '0' then
				write_reg <= '1'; -- We don't need to write more
				state <= IDLE_S;
--				else
--					state <= SETTLE_S;				
--				end if;
			
		end case;	
	end if;
end process;

end rtl;
