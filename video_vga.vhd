library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity video_vga is
	Port ( clk : in STD_LOGIC;
			shor : out STD_LOGIC;
			sver : out STD_LOGIC;
			RGB : out STD_LOGIC_VECTOR(7 downto 0);
			up1: in std_logic; --Entradas de control
		   up2: in std_logic;
			down1: in std_logic; 
			down2: in std_logic);
end video_vga;

architecture arq_video_vga of video_vga is
	constant hpixels : std_logic_vector(9 downto 0) := "1100100000"; --Valor de pixeles en línea horizontal (800)
	constant vlines : std_logic_vector(9 downto 0) := "1000001001"; --Valor de lineas horizontales en pantalla (521)
	constant hbp : std_logic_vector(9 downto 0) := "0010010000"; --Límite horizontal inferior "back porch" (144)
	constant hfp : std_logic_vector(9 downto 0) := "1100100000"; --Límite horizontal superior "front porch" (784)
	constant vbp : std_logic_vector(9 downto 0) := "0000011111"; --Límite vertical inferior "back porch" (31)
	constant vfp : std_logic_vector(9 downto 0) := "0111111111"; --Límite vertical superior "front porch" (521)

	signal conh : std_logic_vector(9 downto 0) := (others=>'0'); --Contador horizontal
	signal conv : std_logic_vector(9 downto 0) := (others=>'0'); --Contador vertical
	signal clkdiv : std_logic := '0';--Señal de reloj a 25Mhz
	signal vidon : std_logic := '0';--Habilita la señal de video
	signal vsenable : std_logic := '0';--Habilita el contador vertical
	signal clkdiv2 : std_logic := '0'; --Señal de reloj dividida a 60 Hz
	signal counter : integer range 0 to 104165 := 0; --Contador para dividir el clk de 50Mhz a 60Hz
	--signal vstart: std_logic_vector(9 downto 0) := "0011010010"; 
	signal vstart1: std_logic_vector(9 downto 0) := "0011010010";--Señal de posición vertical de la barra 1
	signal vstart2: std_logic_vector(9 downto 0) := "0011010010";--Señal de posición vertical de la barra 2
	
	signal pelotav: std_logic_vector(9 downto 0) := "0011110000";
	signal pelotah: std_logic_vector(9 downto 0) := "0111100000";
	signal dirh: std_logic:= '0';
	signal dirv: std_logic:= '0';
	
	begin
	
		--clk es de 50MHz del reloj interno de la FPGA. Se genera la señal clkdiv a 25 MHz.
		process (clk)
		begin
			if (clk = '1' and clk' event) then
				clkdiv <= not clkdiv;
			end if;
		end process;
		
		--clk es de 50MHz. Se genera otra señal a 60 Hz.
		process (clk)
		begin
			if (clk = '1' and clk' event) then
				if(counter = 104165) then --Cuando el contador llega a la cuenta maxima (mitad del periodo de señal a 60Hz)
					clkdiv2 <= not clkdiv2; --clkdiv2 se invierte
					counter <= 0; --Contador regresa a 0
				else
					counter <= counter + 1; --Contador se incrementa
				end if;
			end if;
		end process;

		--Contador horizontal
		process (clkdiv)
		begin
			if (clkdiv = '1' and clkdiv' event) then
				if conh = hpixels then --Monitoreo de número de pixeles en línea horizontal
					conh <= (others=>'0'); --Inicializa en 0's el contador
					vsenable <= '1'; --Habilita el contador veritical cuando conh = 800.
				else
					conh <= conh + 1; --Incrementa el contador horizontal
					vsenable <= '0'; --Deshabilita el contador vertical
				end if;
			end if;
		end process;

		--Pulso de sincronía horizontal
		shor <= '1' when conh(9 downto 7) = "000" else '0'; --Las señales de sincronización se habilitan en '0'

		--Contador vertical
		process (clkdiv)
		begin
			if (clkdiv = '1' and clkdiv' event and vsenable = '1') then
				if conv = vlines then --Monitorea el número de líneas verticales
					conv <= (others=>'0'); --Inicializa el contador 
				else conv <= conv + 1; --Incrementa el contador vertical
				end if;
			end if;
		end process;
		
		--Pulso de sincronía vertical
		sver <= '1' when conv(9 downto 1) = "000000000" else '0';
		
	--PRUEBAS (NO SIRVE)
--		process(clkdiv)
--		begin
--			if (clkdiv = '1' and clkdiv' event) then
--				if(starth = "111111111" and rlimit = "1111111111" and startv = "1111111111" and dlimit = "1111111111") then
--					starth <= (others=>'0');
--					rlimit <= (others=>'0');
--					startv <= (others=>'0');
--					dlimit <= (others=>'0');
--				else
--					starth <= starth + '1';
--					rlimit <= rlimit + '1';
--					startv <= startv + '1';
--					dlimit <= dlimit + '1';
--				end if;
--			end if;
--		end process;
		
--		process(clkdiv2)
--		begin
--			if(clkdiv2 = '1' and clkdiv2' event) then
--				if(vstart = 420 - vbp) then -- 420 = 480 - 60 (60 es  la altura de la barra)
--					vstart <= "0000101000";
--				else
--					vstart <= vstart + 1;
--				end if;
--			end if;
--		end process;
		
		
		
		--Movimiento de barra 1
		process(clkdiv2)
		begin
			if(clkdiv2 = '1' and clkdiv2' event) then
				
				if(vstart1 = "0000101000") then
					if(down1 = '1') then vstart1 <= vstart1 + 1;
					end if;
				elsif (vstart1 = (450 - vbp)) then
					if(up1 = '1') then vstart1 <= vstart1 - 1;
					end if;
				else
					if(up1 = '1') then vstart1 <= vstart1 - 1;
					end if;
					if(down1 = '1') then vstart1 <= vstart1 + 1;
					end if;
				end if;
				
			end if;
		end process;
		
		--Movimiento de barra 2
		process(clkdiv2)
		begin
			if(clkdiv2 = '1' and clkdiv2' event) then
				
				if(vstart2 = "0000101000") then
					if(down2 = '1') then vstart2 <= vstart2 + 1;
					end if;
				elsif (vstart2 = (450 - vbp)) then
					if(up2 = '1') then vstart2 <= vstart2 - 1;
					end if;
				else
					if(up2 = '1') then vstart2 <= vstart2 - 1;
					end if;
					if(down2 = '1') then vstart2 <= vstart2 + 1;
					end if;
				end if;
				
			end if;
		end process;
		
		--Movimiento de pelota
		process(clkdiv2)
		begin
			if(clkdiv2 = '1' and clkdiv2' event) then
				
				if((pelotah + 10 + hbp) > (545 + hbp)) then
					
					if(((pelotav > vstart2) and (pelotav < vstart2 + 60))) then
						
						dirh <= '1';
						
					else
						pelotav <= "0011110000";
						pelotah <= "0111100000";
					end if;
				
				elsif((pelotah + hbp) < (95 + hbp)) then
					
					if(((pelotav > vstart1) and (pelotav < vstart1 + 60))) then
						
						dirh <= '0';
					else
						pelotav <= "0011110000";
						pelotah <= "0111100000";
					end if;
				end if;	
				
--				if((pelotah = 630 + hbp) or (pelotah = 0 + hbp)) then
--					pelotav <= "0011110000";
--					pelotah <= "0111100000";
--				end if;
				
				--Mueve dependiendo de la bandera de direccion
				if(dirh = '0')then
					pelotah <= pelotah + 1;
				else
					pelotah <= pelotah - 1;
				end if;
				
			end if;
		end process;
		
		

	--***********************
		--Pixels a visualizar				Posiciones horizontales								Posiciones verticales
		RGB <= "11111111" when (conh > (80 + hbp) and conh < (95 + hbp) and conv > (vstart1 + vbp) and conv < ((vstart1 + 60) + vbp) and vidon = '1') 
			else "11111111" when(conh > (545 + hbp) and conh < (560 + hbp) and conv > (vstart2 + vbp) and conv < ((vstart2 + 60) + vbp) and vidon = '1') 
			else "11111111" when(conh > (318 + hbp) and conh < (320 + hbp) and conv > ("0000101000" + vbp) and conv < (480 + vbp) and vidon = '1')
			else "11111111" when(conh > (hbp) and conh < (600 + hbp) and conv > ("0000101000" + vbp) and conv < ("0000101010" + vbp) and vidon = '1')
			else "11111111" when (conh > (pelotah + hbp) and conh < (pelotah + 10 + hbp) and conv > (pelotav + vbp) and conv < (pelotav + 10 + vbp) and vidon = '1') 
			else "00000000";
	--***********************

 --Habilitación de la señal de video solo en los márgenes de visualización (480 x 640)
 vidon <= '1' when (((conh < hbp and (conh < hfp )) or ((conv > vbp) and (conv < vfp)))) else '0';
end arq_video_vga;
