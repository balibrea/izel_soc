library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.zpupkg.ALL;
use work.DMACache_pkg.ALL;
use work.DMACache_config.ALL;

entity VirtualToplevel is
	generic (
		sdram_rows : integer := 12;
		sdram_cols : integer := 8;
		sysclk_frequency : integer := 1000; -- Sysclk frequency * 10
		GPIO_LEN : integer := 15
	);
	port (
		clk 			: in std_logic;
		reset_in 	: in std_logic;

		jtag_o		: out std_logic;

		GPIO_IN		: in std_logic_vector(GPIO_LEN downto 0);
		GPIO_OUT	: out std_logic_vector(GPIO_LEN downto 0);

		-- VGA
		vga_red 		: out unsigned(7 downto 0);
		vga_green 	: out unsigned(7 downto 0);
		vga_blue 	: out unsigned(7 downto 0);
		vga_hsync 	: out std_logic;
		vga_vsync 	: buffer std_logic;
		vga_window	: out std_logic;

		-- SDRAM
		sdr_data		: inout std_logic_vector(15 downto 0);
		sdr_addr		: out std_logic_vector((sdram_rows-1) downto 0);
		sdr_dqm 		: out std_logic_vector(1 downto 0);
		sdr_we 		: out std_logic;
		sdr_cas 		: out std_logic;
		sdr_ras 		: out std_logic;
		sdr_cs		: out std_logic;
		sdr_ba		: out std_logic_vector(1 downto 0);
--		sdr_clk		: out std_logic;
		sdr_cke		: out std_logic;

		-- SPI signals
		spi_miso		: in std_logic := '1'; -- Allow the SPI interface not to be plumbed in.
		spi_mosi		: out std_logic;
		spi_clk		: out std_logic;
		spi_cs 		: out std_logic;
		
		-- UART
		rxd	: in std_logic;
		txd	: out std_logic;
		
		-- PS/2 signals
		ps2k_clk_in : in std_logic := '1';
		ps2k_dat_in : in std_logic := '1';
		ps2k_clk_out : out std_logic;
		ps2k_dat_out : out std_logic;
		ps2m_clk_in : in std_logic := '1';
		ps2m_dat_in : in std_logic := '1';
		ps2m_clk_out : out std_logic;
		ps2m_dat_out : out std_logic;

		-- AUDIO
		audio_l : out signed(15 downto 0);
		audio_r : out signed(15 downto 0)--;
		--mic_l : in signed(15 downto 0);
		--mic_r : in signed(15 downto 0)
);
end entity;

architecture rtl of VirtualToplevel is

constant sysclk_hz : integer := sysclk_frequency*1000;
constant uart_divisor : integer := sysclk_hz/1152;
constant maxAddrBit : integer := 31;

signal reset : std_logic := '0';
signal reset_counter : unsigned(15 downto 0) := X"FFFF";

-- Millisecond counter
signal millisecond_counter : unsigned(31 downto 0) := X"00000000";
signal millisecond_tick : unsigned(19 downto 0);


-- SPI Clock counter
signal spi_tick : unsigned(8 downto 0);
signal spiclk_in : std_logic;
signal spi_fast : std_logic;

-- SPI signals
signal host_to_spi : std_logic_vector(7 downto 0);
signal spi_to_host : std_logic_vector(31 downto 0);
signal spi_wide : std_logic;
signal spi_trigger : std_logic;
signal spi_busy : std_logic;
signal spi_active : std_logic;


-- UART signals

signal ser_txdata : std_logic_vector(7 downto 0);
signal ser_txready : std_logic;
signal ser_rxdata : std_logic_vector(7 downto 0);
signal ser_rxrecv : std_logic;
signal ser_txgo : std_logic;
signal ser_rxint : std_logic;


-- PS2 signals
signal ps2_int : std_logic;

signal kbdidle : std_logic;
signal kbdrecv : std_logic;
signal kbdrecvreg : std_logic;
signal kbdsendbusy : std_logic;
signal kbdsendtrigger : std_logic;
signal kbdsenddone : std_logic;
signal kbdsendbyte : std_logic_vector(7 downto 0);
signal kbdrecvbyte : std_logic_vector(10 downto 0);

signal mouseidle : std_logic;
signal mouserecv : std_logic;
signal mouserecvreg : std_logic;
signal mousesendbusy : std_logic;
signal mousesenddone : std_logic;
signal mousesendtrigger : std_logic;
signal mousesendbyte : std_logic_vector(7 downto 0);
signal mouserecvbyte : std_logic_vector(10 downto 0);


-- ZPU signals

signal mem_busy           : std_logic;
signal mem_read             : std_logic_vector(wordSize-1 downto 0);
signal mem_write            : std_logic_vector(wordSize-1 downto 0);
signal mem_addr             : std_logic_vector(maxAddrBit downto 0);
signal mem_writeEnable      : std_logic; 
signal mem_writeEnableh      : std_logic; 
signal mem_writeEnableb      : std_logic; 
signal mem_readEnable       : std_logic;

signal zpu_to_rom : ZPU_ToROM;
signal zpu_from_rom : ZPU_FromROM;


-- Plumbing between DMA controller and SDRAM

signal vga_addr : std_logic_vector(31 downto 0);
signal vga_data : std_logic_vector(15 downto 0);
signal vga_req : std_logic;
signal vga_fill : std_logic;
signal vga_refresh : std_logic;
signal vga_newframe : std_logic;
signal vga_reservebank : std_logic; -- Keep bank clear for instant access.
signal vga_reserveaddr : std_logic_vector(31 downto 0); -- to SDRAM

signal dma_data : std_logic_vector(15 downto 0);

-- Plumbing between VGA controller and DMA controller

signal vgachannel_fromhost : DMAChannel_FromHost;
signal vgachannel_tohost : DMAChannel_ToHost;
signal spr0channel_fromhost : DMAChannel_FromHost;
signal spr0channel_tohost : DMAChannel_ToHost;


-- Audio channel plumbing

signal aud0_fromhost : DMAChannel_FromHost;
signal aud0_tohost : DMAChannel_ToHost;
signal aud1_fromhost : DMAChannel_FromHost;
signal aud1_tohost : DMAChannel_ToHost;
signal aud2_fromhost : DMAChannel_FromHost;
signal aud2_tohost : DMAChannel_ToHost;
signal aud3_fromhost : DMAChannel_FromHost;
signal aud3_tohost : DMAChannel_ToHost;

signal audio_reg_req : std_logic;


-- Timer register block signals
signal timer_reg_req : std_logic;
signal timer_tick : std_logic;


-- VGA register block signals

signal vga_reg_addr : std_logic_vector(11 downto 0);
signal vga_reg_dataout : std_logic_vector(15 downto 0);
signal vga_reg_datain : std_logic_vector(15 downto 0);
signal vga_reg_rw : std_logic;
signal vga_reg_req : std_logic;
signal vga_reg_dtack : std_logic;
signal vga_ack : std_logic;
signal vblank_int : std_logic;


-- SDRAM signals

signal sdr_ready : std_logic;
signal sdram_write : std_logic_vector(31 downto 0); -- 32-bit width for ZPU
signal sdram_addr : std_logic_vector(31 downto 0);
signal sdram_req : std_logic;
signal sdram_wr : std_logic;
signal sdram_read : std_logic_vector(31 downto 0);
signal sdram_ack : std_logic;

signal sdram_wrL : std_logic;
signal sdram_wrU : std_logic;
signal sdram_wrU2 : std_logic;

type sdram_states is (read1, read2, read3, write1, writeb, write2, write3, idle);
signal sdram_state : sdram_states;


-- Interrupt signals

constant int_max : integer := 1;
signal int_triggers : std_logic_vector(int_max downto 0);
signal int_status : std_logic_vector(int_max downto 0);
signal int_ack : std_logic;
signal int_req : std_logic;
signal int_enabled : std_logic :='0'; -- Disabled by default
signal int_trigger : std_logic;


-- JTAG signals
signal jtag_dat_i : std_logic_vector(7 downto 0);
signal jtag_dat_o : std_logic_vector(7 downto 0);
signal jtag_rx_av : std_logic;
signal jtag_tx_ready : std_logic;
signal jtag_rEn : std_logic;
signal jtag_wEn : std_logic;
signal jtag_En : std_logic;

-- GPIO signals
signal io_En : std_logic;
signal io_rEn : std_logic;
signal io_wEn : std_logic;
signal io_data_i : std_logic_vector(GPIO_LEN downto 0);
signal io_data_o : std_logic_vector(GPIO_LEN downto 0); 

begin

sdr_cke <='1';
--audio_l <= X"0000";
--audio_r <= X"0000";


-- ROM

	myrom : entity work.prog_mem	--SDBootstrap_ROM
	generic map
	(
		maxAddrBitBRAM => 13
	)
	port map (
		clk => clk,
		from_zpu => zpu_to_rom,
		to_zpu => zpu_from_rom
	);


	usb_jtag : entity work.usb_jtag_uart
    port map(
		clk => clk,
		rst => jtag_En,
		data_i => jtag_dat_i,
		data_o => jtag_dat_o,
		rx_dat_av => jtag_rx_av,
		tx_ready => jtag_tx_ready,
		readEn => jtag_rEn,
		writeEn => jtag_wEn
    );

    jtag_En  <= reset_in;--jtag_rEn or jtag_wEn;


	zpu_io : entity work.gpio
		generic map(
		GPIO_LEN => GPIO_LEN
	)
		port map(
		clk => clk,
		rst => reset, --io_En,
		rd => io_rEn,
		wr => io_wEn,
		data_i => io_data_i,
		data_o => io_data_o,
		GPIO_IN => GPIO_IN,
		GPIO_OUT => GPIO_OUT
	);
    

-- Reset counter.
process(clk)
begin
	if reset_in='0' then
		reset_counter<=X"FFFF";
		reset<='0';
	elsif rising_edge(clk) then
		reset_counter<=reset_counter-1;
		if reset_counter=X"0000" then
			reset<='1';
		end if;
	end if;
end process;


-- Timer
process(clk)
begin
	if rising_edge(clk) then
		millisecond_tick<=millisecond_tick+1;
		if millisecond_tick=sysclk_frequency*100 then
			millisecond_counter<=millisecond_counter+1;
			millisecond_tick<=X"00000";
		end if;
	end if;
end process;


-- UART

myuart : entity work.simple_uart
	generic map(
		enable_tx=>true,
		enable_rx=>true
	)
	port map(
		clk => clk,
		reset => reset, -- active low
		txdata => ser_txdata,
		txready => ser_txready,
		txgo => ser_txgo,
		rxdata => ser_rxdata,
		rxint => ser_rxint,
		txint => open,
		clock_divisor => to_unsigned(uart_divisor,16),
		rxd => rxd,
		txd => txd
	);


-- PS2 devices

	--~ mykeyboard : entity work.io_ps2_com
		--~ generic map (
			--~ clockFilter => 15,
			--~ ticksPerUsec => sysclk_frequency/10
		--~ )
		--~ port map (
			--~ clk => clk,
			--~ reset => not reset, -- active high!
			--~ ps2_clk_in => ps2k_clk_in,
			--~ ps2_dat_in => ps2k_dat_in,
			--~ ps2_clk_out => ps2k_clk_out,
			--~ ps2_dat_out => ps2k_dat_out,
			
			--~ inIdle => open,	-- Probably don't need this
			--~ sendTrigger => kbdsendtrigger,
			--~ sendByte => kbdsendbyte,
			--~ sendBusy => kbdsendbusy,
			--~ sendDone => kbdsenddone,
			--~ recvTrigger => kbdrecv,
			--~ recvByte => kbdrecvbyte
		--~ );


	--~ mymouse : entity work.io_ps2_com
		--~ generic map (
			--~ clockFilter => 15,
			--~ ticksPerUsec => sysclk_frequency/10
		--~ )
		--~ port map (
			--~ clk => clk,
			--~ reset => not reset, -- active high!
			--~ ps2_clk_in => ps2m_clk_in,
			--~ ps2_dat_in => ps2m_dat_in,
			--~ ps2_clk_out => ps2m_clk_out,
			--~ ps2_dat_out => ps2m_dat_out,
			
			--~ inIdle => open,	-- Probably don't need this
			--~ sendTrigger => mousesendtrigger,
			--~ sendByte => mousesendbyte,
			--~ sendBusy => mousesendbusy,
			--~ sendDone => mousesenddone,
			--~ recvTrigger => mouserecv,
			--~ recvByte => mouserecvbyte
		--~ );


-- SPI Timer
process(clk)
begin
	if rising_edge(clk) then
		spiclk_in<='0';
		spi_tick<=spi_tick+1;
		if (spi_fast='1' and spi_tick(5)='1') or spi_tick(8)='1' then
			spiclk_in<='1'; -- Momentary pulse for SPI host.
			spi_tick<='0'&X"00";
		end if;
	end if;
end process;


-- SPI host
spi : entity work.spi_interface
	port map(
		sysclk => clk,
		reset => reset,

		-- Host interface
		spiclk_in => spiclk_in,
		host_to_spi => host_to_spi,
		spi_to_host => spi_to_host,
		trigger => spi_trigger,
		busy => spi_busy,

		-- Hardware interface
		miso => spi_miso,
		mosi => spi_mosi,
		spiclk_out => spi_clk
	);


-- DMA controller

	mydmacache : entity work.DMACache
		port map(
			clk => clk,
			reset_n => reset,

			channels_from_host(0) => vgachannel_fromhost,
			channels_from_host(1) => spr0channel_fromhost,
			channels_from_host(2) => aud0_fromhost,
			channels_from_host(3) => aud1_fromhost,
			channels_from_host(4) => aud2_fromhost,
			channels_from_host(5) => aud3_fromhost,
			
			channels_to_host(0) => vgachannel_tohost,
			channels_to_host(1) => spr0channel_tohost,
			channels_to_host(2) => aud0_tohost,
			channels_to_host(3) => aud1_tohost,
			channels_to_host(4) => aud2_tohost,
			channels_to_host(5) => aud3_tohost,

			data_out => dma_data,

			-- SDRAM interface
			sdram_addr=> vga_addr,
			sdram_reserveaddr(31 downto 0) => vga_reserveaddr,
			sdram_reserve => vga_reservebank,
			sdram_req => vga_req,
			sdram_ack => vga_ack,
			sdram_fill => vga_fill,
			sdram_data => vga_data
		);

	
-- SDRAM
mysdram : entity work.sdram_cached
	generic map
	(
		rows => sdram_rows,
		cols => sdram_cols,
		cache => true
	)
	port map
	(
	-- Physical connections to the SDRAM
		sdata => sdr_data,
		sdaddr => sdr_addr,
		sd_we	=> sdr_we,
		sd_ras => sdr_ras,
		sd_cas => sdr_cas,
		sd_cs	=> sdr_cs,
		dqm => sdr_dqm,
		ba	=> sdr_ba,

	-- Housekeeping
		sysclk => clk,
		reset => reset_in,  -- Contributes to reset, so have to use reset_in here.
		reset_out => sdr_ready,

		vga_addr => vga_addr,
		vga_data => vga_data,
		vga_fill => vga_fill,
		vga_req => vga_req,
		vga_ack => vga_ack,
		vga_refresh => vga_refresh,
		vga_reservebank => vga_reservebank,
		vga_reserveaddr => vga_reserveaddr,

		vga_newframe => vga_newframe,
		datawr1 => sdram_write,
		addr1 => sdram_addr,
		req1 => sdram_req,
		wr1 => sdram_wr, -- active low
		wrL1 => sdram_wrL, -- lower byte
		wrU1 => sdram_wrU, -- upper byte
		wrU2 => sdram_wrU2, -- upper halfword, only written on longword accesses
		dataout1 => sdram_read,
		dtack1 => sdram_ack
	);

	
-- VGA controller
-- Video
	
	myvga : entity work.vga_controller
		generic map (
			enable_sprite => false
		)
		port map (
		clk => clk,
		reset => reset,

		reg_addr_in => mem_addr(7 downto 0),
		reg_data_in => mem_write,
--		reg_data_out => vga_reg_dataout,
		reg_rw => vga_reg_rw,
		reg_req => vga_reg_req,

		sdr_refresh => vga_refresh,

		dma_data => dma_data,
		vgachannel_fromhost => vgachannel_fromhost,
		vgachannel_tohost => vgachannel_tohost,
		spr0channel_fromhost => spr0channel_fromhost,
		spr0channel_tohost => spr0channel_tohost,

		hsync => vga_hsync,
		vsync => vga_vsync,
		vblank_int => vblank_int,
		red => vga_red,
		green => vga_green,
		blue => vga_blue,
		vga_window => vga_window
	);

	
	myaudio : entity work.sound_wrapper
		generic map(
			clk_frequency => sysclk_frequency -- Prescale incoming clock
		)
	port map (
		clk => clk,
		reset => reset,

		reg_addr_in => mem_addr(7 downto 0),
		reg_data_in => mem_write,
		reg_rw => '0', -- we never read from the sound controller
		reg_req => audio_reg_req,

		dma_data => dma_data,
		channel0_fromhost => aud0_fromhost,
		channel0_tohost => aud0_tohost,
		channel1_fromhost => aud1_fromhost,
		channel1_tohost => aud1_tohost,
		channel2_fromhost => aud2_fromhost,
		channel2_tohost => aud2_tohost,
		channel3_fromhost => aud3_fromhost,
		channel3_tohost => aud3_tohost,

		audio_l => audio_l,
		audio_r => audio_r
	);


mytimer : entity work.timer_controller
  generic map(
		prescale => sysclk_frequency, -- Prescale incoming clock
		timers => 0
  )
  port map (
		clk => clk,
		reset => reset,

		reg_addr_in => mem_addr(7 downto 0),
		reg_data_in => mem_write,
		reg_rw => '0', -- we never read from the timers
		reg_req => timer_reg_req,

		ticks(0) => timer_tick -- Tick signal is used to trigger an interrupt
	);


-- Interrupt controller

intcontroller: entity work.interrupt_controller
generic map (
	max_int => int_max
)
port map (
	clk => clk,
	reset_n => reset,
	trigger => int_triggers, -- Again, thanks ISE.
	ack => int_ack,
	int => int_req,
	status => int_status
);

int_triggers<=(0=>timer_tick,
					1=>ps2_int,
					others => '0');


-- Main CPU

	zpu: zpu_core_flex
	generic map (
		IMPL_MULTIPLY => true,
		IMPL_COMPARISON_SUB => true,
		IMPL_EQBRANCH => true,
		IMPL_STOREBH => true,
		IMPL_LOADBH => true,
		IMPL_CALL => true,
		IMPL_SHIFT => true,
		IMPL_XOR => true,
		CACHE => false,
--		IMPL_EMULATION => minimal,
		REMAP_STACK => true, -- We need to remap the Boot ROM / Stack RAM so we can access SDRAM
		EXECUTE_RAM => true, -- We might need to execute code from SDRAM, too.
		maxAddrBitBRAM => 13
	)
	port map (
		clk                 => clk,
		reset               => not reset,
		interrupt			  => int_trigger,
		in_mem_busy         => mem_busy,
		mem_read            => mem_read,
		mem_write           => mem_write,
		out_mem_addr        => mem_addr,
		out_mem_writeEnable => mem_writeEnable,
		out_mem_hEnable     => mem_writeEnableh,
		out_mem_bEnable     => mem_writeEnableb,
		out_mem_readEnable  => mem_readEnable,
		from_rom => zpu_from_rom,
		to_rom => zpu_to_rom
	);

int_trigger<=int_req and int_enabled;	
	
process(clk)
begin
	if reset='0' then
		spi_cs<='1';
		spi_active<='0';
		int_enabled<='0';
		kbdrecvreg <='0';
		mouserecvreg <='0';
		jtag_o <= '0';
	elsif rising_edge(clk) then
		mem_busy<='1';
		ser_txgo<='0';
		vga_reg_req<='0';
		spi_trigger<='0';
		int_ack<='0';
		kbdsendtrigger<='0';
		mousesendtrigger<='0';
		audio_reg_req<='0';
		timer_reg_req<='0';
		jtag_wEn <= '0';
		jtag_rEn <= '0';
		io_En <= '0';
		jtag_o <= '0';

		-- Write from CPU?
		if mem_writeEnable='1' then
			case mem_addr(31)&mem_addr(10 downto 8) is
				when X"E" =>	-- VGA controller at 0xFFFFFE00
					vga_reg_rw<='0';
					vga_reg_req<='1';
					mem_busy<='0';
				when X"D" => -- Audio controller at 0xFFFFFD00
					audio_reg_req<='1';
					mem_busy<='0'; 	-- Audio controller never blocks the CPU
				when X"C" =>	-- Timer controller at 0xFFFFFC00
					timer_reg_req<='1';
					mem_busy<='0';
				when X"F" =>	-- Peripherals at 0xFFFFFFF00
					case mem_addr(7 downto 0) is
						when X"B0" => -- Interrupts
							int_enabled<=mem_write(0);
							mem_busy<='0';

						when X"C0" => -- UART
							ser_txdata<=mem_write(7 downto 0);
							ser_txgo<='1';
							mem_busy<='0';
							jtag_dat_i <= mem_write(7 downto 0); --JTAG
							jtag_wEn <= '1';
							jtag_rEn <= '0';
							jtag_o <= '1';							

						when X"B4" => -- GPIO
							--io_En <= '1';
							io_data_i <= mem_write(GPIO_LEN downto 0);
							io_wEn <= '1';
							io_rEn <= '0';
							mem_busy<='0';

						when X"D0" => -- SPI CS
							spi_cs<=not mem_write(0);
							spi_fast<=mem_write(8);
							mem_busy<='0';

						when X"D4" => -- SPI Data
							spi_wide<='0';
							spi_trigger<='1';
							host_to_spi<=mem_write(7 downto 0);
							spi_active<='1';
						
						when X"D8" => -- SPI Pump (32-bit read)
							spi_wide<='1';
							spi_trigger<='1';
							host_to_spi<=mem_write(7 downto 0);
							spi_active<='1';

						-- Write to PS/2 registers
						when X"e0" =>
							kbdsendbyte<=mem_write(7 downto 0);
							kbdsendtrigger<='1';
							mem_busy<='0';

						when X"e4" =>
							mousesendbyte<=mem_write(7 downto 0);
							mousesendtrigger<='1';
							mem_busy<='0';

						when others =>
							mem_busy<='0';
							null;
					end case;
				when others => -- SDRAM
					sdram_wrL<=mem_writeEnableb and not mem_addr(0);
					sdram_wrU<=mem_writeEnableb and mem_addr(0);
					sdram_wrU2<=mem_writeEnableh or mem_writeEnableb; -- Halfword access
					sdram_addr<=mem_Addr;
					sdram_wr<='0';
					sdram_req<='1';
					sdram_write<=mem_write; -- 32-bits now
					if mem_writeEnableb='1' then
						sdram_write(15 downto 8)<=mem_write(7 downto 0); -- 32-bits now
						sdram_state<=writeb;
					else
						sdram_state<=write1;
					end if;
			end case;

		elsif mem_readEnable='1' then -- Read from CPU?
			case mem_addr(31)&mem_addr(10 downto 8) is

				when X"F" =>	-- Peripherals
					case mem_addr(7 downto 0) is
						when X"B0" => -- Interrupt
							mem_read<=(others=>'X');
							mem_read(int_max downto 0)<=int_status;
							int_ack<='1';
							mem_busy<='0';

						when X"C0" => -- UART
							mem_read<=(others=>'X');
							--mem_read(9 downto 0)<=ser_rxrecv&ser_txready&ser_rxdata;
							ser_rxrecv<='0';	-- Clear rx flag.
							mem_busy<='0';
							mem_read(9 downto 0) <= jtag_tx_ready & jtag_rx_av & jtag_dat_o;
							jtag_wEn <= '0';
							jtag_rEn <= '1';

						when X"B4" =>
							io_En <= '1';
							mem_read(GPIO_LEN downto 0) <= io_data_o;
							io_rEn <= '1';
							io_wEn <= '0';
							mem_busy<='0';

						when X"C8" => -- Millisecond counter
							mem_read<=std_logic_vector(millisecond_counter);
							mem_busy<='0';

						when X"D0" => -- SPI Status
							mem_read<=(others=>'X');
							mem_read(15)<=spi_busy;
							mem_busy<='0';

						when X"D4" => -- SPI read (blocking)
							spi_active<='1';

						when X"D8" => -- SPI wide read (blocking)
							spi_wide<='1';
							spi_trigger<='1';
							spi_active<='1';
							host_to_spi<=X"FF";

						-- Read from PS/2 regs
						when X"E0" =>
							mem_read<=(others =>'0');
							mem_read(11 downto 0)<=kbdrecvreg & not kbdsendbusy & kbdrecvbyte(10 downto 1);
							kbdrecvreg<='0';
							mem_busy<='0';
							
						when X"E4" =>
							mem_read<=(others =>'0');
							mem_read(11 downto 0)<=mouserecvreg & not mousesendbusy & mouserecvbyte(10 downto 1);
							mouserecvreg<='0';
							mem_busy<='0';

						when others =>
							mem_busy<='0';
							null;
					end case;

				when others => -- SDRAM
					sdram_addr<=mem_Addr;
					sdram_addr(1 downto 0)<="00";
--					sdram_wrL<=mem_writeEnableb and not mem_addr(0);
--					sdram_wrU<=mem_writeEnableb and mem_addr(0);
--					sdram_wrU2<=mem_writeEnableh or mem_writeEnableb; -- Halfword access
					sdram_wr<='1';
					sdram_req<='1';
					sdram_state<=read1;
			end case;
		end if;
		
	-- SPI cycles

	if spi_active='1' and spi_busy='0' then
		mem_read<=spi_to_host;
		spi_active<='0';
		mem_busy<='0';
	end if;

	-- SDRAM state machine
	
		case sdram_state is
			when read1 => -- read first word from RAM
				if sdram_ack='0' then
					if mem_WriteEnableh='1' then  -- halfword read
						mem_read(31 downto 16) <= (others=>'0');
						if mem_Addr(1)='0' then
							mem_read(15 downto 0)<=sdram_read(31 downto 16);
						else
							mem_read(15 downto 0)<=sdram_read(15 downto 0);
						end if;
					elsif mem_WriteEnableb='1' then -- Byte read
						mem_read(31 downto 8) <= (others=>'0');
						case mem_Addr(1 downto 0) is
							when "00" =>
								mem_read(7 downto 0)<=sdram_read(31 downto 24);
							when "01" =>
								mem_read(7 downto 0)<=sdram_read(23 downto 16);
							when "10" =>
								mem_read(7 downto 0)<=sdram_read(15 downto 8);
							when "11" =>
								mem_read(7 downto 0)<=sdram_read(7 downto 0);
							when others =>
								null;
						end case;
					else
						mem_read<=sdram_read;
					end if;
					sdram_req<='0';
					sdram_state<=idle;
					mem_busy<='0';
				end if;
			when write1 => -- write 32-bit word to SDRAM
				if sdram_ack='0' then -- done?
					sdram_req<='0';
					sdram_state<=idle;
					mem_busy<='0';
				end if;
			when writeb => -- write 8-bit value to SDRAM
				if sdram_ack='0' then -- done?
					sdram_req<='0';
					sdram_state<=idle;
					mem_busy<='0';
				end if;
			when others =>
				null;

		end case;

		-- Set this after the read operation has potentially cleared it.
		if ser_rxint='1' then
			ser_rxrecv<='1';
		end if;

		-- PS2 interrupt
		ps2_int <= kbdrecv or kbdsenddone
			or mouserecv or mousesenddone;
			-- mouserecv or kbdsenddone or mousesenddone ; -- Momentary high pulses to indicate retrieved data.
		if kbdrecv='1' then
			kbdrecvreg <= '1'; -- remains high until cleared by a read
		end if;
		if mouserecv='1' then
			mouserecvreg <= '1'; -- remains high until cleared by a read
		end if;	

	end if; -- rising-edge(clk)

end process;
	
end architecture;
