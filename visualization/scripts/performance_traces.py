import struct

# Parse performance traces
def parse_file():

    i = 0

    # Open a file to store traces after converting them from binary to integer
    performance_store_file = open("parsed_data/sig.txt", "w+")

    # Open traces binary file in binary mode
    with open("../SIG.BIN", "rb") as performance_binary_file:
        
        # Each trace has two 4-bytes data (timestamp and probes)
        timestamp = performance_binary_file.read(4) 		
        probes = performance_binary_file.read(4)
        
        # If performance_binary_file.read() return false means EOF
        while timestamp and probes:

            # The first data is 0 (i == 0) but after that, if the first byte is 0 it means there's no more traces
            if struct.unpack('I', timestamp)[0] != 0 or i == 0 :
                # Format "iter, timestamp, trace"
                performance_store_file.writelines("{},{},{}\n".format(i,struct.unpack('I', timestamp)[0],struct.unpack('I', probes)[0]))

            # Each trace has two 4-bytes data (timestampt and trace)
            timestamp = performance_binary_file.read(4)
            probes = performance_binary_file.read(4)
            # Next data
            i += 1

    # Close traces store file
    performance_store_file.close()