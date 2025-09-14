import serial
inst=serial.Serial("COM41",115200)

RST=bytearray([0b00000000])
WRITE=bytearray([0b01000000])
READ=bytearray([0b10000000])

ADDR=bytearray([0x08,0x00,0x00,0x40])   ##AXI addr is 0x40000008
DATA=bytearray([0x03,0x00,0x00,0x00])   ##AXI data is 0x00000003
inst.write(WRITE)
inst.write(ADDR)
inst.write(DATA)

ADDR=bytearray([0x00,0x00,0x00,0x40])   ##AXI addr is 0x40000000
inst.write(READ)
inst.write(ADDR)
buf=inst.read(4)
print(buf)