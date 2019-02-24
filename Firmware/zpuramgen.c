// zpuramgen.c (adapted from zpuromgen.c)
//
// Program to turn a binary file into a VHDL lookup table.
//   by Yosel Balibrea
//   20-Jun-2018
//
// This software is free to use by anyone for any purpose.
//
// 2018.07.30: Generation of full VHDL code
//

#include <unistd.h>
#include <stdio.h>
#include <stdint.h>

typedef uint8_t BYTE;

int cnt = 0;
float mem_max_add_bit = 4096.0;

int main(int argc, char **argv) {
    BYTE    opcode[4];
    int     fd;
    int     addr = 0;
    ssize_t s;

    // Check the user has given us an input file.
    if(argc < 2) {
        printf("Usage: %s <binary_file> <output_file>\n\n", argv[0]);
        return 1;
    }

    // Open the input file.
    fd = open(argv[1], 0);
    
    //Output file
    FILE *fo = fopen(argv[2], "w");
    
    if(fd == -1) {
        perror("Eror Opening File");
        return 2;
    }
    fprintf(fo, "--\n");
    fprintf(fo, "-- (C) 2018, ZPUROMGEN, Yosel de Jesus Balibrea Lastre.\n");
    fprintf(fo, "--           Automatically Generated ROM file\n");
    fprintf(fo, "--           Please do NOT CHANGE!\n");
    fprintf(fo, "--\n");
    fprintf(fo, "library ieee;\n");
    fprintf(fo, "use ieee.std_logic_1164.all;\n");
    fprintf(fo, "use ieee.numeric_std.all;\n");
    fprintf(fo, "\n");
    fprintf(fo, "\n");
    fprintf(fo, "library work;\n");
    //fprintf(fo, "use work.zpu_config.all;\n");
    fprintf(fo, "use work.zpupkg.all;\n");
    fprintf(fo, "\n");
    fprintf(fo, "entity prog_mem is\n");
    fprintf(fo, "generic\n");
	fprintf(fo,"(\n");
	fprintf(fo,"maxAddrBitBRAM : integer := maxAddrBitBRAMLimit -- Specify your actual ROM size to save LEs and unnecessary block RAM usage.\n");
	fprintf(fo,");\n");
	fprintf(fo, "port (\n");
	fprintf(fo, "		clk : in std_logic;\n");
	fprintf(fo, "		areset : in std_logic := '0';\n");
	fprintf(fo, "		from_zpu : in ZPU_ToROM;\n");
	fprintf(fo, "		to_zpu : out ZPU_FromROM\n");
	fprintf(fo, "		);\n");
	fprintf(fo, "end prog_mem;\n");
    fprintf(fo, "\n");
    
    fprintf(fo, "architecture rtl of prog_mem is\n");
    fprintf(fo, "\n");
    fprintf(fo, "	type ram_type is array(natural range 0 to ((2**(maxAddrBitBRAM+1))/4)-1) of std_logic_vector(wordSize-1 downto 0);\n");
    fprintf(fo, "\n");
    fprintf(fo, "	shared variable ram : ram_type := (\n");

    
    while(1) {
		cnt = cnt+1;
        // Read 32 bits.
        s = read(fd, opcode, 4);
        if(s == -1) {
            perror("File read");
            return 3;
        }

        if(s == 0)
            break; // End of file.

        // Output to FILE.
        fprintf(fo, "%6d => x\"%02x%02x%02x%02x\",\n", addr++, opcode[0], opcode[1], opcode[2], opcode[3]);        
    }
    fprintf(fo, "others => x\"00000000\"\n");
    fprintf(fo, ");\n");
    fprintf(fo, "\n");
    fprintf(fo, "begin\n");
    fprintf(fo, "\n");
    
    fprintf(fo, "process (clk)\n");
    fprintf(fo, "begin\n");
    fprintf(fo, "	if (clk'event and clk = '1') then\n");
    fprintf(fo, "		if (from_zpu.memAWriteEnable = '1') and (from_zpu.memBWriteEnable = '1') and (from_zpu.memAAddr=from_zpu.memBAddr) and (from_zpu.memAWrite/=from_zpu.memBWrite) then\n");
    fprintf(fo, "			report \"write collision\" severity failure;\n");
    fprintf(fo, "		end if;\n");
    fprintf(fo, "\n");
    fprintf(fo, "		if (from_zpu.memAWriteEnable = '1') then\n");
    fprintf(fo, "			ram(to_integer(unsigned(from_zpu.memAAddr(maxAddrBitBRAM downto 2)))) := from_zpu.memAWrite;\n");
    fprintf(fo, "			to_zpu.memARead <= from_zpu.memAWrite;\n");
    fprintf(fo, "		else\n");
    fprintf(fo, "			to_zpu.memARead <= ram(to_integer(unsigned(from_zpu.memAAddr(maxAddrBitBRAM downto 2))));\n");
    fprintf(fo, "		end if;\n");
    fprintf(fo, "	end if;\n");
    fprintf(fo, "end process;\n");

    fprintf(fo, "\n");
    
    fprintf(fo, "process (clk)\n");
    fprintf(fo, "begin\n");
    fprintf(fo, "	if (clk'event and clk = '1') then\n");
    fprintf(fo, "		if (from_zpu.memBWriteEnable = '1') then\n");
    fprintf(fo, "			ram(to_integer(unsigned(from_zpu.memBAddr(maxAddrBitBRAM downto 2)))) := from_zpu.memBWrite;\n");
    fprintf(fo, "			to_zpu.memBRead <= from_zpu.memBWrite;\n");
    fprintf(fo, "		else\n");
    fprintf(fo, "			to_zpu.memBRead <= ram(to_integer(unsigned(from_zpu.memBAddr(maxAddrBitBRAM downto 2))));\n");
    fprintf(fo, "		end if;\n");
    fprintf(fo, "	end if;\n");
    fprintf(fo, "end process;\n");
    
    fprintf(fo, "\n");
    fprintf(fo, "\n");
    
    fprintf(fo, "end rtl;\n");
    fprintf(fo, "\n");
    
    close(fd);
    fclose(fo);
    printf("\nMemory usage: %f %\n", (cnt/mem_max_add_bit)*100);
    return 0;
}

