library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	

entity timer is 
   generic( 
		clk_frequency 	: integer; -- clock frequency in Hz
		timer_value   	: integer  -- timer in microseconds (us)
	);

	port( 
		clk 				: in	std_logic;
		reset		     	: in	std_logic;
		timer_tick		: out	std_logic 
	);

end entity;


architecture behavioural of timer is

signal cycle_counter : integer;
signal cycle_value 	: integer;

begin

	cycle_value <= ((clk_frequency/1000000) * timer_value) ;

	process(clk, reset) 

	begin
		if(reset = '0') then
			cycle_counter 			<= 0;
			timer_tick 				<= '0';
		else
			if(rising_edge(clk)) then
				cycle_counter 		<= cycle_counter + 1;
				if(cycle_counter < cycle_value ) then
					timer_tick 		<= '0';
				else
					timer_tick 		<= '1';
					cycle_counter 	<= 0;
				end if;
			end if;
		end if;
	end process;
end architecture;