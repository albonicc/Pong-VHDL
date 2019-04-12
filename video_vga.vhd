library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity video_vga is
 Port ( clk : in STD_LOGIC;
 a : in STD_LOGIC_VECTOR(1 downto 0);
 shor : out STD_LOGIC;
 sver : out STD_LOGIC;
 RGB : out STD_LOGIC_VECTOR(7 downto 0));
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
 signal clkdiv : std_logic := '0';
 --Señal de reloj a 25Mhz
 signal vidon : std_logic := '0';
 --Habilita la señal de video
 signal vsenable : std_logic := '0';
 --Habilita el contador vertical

begin
 --clk es de 50MHz del reloj interno de la FPGA. Se genera la señal clkdiv a 25 MHz.
 process (clk)
 begin
 if (clk = '1' and clk' event) then
 clkdiv <= not clkdiv;
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

 --*******************************************************************
 --Pixels a visualizar
 RGB <= "11111100" when (conh(4 downto 0) = "00000" and
 conv(4 downto 0) = "00000" and
 vidon = '1' and a = "00") else
 -- Cuadro a visualizar
 "11100011" when (conh > ("0100001110" + hbp) and conh < ("0101110010" + hbp)
 and conv > ("0010111110" + vbp) and conv < ("0100100010" + vbp)
 and vidon = '1' and a = "01") else
 -- Rayas verticales
 "00011111" when (conh (4 downto 0) = "00000" and
 vidon = '1' and a = "10" )else
 -- Rayas horizontales
 "11100000" when (conv (4 downto 0) = "00000" and
 vidon = '1' and a = "11" )else "00000000";
 --*********************************************************************

 --Habilitación de la señal de video solo en los márgenes de visualización (480 x 640)
 vidon <= '1' when (((conh < hbp and (conh < hfp )) or ((conv > vbp) and (conv < vfp)))) else '0';
end arq_video_vga;