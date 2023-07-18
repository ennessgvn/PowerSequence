library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PowerSequence is
   generic(
	   clk_freq                            : natural := 25e6
	);
	port(
	-- INPUTS --
		CPLD_REFCLK_25M_3V3						: in		std_logic;	-- System Clock
		LV1_5V0_PGOOD_3V3                   : in     std_logic;  -- Powergood signals coming from Power Channels
		LV2_PGOOD_3V3                       : in     std_logic;  --
		LV3_PGOOD_3V3                       : in     std_logic;  --
		LV4_1V0_PGOOD_3V3                   : in     std_logic;  --
		LV5_PGOOD_3V3                       : in     std_logic;  --
		
      DEV_INIT_DONE_3V3                   : in     std_logic;  -- A signal coming from CPU that shows all powers and resets up	
		
	-- OUTPUTS -- 
		LV2_CH12_EN_3V3                     : out		std_logic;  -- Enable signals that supply to power blocks
		LV2_CH3_EN_3V3                      : out		std_logic;  -- 
		LV2_CH4_EN_3V3                      : out		std_logic;  -- 
		LV5_2V5_EN_3V3                      : out		std_logic;  -- 
		LV3_1V8_EN_3V3                      : out		std_logic;  -- 
		LV3_1V5_EN_3V3                      : out		std_logic;  -- 
		LV3_1V1_EN_3V3                      : out		std_logic;  -- 
		LV3_3V3_EN_3V3	                     : out		std_logic;  -- 
		LV4_1V0_EN_3V3	                     : out		std_logic;  --	 
      
		RST_OPHY_3V3                        : out    std_logic;  -- Reset signals (Active Low)
		RST_MNGPHY_3V3                      : out    std_logic;  --
		RST_DDR4_3V3                        : out    std_logic;  --
		RST_FRQ_3V3                         : out    std_logic;  --
		RST_I2CMUX_3V3                      : out    std_logic;  --
		CPU_POW_EN                          : out    std_logic
		);
end entity;

architecture rtl of PowerSequence is

component timer
	generic(
		clk_frequency 	: integer; -- clock frequency in Hz
		timer_value   	: integer  -- timer in microseconds (us)
	);
	port(
		clk 				: in 	std_logic;
		reset		   	: in 	std_logic;
		timer_tick		: out std_logic
	);
end component;

type machine is (
	PWR_OFF, 
	PWR_ON_OTHERS, 
	PWR_GOOD_OTHERS,
   PWR_ON_LV3,
	PWR_GOOD_LV3,
	PWR_ON_CORE, 
	PWR_GOOD_CORE,  
	RST_UP, 
	RUNNING
	);
	
signal state 						: machine:= PWR_OFF;	

signal tick_10ms,	rst_10ms 	   : std_logic;
signal tick_20ms,	rst_20ms 	   : std_logic;
signal tick_50ms, rst_50ms 	   : std_logic;
signal tick_200ms, rst_200ms 	   : std_logic;
signal tick_350ms, rst_350ms 	   : std_logic;

signal LV1_5V0_PGOOD_3V3_r		   : std_logic;
signal LV2_PGOOD_3V3_r		      : std_logic;
signal LV3_PGOOD_3V3_r			   : std_logic;
signal LV4_1V0_PGOOD_3V3_r	      : std_logic;
signal LV5_PGOOD_3V3_r	         : std_logic;
signal PP_DEV_INIT_DONE_3V3_r	   : std_logic;

begin

timer_10ms: timer
	generic map(
		clk_frequency 	=> clk_freq,
		timer_value 	=> 10000
	)
	port map(
		clk 				=> CPLD_REFCLK_25M_3V3,
		reset 			=> rst_10ms,
		timer_tick 		=> tick_10ms
	);
	
	timer_20ms: timer
	generic map(
		clk_frequency 	=> clk_freq,
		timer_value 	=> 20000
	)
	port map(
		clk 				=> CPLD_REFCLK_25M_3V3,
		reset 			=> rst_20ms,
		timer_tick 		=> tick_20ms
	);		
	
	timer_50ms: timer
	generic map(
		clk_frequency 	=> clk_freq,
		timer_value 	=> 50000
	)
	port map(
		clk 				=> CPLD_REFCLK_25M_3V3,
		reset 			=> rst_50ms,
		timer_tick 		=> tick_50ms
	);		
	
	timer_200ms: timer
	generic map(
		clk_frequency 	=> clk_freq,
		timer_value 	=> 200000
	)
	port map(
		clk 				=> CPLD_REFCLK_25M_3V3,
		reset 			=> rst_200ms,
		timer_tick 		=> tick_200ms
	);
	
	timer_350ms: timer
	generic map(
		clk_frequency 	=> clk_freq,
		timer_value 	=> 350000
	)
	port map(
		clk 				=> CPLD_REFCLK_25M_3V3,
		reset 			=> rst_350ms,
		timer_tick 		=> tick_350ms
	);
		
process(all)
	begin
		
		if(rising_edge(CPLD_REFCLK_25M_3V3))then
		RST_OPHY_3V3             		<= 'Z';               
		RST_MNGPHY_3V3		            <= 'Z';     
		RST_DDR4_3V3  		            <= 'Z';      
		RST_FRQ_3V3   		            <= 'Z';     
		RST_I2CMUX_3V3		            <= 'Z';
		
		LV2_CH12_EN_3V3      	      <= '0';	
		LV2_CH3_EN_3V3      	         <= '0';  		
		LV2_CH4_EN_3V3      	         <= '0';   		
		LV5_2V5_EN_3V3      	         <= '0';   		
		LV3_1V8_EN_3V3      	         <= '0';   		
		LV3_1V5_EN_3V3      	         <= '0';   		
		LV3_1V1_EN_3V3      	         <= '0';   		
		LV3_3V3_EN_3V3      	         <= '0'; 	 		
		LV4_1V0_EN_3V3      	         <= '0'; 	 		

		CPU_POW_EN							<= '0';
		rst_10ms 						   <= '0';
		rst_20ms 						   <= '0';
		rst_50ms 						   <= '0';
		rst_200ms						   <= '0';
		rst_350ms						   <= '0';		
		
		LV1_5V0_PGOOD_3V3_r			   <= LV1_5V0_PGOOD_3V3;
		LV2_PGOOD_3V3_r				 	<= LV2_PGOOD_3V3;
		LV3_PGOOD_3V3_r				   <= LV3_PGOOD_3V3;
		LV4_1V0_PGOOD_3V3_r			 	<= LV4_1V0_PGOOD_3V3;
		LV5_PGOOD_3V3_r				 	<= LV5_PGOOD_3V3;
		PP_DEV_INIT_DONE_3V3_r		   <= DEV_INIT_DONE_3V3;
		
			case state is
			
				when PWR_OFF =>
					LV5_2V5_EN_3V3						   <= '0';
					LV3_1V8_EN_3V3						   <= '0';
					LV3_1V5_EN_3V3						   <= '0';
					LV3_1V1_EN_3V3						   <= '0';
					LV3_3V3_EN_3V3						   <= '0';
					LV2_CH4_EN_3V3                   <= '0';
					LV4_1V0_EN_3V3						   <= '0';               
					
					if(LV1_5V0_PGOOD_3V3_r = '1') then
						rst_10ms <= '1';
						if(tick_10ms = '1') then
							state <= PWR_ON_OTHERS;
						end if;
					end if;
					
					
				when PWR_ON_OTHERS =>												
					LV5_2V5_EN_3V3						   <= '1';
					LV3_1V5_EN_3V3						   <= '1';
					LV3_1V1_EN_3V3						   <= '1';
					LV3_3V3_EN_3V3						   <= '1';
					LV2_CH4_EN_3V3                   <= '1';
					
					LV3_1V8_EN_3V3						   <= '0';              
					LV4_1V0_EN_3V3						   <= '0';
	
					rst_10ms <= '1';
					if(tick_10ms = '1') then
						state <= PWR_GOOD_OTHERS;
					end if;

					
				when PWR_GOOD_OTHERS =>													
					LV5_2V5_EN_3V3						   <= '1';
					LV3_1V5_EN_3V3						   <= '1';
					LV3_1V1_EN_3V3						   <= '1';
					LV3_3V3_EN_3V3						   <= '1';
					LV2_CH4_EN_3V3                   <= '1';
					
					LV3_1V8_EN_3V3						   <= '0';
					LV4_1V0_EN_3V3						   <= '0';
					
					if(LV5_PGOOD_3V3_r = '1') then
						rst_50ms <= '1';
						if(tick_50ms = '1') then
							state <= PWR_ON_LV3;
						end if;
					end if;
					
					
				when PWR_ON_LV3 =>												
					LV5_2V5_EN_3V3						   <= '1';
					LV3_1V5_EN_3V3						   <= '1';
					LV3_1V1_EN_3V3						   <= '1';
					LV3_3V3_EN_3V3						   <= '1';
					LV2_CH4_EN_3V3                   <= '1';
					
					LV3_1V8_EN_3V3						   <= '1';
					
					LV4_1V0_EN_3V3						   <= '0';
	
					rst_10ms <= '1';
					if(tick_10ms = '1') then
						state <= PWR_GOOD_LV3;
					end if;

					
				when PWR_GOOD_LV3 =>														
					LV5_2V5_EN_3V3						   <= '1';
					LV3_1V5_EN_3V3						   <= '1';
					LV3_1V1_EN_3V3						   <= '1';
					LV3_3V3_EN_3V3						   <= '1';
					LV2_CH4_EN_3V3                   <= '1';
					
					LV3_1V8_EN_3V3						   <= '1';
					
					LV4_1V0_EN_3V3						   <= '0';
					
					if(LV3_PGOOD_3V3_r = '1') then
						rst_50ms <= '1';
						if(tick_50ms = '1') then
							state <= PWR_ON_CORE;
						end if;
					end if;
					
					
				when PWR_ON_CORE =>													
					LV5_2V5_EN_3V3						   <= '1';
					LV3_1V5_EN_3V3						   <= '1';
					LV3_1V1_EN_3V3						   <= '1';
					LV3_3V3_EN_3V3						   <= '1';
					LV2_CH4_EN_3V3                   <= '1';
		         LV3_1V8_EN_3V3						   <= '1';			
					
					LV4_1V0_EN_3V3						   <= '1';
					
					rst_10ms <= '1';
					if(tick_10ms = '1') then
						state <= PWR_GOOD_CORE;
					end if;

					
				when PWR_GOOD_CORE =>											  
					LV5_2V5_EN_3V3						   <= '1';
					LV3_1V8_EN_3V3						   <= '1';
					LV3_1V5_EN_3V3						   <= '1';
					LV3_1V1_EN_3V3						   <= '1';
					LV3_3V3_EN_3V3						   <= '1';
					LV2_CH4_EN_3V3                   <= '1';   
					
					LV4_1V0_EN_3V3						   <= '1';
					
					if(LV4_1V0_PGOOD_3V3_r = '1') then
						rst_10ms <= '1';
						if(tick_10ms = '1') then
							state <= RST_UP;
						end if;
					end if;		
					
				when RST_UP =>											  
					LV5_2V5_EN_3V3						   <= '1';
					LV3_1V8_EN_3V3						   <= '1';
					LV3_1V5_EN_3V3						   <= '1';
					LV3_1V1_EN_3V3						   <= '1';
					LV3_3V3_EN_3V3						   <= '1';
					LV2_CH4_EN_3V3                   <= '1';   
					LV4_1V0_EN_3V3						   <= '1';
					
				   RST_OPHY_3V3             		   <= '1';               
		         RST_MNGPHY_3V3		               <= '1';     
		         RST_DDR4_3V3  		               <= '1';      
		         RST_FRQ_3V3   		               <= '1';     
		         RST_I2CMUX_3V3		               <= '1';
					
					if(PP_DEV_INIT_DONE_3V3_r = '1') then
						state <= RUNNING;
					end if;
			
				when RUNNING =>											  
					LV5_2V5_EN_3V3						   <= '1';
					LV3_1V8_EN_3V3						   <= '1';
					LV3_1V5_EN_3V3						   <= '1';
					LV3_1V1_EN_3V3						   <= '1';
					LV3_3V3_EN_3V3						   <= '1';
					LV2_CH4_EN_3V3                   <= '1';   
					LV4_1V0_EN_3V3						   <= '1';
					
				   RST_OPHY_3V3             		   <= '1';               
		         RST_MNGPHY_3V3		               <= '1';     
		         RST_DDR4_3V3  		               <= '1';      
		         RST_FRQ_3V3   		               <= '1';     
		         RST_I2CMUX_3V3		               <= '1';
					
					CPU_POW_EN								<= '1';							
		
				when others =>
					rst_200ms <= '1';
					if(tick_200ms = '1') then
						state <= PWR_OFF;
					end if;		
		
			end case;
		end if;
	end process;
end architecture;			